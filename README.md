# 🤖 Claude Workflows

[![Version](https://img.shields.io/badge/version-2.9.0-blue.svg)](https://github.com/Liamns/claude-workflows)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Compatible-purple.svg)](https://claude.ai/code)
[![Validation](https://img.shields.io/badge/validation-automated-success.svg)](https://github.com/Liamns/claude-workflows)

> Claude Code의 토큰 효율성을 극대화하면서 코드 품질을 보장하는 지능형 워크플로우 시스템

**📖 새로운 Claude 세션?** → [프로젝트 컨텍스트 문서](.claude/docs/PROJECT-CONTEXT.md) (5분이면 전체 파악)

## 🆕 v2.9.0 주요 기능

### Plan Mode Integration
- **📋 Claude Code Plan Mode 통합** - 복잡한 작업 시 체계적인 계획 수립 후 자동 실행
  - 복잡도 점수 5점 이상 시 Plan Mode 사용 가이드 자동 표시
  - Plan Mode에서 작성한 계획을 대화 컨텍스트에서 자동 감지
  - Major 워크플로우 Step 2-4 자동 건너뛰기 (50% 시간 절약)
  - 항상 Fallback 옵션 제공 (기존 워크플로우 100% 유지)
- **🔍 키워드 기반 컨텍스트 추출** - 자연어 계획 자동 파싱
  - 키워드 감지: '계획', 'plan', 'phase', '단계', 'step'
  - 최소 200자 이상 메시지 필터링
  - 15개 유닛 테스트로 검증된 추출 로직
- **⚡ 간소화된 접근** - ExitPlanMode API 의존성 제거
  - 대화 컨텍스트 기반 통합 (구조화된 API 불필요)
  - `/triage` → Plan Mode → `/major` 원활한 흐름
  - 사용자 가이드 템플릿 제공

## 🆕 v2.8.0 주요 기능

### PR Review with Codebase Context (v2.8.0)
- **🔍 전체 코드베이스 참조** - PR diff만이 아닌 전체 프로젝트를 분석하여 더 정확한 리뷰 제공
  - 재사용 가능한 기존 모듈 자동 감지 및 제안
  - 중복 코드 탐지 (80% 이상 유사도)
  - 프로젝트 표준 패턴 준수 검증
- **📊 성능 최적화** - 하이브리드 캐싱으로 빠른 분석 (30초 타임아웃)
  - 메모리 + 파일 캐시 (SHA256 해시 검증)
  - Progressive 인덱싱으로 대규모 코드베이스 지원
- **⚠️ 스마트한 경고** - 불필요한 경고 50% 감소, 정확도 80% 달성
  - 기존 컴포넌트 재사용 제안 (예: MyButton → shared/ui/Button)
  - 중복 함수/유틸리티 발견 및 통합 권장
  - 표준 패턴 (예: React Query) 사용 권장
- **📁 신규 파일**: `.claude/agents/code-reviewer/lib/` (4개 스크립트)
  - `cache-manager.sh` - 하이브리드 캐싱 관리
  - `codebase-indexer.sh` - 모듈/패턴 인덱싱
  - `similarity-analyzer.sh` - 유사도 계산 (이름 30%, 타입 20%, 시그니처 30%, Props 20%)
  - `suggestion-generator.sh` - 리뷰 제안 생성

### Installation Stability Hotfix (v2.7.2)
- **🔧 Checksum 검증 최적화** - 불필요한 파일 검증 제거
  - 로컬 설정 파일 제외 (`.claude/settings.local.json`, `*.local.json`)
  - 설치 시 생성되는 파일 제외 (`.claude/hooks/*`)
  - 프로젝트별 문서 제외 (`.specify/memory/*`)
  - 체크섬 파일 수: 105 → 100개 (5개 제외)
- **✅ 설치 안정성 향상** - 404 에러 완전 제거, 설치 속도 개선

### FSD Custom Architecture (v2.7.0)
- **🏗️ Domain-Centric Features** - 하나의 feature = 하나의 도메인 (백엔드 서비스처럼)
  - config.json v2.1.0-team-custom
  - Widgets 레이어 제거 → Features/Pages로 병합
  - Type-only imports 지원 (feature 간 타입 참조)
  - Pages First 원칙 적용 (페이지 특화 로직은 pages에 유지)
- **📐 4 Core Layers** - app → pages → features → entities (optional) → shared
- **📖 자세한 가이드** - [FSD Architecture Guide](architectures/frontend/fsd/fsd-architecture.mdc)

### 이전 기능 (v2.6.0)

### 핵심 개선사항
- **🔒 SHA256 체크섬 기반 파일 무결성 검증** - 설치 시 자동 파일 검증 및 복구
  - 100개 핵심 파일의 SHA256 체크섬 자동 검증
  - 불일치 파일 자동 재다운로드
  - 복구 실패 시 안전한 롤백
  - .gitignore 자동 관리 (백업/캐시 제외)
- **✅ 강화된 Validation 시스템** - 4가지 마이그레이션 시나리오 완전 검증
  - v1.0 → v2.6 마이그레이션
  - v2.4/v2.5 → v2.6 업그레이드
  - 신규 설치 검증
  - 롤백 시나리오 자동 테스트
- **🔄 자동 롤백 기능** - 마이그레이션 실패 시 이전 상태로 안전하게 복구
- **📋 Pre-commit Hook** - .claude/ 변경사항 자동 검증 및 커밋 차단
- **🔍 통합 Validation** - install.sh에 validation 자동 실행 통합

### 기존 기능 (v2.5)
- **📊 실시간 메트릭스 대시보드** - 토큰 사용량, 성능, 품질 지표 모니터링
- **🎯 자동 워크플로우 선택** - /triage로 Major/Minor/Micro 자동 분류

## 🚀 Quick Start

```bash
# 설치
curl -fsSL https://raw.githubusercontent.com/Liamns/claude-workflows/main/install.sh | bash

# 또는 로컬 설치
bash install.sh

# 헬스 체크
bash install.sh --health-check

# Validation 실행
bash .claude/lib/validate-system.sh
```

## 🔒 Installation Verification

### SHA256 체크섬 기반 파일 무결성 검증

설치 시 자동으로 실행되는 고급 검증 시스템:

- **✅ 파일 무결성 검증**: 100개 핵심 파일의 SHA256 체크섬 자동 검증
- **🔄 자동 복구**: 불일치 파일 자동 재다운로드
- **🛡️ 안전한 롤백**: 복구 실패 시 이전 버전으로 자동 복원
- **📝 .gitignore 관리**: 백업/캐시 파일 자동 제외

### 수동 검증

```bash
# 체크섬 매니페스트 다운로드
cd /path/to/project
source .claude/lib/verify-with-checksum.sh
download_checksum_manifest "https://github.com/Liamns/claude-workflows" "main"

# 파일 무결성 검증
verify_installation_with_checksum

# 실패 파일 자동 복구
retry_failed_files "https://github.com/Liamns/claude-workflows" "main"
```

### 체크섬 매니페스트 생성 (개발자용)

```bash
# 현재 프로젝트의 체크섬 생성
bash .claude/lib/generate-checksums.sh -o .claude/.checksums.json --verbose

# 출력 예시
# ✓ Checksum manifest generated: .claude/.checksums.json
#   Version: 2.7.0
#   Files: 190
#   Generated at: 2025-01-11T10:00:00Z
```

**자세한 내용**: [Installation Verification Guide](.specify/specs/003-install-verification-improvement/quickstart.md)

## 💡 핵심 기능

### 3단계 자동 워크플로우

```bash
/triage "작업 설명"    # AI가 자동으로 Major/Minor/Micro 선택
/dashboard            # 실시간 메트릭스 모니터링
```

| 워크플로우 | 토큰 절감 | 대상 |
|------------|-----------|------|
| **Micro** | 85% | 타이포, 로그 제거 등 간단한 수정 |
| **Minor** | 75% | 버그 수정, 기능 개선 |
| **Major** | 60% | 신규 기능, 아키텍처 변경 |

### 주요 명령어

```bash
/start              # 프로젝트 초기화 (처음 한 번만)
/triage "작업"      # ⭐ 자동 워크플로우 선택 + Plan Mode 가이드
/major "기능명"     # 신규 기능 개발 (60% 토큰 절감)
/minor "설명"       # 버그 수정, 개선 (75% 토큰 절감)
/micro "설명"       # 간단한 수정 (85% 토큰 절감)
/review --staged    # 코드 리뷰
/commit            # 스마트 커밋
/pr                # PR 자동 생성
/dashboard         # 📊 실시간 메트릭스 대시보드
```

### 🆕 Plan Mode 사용법 (v2.9.0-dev)

복잡한 작업(복잡도 5점 이상)은 Plan Mode로 먼저 계획을 수립하면 효율적입니다:

```bash
# 1. 복잡도 분석
/triage "새로운 인증 시스템 추가"
# → 복잡도 12점 (Major) 감지
# → Plan Mode 가이드 자동 표시

# 2. Plan Mode 진입
Shift+Tab  # Plan Mode 활성화

# 3. 계획 요청
"새로운 인증 시스템의 상세 구현 계획을 작성해주세요"
# → Claude가 자동으로 계획 작성
# → 대화 컨텍스트에 저장됨

# 4. Major 워크플로우 실행
/major
# → Step 1.5에서 계획 자동 감지 ✅
# → Step 2-4 질문 건너뛰기 (50% 시간 절약)
# → 바로 문서 생성 단계로 진행
```

**Fallback 옵션**: Plan Mode를 건너뛰고 기존 방식으로도 진행 가능합니다.

```bash
/triage "복잡한 작업"
# → "Option B: 바로 Major 워크플로우 시작" 선택
/major
# → 질문-응답 방식으로 진행 (기존 방식 유지)
```

## 🏗️ 시스템 구성

- **6개 통합 Agents**: 최적화된 전문 AI (v2.4 통합)
- **15개 Skills**: 상황별 자동 활성화 패턴
- **6개 아키텍처 지원**: FSD, Atomic, Clean, DDD 등

## 📁 프로젝트 구조

```
.claude/
├── commands/       # Slash 명령어
├── agents/        # Sub-agents
├── skills/        # 자동 활성화 스킬
└── config/        # 설정 파일

architectures/     # 아키텍처 템플릿
workflow-gates.json # 품질 게이트 설정
```

## 🎯 핵심 원칙

1. **토큰 효율성**: 작업별 60-85% 절감
2. **재사용 우선**: 기존 패턴/모듈 자동 검색
3. **품질 게이트**: 워크플로우별 자동 검증
4. **Test-First**: TDD 적용 (80%+ 커버리지)
5. **자동 Validation**: 문서-코드 일관성 자동 검증

## ✅ Validation 시스템

### 자동 검증
```bash
# 전체 검증
bash .claude/lib/validate-system.sh

# 문서만 검증
bash .claude/lib/validate-system.sh --docs-only

# 마이그레이션만 검증
bash .claude/lib/validate-system.sh --migration-only

# 교차 참조만 검증
bash .claude/lib/validate-system.sh --crossref-only
```

### Pre-commit Hook
```bash
# Hook 설치
bash .claude/hooks/install-hooks.sh

# 이후 git commit 시 자동 validation
git commit -m "feat: new feature"
# → 자동으로 .claude/ 변경사항 검증
```

### Validation 리포트
- 위치: `.claude/cache/validation-reports/`
- 형식: JSON + Markdown
- 자동 정리: 30일 이상 된 리포트 삭제

## 🔄 마이그레이션 지원

### 지원하는 시나리오 (v2.6 강화)
1. **v1.0 → v2.6**: 레거시 시스템 완전 업그레이드
   - Deprecated 파일 자동 정리 (major-specify.md, 구 agents 등)
   - v2.6 구조로 자동 변환
2. **v2.4/v2.5 → v2.6**: 최신 버전 업그레이드
   - 증분 마이그레이션 지원
   - 기존 설정 보존
3. **신규 설치**: 처음 사용하는 경우
   - 깨끗한 v2.6 구조 설치
   - Deprecated 파일 없음 보장
4. **자동 롤백** (v2.6 신규): 마이그레이션 실패 시
   - 자동으로 백업에서 복구
   - Critical 파일 우선 복원
   - 사용자 데이터 보존

### 마이그레이션 실행
```bash
# 자동으로 현재 버전 감지 및 적절한 마이그레이션 실행
bash install.sh

# 버전 확인
cat .claude/.version

# 헬스 체크
bash install.sh --health-check
```

### 백업 및 롤백
- 백업 위치: `.claude/.backup/install-YYYYMMDD-HHMMSS/`
- 마이그레이션 실패 시 자동 롤백
- Critical 파일 우선 복구 (workflow-gates.json, config/, cache/)

## 📚 더 알아보기

### 핵심 문서
- [프로젝트 컨텍스트](.claude/docs/PROJECT-CONTEXT.md) - 전체 구조 이해 (필독)
- [아키텍처 가이드](ARCHITECTURE.md) - 시스템 설계
- [기여 가이드](CONTRIBUTING.md) - 개발 참여

### 상세 가이드
- [Sub-agents 가이드](.claude/docs/SUB-AGENTS-GUIDE.md)
- [Skills 가이드](.claude/docs/SKILLS-GUIDE.md)
- [모델 최적화](.claude/docs/MODEL-OPTIMIZATION-GUIDE.md)

### 예시 및 템플릿
- [사용 예시](EXAMPLES.md)
- [변경 이력](CHANGELOG.md)

## 🤝 기여

1. Fork & Clone
2. Feature branch 생성
3. 코드 작성 및 테스트
4. `/commit`으로 커밋
5. Pull Request

## 📝 라이선스

MIT License - 자유롭게 사용, 수정, 배포 가능

## 🙋 지원

- Issues: [GitHub Issues](https://github.com/Liamns/claude-workflows/issues)
- Wiki: [Notion 문서](https://www.notion.so/2a21e422ebe480c59138f5ca33cbf007)

---

**v2.5.0** | [GitHub](https://github.com/Liamns/claude-workflows) | Made with ❤️ for Claude Code
