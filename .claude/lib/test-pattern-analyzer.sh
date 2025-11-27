#!/bin/bash
# test-pattern-analyzer.sh
# 프로젝트 내 테스트 파일 패턴 분석
#
# 기능:
# - 테스트 프레임워크 감지 (Jest, Vitest, Mocha 등)
# - Mock 패턴 추출
# - AAA 템플릿 제공
# - 기존 테스트 파일 import 패턴 추출
#
# 출력 형식:
# FRAMEWORK:<jest|vitest|mocha|unknown>
# MOCK_PATTERN:<jest.mock|vi.mock|unknown>
# IMPORT_PATTERNS:<패턴들>

set -e

# ============================================
# 테스트 프레임워크 감지
# ============================================

detect_test_framework() {
  local framework="unknown"

  # package.json 확인
  if [ -f "package.json" ]; then
    if grep -q '"vitest"' package.json 2>/dev/null; then
      framework="vitest"
    elif grep -q '"jest"' package.json 2>/dev/null; then
      framework="jest"
    elif grep -q '"mocha"' package.json 2>/dev/null; then
      framework="mocha"
    fi
  fi

  # 설정 파일로 추가 확인
  if [ "$framework" = "unknown" ]; then
    if [ -f "vitest.config.ts" ] || [ -f "vitest.config.js" ]; then
      framework="vitest"
    elif [ -f "jest.config.js" ] || [ -f "jest.config.ts" ] || [ -f "jest.config.json" ]; then
      framework="jest"
    elif [ -f ".mocharc.js" ] || [ -f ".mocharc.json" ]; then
      framework="mocha"
    fi
  fi

  echo "$framework"
}

# ============================================
# Mock 패턴 추출
# ============================================

detect_mock_pattern() {
  local framework="$1"
  local mock_pattern="unknown"

  case "$framework" in
    vitest)
      mock_pattern="vi.mock"
      ;;
    jest)
      mock_pattern="jest.mock"
      ;;
    mocha)
      mock_pattern="sinon"
      ;;
  esac

  # 실제 테스트 파일에서 확인
  local test_files=$(find . -type f \( -name "*.test.ts" -o -name "*.test.tsx" -o -name "*.spec.ts" -o -name "*.spec.tsx" \) -not -path "./node_modules/*" 2>/dev/null | head -5)

  if [ -n "$test_files" ]; then
    for file in $test_files; do
      if grep -q "vi\.mock" "$file" 2>/dev/null; then
        mock_pattern="vi.mock"
        break
      elif grep -q "jest\.mock" "$file" 2>/dev/null; then
        mock_pattern="jest.mock"
        break
      fi
    done
  fi

  echo "$mock_pattern"
}

# ============================================
# Import 패턴 추출
# ============================================

extract_import_patterns() {
  local import_patterns=()

  # 테스트 파일에서 일반적인 import 패턴 추출
  local test_files=$(find . -type f \( -name "*.test.ts" -o -name "*.test.tsx" -o -name "*.spec.ts" -o -name "*.spec.tsx" \) -not -path "./node_modules/*" 2>/dev/null | head -10)

  if [ -n "$test_files" ]; then
    for file in $test_files; do
      # 테스트 라이브러리 import 추출
      while IFS= read -r line; do
        # vitest import
        if [[ "$line" =~ ^import.*from.*[\'\"]\@vitest ]]; then
          import_patterns+=("$line")
        fi
        # jest import
        if [[ "$line" =~ ^import.*from.*[\'\"]jest ]]; then
          import_patterns+=("$line")
        fi
        # testing-library import
        if [[ "$line" =~ ^import.*from.*[\'\"]\@testing-library ]]; then
          import_patterns+=("$line")
        fi
      done < <(grep "^import" "$file" 2>/dev/null || true)
    done
  fi

  # 중복 제거 후 출력
  printf '%s\n' "${import_patterns[@]}" | sort -u | head -10
}

# ============================================
# AAA 템플릿 생성
# ============================================

generate_aaa_template() {
  local framework="$1"
  local mock_pattern="$2"

  case "$framework" in
    vitest)
      cat <<'TEMPLATE'
import { describe, it, expect, beforeEach, vi } from 'vitest';

describe('TargetName', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('should do expected behavior', () => {
    // Arrange
    const input = {};

    // Act
    const result = targetFunction(input);

    // Assert
    expect(result).toBeDefined();
  });
});
TEMPLATE
      ;;
    jest)
      cat <<'TEMPLATE'
describe('TargetName', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should do expected behavior', () => {
    // Arrange
    const input = {};

    // Act
    const result = targetFunction(input);

    // Assert
    expect(result).toBeDefined();
  });
});
TEMPLATE
      ;;
    *)
      cat <<'TEMPLATE'
describe('TargetName', () => {
  beforeEach(() => {
    // Setup
  });

  it('should do expected behavior', () => {
    // Arrange
    const input = {};

    // Act
    const result = targetFunction(input);

    // Assert
    expect(result).toBeDefined();
  });
});
TEMPLATE
      ;;
  esac
}

# ============================================
# 테스트 디렉토리 구조 감지
# ============================================

detect_test_structure() {
  local structure="colocated" # 기본값: 소스와 같은 디렉토리

  # __tests__ 디렉토리 존재 확인
  if [ -d "src/__tests__" ] || find . -type d -name "__tests__" -not -path "./node_modules/*" 2>/dev/null | head -1 | grep -q "__tests__"; then
    structure="__tests__"
  fi

  # tests/ 최상위 디렉토리 존재 확인
  if [ -d "tests" ] || [ -d "test" ]; then
    structure="separate"
  fi

  echo "$structure"
}

# ============================================
# 메인 실행
# ============================================

echo "📊 테스트 패턴 분석 시작..." >&2

# 프레임워크 감지
FRAMEWORK=$(detect_test_framework)
echo "FRAMEWORK:$FRAMEWORK"
echo "   프레임워크: $FRAMEWORK" >&2

# Mock 패턴 감지
MOCK_PATTERN=$(detect_mock_pattern "$FRAMEWORK")
echo "MOCK_PATTERN:$MOCK_PATTERN"
echo "   Mock 패턴: $MOCK_PATTERN" >&2

# 테스트 구조 감지
TEST_STRUCTURE=$(detect_test_structure)
echo "TEST_STRUCTURE:$TEST_STRUCTURE"
echo "   테스트 구조: $TEST_STRUCTURE" >&2

# Import 패턴 추출
echo "" >&2
echo "📦 Import 패턴:" >&2
IMPORT_PATTERNS=$(extract_import_patterns)
if [ -n "$IMPORT_PATTERNS" ]; then
  echo "$IMPORT_PATTERNS" | while read -r line; do
    echo "   $line" >&2
  done
  echo "IMPORT_PATTERNS:$(echo "$IMPORT_PATTERNS" | tr '\n' '|')"
else
  echo "   (패턴 없음)" >&2
  echo "IMPORT_PATTERNS:"
fi

# AAA 템플릿 (캐시에 저장)
echo "" >&2
echo "📝 AAA 템플릿 생성..." >&2
mkdir -p .claude/cache
generate_aaa_template "$FRAMEWORK" "$MOCK_PATTERN" > .claude/cache/test-template.txt
echo "   → .claude/cache/test-template.txt 저장됨" >&2

echo "" >&2
echo "✅ 분석 완료" >&2
