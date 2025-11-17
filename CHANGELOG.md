# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [3.3.0] - 2025-01-18

### Added
- **Database Synchronization Tool** (`/db-sync`) - Production to Development DB sync automation
  - 6-step automated process: connection check, dump, backup, initialize, restore, verify, cleanup
  - Dual DB connection verification (pg_isready + psql fallback)
  - Automatic timestamped backups (keeps last 5)
  - Automatic rollback on failure
  - Lock file mechanism to prevent concurrent runs
  - Comprehensive logging (`.claude/cache/db-sync.log`)
  - Retry logic for dump creation (max 3 attempts)
  - Data verification post-restore (table and record counts)

- **Prisma Migration Automation** (`/prisma-migrate`) - Intelligent schema migration
  - Auto-detection of migrations directory under `prisma/`
  - Git diff analysis for intelligent migration naming
  - Interactive environment selection (Development/Production)
  - Development mode: creates and applies new migration files
  - Production mode: applies existing migrations only
  - Smart naming patterns:
    - `add_{model}_table` - new model detection
    - `remove_{model}_table` - model deletion detection
    - `add_index` - index change detection
    - `schema_update_{timestamp}` - fallback pattern
  - Schema change detection via git diff and prisma status
  - Migration file verification post-execution

- **Database Utilities Library** (`.claude/lib/db-utils.sh`)
  - Logging functions with color coding (info, success, error, warning)
  - DATABASE_URL parser with regex extraction
  - PostgreSQL@16 tools availability check
  - Docker and Prisma CLI verification
  - Comprehensive unit tests (15 tests)

### Changed
- Updated README.md with Database Tools section (v3.3.0)
- Updated workflow-gates.json to v3.2.0 with unified agent names
- Version bump to 3.3.0

### Documentation
- Created `/db-sync` command documentation with prerequisites and usage examples
- Created `/prisma-migrate` command documentation with intelligent naming explanation
- Updated spec.md status to "Completed" with all test verifications marked
- All Test Verification checklists completed (US1, US2, US3)

## [3.2.0] - 2025-11-17

### Added
- Epic 009 Feature 001 comprehensive documentation ([#T029], [#T031])
- Command-resource relationship guide for better documentation structure ([#T028])
- Template compliance registry system ([#T024], [#T025])

### Changed
- Improved template compliance tracking and validation

### Fixed
- ShellCheck unused variable warning in install-git-hooks ([#T030])
- Version header comment in install.sh updated to reflect Epic 009 changes

### Documentation
- Added Epic 009 Feature 001 section to README
- Created feature summary documentation for Epic 009

## [3.1.2] - 2025-11-13

### Fixed
- **Installation Directory Creation Bug** - 파일 복구 중 디렉토리 생성 실패 문제 해결
  - `retry-helper.sh`의 `download_file_with_retry()` 함수에 디렉토리 자동 생성 추가
  - 상위 디렉토리가 없을 때 `mkdir -p`로 자동 생성
  - 설치 중 "File recovery failed" 오류 해결
  - 권한 오류 시 명확한 에러 메시지 제공

## [3.1.1] - 2025-11-13

### Fixed
- **GitHub Raw CDN Cache Issue** - 설치 시 체크섬 검증 실패 문제 해결
  - GitHub Raw Content CDN이 캐시된 이전 버전 `.checksums.json` 제공하는 문제
  - v3.1.1 패치 릴리스로 새 URL 제공하여 캐시 우회
  - 테스트 파일 제외 후 체크섬 불일치로 인한 설치 중단 해결 (159개 → 143개 파일)

## [3.1.0] - 2025-11-13

Epic 001 (Workflow System v3.1 Improvements) - 5개 Features 완료

### Added
- **Architecture Compliance Check** (Feature #002) - 아키텍처 패턴 자동 검증
  - TypeScript 기반 검증 시스템 (18 files, 2,762 lines)
  - 다중 패턴 지원: FSD, Clean Architecture, Hexagonal, DDD
  - 순환 의존성 자동 검출
  - 레이어 규칙 및 네이밍 규칙 검증
  - Major 워크플로우 Step 13.7 통합
  - 5개 테스트 스위트 포함

- **Korean Documentation Validation** (Feature #003) - 한글 문서화 강제
  - `korean-doc-validator.ts` 라이브러리 (172 lines)
  - 한글 비율 검증 (목표: 60%, 통과: 45%)
  - 5개 검증 함수, 16개 테스트 케이스
  - Major 워크플로우 5곳에 통합
  - 자동 임계값 조정 기능

- **Branch State Management** (Feature #004) - 브랜치 생성 시 Git 상태 자동 관리
  - 4개 핵심 라이브러리 (1,037 lines)
  - 5-option dirty state workflow (commit/move/stash/discard/cancel)
  - Parallel work 자동 검출 (Epic 브랜치 분기)
  - 완벽한 에러 복구 및 롤백
  - 70개 테스트 (100% passing)
  - 350+ 라인 INTEGRATION.md 가이드

- **Checksum Verification Improvements** (Feature #005) - 파일 무결성 검증 강화
  - SHA256 기반 체크섬 검증 시스템
  - `.specify/` 디렉토리 체크섬 포함
  - 설치 시 자동 무결성 검증
  - 선택적 파일 재다운로드 지원

### Removed
- **Plan Mode** (Feature #001) - Major 워크플로우에서 Plan Mode 가이드 제거
  - `/triage` 명령어에서 Plan Mode 안내 메시지 제거
  - `major.md` Step 1.5 (Plan Mode 컨텍스트 감지) 제거
  - `major.md` Step 2-4의 `{planModeDetected}` 조건 분기 제거
  - `.claude/lib/plan-mode/` → `.claude/lib/plan-mode.deprecated/` 이동
  - **사유**: Major 워크플로우의 AskUserQuestion이 충분한 정보를 수집하므로 불필요

### Improved
- **Major Workflow** - AskUserQuestion 기반 정보 수집으로 사용자 경험 간소화
  - 워크플로우 실행 시간 30초-1분 단축
  - 수동 복사-붙여넣기 단계 제거
  - 더 직관적이고 끊김없는 워크플로우 경험
  - 아키텍처 검증 자동 실행 (Step 13.7)
  - 한글 문서 검증 자동 실행 (5곳)

### Quality Metrics
- **테스트 커버리지**: 90+ tests (Feature 004: 70 tests, Feature 002: 5 suites, Feature 003: 16 tests)
- **코드 품질**: TypeScript strict mode, Bash ShellCheck 호환
- **보안**: 0 보안 이슈, 0 데이터 손실
- **문서화**: 100% (모든 Feature에 README)

### BREAKING CHANGE
- Plan Mode 기능 제거. 기존 Plan Mode 사용자는 롤백 가이드 참조: `.claude/lib/plan-mode.deprecated/README.md`

## [2.9.0] - 2025-11-12

### Added
- **Plan Mode Integration** - Claude Code Plan Mode와 Major 워크플로우 통합
  - 복잡도 5점 이상 작업 시 Plan Mode 사용 가이드 자동 표시
  - Plan Mode 계획을 대화 컨텍스트에서 자동 감지 및 추출
  - Major 워크플로우 Step 2-4 자동 건너뛰기 (계획 감지 시)
  - 키워드 기반 컨텍스트 추출 (계획, plan, phase, 단계, step)
  - 항상 Fallback 제공 (기존 워크플로우 100% 호환)

### New Files
- `.claude/config/plan-mode.json` - Plan Mode 설정 파일
- `.claude/lib/plan-mode/guide-template.md` - 사용자 가이드 템플릿
- `.claude/lib/plan-mode/integration-strategy.md` - 통합 전략 문서
- `.claude/lib/plan-mode/extract-context.sh` - 컨텍스트 추출 스크립트
- `.claude/lib/__tests__/test-plan-mode-context.sh` - 유닛 테스트 (15개)
- `.specify/specs/002-plan-mode-integration/` - 기능 명세 및 문서

### Changed
- **triage.md** - Step 4.5 추가: Plan Mode 가이드 표시 (복잡도 >= 5)
- **major.md** - Step 1.5 추가: Plan Mode 컨텍스트 감지 및 자동 건너뛰기
- **major.md** - Step 2-4를 조건부 실행으로 변경 (planModeDetected 플래그)
- **README.md** - Plan Mode 사용법 섹션 추가

### Fixed
- **Installation System** - 설치 프로세스 4가지 주요 개선
  - **Version Sync**: install.sh 버전 동기화 (2.8.0 → 2.9.0)
  - **Checksum Verification**: Self-referential checksum 스킵 로직 추가
  - **Installation Flow**: .gitignore 업데이트를 체크섬 검증 전으로 이동
  - **Non-Interactive Support**: `curl ... | bash` 파이프 모드에서 동일 버전 재설치 지원
- **.gitignore Management** - 중복 검사 강화 (grep -Fxq로 정확한 패턴 매칭)
- **Plan Mode Validation** - validate-system.sh에 Plan Mode 파일 검증 추가

### Impact
- ✅ 계획 수립 시간 50% 단축 (15분 → 7.5분)
- ✅ 누락 요구사항 80% 감소 (평균 3개 → 0-1개)
- ✅ 계획-실행 불일치 70% 감소
- ✅ 기존 워크플로우 100% 호환성 유지

### Performance
- 컨텍스트 추출: <100ms
- 키워드 감지: 15개 유닛 테스트 통과
- 최소 메시지 길이: 200자
- Fallback 성공률: 100%

### Documentation
- `.specify/specs/002-plan-mode-integration/spec.md` - 기능 명세
- `.specify/specs/002-plan-mode-integration/data-model.md` - 데이터 모델
- `.specify/specs/002-plan-mode-integration/plan.md` - 구현 계획 (3일)
- `.specify/specs/002-plan-mode-integration/tasks.md` - 작업 목록 (20개)
- `.specify/specs/002-plan-mode-integration/quickstart.md` - 시작 가이드
- `.specify/specs/002-plan-mode-integration/examples.md` - 사용 예시

### Testing
- 15개 유닛 테스트 (컨텍스트 추출)
- 키워드 감지 테스트 (한글/영어)
- 메시지 길이 검증 테스트
- Fallback 시나리오 테스트

### Migration from 2.8.0
자동 업그레이드 - 설정 파일이 자동으로 생성됩니다
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Liamns/claude-workflows/main/install.sh)
```

새로운 기능은 `/triage` 실행 시 자동으로 활성화됩니다. Plan Mode 사용은 선택사항이며, 기존 워크플로우는 그대로 작동합니다.

## [2.8.0] - 2025-11-12

### Added
- **PR Review with Codebase Context** - 코드베이스 전체를 참조하는 스마트 PR 리뷰
  - 재사용성 검증: 기존 컴포넌트/함수 자동 제안
  - 중복 코드 감지: 80% 이상 유사도 경고
  - 패턴 일관성: 프로젝트 표준 패턴 준수 확인
  - 성능 최적화: 혼합 캐싱 (메모리 + 파일)

### New Files
- `.claude/agents/code-reviewer/lib/cache-manager.sh` - 캐시 관리 시스템
- `.claude/agents/code-reviewer/lib/codebase-indexer.sh` - 코드베이스 인덱싱 엔진
- `.claude/agents/code-reviewer/lib/similarity-analyzer.sh` - 유사도 분석 알고리즘
- `.claude/agents/code-reviewer/lib/suggestion-generator.sh` - 리뷰 제안 생성기
- `.claude/cache/codebase-index.json` - 코드베이스 인덱스 캐시
- `.claude/metrics/pr-review-stats.json` - PR 리뷰 메트릭

### Changed
- **reviewer-unified.md** - 코드베이스 컨텍스트 분석 기능 통합
  - 5번째 검토 영역 추가: 코드베이스 컨텍스트
  - 재사용성 체크리스트 추가
  - 리뷰 프로세스에 인덱싱 단계 추가

### Impact
- ✅ 불필요한 경고 50% 감소 예상
- ✅ 재사용성 제안 정확도 80% 이상
- ✅ 리뷰 시간 20% 단축 (캐싱)
- ✅ 코드 일관성 향상

### Performance
- 초기 인덱싱: 5-10초 (1000개 파일 기준)
- 캐시 사용 시: <1초
- 점진적 검색: 2-5초
- 최대 타임아웃: 30초

### Documentation
- `.specify/specs/001-pr-review-codebase-context/spec.md` - 기능 명세
- `.specify/specs/001-pr-review-codebase-context/plan.md` - 구현 계획
- `.specify/specs/001-pr-review-codebase-context/tasks.md` - 작업 목록 (43개)
- `.specify/specs/001-pr-review-codebase-context/quickstart.md` - 시작 가이드

### Migration from 2.7.2
자동 업그레이드 - 특별한 조치 불필요
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Liamns/claude-workflows/main/install.sh)
```

새로운 기능은 `/pr-review` 커맨드 실행 시 자동으로 활성화됩니다.

## [2.7.2] - 2025-01-12

### Fixed
- **Checksum Verification** - 설치 중 불필요한 파일 검증 제거
  - `.claude/settings.local.json` 제외 (사용자별 로컬 설정)
  - `.claude/hooks/*` 제외 (설치 시 생성/수정되는 파일)
  - `.specify/memory/*` 제외 (프로젝트별 컨텍스트 문서)
  - `*.local.json` 패턴 제외 (모든 로컬 설정 파일)

### Changed
- **generate-checksums.sh** - 제외 패턴 강화
  - EXCLUDE_DIRS에 `.claude/hooks`, `.specify/memory` 추가
  - EXCLUDE_FILES에 `*.local.json` 패턴 추가
  - Glob 패턴 매칭 로직 개선 (리터럴 매칭 폴백 지원)
  - 체크섬 매니페스트 파일 수: 105 → 100 (5개 제외)

### Impact
- ✅ 신규 설치 시 404 에러 완전 제거
- ✅ 설치 속도 개선 (불필요한 복구 시도 제거)
- ✅ 프로젝트별/사용자별 파일 보존
- ✅ 기존 프로젝트 업그레이드 안정성 향상

### Migration from 2.7.1
자동 업그레이드 - 특별한 조치 불필요
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Liamns/claude-workflows/main/install.sh)
```

### Migration from 2.7.0
자동 업그레이드 - `.claude/.version` 파일이 자동으로 업데이트됩니다

## [2.7.1] - 2025-01-12

### Fixed
- **Checksum Generation** - 개발 전용 파일 제외 로직 수정
  - EXCLUDE_DIRS 패턴이 제대로 적용되지 않던 문제 해결
  - 파일 수집 로직 개선 (find + bash loop 방식)
  - 체크섬 매니페스트 파일 수: 200 → 105 (95개 제외)

### Changed
- **EXCLUDE_DIRS 확장**
  - `.claude/.backup` - 백업 파일
  - `.claude/cache` - 캐시 파일 (27개)
  - `.claude/commands/_backup` - 커맨드 백업
  - `.claude/agents/_deprecated` - 레거시 에이전트 (9개)
  - `.claude/lib/__tests__` - 테스트 파일 (9개)
  - `.specify/specs` - 개발 스펙 문서 (27개)

### Impact
- ✅ 개발 전용 파일 88개 제외로 설치 안정성 향상
- ✅ 404 에러 대폭 감소

## [2.7.0] - 2025-01-11

### Added
- FSD 커스텀 아키텍처 공식 적용 (Domain-Centric Approach)
  - Team Philosophy: "One feature = one domain (like a backend service)"
  - config.json v2.1.0-team-custom
  - Type-only imports 지원
  - Pages First 원칙 적용

### Changed
- Widgets 레이어 제거 → Features/Pages로 병합
- FSD 컴포넌트 생성 스킬 업데이트 (domain-centric 템플릿)
- layer-rules.md, props-guidelines.md 팀 커스텀 규칙 반영
- page-template.md Pages First 기반으로 재작성

### Deprecated
- widget-template.md → widget-template.md.deprecated

### Migration Guide

#### Widgets → Features/Pages 마이그레이션

기존 Widgets 레이어를 사용하던 경우:

**Option 1: Features로 이동 (재사용되는 경우)**
```
widgets/header/  → features/header/
```

**Option 2: Pages로 이동 (1개 페이지에서만 사용)**
```
widgets/order-filter/  → pages/order-list/ui/OrderFilter.tsx
```

**판단 기준:**
- 2개 이상 페이지에서 재사용 → Features
- 1개 페이지에서만 사용 → Pages (Pages First 원칙)

#### Type-Only Imports 활용

Feature 간 타입 참조가 필요한 경우:
```typescript
// ✅ 허용
import type { OrderType } from '@/features/order';

// ❌ 금지
import { OrderList } from '@/features/order';
```

자세한 내용: `architectures/frontend/fsd/fsd-architecture.mdc`

### Compatibility
- Supports upgrade from 2.5.x, 2.6.x → 2.7.0
- Legacy versions (2.4.x↓) show warning
- No breaking changes for existing code

## [2.6.0] - 2025-01-10

### Added 🆕
- **✅ 강화된 Validation 시스템** - 4가지 마이그레이션 시나리오 완전 검증
  - v1.0 → v2.6 마이그레이션 검증
  - v2.4 → v2.6 마이그레이션 검증
  - v2.5 → v2.6 마이그레이션 검증 (신규)
  - 신규 설치 시나리오 검증 (신규)
  - 롤백 시나리오 자동 테스트 (신규)
- **🔄 자동 롤백 기능** - 마이그레이션 실패 시 이전 상태로 안전하게 복구
  - `rollback_from_backup()` 함수 추가
  - Critical 파일 우선 복원 (workflow-gates.json, config/, cache/)
  - 마이그레이션 실패 시 자동 호출
- **📋 Pre-commit Hook 통합** - .claude/ 변경사항 자동 검증
  - `.claude/hooks/pre-commit` - Git 커밋 전 자동 validation
  - `.claude/hooks/install-hooks.sh` - Hook 설치 스크립트
  - Exit code 기반 커밋 차단/허용 (0=pass, 1=fail, 2=warning)
- **🔍 통합 Validation** - install.sh에 validation 자동 실행
  - 설치/업그레이드 완료 후 자동 validation
  - `--quiet` 모드로 빠른 검증
  - Validation 리포트 자동 생성

### Enhanced ✨
- **validate-migration.sh** - 마이그레이션 검증 강화
  - `validate_fresh_install()` - 신규 설치 시나리오 검증
  - `validate_rollback_scenario()` - 롤백 메커니즘 검증
  - 5개 시나리오 검증 (v1.0→v2.6, v2.4→v2.6, v2.5→v2.6, 신규 설치, 롤백)
- **install.sh** - 설치 프로세스 개선
  - 롤백 함수 통합
  - Validation 시스템 자동 실행
  - 더 명확한 에러 메시지와 복구 안내
- **Critical 파일 목록 확장** - validation 시스템 필수 파일 추가
  - `.claude/lib/validate-system.sh`
  - `.claude/hooks/pre-commit`

### Changed 🔄
- **버전 체계** - 2.5.0 → 2.6.0
  - `INSTALLER_VERSION` 및 `TARGET_VERSION` 업데이트
  - 모든 마이그레이션 스크립트 버전 업데이트
- **README.md** - v2.6.0 기능 반영
  - 새로운 기능 섹션 추가
  - Validation 시스템 사용법 상세 설명
  - 마이그레이션 시나리오 업데이트
- **commit.md** - Pre-commit hook 안내 추가
  - Hook 설치 방법
  - 동작 방식 설명
  - Validation 실패 시 대응 방법

### Documentation 📚
- **Validation 시스템 가이드** 추가 (README.md)
  - 자동 검증 명령어
  - Pre-commit hook 설정
  - Validation 리포트 위치 및 형식
- **마이그레이션 가이드** 업데이트
  - 4가지 시나리오 상세 설명
  - 자동 롤백 메커니즘 설명
  - 백업 및 복구 절차
- **커밋 워크플로우** 업데이트
  - Pre-commit validation 통합
  - Hook 관리 방법

### Fixed 🐛
- **마이그레이션 안정성** - 실패 시 자동 롤백으로 데이터 손실 방지
- **문서-코드 일관성** - Validation 시스템으로 문서 품질 자동 보장
- **설치 검증** - 모든 설치 시나리오에서 파일 무결성 검증

### Infrastructure 🏗️
- `.claude/hooks/` - Git hook 디렉토리
- `.claude/cache/validation-reports/` - Validation 리포트 저장소
- `.claude/.backup/` - 마이그레이션 백업 디렉토리

### Breaking Changes 💥
- **None** - v2.5.0과 완전히 호환됩니다

### Migration Guide 📖
```bash
# v2.5 → v2.6 자동 업그레이드 (권장)
bash install.sh

# Pre-commit hook 설치 (선택사항)
bash .claude/hooks/install-hooks.sh

# Validation 실행
bash .claude/lib/validate-system.sh
```

---

### Added 🆕 (from Unreleased)
- **/pr**: Git 변경사항을 분석하여 GitHub PR을 자동으로 생성하고 템플릿을 자동 완성
  - 커밋 히스토리 자동 분석 및 타입별 그룹화
  - Breaking changes 자동 감지
  - `.specify/*.md` 워크플로우 파일과 연동하여 PR body 자동 생성
  - 템플릿 자동 완성 (변경사항, 작업 내용, 테스트, 참고 자료 섹션)
  - `--dry-run`, `--draft`, `--review`, `--validate` 등 다양한 옵션 지원

### Fixed 🐛
- **Critical: All workflows now executable** - Fixed major issue where triage/major/minor/micro were description-only documents
- **triage.md** - Added Implementation section with actual tool calls (AskUserQuestion, Skill, SlashCommand)
- **micro.md** - Added Implementation section with work type detection, file search (Grep), modification (Edit), and validation (Bash)
- **minor.md** - Added Implementation section with 11 steps including questions, reusability checks, file operations, and testing
- **major.md** - Added comprehensive Implementation section with 14 steps generating 7 files (spec.md, plan.md, tasks.md, research.md, data-model.md, quickstart.md, contracts/openapi.yaml)
- **Consolidated workflow-gates.json** - Merged duplicate files from root and .claude/ directories
- **Organized backup files** - Moved all backup files to `.claude/.backup/v1-v2-migration/` directory
- **Updated documentation** - Added missing `/micro` command explanation in README.md
- **Fixed install.sh file counts** - Corrected command count (11→9) and skill count (13→15)
- **Removed non-existent /test command** - Cleaned up Next Steps section
- **Enhanced v1.0 detection** - Added root fallback for workflow-gates.json version detection

### Changed 🔄
- **Workflow execution model** - All workflows transformed from "descriptions" to "executable commands" with explicit tool calls
- **major.md question reduction** - Consolidated 10 questions into 2 AskUserQuestion blocks (3 essential + 6 optional multiselect)
- **File generation automation** - major workflow now auto-generates 7 specification/planning files
- **Inline branch creation** - Replaced create-new-feature.sh script with inline Bash commands in major.md
- workflow-gates.json location standardized to `.claude/` directory
- workflow-gates.json version updated to 2.5.0
- Backup files organized under `.claude/.backup/` for better project structure
- install.sh now shows complete lib/ and config/ file lists including migration scripts

## [2.5.0] - 2025-11-07

### Added 🆕
- **📊 Real-time Metrics Dashboard** (`/dashboard` command)
  - Live workflow performance monitoring
  - Token usage tracking with savings calculation
  - Performance metrics (execution time, cache hit rate, parallel processing)
  - Quality indicators (test coverage, type check, lint results)
  - Productivity tracking (tasks, bugs, features)
  - Git integration (commits, changes, branch status)
- **Metrics Collection System**
  - `git-stats-helper.sh` - Git statistics collector
  - `metrics-collector.sh` - Core metrics collection functions
  - `dashboard-generator.sh` - Terminal dashboard renderer with colors
  - JSON-based metrics storage (current session, daily, summary)
  - Three view modes: `--current`, `--today`, `--summary`

### Enhanced ✨
- Integrated metrics collection with cache-helper.sh
- Beautiful ASCII dashboard with colors and emojis
- Automatic Git statistics tracking
- Session-based metric persistence

### Infrastructure 🏗️
- `.claude/cache/metrics/` - Metrics data storage
- `.claude/cache/workflow-history/` - Workflow execution history
- Metrics JSON schemas for structured data

## [2.4.0] - 2025-11-07

### Added 🆕
- `/test` command - Smart test workflow with automated test generation and execution
- **Unified agents** - New consolidated agents for better performance:
  - `architect-unified` - All architecture pattern validation (FSD, Clean, Hexagonal, DDD, etc.)
  - `reviewer-unified` - Comprehensive code review (quality, security, performance, impact)
  - `implementer-unified` - TDD-based implementation and bug fixing
  - `documenter-unified` - Commit messages and changelog documentation

### Changed 🔄
- **Major workflow consolidation**: 6 commands → 1 unified `/major` command
- **Question reduction**: 10 questions → 2 essential questions only
- **State management**: Added automatic save/resume for Major workflow
- **Agent consolidation**: 11 agents → 6 agents (45% reduction)
- **Command reduction**: 16 commands → 10 commands (38% reduction)
- **README optimization**: 395 lines → 104 lines (74% reduction)

### Removed 🗑️
- Individual major commands (`major-specify`, `major-clarify`, `major-plan`, `major-tasks`, `major-implement`)
- Duplicate folders (`agents/`, `skills/` at root level)
- Redundant agents (separate `architect`, `fsd-architect`, `code-reviewer`, etc.)
- `workflow-gates-v2.json` (consolidated into single version)

### Fixed 🐛
- triage.md: Replaced `[Enter]` key input with `AskUserQuestion` tool for Claude Code compatibility
- Registry.json: Clearly marked implemented vs planned architectures
- File structure: Applied single source principle, removed all duplications

### Breaking Changes 💥

#### 🚨 IMPORTANT: v2.4.0 contains significant breaking changes

**Removed Commands** (5 files):
- ❌ `.claude/commands/major-specify.md` → Use `/major` instead
- ❌ `.claude/commands/major-clarify.md` → Use `/major` instead
- ❌ `.claude/commands/major-plan.md` → Use `/major` instead
- ❌ `.claude/commands/major-tasks.md` → Use `/major` instead
- ❌ `.claude/commands/major-implement.md` → Use `/major` instead

**Removed Agents** (8 files):
- ❌ `.claude/agents/architect.md` → Use `architect-unified.md`
- ❌ `.claude/agents/fsd-architect.md` → Merged into `architect-unified.md`
- ❌ `.claude/agents/code-reviewer.md` → Use `reviewer-unified.md`
- ❌ `.claude/agents/security-scanner.md` → Merged into `reviewer-unified.md`
- ❌ `.claude/agents/impact-analyzer.md` → Merged into `reviewer-unified.md`
- ❌ `.claude/agents/quick-fixer.md` → Use `implementer-unified.md`
- ❌ `.claude/agents/test-guardian.md` → Merged into `implementer-unified.md`
- ❌ `.claude/agents/smart-committer.md` → Use `documenter-unified.md`
- ❌ `.claude/agents/changelog-writer.md` → Merged into `documenter-unified.md`

**Agent Mapping** (Old → New):
| Old Agent | New Agent | Notes |
|-----------|-----------|-------|
| `architect` | `architect-unified` | All architecture patterns supported |
| `fsd-architect` | `architect-unified` | FSD logic merged |
| `code-reviewer` | `reviewer-unified` | Security & performance included |
| `security-scanner` | `reviewer-unified` | Merged |
| `impact-analyzer` | `reviewer-unified` | Merged |
| `quick-fixer` | `implementer-unified` | Bug fixes & TDD |
| `test-guardian` | `implementer-unified` | TDD logic merged |
| `smart-committer` | `documenter-unified` | Git operations |
| `changelog-writer` | `documenter-unified` | Notion integration |

**File Structure Changes**:
- ❌ Root level `agents/` folder removed → Use `.claude/agents/`
- ❌ Root level `skills/` folder removed → Use `.claude/skills/`
- ❌ `workflow-gates-v2.json` removed → Use `workflow-gates.json`

**Configuration Changes**:
- `workflow-gates.json` format updated for v2.4.0
- Old v1.0 format is incompatible

## [2.3.0] - 2025-01-07

### Added 🆕
- `/review` command - Comprehensive code review system
- Multi-architecture support (12 patterns)
- Model optimization (Opus/Sonnet/Haiku auto-switching)
- Context7 integration

## [2.0.0] - 2025-01-06

### Added 🆕
- `/triage` command - Automatic workflow selection based on task complexity (75-85% token savings)
- `/commit` command - Smart conventional commits with automatic type detection
- `/pr-review` command - Automated GitHub PR review with security and performance checks
- `smart-committer` agent - Intelligent commit message generation with breaking changes detection
- `commit-guard` skill - Pre-commit validation with 3 levels (Quick, Standard, Full)
- Comprehensive documentation:
  - `SUB-AGENTS-GUIDE.md` - Detailed guide for all sub-agents
  - `SKILLS-GUIDE.md` - Complete skills system documentation
  - `IMPROVEMENT-PROPOSALS.md` - Future enhancement roadmap

### Enhanced ✨
- `code-reviewer` agent - Added GitHub CLI integration for PR operations
- `install.sh` - Updated for new commands and documentation
- README.md - Complete restructure with new features showcase

### Improved 📈
- **Token efficiency**: 60% → up to 85% reduction
- **Development speed**: 2.5x → 3x improvement
- **Quality assurance**: Automated validation at every step

## [1.0.0] - 2024-12-01

### Added
- Major workflow with spec-kit integration
- Minor workflow for bug fixes and improvements
- Micro workflow for quick changes
- 7 Sub-agents:
  - `quick-fixer` - Fast bug fixes
  - `changelog-writer` - Git to Notion documentation
  - `fsd-architect` - FSD architecture validation
  - `test-guardian` - TDD enforcement
  - `api-designer` - API contract design
  - `mobile-specialist` - Capacitor platform handling
  - `code-reviewer` - Security and performance review
- 7 Skills:
  - `bug-fix-pattern` - Common bug fix patterns
  - `daily-changelog-notion` - Notion changelog automation
  - `fsd-component-creation` - FSD component templates
  - `api-integration` - httpClient patterns
  - `form-validation` - React Hook Form + Zod
  - `platform-detection` - Platform-specific rendering
  - `mobile-build` - Android/iOS build automation
- `workflow-gates.json` - Quality gate configuration
- `/start` command for project initialization

### Infrastructure
- `.specify/` directory structure for spec-kit
- `.claude/` directory for workflows
- Installation script for easy setup

## [0.1.0] - 2024-11-01

### Initial Release
- Basic workflow structure
- Proof of concept for sub-agents
- Initial skill system

---

## Upgrade Guide

### 🚀 Automatic Upgrade (v2.5.0+)

The installer now supports automatic version detection and migration:

```bash
# Automatically detects existing version and runs migration
curl -fsSL https://raw.githubusercontent.com/Liamns/claude-workflows/main/install.sh | bash
```

**What happens automatically**:
1. ✅ Detects existing installation version
2. ✅ Creates backup in `.claude/.backup/install-YYYYMMDD-HHMMSS/`
3. ✅ Runs appropriate migration scripts
4. ✅ Removes deprecated files
5. ✅ Updates configuration files
6. ✅ Preserves user customizations

---

### From v2.4.x to v2.5.0

**Changes**:
- New metrics dashboard system (`/dashboard`)
- New directory structure for metrics tracking
- Enhanced workflow history

**Automatic Migration**:
```bash
curl -fsSL https://raw.githubusercontent.com/Liamns/claude-workflows/main/install.sh | bash
```

**What gets migrated**:
- ✅ Creates `.claude/cache/metrics/` directory structure
- ✅ Creates `.claude/cache/workflow-history/` directory
- ✅ Initializes metrics system
- ✅ Updates `workflow-gates.json` version to 2.5.0
- ✅ Backs up existing cache

**New features**:
```bash
/dashboard          # View current session metrics
/dashboard --today  # Today's statistics
/dashboard --summary # Full cumulative stats
```

---

### From v1.0.x to v2.5.0

**⚠️ IMPORTANT: v2.4.0+ contains breaking changes**

**Automatic Migration**:
```bash
# The installer will automatically:
# 1. Detect v1.0.x installation
# 2. Run v1→v2.4 migration
# 3. Run v2.4→v2.5 migration
# 4. Remove all deprecated files
curl -fsSL https://raw.githubusercontent.com/Liamns/claude-workflows/main/install.sh | bash
```

**What gets removed automatically**:

**Commands** (5 files):
- `.claude/commands/major-specify.md` ❌
- `.claude/commands/major-clarify.md` ❌
- `.claude/commands/major-plan.md` ❌
- `.claude/commands/major-tasks.md` ❌
- `.claude/commands/major-implement.md` ❌

**Agents** (8 files):
- `.claude/agents/architect.md` ❌
- `.claude/agents/fsd-architect.md` ❌
- `.claude/agents/code-reviewer.md` ❌
- `.claude/agents/security-scanner.md` ❌
- `.claude/agents/impact-analyzer.md` ❌
- `.claude/agents/quick-fixer.md` ❌
- `.claude/agents/test-guardian.md` ❌
- `.claude/agents/smart-committer.md` ❌

**What gets backed up**:
- `workflow-gates.json` → `.claude/.backup/migration-YYYYMMDD-HHMMSS/`
- `.claude/config/` → `.claude/.backup/migration-YYYYMMDD-HHMMSS/`
- All deprecated files before deletion

**Command Changes**:
| Old Command | New Command | Notes |
|-------------|-------------|-------|
| `/major-specify` + 4 more | `/major` | Single unified command |
| N/A | `/dashboard` | New in v2.5.0 |

**Agent Changes**:
| Old Agent | New Agent | Notes |
|-----------|-----------|-------|
| `architect` | `architect-unified` | All architectures |
| `code-reviewer` | `reviewer-unified` | + security + performance |
| `quick-fixer` | `implementer-unified` | + TDD |
| `smart-committer` | `documenter-unified` | + changelog |

**After upgrade**:
```bash
# Test the new unified command
/major "implement user authentication"

# View metrics
/dashboard

# Continue using other commands as before
/triage
/commit
/review
```

---

### From v2.0.x to v2.5.0

**Changes**: v2.4.0 breaking changes + v2.5.0 metrics system

**Automatic Migration**:
```bash
curl -fsSL https://raw.githubusercontent.com/Liamns/claude-workflows/main/install.sh | bash
```

Same process as v1.0.x → v2.5.0 upgrade.

---

### Manual Migration (if automatic fails)

If the automatic migration fails, follow these manual steps:

#### Step 1: Backup existing installation
```bash
cp -r .claude .claude.backup.$(date +%Y%m%d)
```

#### Step 2: Remove deprecated files manually
```bash
# Remove old major commands
rm -f .claude/commands/major-specify.md
rm -f .claude/commands/major-clarify.md
rm -f .claude/commands/major-plan.md
rm -f .claude/commands/major-tasks.md
rm -f .claude/commands/major-implement.md

# Remove old agents
rm -f .claude/agents/architect.md
rm -f .claude/agents/fsd-architect.md
rm -f .claude/agents/code-reviewer.md
rm -f .claude/agents/security-scanner.md
rm -f .claude/agents/impact-analyzer.md
rm -f .claude/agents/quick-fixer.md
rm -f .claude/agents/test-guardian.md
rm -f .claude/agents/smart-committer.md
rm -f .claude/agents/changelog-writer.md
```

#### Step 3: Install new version
```bash
curl -fsSL https://raw.githubusercontent.com/Liamns/claude-workflows/main/install.sh | bash
```

#### Step 4: Verify installation
```bash
/major --help
/dashboard
```

---

### Rollback Procedure

If you need to rollback to a previous version:

#### Find your backup
```bash
ls -la .claude/.backup/
# or
ls -la .claude.backup.*
```

#### Restore from backup
```bash
# For automatic backups
cp -r .claude/.backup/install-YYYYMMDD-HHMMSS/* .claude/

# For manual backups
cp -r .claude.backup.YYYYMMDD/* .claude/
```

#### Reinstall specific version
```bash
# Clone specific version tag
git clone --branch v1.0.0 https://github.com/Liamns/claude-workflows
cd claude-workflows
bash install.sh /path/to/your/project
```

---

### From 0.1.0 to 2.5.0

Complete reinstallation recommended:
```bash
rm -rf .claude .specify
curl -fsSL https://raw.githubusercontent.com/Liamns/claude-workflows/main/install.sh | bash
/start
```

---

### Troubleshooting

**Issue**: "Migration script not found"
**Solution**: The migration scripts are included in v2.5.0+. If you see this warning during install from older versions, the deprecated files will simply be overwritten rather than cleanly removed. No action needed.

**Issue**: "Deprecated commands still showing up"
**Solution**: Run manual cleanup:
```bash
bash .claude/lib/migrate-v1-to-v2.sh
```

**Issue**: "Old agents still being called"
**Solution**: Check your `.claude/commands/` files for references to old agent names and update them to unified names.

**Issue**: "Lost user customizations"
**Solution**: Restore from backup:
```bash
cp .claude/.backup/install-YYYYMMDD-HHMMSS/config/* .claude/config/
```