# validate-system.sh 개선 계획 (Plan)

**작성일:** 2025-11-11
**예상 기간:** 2-3일
**복잡도:** High

---

## 🎯 실행 전략

### 접근 방식
- **점진적 개선 (Incremental Improvement)**
- **하위 호환성 최우선 (Backward Compatibility First)**
- **테스트 주도 (Test-Driven)**

### 롤아웃 계획
1. Phase 1: Critical 보안 및 안정성 수정 (우선)
2. Phase 2: 코드 품질 개선
3. Phase 3: 확장성 강화
4. Phase 4: 성능 최적화

---

## 📋 Phase 1: Critical 보안 및 안정성 수정

**목표:** P0 우선순위 문제 해결
**예상 시간:** 4-6시간

### 1.1 set -e 문제 해결

**현재 문제:**
```bash
# validate-system.sh:6
set -e  # 전역 활성화

# validate-system.sh:348-352
run_documentation_validation || doc_status=$?  # 의도대로 작동 안 할 수 있음
```

**해결 방안:**
```bash
# validate-system.sh 수정
set -e  # 초기화 및 인자 파싱에서만 사용

# 검증 실행 전 비활성화
set +e  # 에러 수집 모드
run_documentation_validation
doc_status=$?

run_migration_validation
mig_status=$?

run_crossref_validation
ref_status=$?
set -e  # 다시 활성화 (필요시)
```

**수정 파일:**
- `.claude/lib/validate-system.sh:6, 333-354`

**검증:**
```bash
# 문서 검증 실패 시에도 마이그레이션 검증 실행되는지 확인
bash .claude/lib/validate-system.sh --all
```

---

### 1.2 cleanup_temp_dir 보안 강화

**현재 문제:**
```bash
# validation-utils.sh:124-129
cleanup_temp_dir() {
    rm -rf "$temp_dir"  # 경로 검증 없음
}
```

**해결 방안:**
```bash
cleanup_temp_dir() {
    local temp_dir="$1"

    # 안전성 검사
    if [[ -z "$temp_dir" ]]; then
        log_warning "cleanup_temp_dir: 빈 경로"
        return 1
    fi

    # /tmp 또는 /var/tmp 하위만 허용
    case "$temp_dir" in
        /tmp/*|/var/tmp/*)
            if [[ -d "$temp_dir" ]]; then
                rm -rf "$temp_dir"
                log_info "임시 디렉토리 정리: $temp_dir"
                return 0
            fi
            ;;
        *)
            log_error "cleanup_temp_dir: 안전하지 않은 경로: $temp_dir"
            return 1
            ;;
    esac
}
```

**수정 파일:**
- `.claude/lib/validation-utils.sh:124-130`

**검증:**
```bash
# 단위 테스트 추가
bash .claude/lib/__tests__/test-validation-utils.sh
```

---

### 1.3 파일 쓰기 에러 처리 추가

**현재 문제:**
```bash
# report-generator.sh:110-134
cat > "$output_file" << EOF
...
EOF
# 성공 여부 확인 없음
```

**해결 방안:**
```bash
# JSON 보고서 생성 함수 수정
generate_json_report() {
    # ... (기존 코드)

    # 임시 파일에 먼저 작성
    local temp_file
    temp_file=$(mktemp) || {
        log_error "임시 파일 생성 실패"
        return 1
    }

    # JSON 생성
    if ! cat > "$temp_file" << EOF
{
  "id": "$report_id",
  ...
}
EOF
    then
        log_error "JSON 작성 실패"
        rm -f "$temp_file"
        return 1
    fi

    # 최종 위치로 이동
    if ! mv "$temp_file" "$output_file"; then
        log_error "보고서 파일 저장 실패: $output_file"
        rm -f "$temp_file"
        return 1
    fi

    log_success "JSON 보고서 생성: $output_file"
    return 0
}
```

**수정 파일:**
- `.claude/lib/report-generator.sh:24-139`
- `.claude/lib/report-generator.sh:142-243` (Markdown도 동일 적용)

**검증:**
```bash
# 읽기 전용 디렉토리에 쓰기 시도
chmod 444 /tmp/test-report-dir
bash .claude/lib/validate-system.sh
# 예상: 명확한 에러 메시지
```

---

### 1.4 trap 정리 범위 확장

**현재 문제:**
```bash
# validate-migration.sh:69
trap "cleanup_temp_dir $test_dir" RETURN  # 함수 반환 시에만
```

**해결 방안:**
```bash
# validation-utils.sh에 범용 trap 함수 추가
setup_cleanup_trap() {
    local cleanup_cmd="$1"

    # 기존 trap 보존
    local existing_trap
    existing_trap=$(trap -p EXIT)

    if [[ -n "$existing_trap" ]]; then
        # 기존 trap 실행 후 새 cleanup 실행
        eval "trap '$existing_trap ; $cleanup_cmd' EXIT INT TERM"
    else
        trap "$cleanup_cmd" EXIT INT TERM
    fi
}

# validate-migration.sh에서 사용
setup_cleanup_trap "cleanup_temp_dir '$test_dir'"
```

**수정 파일:**
- `.claude/lib/validation-utils.sh` (새 함수 추가)
- `.claude/lib/validate-migration.sh:69, 382, 434`

**검증:**
```bash
# Ctrl+C 테스트
bash .claude/lib/validate-migration.sh &
PID=$!
sleep 1
kill -INT $PID
# 예상: 임시 디렉토리 정리 확인
```

---

## 📋 Phase 2: 코드 품질 개선

**목표:** P1-P2 우선순위 문제 해결
**예상 시간:** 6-8시간

### 2.1 설정 파일 외부화

**목표:** 매직 넘버 제거 (P6)

**구현:**
```bash
# .claude/lib/validation-config.sh (신규 생성)
#!/bin/bash
# Validation System Configuration

# 문서 검증 임계값
readonly VALIDATION_DOC_THRESHOLD_PASS=90
readonly VALIDATION_DOC_THRESHOLD_WARNING=70

# 일관성 점수 임계값
readonly VALIDATION_CONSISTENCY_THRESHOLD_PASS=90
readonly VALIDATION_CONSISTENCY_THRESHOLD_WARNING=70

# 보고서 보존 기간 (일)
readonly VALIDATION_REPORT_RETENTION_DAYS=30

# 타임아웃 (초)
readonly VALIDATION_TIMEOUT_SECONDS=300

# 병렬 실행 여부 (기본값)
readonly VALIDATION_PARALLEL_DEFAULT=false

# jq 필수 여부
readonly VALIDATION_REQUIRE_JQ=false
```

**수정 파일:**
- `.claude/lib/validation-config.sh` (신규)
- `.claude/lib/validate-system.sh` (config source 추가)
- `.claude/lib/validate-documentation.sh:59-66` (상수 사용)
- `.claude/lib/report-generator.sh:349` (보존 기간 사용)

**검증:**
```bash
# 설정 파일 없이 실행 시 기본값 사용
mv .claude/lib/validation-config.sh .claude/lib/validation-config.sh.bak
bash .claude/lib/validate-system.sh
# 예상: 정상 동작 (기본값)
```

---

### 2.2 JSON 처리 통일 및 개선

**목표:** JSON 파싱 중복 제거 (P2), 이스케이핑 (P13)

**구현:**
```bash
# validation-utils.sh에 JSON 유틸리티 추가
parse_json_field() {
    local json="$1"
    local field="$2"
    local default="${3:-0}"

    if command -v jq > /dev/null 2>&1; then
        echo "$json" | jq -r ".${field} // $default" 2>/dev/null || echo "$default"
    else
        # jq 없을 때 폴백 (간단한 경우만)
        local value
        value=$(echo "$json" | grep -o "\"$field\":[0-9]*" | cut -d':' -f2 2>/dev/null)
        echo "${value:-$default}"
    fi
}

generate_json_safely() {
    local -n fields=$1  # nameref (Bash 4.3+)

    if command -v jq > /dev/null 2>&1; then
        # jq로 안전하게 생성
        jq -n \
            --arg id "${fields[id]}" \
            --arg timestamp "${fields[timestamp]}" \
            --argjson score "${fields[score]}" \
            '{
                id: $id,
                timestamp: $timestamp,
                score: $score
            }'
    else
        # 수동 이스케이핑
        cat << EOF
{
  "id": "${fields[id]//\"/\\\"}",
  "timestamp": "${fields[timestamp]}",
  "score": ${fields[score]}
}
EOF
    fi
}
```

**수정 파일:**
- `.claude/lib/validation-utils.sh` (새 함수 추가)
- `.claude/lib/validate-system.sh:361-370` (parse_json_field 사용)
- `.claude/lib/report-generator.sh:24-139` (generate_json_safely 사용)

**검증:**
```bash
# 특수 문자 포함 테스트
# JSON에 ", \n 등 포함 시 정상 처리
```

---

### 2.3 ShellCheck 위반 수정

**목표:** 모든 ShellCheck warnings 해결

**수정 항목:**

1. **SC2116: Useless echo**
   ```bash
   # Before
   local json_result=$(echo "$doc_results" | tail -1)

   # After
   local json_result=$(printf '%s\n' "$doc_results" | tail -1)
   ```

2. **SC2086: Quote to prevent word splitting**
   - 모든 변수 참조에 인용 추가

3. **SC2181: Check exit code directly**
   ```bash
   # Before
   command
   if [[ $? -ne 0 ]]; then

   # After
   if ! command; then
   ```

**수정 파일:**
- 모든 `.sh` 파일

**검증:**
```bash
shellcheck .claude/lib/*.sh
# 예상: 0 warnings
```

---

### 2.4 전역 변수 네임스페이스 관리

**목표:** 변수 오염 방지 (P3)

**구현:**
```bash
# validate-system.sh:23-28 수정
# Before
OVERALL_STATUS="PASS"
CONSISTENCY_SCORE=0

# After
readonly __VALIDATE_SYSTEM_VERSION="2.6.1"
__VALIDATE_SYSTEM_STATUS="PASS"
__VALIDATE_SYSTEM_CONSISTENCY=0
__VALIDATE_SYSTEM_DOC_RESULTS="{}"
__VALIDATE_SYSTEM_MIG_RESULTS="{}"
__VALIDATE_SYSTEM_CROSSREF_RESULTS="{}"
```

**수정 파일:**
- `.claude/lib/validate-system.sh:23-28`
- 모든 참조 위치 업데이트

**검증:**
```bash
# source 테스트
source .claude/lib/validate-system.sh
env | grep -i validate
# 예상: __VALIDATE_로 시작하는 변수만
```

---

## 📋 Phase 3: 확장성 강화

**목표:** 새 기능 추가 용이성
**예상 시간:** 4-6시간

### 3.1 검증 모듈 플러그인화

**구현:**
```bash
# validate-system.sh에 모듈 등록 시스템 추가
declare -A VALIDATION_MODULES

register_validator() {
    local module_path="$1"
    local module_name=$(basename "$module_path" .sh)

    # validate-로 시작하는 파일만
    if [[ "$module_name" == validate-* ]]; then
        VALIDATION_MODULES["$module_name"]="$module_path"
        log_info "검증 모듈 등록: $module_name"
    fi
}

# 자동 탐색
discover_validators() {
    for validator in "$SCRIPT_DIR"/validate-*.sh; do
        if [[ -f "$validator" ]] && [[ "$validator" != *"validate-system.sh" ]]; then
            register_validator "$validator"
        fi
    done
}

# main()에서 호출
discover_validators
```

**수정 파일:**
- `.claude/lib/validate-system.sh` (새 함수 추가)

**검증:**
```bash
# 새 검증 모듈 추가 테스트
touch .claude/lib/validate-custom.sh
bash .claude/lib/validate-system.sh
# 예상: "검증 모듈 등록: validate-custom" 로그
```

---

### 3.2 CLI 옵션 확장

**새 옵션 추가:**
```bash
--fail-fast          # 첫 실패 시 즉시 종료
--parallel           # 병렬 실행 활성화
--format=<format>    # 보고서 포맷 (json, markdown, html)
--timeout=<seconds>  # 타임아웃 설정
--config=<file>      # 커스텀 설정 파일
```

**구현:**
```bash
# parse_arguments() 함수 확장
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --fail-fast)
                FAIL_FAST=true
                shift
                ;;
            --parallel)
                PARALLEL=true
                shift
                ;;
            --format)
                REPORT_FORMAT="$2"
                shift 2
                ;;
            # ... 기존 옵션
        esac
    done
}
```

**수정 파일:**
- `.claude/lib/validate-system.sh:57-101`
- Usage 메시지 업데이트

**검증:**
```bash
bash .claude/lib/validate-system.sh --help
# 예상: 새 옵션 표시
```

---

## 📋 Phase 4: 성능 최적화

**목표:** 실행 시간 40% 단축
**예상 시간:** 3-4시간

### 4.1 병렬 검증 실행

**구현:**
```bash
# validate-system.sh 수정
run_all_validations_parallel() {
    log_info "병렬 검증 실행 중..."

    # 백그라운드 실행
    run_documentation_validation > "$REPORT_DIR/doc.tmp" 2>&1 & pid_doc=$!
    run_migration_validation > "$REPORT_DIR/mig.tmp" 2>&1 & pid_mig=$!
    run_crossref_validation > "$REPORT_DIR/ref.tmp" 2>&1 & pid_ref=$!

    # 결과 대기
    wait $pid_doc
    doc_status=$?
    DOC_VALIDATION_RESULTS=$(tail -1 "$REPORT_DIR/doc.tmp")

    wait $pid_mig
    mig_status=$?
    MIG_VALIDATION_RESULTS=$(tail -1 "$REPORT_DIR/mig.tmp")

    wait $pid_ref
    ref_status=$?
    CROSSREF_VALIDATION_RESULTS=$(tail -1 "$REPORT_DIR/ref.tmp")

    # 임시 파일 정리
    rm -f "$REPORT_DIR"/{doc,mig,ref}.tmp
}
```

**수정 파일:**
- `.claude/lib/validate-system.sh` (새 함수 추가)
- `main()` 함수에서 `--parallel` 옵션 시 호출

**검증:**
```bash
time bash .claude/lib/validate-system.sh
time bash .claude/lib/validate-system.sh --parallel
# 예상: 40% 시간 단축
```

---

### 4.2 조기 종료 최적화

**구현:**
```bash
# validate-crossref.sh 수정
check_critical_files() {
    # ...
    for file in "${CRITICAL_FILES[@]}"; do
        if [[ ! -f "$full_path" ]]; then
            log_error "Critical 파일 없음: $file"
            ((missing_count++))

            # --fail-fast 옵션 시 즉시 반환
            if [[ "${FAIL_FAST:-false}" == "true" ]]; then
                return 1
            fi
        fi
    done
    # ...
}
```

**수정 파일:**
- `.claude/lib/validate-migration.sh:329-363`
- `.claude/lib/validate-crossref.sh:23-110`

**검증:**
```bash
bash .claude/lib/validate-system.sh --fail-fast
# 예상: 첫 실패 시 즉시 종료
```

---

## 🧪 테스트 계획

### 단위 테스트 추가

**신규 테스트 파일:**
```bash
# .claude/lib/__tests__/test-validation-utils.sh
test_cleanup_temp_dir_security() {
    # 안전하지 않은 경로 테스트
    if cleanup_temp_dir "/"; then
        fail "/ 경로 정리 허용됨"
    fi

    # 안전한 경로 테스트
    local temp=$(mktemp -d)
    if ! cleanup_temp_dir "$temp"; then
        fail "안전한 경로 정리 실패"
    fi
}

test_parse_json_field() {
    local json='{"total":10,"passed":8}'
    local result=$(parse_json_field "$json" "total" "0")
    [[ "$result" == "10" ]] || fail "JSON 파싱 실패"
}
```

**추가 파일:**
- `.claude/lib/__tests__/test-validation-utils.sh`
- `.claude/lib/__tests__/test-report-generator.sh`

---

### 통합 테스트

```bash
# .claude/lib/__tests__/integration-test.sh
#!/bin/bash

# 전체 워크플로우 테스트
test_full_validation() {
    bash .claude/lib/validate-system.sh --all
    local status=$?

    # 보고서 생성 확인
    [[ -f .claude/cache/validation-reports/latest.json ]] || fail "JSON 보고서 없음"
    [[ -f .claude/cache/validation-reports/latest.md ]] || fail "MD 보고서 없음"

    return $status
}

# 병렬 실행 테스트
test_parallel_execution() {
    local start=$(date +%s)
    bash .claude/lib/validate-system.sh --parallel
    local end=$(date +%s)
    local duration=$((end - start))

    log_info "병렬 실행 시간: ${duration}초"
}
```

---

## 📦 배포 계획

### 롤백 전략

```bash
# 배포 전 백업
cp -r .claude/lib .claude/lib.backup-$(date +%Y%m%d)

# 롤백 스크립트
#!/bin/bash
# rollback.sh
BACKUP_DIR="${1:-.claude/lib.backup-latest}"
if [[ -d "$BACKUP_DIR" ]]; then
    rm -rf .claude/lib
    cp -r "$BACKUP_DIR" .claude/lib
    echo "Rollback 완료: $BACKUP_DIR"
else
    echo "백업 없음: $BACKUP_DIR"
    exit 1
fi
```

---

### 마이그레이션 가이드

**사용자 공지:**
```markdown
## validate-system.sh v2.7 업그레이드 가이드

### 호환성
- ✅ 기존 CLI 옵션 100% 호환
- ✅ JSON 출력 포맷 유지 (새 필드 추가)
- ⚠️ 설정 파일 위치 변경: `.claude/lib/validation-config.sh`

### 새 기능
- `--parallel`: 병렬 검증으로 40% 빠름
- `--fail-fast`: 첫 실패 시 즉시 종료
- `--format=html`: HTML 보고서 생성

### 마이그레이션 필요 사항
없음 (자동 호환)
```

---

## 📅 일정

| Phase | 작업 | 예상 시간 | 담당 |
|-------|------|----------|------|
| Phase 1.1 | set -e 문제 해결 | 1h | - |
| Phase 1.2 | cleanup 보안 강화 | 1h | - |
| Phase 1.3 | 파일 쓰기 에러 처리 | 1.5h | - |
| Phase 1.4 | trap 범위 확장 | 1.5h | - |
| **Phase 1 소계** | | **5h** | |
| Phase 2.1 | 설정 외부화 | 2h | - |
| Phase 2.2 | JSON 처리 통일 | 2h | - |
| Phase 2.3 | ShellCheck 수정 | 2h | - |
| Phase 2.4 | 전역 변수 관리 | 1h | - |
| **Phase 2 소계** | | **7h** | |
| Phase 3.1 | 플러그인화 | 2h | - |
| Phase 3.2 | CLI 옵션 확장 | 2h | - |
| **Phase 3 소계** | | **4h** | |
| Phase 4.1 | 병렬 실행 | 2h | - |
| Phase 4.2 | 조기 종료 | 1h | - |
| **Phase 4 소계** | | **3h** | |
| **테스트** | 단위/통합 테스트 | 4h | - |
| **문서화** | 주석, README 업데이트 | 2h | - |
| **총계** | | **25h** (~3일) | |

---

**다음 단계:** tasks.md 작성 (구체적인 체크리스트)
