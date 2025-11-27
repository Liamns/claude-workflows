#!/bin/bash
# PreHook: /test 실행 전 대상 파일 및 관련 리소스 수집
# Exit codes: 0=성공(계속)
#
# 기능:
# - 대상 파일 감지 (인자 또는 git diff)
# - 관련 DTO/Type 검색 (reusability-checker 연동)
# - 기존 테스트 패턴 분석
# - Mock/Stub 파일 검색

set -e

# ============================================
# 인자 파싱
# ============================================

TARGET_FILES=()
COVERAGE_MODE=false
FIX_MODE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --coverage)
      COVERAGE_MODE=true
      shift
      ;;
    --fix)
      FIX_MODE=true
      shift
      ;;
    *)
      # 파일 경로로 간주
      if [ -f "$1" ]; then
        TARGET_FILES+=("$1")
      fi
      shift
      ;;
  esac
done

echo "🧪 테스트 생성 준비 중..." >&2

# ============================================
# 대상 파일 감지
# ============================================

# 인자로 파일이 지정되지 않은 경우 git diff 사용
if [ ${#TARGET_FILES[@]} -eq 0 ]; then
  echo "" >&2
  echo "📁 변경된 파일 감지 중..." >&2

  # git diff로 변경된 .ts/.tsx 파일 (테스트 파일 제외)
  while IFS= read -r file; do
    if [[ -n "$file" ]]; then
      TARGET_FILES+=("$file")
    fi
  done < <(git diff --name-only 2>/dev/null | grep -E '\.(ts|tsx)$' | grep -v -E '\.test\.|\.spec\.' || true)

  # staged 파일도 포함
  while IFS= read -r file; do
    if [[ -n "$file" ]]; then
      # 중복 제거
      if [[ ! " ${TARGET_FILES[*]} " =~ " ${file} " ]]; then
        TARGET_FILES+=("$file")
      fi
    fi
  done < <(git diff --cached --name-only 2>/dev/null | grep -E '\.(ts|tsx)$' | grep -v -E '\.test\.|\.spec\.' || true)
fi

if [ ${#TARGET_FILES[@]} -eq 0 ]; then
  echo "" >&2
  echo "⚠️  대상 파일이 없습니다" >&2
  echo "변경된 파일이 없거나 파일 경로를 지정해주세요:" >&2
  echo "  /test <file-path>" >&2
  echo "" >&2
  # 파일이 없어도 명령어 실행은 허용 (명령어에서 처리)
fi

echo "   대상 파일: ${#TARGET_FILES[@]}개" >&2
for file in "${TARGET_FILES[@]}"; do
  echo "   - $file" >&2
done

# ============================================
# 관련 DTO/Type 검색
# ============================================

echo "" >&2
echo "🔍 관련 리소스 검색 중..." >&2

RELATED_DTOS=""
RELATED_TYPES=""

# reusability-checker 스크립트 경로
REUSABILITY_CHECKER=".claude/lib/reusability/reusability-checker.sh"

if [ -f "$REUSABILITY_CHECKER" ]; then
  for file in "${TARGET_FILES[@]}"; do
    # 파일명에서 키워드 추출 (예: OrderForm.tsx → Order)
    filename=$(basename "$file" | sed 's/\.[^.]*$//')
    keyword=$(echo "$filename" | sed 's/Form$//; s/Page$//; s/Component$//; s/Api$//')

    if [ -n "$keyword" ]; then
      # DTO 검색
      dto_result=$(bash "$REUSABILITY_CHECKER" -t dto "$keyword" 2>/dev/null | head -3 || true)
      if [ -n "$dto_result" ]; then
        RELATED_DTOS="$RELATED_DTOS$dto_result"$'\n'
      fi

      # Type 검색
      type_result=$(bash "$REUSABILITY_CHECKER" -t type "$keyword" 2>/dev/null | head -3 || true)
      if [ -n "$type_result" ]; then
        RELATED_TYPES="$RELATED_TYPES$type_result"$'\n'
      fi
    fi
  done

  if [ -n "$RELATED_DTOS" ]; then
    echo "   ✓ DTO 발견" >&2
  fi
  if [ -n "$RELATED_TYPES" ]; then
    echo "   ✓ Type 발견" >&2
  fi
else
  echo "   ⚠️  reusability-checker 미발견, 검색 건너뜀" >&2
fi

# ============================================
# 기존 테스트 패턴 분석
# ============================================

echo "" >&2
echo "📊 테스트 패턴 분석 중..." >&2

TEST_FRAMEWORK="unknown"
MOCK_PATTERN="unknown"

# test-pattern-analyzer 스크립트 경로
PATTERN_ANALYZER=".claude/lib/test-pattern-analyzer.sh"

if [ -f "$PATTERN_ANALYZER" ]; then
  pattern_result=$(bash "$PATTERN_ANALYZER" 2>/dev/null || true)

  # 결과 파싱
  if echo "$pattern_result" | grep -q "FRAMEWORK:"; then
    TEST_FRAMEWORK=$(echo "$pattern_result" | grep "FRAMEWORK:" | cut -d: -f2 | tr -d ' ')
  fi
  if echo "$pattern_result" | grep -q "MOCK_PATTERN:"; then
    MOCK_PATTERN=$(echo "$pattern_result" | grep "MOCK_PATTERN:" | cut -d: -f2 | tr -d ' ')
  fi
else
  # 패턴 분석기 없으면 직접 감지
  if [ -f "package.json" ]; then
    if grep -q '"vitest"' package.json 2>/dev/null; then
      TEST_FRAMEWORK="vitest"
      MOCK_PATTERN="vi.mock"
    elif grep -q '"jest"' package.json 2>/dev/null; then
      TEST_FRAMEWORK="jest"
      MOCK_PATTERN="jest.mock"
    fi
  fi
fi

echo "   - 프레임워크: $TEST_FRAMEWORK" >&2
echo "   - Mock 패턴: $MOCK_PATTERN" >&2

# ============================================
# Mock/Stub 파일 검색
# ============================================

echo "" >&2
echo "🎭 Mock/Stub 검색 중..." >&2

EXISTING_MOCKS=()

# __mocks__ 디렉토리 검색
shopt -s nullglob
for mock_file in **/__mocks__/*.ts **/__mocks__/*.tsx; do
  EXISTING_MOCKS+=("$mock_file")
done

# *.mock.ts 파일 검색
for mock_file in **/*.mock.ts **/*.mock.tsx; do
  EXISTING_MOCKS+=("$mock_file")
done
shopt -u nullglob

echo "   발견된 Mock: ${#EXISTING_MOCKS[@]}개" >&2

# ============================================
# 결과 출력 (stdout으로, 명령어가 파싱)
# ============================================

echo "" >&2
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2

# stdout으로 구조화된 결과 출력
echo "TARGET_FILES:$(IFS=','; echo "${TARGET_FILES[*]}")"
echo "COVERAGE_MODE:$COVERAGE_MODE"
echo "FIX_MODE:$FIX_MODE"
echo "TEST_FRAMEWORK:$TEST_FRAMEWORK"
echo "MOCK_PATTERN:$MOCK_PATTERN"
echo "EXISTING_MOCKS:$(IFS=','; echo "${EXISTING_MOCKS[*]}")"

# 캐시 저장
mkdir -p .claude/cache
cat > .claude/cache/test-context.json <<EOF
{
  "target_files": [$(printf '"%s",' "${TARGET_FILES[@]}" | sed 's/,$//')],
  "coverage_mode": $COVERAGE_MODE,
  "fix_mode": $FIX_MODE,
  "test_framework": "$TEST_FRAMEWORK",
  "mock_pattern": "$MOCK_PATTERN",
  "existing_mocks": [$(printf '"%s",' "${EXISTING_MOCKS[@]}" | sed 's/,$//')],
  "analyzed_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF

exit 0
