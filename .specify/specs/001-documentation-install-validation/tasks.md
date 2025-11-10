# Tasks: 문서 및 설치 검증 시스템

> 이 문서는 spec.md의 사용자 시나리오와 plan.md의 구현 계획을 기반으로 작성되었습니다.
> 참조: [spec.md](./spec.md), [plan.md](./plan.md)

## 작업 형식
- [ ] [T001] [P?] [Story?] 설명 /절대/경로/파일
  - [P]: 병렬 처리 가능
  - [Story]: 사용자 스토리 ID (예: US1, US2, US3)

## Phase 1: 설정 및 전제조건

- [ ] [T001] [P] 디렉토리 구조 초기화 /.claude/lib, /.claude/cache/validation-reports
- [ ] [T002] [P] 공통 유틸리티 함수 작성 /.claude/lib/validation-utils.sh
- [ ] [T003] [P] 보고서 템플릿 작성 /.claude/templates/validation/report-template.md

**설명**:
```bash
# T001
mkdir -p .claude/cache/validation-reports
mkdir -p .claude/cache/validation-tmp
mkdir -p .claude/templates/validation

# T002
# validation-utils.sh에 다음 함수 구현:
# - log_info(), log_error(), log_success()
# - validate_prerequisites()
# - cleanup_temp_dir()

# T003
# Markdown 보고서 템플릿 작성
```

## Phase 2: 기본 검증 인프라 (US1, US2, US3에 공통 필요)

- [ ] [T004] [P] 메인 검증 스크립트 골격 작성 /.claude/lib/validate-system.sh
- [ ] [T005] [P] 파일 존재 확인 함수 추가 /.claude/lib/validation-utils.sh
- [ ] [T006] [P] 버전 검증 함수 추가 /.claude/lib/validation-utils.sh

**설명**:
```bash
# T004
# validate-system.sh 골격:
# - parse_arguments()
# - main()
# - 옵션: --docs-only, --migration-only, --crossref-only

# T005
# check_file_exists(), check_dir_exists()

# T006
# verify_version_file(), detect_current_version()
```

## Phase 3: User Story - [US1] 문서-코드 일관성 검증

**목표**: 모든 슬래시 명령어 문서가 실제 구현과 일치하는지 검증
**테스트 검증**: spec.md의 US1 테스트 검증 항목 참조

### 테스트 작성 (TDD)
- [ ] [T007] [US1] 문서 검증 테스트 스크립트 작성 /.claude/lib/__tests__/test-validate-documentation.sh
  - 10개 슬래시 명령어 파일 존재 확인
  - Step 패턴 추출 테스트
  - 일치율 계산 테스트

### 구현
- [ ] [T008] [P] [US1] 문서 검증 모듈 작성 /.claude/lib/validate-documentation.sh
  ```bash
  # 함수 구현:
  # - validate_all_documentation()
  # - validate_single_doc()
  # - extract_steps_from_doc()
  # - calculate_consistency()
  ```

- [ ] [T009] [US1] Step 패턴 추출 로직 구현 /.claude/lib/validate-documentation.sh
  ```bash
  # grep -E "^### Step [0-9]+" $doc_file
  # sed 's/^### //'
  ```

- [ ] [T010] [US1] 코드 블록 추출 로직 구현 /.claude/lib/validate-documentation.sh
  ```bash
  # grep -A 10 '```bash' $doc_file
  # 실행 가능 여부 확인
  ```

- [ ] [T011] [US1] 일치율 계산 및 불일치 보고 로직 /.claude/lib/validate-documentation.sh
  ```bash
  # 일치율 = (matches / total_steps) * 100
  # 불일치 항목 JSON 생성
  ```

## Phase 4: User Story - [US2] 마이그레이션 시나리오 검증

**목표**: v1.0 및 v2.4에서 v2.5로의 업그레이드가 올바르게 작동하는지 검증
**테스트 검증**: spec.md의 US2 테스트 검증 항목 참조

### 테스트 작성 (TDD)
- [ ] [T012] [US2] 마이그레이션 검증 테스트 스크립트 작성 /.claude/lib/__tests__/test-validate-migration.sh
  - 임시 환경 생성 테스트
  - v1.0 환경 설정 테스트
  - v2.4 환경 설정 테스트
  - Deprecated 파일 제거 검증
  - Critical 파일 존재 검증

### 구현
- [ ] [T013] [P] [US2] 마이그레이션 검증 모듈 작성 /.claude/lib/validate-migration.sh
  ```bash
  # 함수 구현:
  # - validate_migration_scenario()
  # - setup_version_environment()
  # - check_deprecated_files()
  # - check_critical_files()
  ```

- [ ] [T014] [US2] 임시 환경 설정 로직 /.claude/lib/validate-migration.sh
  ```bash
  # mktemp -d
  # trap "rm -rf $test_dir" EXIT
  # 버전별 파일 구조 생성
  ```

- [ ] [T015] [US2] v1.0 환경 시뮬레이션 /.claude/lib/validate-migration.sh
  ```bash
  # major-specify.md, major-clarify.md 등 생성
  # workflow-gates.json v1.0 버전
  ```

- [ ] [T016] [US2] v2.4 환경 시뮬레이션 /.claude/lib/validate-migration.sh
  ```bash
  # major.md (통합 버전)
  # workflow-gates.json v2.4 버전
  ```

- [ ] [T017] [US2] 마이그레이션 실행 및 로깅 /.claude/lib/validate-migration.sh
  ```bash
  # bash install.sh $test_dir > $log_file 2>&1
  # 종료 코드 캡처
  ```

- [ ] [T018] [US2] Deprecated 파일 제거 검증 /.claude/lib/validate-migration.sh
  ```bash
  # 정의된 파일 목록:
  # - .claude/commands/major-specify.md
  # - .claude/agents/architect.md
  # 각 파일이 존재하지 않는지 확인
  ```

- [ ] [T019] [US2] Critical 파일 존재 검증 /.claude/lib/validate-migration.sh
  ```bash
  # 필수 파일 목록:
  # - .claude/workflow-gates.json
  # - .claude/commands/major.md
  # - .claude/.version
  # 각 파일이 존재하는지 확인
  ```

## Phase 5: User Story - [US3] 교차 참조 검증

**목표**: 모든 마크다운 링크 및 파일 참조가 유효한지 검증
**테스트 검증**: spec.md의 US3 테스트 검증 항목 참조

### 테스트 작성 (TDD)
- [ ] [T020] [US3] 교차 참조 검증 테스트 스크립트 작성 /.claude/lib/__tests__/test-validate-crossref.sh
  - 마크다운 링크 추출 테스트
  - 상대 경로 해석 테스트
  - 파일 존재 확인 테스트

### 구현
- [ ] [T021] [P] [US3] 교차 참조 검증 모듈 작성 /.claude/lib/validate-crossref.sh
  ```bash
  # 함수 구현:
  # - validate_all_cross_references()
  # - validate_single_crossref()
  # - extract_links()
  # - resolve_relative_path()
  ```

- [ ] [T022] [US3] 마크다운 링크 추출 로직 /.claude/lib/validate-crossref.sh
  ```bash
  # grep -oE '\[.*\]\([^)]+\)' $md_file
  # sed 's/.*(\(.*\))/\1/'
  ```

- [ ] [T023] [US3] 상대 경로 해석 로직 /.claude/lib/validate-crossref.sh
  ```bash
  # dirname $source_file
  # realpath -m "$source_dir/$reference"
  ```

- [ ] [T024] [US3] 에이전트/스킬 참조 검증 /.claude/lib/validate-crossref.sh
  ```bash
  # 에이전트: .claude/agents/*.md
  # 스킬: .claude/skills/*/SKILL.md
  ```

- [ ] [T025] [US3] 깨진 링크 보고 로직 /.claude/lib/validate-crossref.sh
  ```bash
  # JSON 형식으로 깨진 링크 목록 생성
  # 소스 파일 및 라인 번호 포함
  ```

## Phase 6: 보고서 생성 및 출력

- [ ] [T026] [P] 보고서 생성 모듈 작성 /.claude/lib/report-generator.sh
  ```bash
  # 함수 구현:
  # - generate_json_report()
  # - generate_markdown_report()
  # - generate_terminal_output()
  # - save_report_to_file()
  ```

- [ ] [T027] [P] JSON 보고서 생성 로직 /.claude/lib/report-generator.sh
  ```bash
  # jq를 사용한 JSON 생성
  # ValidationReport 구조 (data-model.md 참조)
  ```

- [ ] [T028] [P] Markdown 보고서 생성 로직 /.claude/lib/report-generator.sh
  ```bash
  # 템플릿 기반 Markdown 생성
  # 색상 코드 없이 순수 Markdown
  ```

- [ ] [T029] [P] 터미널 색상 출력 로직 /.claude/lib/report-generator.sh
  ```bash
  # ANSI 색상 코드 사용
  # 녹색: ✓, 빨강: ✗, 노랑: ⚠️
  ```

- [ ] [T030] [P] 보고서 파일 저장 및 히스토리 관리 /.claude/lib/report-generator.sh
  ```bash
  # 타임스탬프 기반 파일명
  # latest.json 심볼릭 링크 생성
  # 30일 이상 된 보고서 자동 삭제
  ```

## Phase 7: 통합 및 CLI 옵션

- [ ] [T031] 메인 스크립트 통합 /.claude/lib/validate-system.sh
  ```bash
  # 모든 검증 모듈 통합
  # 전체 검증 흐름 구현
  ```

- [ ] [T032] CLI 옵션 파싱 /.claude/lib/validate-system.sh
  ```bash
  # --docs-only, --migration-only, --crossref-only
  # --dry-run, --integration
  # --verbose, --quiet
  ```

- [ ] [T033] 전체 상태 계산 로직 /.claude/lib/validate-system.sh
  ```bash
  # overallStatus: PASS | FAIL | WARNING
  # consistencyScore: 0-100
  ```

- [ ] [T034] 종료 코드 반환 /.claude/lib/validate-system.sh
  ```bash
  # 0: PASS
  # 1: FAIL
  # 2: WARNING (비중요 이슈)
  ```

## Phase 8: 문서화 및 최종 검증

- [ ] [T035] [P] README 작성 /.claude/lib/validation/README.md
  - 사용법 설명
  - 예제 명령어
  - 옵션 설명

- [ ] [T036] [P] 전체 검증 실행 및 테스트
  ```bash
  bash .claude/lib/validate-system.sh
  ```

- [ ] [T037] [P] 개별 검증 테스트
  ```bash
  bash .claude/lib/validate-system.sh --docs-only
  bash .claude/lib/validate-system.sh --migration-only
  bash .claude/lib/validate-system.sh --crossref-only
  ```

- [ ] [T038] 성능 측정 (spec.md 기준)
  - [ ] 전체 검증 < 5분
  - [ ] 개별 문서 검증 < 10초
  - [ ] 마이그레이션 시뮬레이션 < 1분

- [ ] [T039] CI/CD 통합 스크립트 작성 /.github/workflows/validation.yml
  ```yaml
  # GitHub Actions 워크플로우
  # PR 생성 시 자동 검증
  ```

- [ ] [T040] Pre-commit hook 작성 /.git/hooks/pre-commit
  ```bash
  # 커밋 전 문서 검증
  # --docs-only --quick 옵션
  ```

## Progress Tracking

**전체 작업**: 40개
**완료**: 0
**진행 중**: 0
**남은 작업**: 40

**예상 소요 시간**: 5-7일 (spec.md 기준)

## 주요 마일스톤

- [ ] **M1**: Phase 1-2 완료 (기본 인프라) - 1-2일
- [ ] **M2**: Phase 3 완료 (US1 문서 검증) - 2-3일
- [ ] **M3**: Phase 4 완료 (US2 마이그레이션 검증) - 1-2일
- [ ] **M4**: Phase 5 완료 (US3 교차 참조 검증) - 1일
- [ ] **M5**: Phase 6-8 완료 (보고서, 통합, 문서화) - 1일

## 주의사항

⚠️ **TDD 원칙 준수**:
- 각 User Story별로 테스트를 먼저 작성 (T007, T012, T020)
- 테스트 통과 후 다음 작업 진행

⚠️ **기존 함수 재사용**:
- install.sh의 health_check(), verify_installation(), validate_installation() 참조
- 중복 코드 작성 금지

⚠️ **병렬 처리 가능 작업** ([P] 표시):
- 동시에 여러 파일 작업 가능
- 서로 의존성 없음

⚠️ **순차 처리 필수 작업**:
- User Story별 테스트 작성 → 구현 순서 필수
- 통합 작업은 모든 모듈 완성 후 진행

## 품질 체크리스트

### 각 스크립트 완성 시:
- [ ] Bash 4.0+ 호환성 확인
- [ ] macOS 및 Linux 테스트
- [ ] 에러 처리 구현 (종료 코드, stderr 출력)
- [ ] 임시 파일 정리 (`trap` 사용)
- [ ] 주석 및 사용 예시 포함

### 통합 완료 시:
- [ ] 전체 검증 스크립트 실행 성공
- [ ] 모든 테스트 검증 항목 통과 (spec.md US1, US2, US3)
- [ ] 성능 목표 달성 (< 5분)
- [ ] CI/CD 통합 성공
- [ ] 문서 완성 (README, quickstart.md)

---

**다음 단계**: T001부터 순차적으로 구현 시작
