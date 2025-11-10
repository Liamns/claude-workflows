# validate-system.sh 개선 작업 태스크 (Tasks)

**작성일:** 2025-11-11
**우선순위:** Phase 1 → Phase 2 → Phase 3 → Phase 4

---

## ✅ Phase 1: Critical 보안 및 안정성 수정

### Task 1.1: set -e 문제 해결

**파일:** `.claude/lib/validate-system.sh`

- [ ] Line 333 앞에 주석 추가: `# 에러 수집 모드: 모든 검증 실행`
- [ ] Line 333에 `set +e` 추가
- [ ] Line 348-352 수정:
  ```bash
  run_documentation_validation
  doc_status=$?

  echo ""

  run_migration_validation
  mig_status=$?

  echo ""

  run_crossref_validation
  ref_status=$?
  ```
- [ ] Line 353 뒤에 `set -e` 재활성화 (필요 시)
- [ ] 주석 추가: 왜 `set +e`가 필요한지 설명

**검증:**
- [ ] 문서 검증 실패 시뮬레이션 후 나머지 검증 실행 확인
- [ ] 모든 검증 실행 후 개별 상태 코드 수집 확인

---

### Task 1.2: cleanup_temp_dir 보안 강화

**파일:** `.claude/lib/validation-utils.sh`

- [ ] Line 124-130 전체 교체:
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
              else
                  log_warning "디렉토리 없음: $temp_dir"
                  return 1
              fi
              ;;
          *)
              log_error "cleanup_temp_dir: 안전하지 않은 경로: $temp_dir"
              return 1
              ;;
      esac
  }
  ```
- [ ] 주석 추가: 보안상의 이유로 경로 검증 필수

**검증:**
- [ ] `cleanup_temp_dir "/"` 호출 시 에러 반환 확인
- [ ] `cleanup_temp_dir "/home/user"` 호출 시 에러 반환 확인
- [ ] 정상 경로 (`/tmp/test-*`) 정리 확인

---

### Task 1.3: 파일 쓰기 에러 처리 추가

**파일:** `.claude/lib/report-generator.sh`

#### Subtask 1.3.1: generate_json_report() 수정

- [ ] Line 24-139 함수 수정:
  - [ ] 함수 시작 부분에 임시 파일 생성:
    ```bash
    local temp_file
    temp_file=$(mktemp) || {
        log_error "임시 파일 생성 실패"
        return 1
    }
    ```
  - [ ] Line 110-134 cat 블록을 `if ! cat > "$temp_file" << EOF` 로 변경
  - [ ] cat 실패 시 임시 파일 정리 및 에러 반환
  - [ ] `mv "$temp_file" "$output_file"` 추가 및 에러 처리
  - [ ] 실패 시 임시 파일 정리

- [ ] Line 136 `log_success` 메시지 유지

**검증:**
- [ ] 읽기 전용 디렉토리 쓰기 시도 시 명확한 에러
- [ ] 디스크 공간 부족 시뮬레이션 (가능하면)

#### Subtask 1.3.2: generate_markdown_report() 동일 적용

- [ ] Line 142-243 함수에도 동일한 패턴 적용

---

### Task 1.4: trap 정리 범위 확장

**파일:** `.claude/lib/validation-utils.sh`, `.claude/lib/validate-migration.sh`

#### Subtask 1.4.1: 범용 trap 함수 추가

- [ ] `validation-utils.sh` Line 220 (마지막) 앞에 새 함수 추가:
  ```bash
  # Trap 설정 - 여러 시그널 처리
  setup_cleanup_trap() {
      local cleanup_cmd="$1"

      # 기존 trap 보존
      local existing_trap
      existing_trap=$(trap -p EXIT 2>/dev/null | sed "s/^trap -- '\(.*\)' EXIT$/\1/")

      if [[ -n "$existing_trap" ]]; then
          # 기존 trap 실행 후 새 cleanup 실행
          trap "$existing_trap ; $cleanup_cmd" EXIT INT TERM
      else
          trap "$cleanup_cmd" EXIT INT TERM
      fi
  }
  ```

#### Subtask 1.4.2: validate-migration.sh 수정

- [ ] Line 69 교체:
  ```bash
  setup_cleanup_trap "cleanup_temp_dir '$test_dir'"
  ```
- [ ] Line 382 교체 (동일)
- [ ] Line 434 교체 (동일)

**검증:**
- [ ] 정상 완료 시 임시 디렉토리 정리 확인
- [ ] Ctrl+C 인터럽트 시 임시 디렉토리 정리 확인
- [ ] SIGTERM 시그널 시 임시 디렉토리 정리 확인

---

## ✅ Phase 2: 코드 품질 개선

### Task 2.1: 설정 파일 외부화

**파일:** `.claude/lib/validation-config.sh` (신규)

#### Subtask 2.1.1: 설정 파일 생성

- [ ] 신규 파일 생성: `.claude/lib/validation-config.sh`
- [ ] 내용 작성:
  ```bash
  #!/bin/bash
  # Validation System Configuration
  # 이 파일을 수정하여 검증 임계값 및 동작 변경 가능

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

  # 병렬 실행 기본값
  readonly VALIDATION_PARALLEL_DEFAULT=false

  # jq 필수 여부
  readonly VALIDATION_REQUIRE_JQ=false

  # 점수 계산 가중치
  readonly VALIDATION_SCORE_FILE_EXISTS=10
  readonly VALIDATION_SCORE_STEP_EXISTS=30
  readonly VALIDATION_SCORE_CODE_EXISTS=30
  readonly VALIDATION_SCORE_BALANCE=30
  ```

#### Subtask 2.1.2: 설정 파일 로드

- [ ] `validate-system.sh` Line 12 뒤에 추가:
  ```bash
  # 설정 로드 (있으면)
  CONFIG_FILE="${CONFIG_FILE:-$SCRIPT_DIR/validation-config.sh}"
  if [[ -f "$CONFIG_FILE" ]]; then
      source "$CONFIG_FILE"
  else
      # 기본값 (호환성)
      readonly VALIDATION_DOC_THRESHOLD_PASS=90
      readonly VALIDATION_DOC_THRESHOLD_WARNING=70
  fi
  ```

#### Subtask 2.1.3: 코드 내 상수 교체

- [ ] `validate-documentation.sh` Line 59-66:
  ```bash
  if [[ $consistency -ge $VALIDATION_DOC_THRESHOLD_PASS ]]; then
      log_success "..."
  elif [[ $consistency -ge $VALIDATION_DOC_THRESHOLD_WARNING ]]; then
      log_warning "..."
  ```
- [ ] `validate-system.sh` Line 163, 375:
  - `90` → `$VALIDATION_DOC_THRESHOLD_PASS`
  - `70` → `$VALIDATION_CONSISTENCY_THRESHOLD_WARNING`
- [ ] `report-generator.sh` Line 349:
  - `30` → `$VALIDATION_REPORT_RETENTION_DAYS`
- [ ] `validate-documentation.sh` Line 206-223:
  - 점수 가중치를 상수로 교체

**검증:**
- [ ] 설정 파일 수정 후 동작 변경 확인
- [ ] 설정 파일 없이 실행 시 기본값 사용 확인

---

### Task 2.2: JSON 처리 통일 및 개선

**파일:** `.claude/lib/validation-utils.sh`

#### Subtask 2.2.1: JSON 유틸리티 함수 추가

- [ ] Line 220 앞에 새 함수 추가:
  ```bash
  # JSON 필드 파싱 (jq 우선, 폴백 제공)
  parse_json_field() {
      local json="$1"
      local field="$2"
      local default="${3:-0}"

      if command -v jq > /dev/null 2>&1; then
          local value
          value=$(printf '%s\n' "$json" | jq -r ".${field} // ${default}" 2>/dev/null)
          echo "${value:-$default}"
      else
          # 폴백: grep + cut (간단한 숫자 필드만)
          local value
          value=$(printf '%s\n' "$json" | grep -o "\"$field\":[0-9]*" | cut -d':' -f2 2>/dev/null)
          echo "${value:-$default}"
      fi
  }
  ```

#### Subtask 2.2.2: validate-system.sh에서 사용

- [ ] Line 361-368 교체:
  ```bash
  if [[ -n "$DOC_VALIDATION_RESULTS" ]] && [[ "$DOC_VALIDATION_RESULTS" != "{}" ]]; then
      doc_avg=$(parse_json_field "$DOC_VALIDATION_RESULTS" "avgConsistency" "0")
  fi

  if [[ -n "$CROSSREF_VALIDATION_RESULTS" ]] && [[ "$CROSSREF_VALIDATION_RESULTS" != "{}" ]]; then
      ref_validity=$(parse_json_field "$CROSSREF_VALIDATION_RESULTS" "validity" "100")
  fi
  ```

#### Subtask 2.2.3: JSON 생성 함수 추가 (선택적)

- [ ] `validation-utils.sh`에 안전한 JSON 생성 함수 추가 (보류: Phase 2 범위 초과 가능)

**검증:**
- [ ] jq 있을 때 정상 동작
- [ ] jq 없을 때 폴백 동작
- [ ] 잘못된 JSON 입력 시 기본값 반환

---

### Task 2.3: ShellCheck 위반 수정

**파일:** 모든 `.sh` 파일

#### Subtask 2.3.1: SC2116 (Useless echo) 수정

- [ ] `validate-system.sh` Line 142:
  ```bash
  # Before
  local json_result=$(echo "$doc_results" | tail -1)

  # After
  local json_result=$(printf '%s\n' "$doc_results" | tail -1)
  ```
- [ ] 유사한 패턴을 모든 파일에서 검색 및 수정

#### Subtask 2.3.2: SC2181 (Check exit code directly) 수정

- [ ] 모든 파일에서 패턴 검색:
  ```bash
  # Before
  command
  if [[ $? -ne 0 ]]; then

  # After
  if ! command; then
  ```

#### Subtask 2.3.3: ShellCheck 실행 및 확인

- [ ] 각 파일별 shellcheck 실행:
  ```bash
  shellcheck .claude/lib/validate-system.sh
  shellcheck .claude/lib/validation-utils.sh
  shellcheck .claude/lib/validate-documentation.sh
  shellcheck .claude/lib/validate-migration.sh
  shellcheck .claude/lib/validate-crossref.sh
  shellcheck .claude/lib/report-generator.sh
  ```
- [ ] 모든 warnings 해결

**검증:**
- [ ] `shellcheck .claude/lib/*.sh` 실행 시 0 warnings

---

### Task 2.4: 전역 변수 네임스페이스 관리

**파일:** `.claude/lib/validate-system.sh`

#### Subtask 2.4.1: 전역 변수 리네임

- [ ] Line 23-28 교체:
  ```bash
  # 전역 변수 (네임스페이스: __VALIDATE_SYSTEM_)
  readonly __VALIDATE_SYSTEM_VERSION="2.7.0"
  __VALIDATE_SYSTEM_STATUS="PASS"
  __VALIDATE_SYSTEM_CONSISTENCY=0
  __VALIDATE_SYSTEM_START_TIME=$(date +%s)
  __VALIDATE_SYSTEM_DOC_RESULTS="{}"
  __VALIDATE_SYSTEM_MIG_RESULTS="{}"
  __VALIDATE_SYSTEM_CROSSREF_RESULTS="{}"
  ```

#### Subtask 2.4.2: 모든 참조 업데이트

- [ ] 함수 내에서 사용하는 모든 위치 검색 및 교체:
  - `OVERALL_STATUS` → `__VALIDATE_SYSTEM_STATUS`
  - `CONSISTENCY_SCORE` → `__VALIDATE_SYSTEM_CONSISTENCY`
  - `START_TIME` → `__VALIDATE_SYSTEM_START_TIME`
  - `DOC_VALIDATION_RESULTS` → `__VALIDATE_SYSTEM_DOC_RESULTS`
  - `MIG_VALIDATION_RESULTS` → `__VALIDATE_SYSTEM_MIG_RESULTS`
  - `CROSSREF_VALIDATION_RESULTS` → `__VALIDATE_SYSTEM_CROSSREF_RESULTS`

**검증:**
- [ ] source 후 `env | grep VALIDATE` 실행
- [ ] `__VALIDATE_` 접두사 변수만 존재 확인

---

## ✅ Phase 3: 확장성 강화

### Task 3.1: 검증 모듈 플러그인화

**파일:** `.claude/lib/validate-system.sh`

#### Subtask 3.1.1: 모듈 등록 시스템 추가

- [ ] Line 29 뒤에 추가:
  ```bash
  # 검증 모듈 레지스트리
  declare -A VALIDATION_MODULES
  ```

- [ ] Line 101 뒤 (parse_arguments 함수 뒤)에 새 함수 추가:
  ```bash
  # 검증 모듈 등록
  register_validator() {
      local module_path="$1"
      local module_name
      module_name=$(basename "$module_path" .sh)

      # validate-로 시작하고 validate-system이 아닌 파일만
      if [[ "$module_name" == validate-* ]] && [[ "$module_name" != "validate-system" ]]; then
          VALIDATION_MODULES["$module_name"]="$module_path"
          if [[ "$VERBOSE" == "true" ]]; then
              log_info "검증 모듈 등록: $module_name"
          fi
      fi
  }

  # 검증 모듈 자동 탐색
  discover_validators() {
      for validator in "$SCRIPT_DIR"/validate-*.sh; do
          if [[ -f "$validator" ]]; then
              register_validator "$validator"
          fi
      done
  }
  ```

#### Subtask 3.1.2: main() 함수에서 호출

- [ ] `main()` 함수 시작 부분에 추가:
  ```bash
  # 검증 모듈 자동 탐색
  discover_validators
  ```

**검증:**
- [ ] 기존 모듈 3개 등록 확인 (--verbose 옵션)
- [ ] 새 파일 추가 시 자동 인식 확인

---

### Task 3.2: CLI 옵션 확장

**파일:** `.claude/lib/validate-system.sh`

#### Subtask 3.2.1: 새 옵션 변수 추가

- [ ] Line 16-20 뒤에 추가:
  ```bash
  FAIL_FAST=false
  PARALLEL=false
  REPORT_FORMAT="json,markdown"  # 쉼표 구분
  TIMEOUT_SECONDS="${VALIDATION_TIMEOUT_SECONDS:-300}"
  ```

#### Subtask 3.2.2: parse_arguments() 확장

- [ ] Line 57-94 case문에 추가:
  ```bash
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
  --timeout)
      TIMEOUT_SECONDS="$2"
      shift 2
      ;;
  --config)
      CONFIG_FILE="$2"
      shift 2
      ;;
  ```

#### Subtask 3.2.3: usage() 업데이트

- [ ] Line 32-53에 새 옵션 추가:
  ```bash
  옵션:
      --docs-only          문서 검증만 실행
      --migration-only     마이그레이션 검증만 실행
      --crossref-only      교차 참조 검증만 실행
      --parallel           검증을 병렬로 실행 (빠름)
      --fail-fast          첫 실패 시 즉시 종료
      --format FORMAT      보고서 포맷 (json,markdown,html)
      --timeout SECONDS    타임아웃 설정 (기본: 300초)
      --config FILE        커스텀 설정 파일
      --dry-run            드라이런 모드
      --verbose, -v        상세 출력
      --quiet, -q          최소 출력
      --help, -h           도움말 표시
  ```

**검증:**
- [ ] `bash .claude/lib/validate-system.sh --help` 실행
- [ ] 모든 새 옵션 표시 확인

---

## ✅ Phase 4: 성능 최적화

### Task 4.1: 병렬 검증 실행

**파일:** `.claude/lib/validate-system.sh`

#### Subtask 4.1.1: 병렬 실행 함수 추가

- [ ] Line 213 뒤 (run_crossref_validation 함수 뒤)에 새 함수 추가:
  ```bash
  # 병렬 검증 실행
  run_all_validations_parallel() {
      log_info "🚀 병렬 검증 실행 중..."

      # 임시 출력 파일
      local tmp_dir
      tmp_dir=$(mktemp -d) || {
          log_error "임시 디렉토리 생성 실패"
          return 1
      }
      setup_cleanup_trap "rm -rf '$tmp_dir'"

      # 백그라운드 실행
      (run_documentation_validation > "$tmp_dir/doc.out" 2>&1 ; echo $? > "$tmp_dir/doc.status") & pid_doc=$!
      (run_migration_validation > "$tmp_dir/mig.out" 2>&1 ; echo $? > "$tmp_dir/mig.status") & pid_mig=$!
      (run_crossref_validation > "$tmp_dir/ref.out" 2>&1 ; echo $? > "$tmp_dir/ref.status") & pid_ref=$!

      # 진행 상태 표시
      while kill -0 $pid_doc $pid_mig $pid_ref 2>/dev/null; do
          sleep 0.5
      done

      # 결과 수집
      wait $pid_doc 2>/dev/null
      wait $pid_mig 2>/dev/null
      wait $pid_ref 2>/dev/null

      # 상태 코드 및 결과 읽기
      doc_status=$(cat "$tmp_dir/doc.status" 2>/dev/null || echo "1")
      __VALIDATE_SYSTEM_DOC_RESULTS=$(tail -1 "$tmp_dir/doc.out" 2>/dev/null || echo "{}")

      mig_status=$(cat "$tmp_dir/mig.status" 2>/dev/null || echo "1")
      __VALIDATE_SYSTEM_MIG_RESULTS=$(tail -1 "$tmp_dir/mig.out" 2>/dev/null || echo "{}")

      ref_status=$(cat "$tmp_dir/ref.status" 2>/dev/null || echo "1")
      __VALIDATE_SYSTEM_CROSSREF_RESULTS=$(tail -1 "$tmp_dir/ref.out" 2>/dev/null || echo "{}")

      log_info "병렬 검증 완료"
  }
  ```

#### Subtask 4.1.2: main() 함수에서 호출

- [ ] Line 337-354 (검증 실행 부분)를 조건부로 수정:
  ```bash
  if [[ "$PARALLEL" == "true" ]] && [[ "$VALIDATION_MODE" == "all" ]]; then
      # 병렬 실행
      run_all_validations_parallel
      doc_status=? mig_status=? ref_status=?  # 함수 내에서 설정됨
  else
      # 기존 순차 실행
      case "$VALIDATION_MODE" in
          # ... 기존 코드
      esac
  fi
  ```

**검증:**
- [ ] `time bash .claude/lib/validate-system.sh` (순차)
- [ ] `time bash .claude/lib/validate-system.sh --parallel` (병렬)
- [ ] 병렬 실행 시 최소 30% 시간 단축 확인

---

### Task 4.2: 조기 종료 최적화

**파일:** `.claude/lib/validate-migration.sh`, `.claude/lib/validate-crossref.sh`

#### Subtask 4.2.1: check_critical_files 수정

- [ ] `validate-migration.sh` Line 329-363에 조기 종료 추가:
  ```bash
  for file in "${CRITICAL_FILES[@]}"; do
      local full_path="$test_dir/$file"
      if [[ ! -f "$full_path" ]]; then
          log_error "    ✗ Critical 파일 없음: $file"
          ((missing_count++))

          # --fail-fast 옵션 시 즉시 반환
          if [[ "${FAIL_FAST:-false}" == "true" ]]; then
              log_warning "Fail-fast 모드: 즉시 종료"
              return 1
          fi
      fi
  done
  ```

#### Subtask 4.2.2: validate_all_cross_references 수정

- [ ] `validate-crossref.sh` Line 42-68에 조기 종료 추가:
  ```bash
  while IFS= read -r md_file; do
      # ... (기존 코드)

      # 깨진 링크가 있고 fail-fast 모드면 즉시 종료
      if [[ -n "$file_broken" ]] && [[ $file_broken -gt 0 ]] && [[ "${FAIL_FAST:-false}" == "true" ]]; then
          log_warning "Fail-fast 모드: 첫 깨진 링크 발견 시 종료"
          echo "{\"totalLinks\":$total_links,\"validLinks\":$valid_links,\"brokenLinks\":$broken_links,\"validity\":0}"
          return 1
      fi
  done
  ```

**검증:**
- [ ] `bash .claude/lib/validate-system.sh --fail-fast` 실행
- [ ] 첫 실패 시 즉시 종료 확인
- [ ] 에러 메시지 명확성 확인

---

## ✅ 테스트 및 검증

### Task 5.1: 단위 테스트 작성

**파일:** `.claude/lib/__tests__/test-validation-utils.sh` (확장)

- [ ] cleanup_temp_dir 보안 테스트 추가:
  ```bash
  test_cleanup_temp_dir_security() {
      # 루트 경로 시도
      if cleanup_temp_dir "/"; then
          fail "/ 경로 정리 허용됨"
      fi

      # 홈 디렉토리 시도
      if cleanup_temp_dir "$HOME"; then
          fail "$HOME 경로 정리 허용됨"
      fi

      # 정상 경로
      local temp=$(mktemp -d)
      if ! cleanup_temp_dir "$temp"; then
          fail "정상 경로 정리 실패"
      fi
  }
  ```

- [ ] parse_json_field 테스트 추가
- [ ] setup_cleanup_trap 테스트 추가

### Task 5.2: 통합 테스트

**파일:** `.claude/lib/__tests__/integration-test.sh` (신규)

- [ ] 전체 워크플로우 테스트 작성
- [ ] 병렬 실행 테스트
- [ ] Fail-fast 모드 테스트
- [ ] 설정 파일 테스트

### Task 5.3: ShellCheck 최종 확인

- [ ] 모든 .sh 파일 shellcheck 실행
- [ ] 0 warnings 확인

---

## ✅ 문서화

### Task 6.1: 인라인 주석 추가

- [ ] 모든 수정 사항에 주석 추가
- [ ] 복잡한 로직에 설명 추가

### Task 6.2: CHANGELOG 작성

- [ ] `.claude/lib/CHANGELOG.md` 업데이트
- [ ] v2.7.0 변경사항 기록

### Task 6.3: README 업데이트 (필요시)

- [ ] 새 옵션 설명 추가
- [ ] 설정 파일 사용법 추가

---

## ✅ 배포 준비

### Task 7.1: 백업 생성

- [ ] `.claude/lib` 전체 백업:
  ```bash
  cp -r .claude/lib .claude/lib.backup-$(date +%Y%m%d)
  ```

### Task 7.2: 최종 테스트

- [ ] 모든 검증 모드 실행:
  - [ ] `--docs-only`
  - [ ] `--migration-only`
  - [ ] `--crossref-only`
  - [ ] `--all`
  - [ ] `--all --parallel`
  - [ ] `--all --fail-fast`

### Task 7.3: 버전 업데이트

- [ ] `.claude/.version` 파일 업데이트
- [ ] `workflow-gates.json` 버전 업데이트

---

**총 태스크 수:** ~70개
**예상 완료 시간:** 25시간 (3일)

---

**다음 단계:** 실제 구현 시작 (Phase 1부터)
