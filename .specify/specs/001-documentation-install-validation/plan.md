# 구현 계획: 문서 및 설치 검증 시스템

> 이 문서는 research.md와 data-model.md를 기반으로 작성되었습니다.
> 참조: [research.md](./research.md), [data-model.md](./data-model.md)

## 기술 기반

### 언어/버전
- Bash 4.0+
- 호환성: macOS (Darwin), Linux

### 주요 의존성
- **필수**:
  - grep (BSD/GNU 호환)
  - sed (BSD/GNU 호환)
  - diff
  - mktemp
  - date
- **선택적**:
  - jq (JSON 보고서 생성용)
  - uuidgen (보고서 ID 생성용, 대체 가능)

### 저장소
- 파일 시스템 기반
- 보고서 저장: `.claude/cache/validation-reports/`
- 임시 파일: `mktemp -d` 생성 디렉토리
- 히스토리: 최근 30일 자동 유지

### 테스트 프레임워크
- Bash 스크립트 직접 테스트
- 통합 테스트: 실제 환경에서 검증 스크립트 실행
- CI/CD: GitHub Actions 통합

## Constitution 준수 여부

| 조항 | 상태 | 위반사항 | 정당화 | 거부된 대안 |
|------|------|---------|--------|------------|
| I: Library-First | ✅ | 없음 | 표준 Unix 도구만 사용 (grep, sed, diff) | Python/Node 스크립팅 (추가 런타임 필요) |
| III: Test-First | ✅ | 없음 | 검증 스크립트 자체가 테스트 도구 | - |
| VIII: Anti-Abstraction | ✅ | 없음 | 직접 구현, 최소 추상화 | 복잡한 프레임워크 (불필요) |
| 재사용성 | ⭐⭐⭐⭐⭐ | 없음 | install.sh의 health_check, verify_installation 재사용 | 새로 작성 (중복 코드) |

**재사용하는 기존 패턴**:
- `install.sh:health_check()` - 설치 상태 검증
- `install.sh:verify_installation()` - 파일 무결성 검증
- `install.sh:validate_installation()` - 버전 및 파일 검증
- `install.sh:detect_installation()` - 버전 감지
- `.claude/lib/migrate-*.sh` - 마이그레이션 패턴

## Phase 0: Research
[Link to research.md](./research.md)

**주요 발견 사항**:
- 기존 검증 함수 3개 발견 (health_check, verify_installation, validate_installation)
- 마이그레이션 스크립트 패턴 재사용 가능
- 문서 구조가 일관적 (Step N 패턴)
- 단순 패턴 매칭으로 충분

**실현 가능성**: 95% (매우 높음)
- Bash 스크립트로 모든 요구사항 구현 가능
- 표준 Unix 도구만 사용
- 복잡한 의존성 없음

## Phase 1: Design Artifacts
- [Data Model](./data-model.md) - ValidationReport, DocumentValidation, MigrationValidation, CrossRefValidation
- [Quickstart Guide](./quickstart.md) - 설치 및 사용 가이드
- API Contracts: N/A (Bash 함수 시그니처는 data-model.md에 정의됨)

## 소스 코드 구조

```
.claude/
├── lib/
│   ├── validate-system.sh           # 메인 검증 스크립트
│   ├── validate-documentation.sh    # 문서 검증 모듈
│   ├── validate-migration.sh        # 마이그레이션 검증 모듈
│   ├── validate-crossref.sh         # 교차 참조 검증 모듈
│   ├── report-generator.sh          # 보고서 생성 모듈
│   └── validation-utils.sh          # 공통 유틸리티 함수
├── cache/
│   └── validation-reports/
│       ├── YYYY-MM-DD-HHMMSS.json
│       ├── YYYY-MM-DD-HHMMSS.md
│       └── latest.json (symlink)
└── templates/
    └── validation/
        └── report-template.md        # Markdown 보고서 템플릿
```

## 구현 단계

### Phase 1: 기본 검증 (1-2일)

**목표**: 파일 존재 및 버전 검증
**산출물**:
- `validate-system.sh` (기본 구조)
- `validation-utils.sh` (공통 함수)

**기능**:
- 명령어 파일 존재 확인
- 버전 파일 검증
- Deprecated 파일 체크

### Phase 2: 문서 검증 (2-3일)

**목표**: 문서-코드 일관성 검증
**산출물**:
- `validate-documentation.sh`
- 문서 파싱 함수
- 일치율 계산 로직

**기능**:
- Step 패턴 추출 (`grep -E "^### Step [0-9]+"`)
- 코드 블록 추출 (` ```bash` 패턴)
- 일치율 계산 및 보고

### Phase 3: 마이그레이션 검증 (1-2일)

**목표**: 마이그레이션 시나리오 테스트
**산출물**:
- `validate-migration.sh`
- 환경 설정 스크립트
- 시나리오 테스트 로직

**기능**:
- 임시 환경 생성 (`mktemp -d`)
- v1.0 → v2.5 시나리오
- v2.4 → v2.5 시나리오
- Deprecated 파일 제거 검증
- Critical 파일 존재 검증

### Phase 4: 교차 참조 검증 (1일)

**목표**: 링크 및 참조 유효성 검증
**산출물**:
- `validate-crossref.sh`
- 링크 추출 로직
- 파일 존재 확인

**기능**:
- 마크다운 링크 추출 (`grep -oE '\[.*\]\([^)]+\)'`)
- 상대 경로 해석
- 에이전트/스킬 참조 검증
- 깨진 링크 보고

### Phase 5: 보고서 생성 (1일)

**목표**: JSON 및 Markdown 보고서 생성
**산출물**:
- `report-generator.sh`
- JSON 템플릿
- Markdown 템플릿

**기능**:
- JSON 보고서 생성 (jq 사용)
- Markdown 보고서 생성 (템플릿 기반)
- 터미널 색상 출력
- 히스토리 관리 (30일 보존)

## 예상 타임라인

- **Phase 1**: 1-2일
- **Phase 2**: 2-3일
- **Phase 3**: 1-2일
- **Phase 4**: 1일
- **Phase 5**: 1일

**전체**: 5-7일 (spec.md의 예상 소요시간과 일치)

## 핵심 기능 명세

### 1. 문서 검증 (`validate-documentation.sh`)

```bash
#!/bin/bash
# validate-documentation.sh
# 모든 슬래시 명령어 문서의 일관성 검증

validate_all_documentation() {
  local results="[]"
  local total=0
  local passed=0

  echo "📄 문서 검증 중..."

  for cmd_file in .claude/commands/*.md; do
    echo "  검증 중: $(basename "$cmd_file")"
    local result=$(validate_single_doc "$cmd_file")
    local consistency=$(echo "$result" | jq -r '.consistencyPercentage')

    if [[ $consistency -ge 90 ]]; then
      echo "    ✓ $(basename "$cmd_file" .md) - $consistency%"
      ((passed++))
    else
      echo "    ✗ $(basename "$cmd_file" .md) - $consistency% (불일치)"
    fi

    results=$(echo "$results" | jq ". += [$result]")
    ((total++))
  done

  echo "  완료: $passed/$total 통과"
  echo "$results"
}

validate_single_doc() {
  local doc_file="$1"
  local command_name=$(basename "$doc_file" .md)

  # Step 추출
  local steps=$(grep -E "^### Step [0-9]+" "$doc_file" | sed 's/^### //')
  local step_count=$(echo "$steps" | wc -l | tr -d ' ')

  # 코드 블록 추출 (placeholder)
  local code_blocks=$(grep -A 10 '```bash' "$doc_file" | grep -v '```' | head -20)

  # 일치율 계산 (placeholder - 실제 구현에서는 더 복잡)
  local consistency=90

  # JSON 결과 생성
  jq -n \
    --arg name "$command_name" \
    --arg path "$doc_file" \
    --argjson steps "$(echo "$steps" | jq -R . | jq -s .)" \
    --argjson percent "$consistency" \
    '{
      commandName: $name,
      filePath: $path,
      extractedSteps: $steps,
      actualImplementation: [],
      matches: [],
      discrepancies: [],
      consistencyPercentage: $percent
    }'
}
```

### 2. 마이그레이션 검증 (`validate-migration.sh`)

```bash
#!/bin/bash
# validate-migration.sh
# 마이그레이션 시나리오 검증

validate_migration_scenario() {
  local from_version="$1"
  local to_version="$2"
  local scenario_name="$from_version to $to_version"

  echo "🔄 마이그레이션 검증: $scenario_name"

  # 임시 디렉토리 생성
  local test_dir=$(mktemp -d)
  trap "rm -rf $test_dir" EXIT

  echo "  임시 환경: $test_dir"

  # 환경 설정 (from_version에 맞는 파일 구조 생성)
  setup_version_environment "$test_dir" "$from_version"

  # 마이그레이션 실행
  local log_file="$test_dir/migration.log"
  echo "  마이그레이션 실행 중..."
  bash install.sh "$test_dir" > "$log_file" 2>&1
  local exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    echo "    ✓ 마이그레이션 성공"
  else
    echo "    ✗ 마이그레이션 실패 (종료 코드: $exit_code)"
    cat "$log_file"
    return 1
  fi

  # Deprecated 파일 검증
  check_deprecated_files "$test_dir" "$from_version"

  # Critical 파일 검증
  check_critical_files "$test_dir"

  echo "  ✓ $scenario_name 검증 완료"
  return 0
}

setup_version_environment() {
  local test_dir="$1"
  local version="$2"

  # 버전에 따라 파일 구조 생성
  case "$version" in
    "1.0.0")
      # v1.0 특징: major-*.md 파일들
      mkdir -p "$test_dir/.claude/commands"
      touch "$test_dir/.claude/commands/major-specify.md"
      touch "$test_dir/.claude/commands/major-clarify.md"
      ;;
    "2.4.0")
      # v2.4 특징: 통합된 major.md
      mkdir -p "$test_dir/.claude/commands"
      touch "$test_dir/.claude/commands/major.md"
      ;;
  esac

  echo "  환경 설정 완료: v$version"
}
```

### 3. 교차 참조 검증 (`validate-crossref.sh`)

```bash
#!/bin/bash
# validate-crossref.sh
# 마크다운 링크 및 파일 참조 검증

validate_all_cross_references() {
  local results="[]"
  local total=0
  local valid=0

  echo "🔗 교차 참조 검증 중..."

  while IFS= read -r md_file; do
    # 마크다운 링크 추출
    local links=$(grep -oE '\[.*\]\([^)]+\)' "$md_file" | sed 's/.*(\(.*\))/\1/')

    while IFS= read -r link; do
      [[ -z "$link" ]] && continue
      [[ "$link" =~ ^http ]] && continue  # 외부 링크 건너뛰기

      ((total++))

      if validate_link "$md_file" "$link"; then
        ((valid++))
      fi
    done <<< "$links"
  done < <(find .claude -name "*.md")

  echo "  완료: $valid/$total 유효"

  local invalid=$((total - valid))
  if [[ $invalid -gt 0 ]]; then
    echo "  ⚠️  깨진 링크: $invalid개"
  fi
}

validate_link() {
  local source="$1"
  local link="$2"

  local source_dir=$(dirname "$source")
  local target_path="$source_dir/$link"

  # 상대 경로 정규화
  target_path=$(realpath -m "$target_path" 2>/dev/null || echo "$target_path")

  if [[ -f "$target_path" ]]; then
    return 0
  else
    echo "    ✗ 깨진 링크: $(basename "$source"):$link"
    return 1
  fi
}
```

## 품질 보증

### 테스트 전략
1. **단위 테스트**: 각 검증 함수 독립 테스트
2. **통합 테스트**: 전체 검증 스크립트 실행
3. **시나리오 테스트**: 실제 환경에서 마이그레이션 시뮬레이션

### 성능 목표 (spec.md 기준)
- 전체 검증: < 5분
- 개별 문서 검증: < 10초
- 마이그레이션 시뮬레이션: < 1분/시나리오

### 에러 처리
- 모든 함수는 명확한 종료 코드 반환 (0=성공, 1-99=에러)
- 상세한 에러 메시지 출력 (stderr)
- 임시 파일 자동 정리 (`trap`)

## 위험 및 완화

| 위험 | 완화 방안 |
|------|---------|
| Bash 버전 호환성 | Bash 4.0+ 최소 요구사항 명시, 호환성 테스트 |
| 임시 디렉토리 권한 | `mktemp -d` 사용, 권한 확인 |
| jq 미설치 | 선택적 의존성, JSON 없이도 작동 |
| Git 저장소 없음 | 사전 조건 확인, 명확한 에러 메시지 |

## 다음 단계

1. ✅ 설계 완료 (plan.md)
2. ⏭️ 작업 분해 (tasks.md)
3. ⏭️ 구현 시작
4. ⏭️ 테스트 및 검증
5. ⏭️ CI/CD 통합
