# validate-system.sh 개선 사양서 (Specification)

**작성일:** 2025-11-11
**버전:** 1.0
**작업 유형:** Major - 시스템 개선

---

## 📋 개요

### 목적
`.claude/lib/validate-system.sh` 및 관련 검증 모듈의 안정성, 코드 품질, 확장성, 성능을 전면 개선

### 배경
현재 검증 시스템은 다음과 같은 구조적 문제를 가지고 있음:
- `set -e`와 에러 수집 로직 간 충돌
- 임시 파일 정리 시 예외 상황 처리 미흡
- 매직 넘버 하드코딩으로 인한 유지보수성 저하
- JSON 파싱의 견고성 부족
- 전역 변수 오염 가능성

### 범위
**포함:**
- `validate-system.sh` (메인 오케스트레이터)
- `validation-utils.sh` (공통 유틸리티)
- `validate-documentation.sh` (문서 검증)
- `validate-migration.sh` (마이그레이션 검증)
- `validate-crossref.sh` (교차 참조 검증)
- `report-generator.sh` (보고서 생성)

**제외:**
- 검증 로직의 비즈니스 규칙 변경
- CLI 인터페이스 변경 (기존 호환성 유지)
- JSON 출력 포맷 변경 (하위 호환성 유지)

---

## 🎯 개선 목표

### 1. 안정성 향상 (Stability)

#### 1.1 에러 처리 개선
**현재 문제:**
```bash
# validate-system.sh:6
set -e  # 모든 에러에서 즉시 종료

# validate-system.sh:348
run_documentation_validation || doc_status=$?  # set -e와 충돌
```

**개선 방안:**
- 에러 수집 구간에서 `set +e` 명시적 사용
- 각 검증 모듈의 종료 코드를 신뢰성 있게 수집
- 모든 검증 실행 후 통합 결과 반환

**성공 기준:**
- 하나의 검증 실패 시에도 나머지 검증 계속 실행
- 각 검증의 실패 원인을 개별적으로 추적 가능

#### 1.2 리소스 정리 강화
**현재 문제:**
```bash
# validate-migration.sh:69
trap "cleanup_temp_dir $test_dir" RETURN  # 함수 반환 시에만 실행
```

**개선 방안:**
- `EXIT INT TERM` 시그널에 대한 trap 추가
- 임시 디렉토리 경로 검증 (`/tmp/*` 또는 `/var/tmp/*`만 허용)
- 중첩된 trap 처리 (기존 trap 보존)

**성공 기준:**
- Ctrl+C로 중단 시에도 임시 파일 정리
- 악의적 경로 입력 시 `rm -rf` 실행 방지

#### 1.3 파일 I/O 에러 처리
**현재 문제:**
```bash
cat > "$output_file" << EOF
...
EOF
# 쓰기 실패 여부 확인 안 함
```

**개선 방안:**
- 모든 파일 쓰기 작업 후 성공 여부 확인
- 디스크 공간, 권한 문제 감지
- 실패 시 명확한 에러 메시지

**성공 기준:**
- 디스크 공간 부족 시 적절한 에러 메시지
- 읽기 전용 디렉토리 접근 시 즉시 실패

---

### 2. 코드 품질 개선 (Code Quality)

#### 2.1 ShellCheck 준수
**현재 문제:**
- SC2116: `echo "$var"` 대신 `printf` 사용 권장
- SC2086: 변수 인용 누락 가능성

**개선 방안:**
```bash
# Before
local json_result=$(echo "$doc_results" | tail -1)

# After
local json_result=$(printf '%s\n' "$doc_results" | tail -1)
```

**성공 기준:**
- `shellcheck` 실행 시 warning 0개
- 모든 변수 적절히 인용 처리

#### 2.2 매직 넘버 제거
**현재 문제:**
```bash
if [[ $avg -ge 90 ]] && [[ $passed -eq $total ]]; then  # 90이 무엇?
```

**개선 방안:**
```bash
# 설정 파일: .claude/lib/validation-config.sh
readonly VALIDATION_THRESHOLD_PASS=90
readonly VALIDATION_THRESHOLD_WARNING=70

# 사용
if [[ $avg -ge $VALIDATION_THRESHOLD_PASS ]]; then
```

**성공 기준:**
- 모든 임계값이 명명된 상수로 관리
- 설정 파일에서 일괄 조정 가능

#### 2.3 전역 변수 네임스페이스 관리
**현재 문제:**
```bash
OVERALL_STATUS="PASS"  # 전역 오염 가능
```

**개선 방안:**
```bash
readonly __VALIDATE_SYSTEM_STATUS="PASS"  # 접두사 + readonly
```

**성공 기준:**
- 모든 전역 변수에 `__VALIDATE_` 접두사
- 수정 불가능한 변수는 `readonly` 선언

---

### 3. 확장성 강화 (Extensibility)

#### 3.1 검증 모듈 플러그인화
**개선 방안:**
```bash
# 검증 모듈 자동 탐색
for validator in "$SCRIPT_DIR"/validate-*.sh; do
    if [[ -f "$validator" ]]; then
        register_validator "$validator"
    fi
done
```

**성공 기준:**
- 새로운 `validate-xxx.sh` 추가 시 자동 감지
- 모듈별 활성화/비활성화 가능

#### 3.2 설정 외부화
**개선 방안:**
```bash
# .claude/lib/validation-config.sh (신규 생성)
readonly VALIDATION_THRESHOLD_PASS=90
readonly VALIDATION_THRESHOLD_WARNING=70
readonly VALIDATION_REPORT_RETENTION_DAYS=30
readonly VALIDATION_TIMEOUT_SECONDS=300
```

**성공 기준:**
- 모든 설정값이 한 파일에 집중
- 환경 변수로 오버라이드 가능

#### 3.3 보고서 포맷 확장
**개선 방안:**
- JSON, Markdown 외에 HTML 포맷 추가
- 커스텀 템플릿 지원

**성공 기준:**
- `--format=html` 옵션으로 HTML 보고서 생성
- 사용자 정의 템플릿 경로 지정 가능

---

### 4. 성능 최적화 (Performance)

#### 4.1 병렬 검증 실행
**현재 문제:**
```bash
run_documentation_validation || doc_status=$?
run_migration_validation || mig_status=$?
run_crossref_validation || ref_status=$?
# 순차 실행으로 시간 소요
```

**개선 방안:**
```bash
# 백그라운드 병렬 실행
run_documentation_validation & pid_doc=$!
run_migration_validation & pid_mig=$!
run_crossref_validation & pid_ref=$!

# 결과 수집
wait $pid_doc || doc_status=$?
wait $pid_mig || mig_status=$?
wait $pid_ref || ref_status=$?
```

**성공 기준:**
- 전체 검증 시간 40% 단축 (3개 모듈 병렬화)
- 순서 의존성 없는 검증만 병렬 실행

#### 4.2 불필요한 재계산 제거
**현재 문제:**
```bash
# 동일한 grep 패턴을 여러 번 실행
local doc_total=$(echo "$doc_results" | grep -o '"total":[0-9]*' | cut -d':' -f2)
# ...
doc_total=$(echo "$doc_results" | grep -o '"total":[0-9]*' | cut -d':' -f2)  # 중복
```

**개선 방안:**
- 한 번 파싱한 결과 재사용
- jq 사용 시 한 번에 여러 필드 추출

**성공 기준:**
- JSON 파싱 횟수 70% 감소

#### 4.3 조기 종료 최적화
**개선 방안:**
```bash
# Critical 파일 검증 시 첫 번째 누락 발견 시 조기 종료 옵션
if [[ "$FAIL_FAST" == "true" ]]; then
    return 1
fi
```

**성공 기준:**
- `--fail-fast` 옵션으로 첫 실패 시 즉시 종료

---

## 🔒 제약사항 및 호환성

### 하위 호환성 보장
1. **CLI 인터페이스 유지**
   - 기존 모든 옵션 동작 보장: `--docs-only`, `--migration-only`, `--crossref-only`, `--verbose`, `--quiet`
   - 새 옵션 추가 가능: `--fail-fast`, `--format`, `--parallel`

2. **JSON 출력 포맷 유지**
   ```json
   {
     "total": 10,
     "passed": 8,
     "avgConsistency": 85
   }
   ```
   - 기존 필드 유지 (추가 필드는 허용)
   - 다른 스크립트가 파싱하는 구조 깨지지 않음

3. **플랫폼 호환성**
   - macOS, Linux (Ubuntu/Debian/CentOS) 모두 동작
   - Bash 4.0+ 요구사항 유지

4. **선택적 의존성**
   - jq 없이도 기본 기능 동작
   - jq 있을 시 향상된 JSON 처리

---

## ✅ 검증 계획

### 1. 기존 테스트 케이스 통과
```bash
# .claude/lib/__tests__/ 디렉토리의 모든 테스트 실행
bash .claude/lib/__tests__/test-validate-documentation.sh
bash .claude/lib/__tests__/test-validate-migration.sh
bash .claude/lib/__tests__/test-validate-crossref.sh
```

**통과 기준:** 모든 테스트 PASS

### 2. 실제 환경 시뮬레이션
```bash
# v1.0 → v2.6 마이그레이션 시나리오
bash .claude/lib/validate-system.sh --migration-only

# v2.4 → v2.6 마이그레이션 시나리오
bash .claude/lib/validate-system.sh --migration-only

# 전체 검증
bash .claude/lib/validate-system.sh
```

**통과 기준:**
- 모든 시나리오 PASS
- 보고서 정상 생성
- 에러 메시지 명확

### 3. ShellCheck 정적 분석
```bash
shellcheck .claude/lib/validate-system.sh
shellcheck .claude/lib/validation-utils.sh
shellcheck .claude/lib/validate-documentation.sh
shellcheck .claude/lib/validate-migration.sh
shellcheck .claude/lib/validate-crossref.sh
shellcheck .claude/lib/report-generator.sh
```

**통과 기준:**
- 모든 파일 0 warnings
- 최소 SC2086, SC2116 해결

### 4. 성능 벤치마크
```bash
time bash .claude/lib/validate-system.sh  # Before
time bash .claude/lib/validate-system.sh --parallel  # After
```

**통과 기준:**
- 병렬 실행 시 최소 30% 시간 단축

### 5. 에러 복원력 테스트
```bash
# 디스크 공간 부족 시뮬레이션
# 임시 디렉토리 삭제 실패 시뮬레이션
# Ctrl+C 인터럽트 테스트
```

**통과 기준:**
- 모든 에러 상황에서 적절한 메시지
- 리소스 누수 없음

---

## 📊 성공 메트릭

### 정량적 지표
- ShellCheck warnings: **0개** (현재: ~10개)
- 전체 검증 시간: **40% 단축** (병렬 실행 시)
- JSON 파싱 횟수: **70% 감소**
- 코드 중복도: **30% 감소**
- 테스트 커버리지: **90% 이상**

### 정성적 지표
- 에러 메시지 명확성: 사용자가 원인 즉시 파악 가능
- 확장성: 새 검증 모듈 추가 시 5분 이내
- 유지보수성: 설정 변경 시 단일 파일 수정만 필요

---

## 🚧 제외 사항 (Out of Scope)

1. **검증 로직 변경**
   - 문서 일치율 계산 알고리즘 변경 없음
   - 마이그레이션 시나리오 추가/삭제 없음

2. **Breaking Changes**
   - 기존 사용자 스크립트가 의존하는 동작 변경 불가
   - JSON 필드 이름 변경 불가

3. **완전히 새로운 기능**
   - GUI 인터페이스 추가 안 함
   - 원격 검증 기능 추가 안 함

---

## 📝 참고 문서

- [Bash Best Practices Guide](https://www.gnu.org/software/bash/manual/)
- [ShellCheck Wiki](https://github.com/koalaman/shellcheck/wiki)
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)

---

**다음 단계:** research.md 작성 (현재 코드 상세 분석)
