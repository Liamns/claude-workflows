# 🤖 Claude Workflows

[![Version](https://img.shields.io/badge/version-4.0.0-blue.svg)](https://github.com/Liamns/claude-workflows)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Compatible-purple.svg)](https://claude.ai/code)
[![Validation](https://img.shields.io/badge/validation-automated-success.svg)](https://github.com/Liamns/claude-workflows)

> Claude Code의 토큰 효율성을 극대화하면서 코드 품질을 보장하는 지능형 워크플로우 시스템

**📖 새로운 Claude 세션?** → [프로젝트 컨텍스트 문서](.claude/docs/PROJECT-CONTEXT.md) (5분이면 전체 파악)

## 🆕 최신 기능

### v4.0.0 - Legacy Cleanup & Streamlined Architecture

**🧹 대규모 레거시 정리**
- deprecated 레거시 명령어 및 설정 파일 완전 제거
- 사용하지 않는 Shell 스크립트 40+ 개 정리
- commands-config/*.yaml 레거시 파일 삭제
- 코드베이스 경량화 및 유지보수성 향상

**🛡️ Epic 007 - md+Hook+CLAUDE.md 3중 방어 구조**
- 명령어 md 파일 자체 규칙 강화
- PostHook 검증 시스템 연동
- CLAUDE.md 프로젝트 레벨 규칙 통합
- 문서 완성도 자동 검증

**🎯 6개 도메인 전문 Skill 추가**
- 에이전트별 Skill 참조 섹션 구조화
- 문서 생성 도구 자동화
- 도메인별 전문 가이드라인 적용

### v3.5.0 - 통합 명령어 시스템

**📝 /docu - Notion 문서 통합 관리**
- 기존 notion-* 명령어 6개를 단일 명령어로 통합
- 10개 액션: `start`, `list`, `switch`, `recommend`, `update`, `log`, `sync`, `search`, `close`, `add`
- 하이브리드 명령어 구조 (.md + .yaml)

**📌 /tracker - 프로젝트 & 이슈 트래커**
- Projects 데이터베이스 연동
- 5개 액션: `add`, `list`, `update`, `assign`, `close`
- Tag 기반 관리: Issue, Bug, Feature, Refactoring

### v3.3.2 - Slash Command UX Improvement

**🎯 실행 흐름 강제화**
- CRITICAL INSTRUCTIONS: 모든 슬래시 커맨드에 실행 순서 가이드 추가
- 타입 시스템: Workflow/Utility/Hybrid 명령어 자동 분류
- 명령어 추천: 완료 후 다음 단계 자동 추천 시스템

**🧹 코드 정리**
- 12,765줄 삭제: 사용하지 않는 테스트 파일 및 deprecated 모듈 제거
- 코드베이스 40% 감소: 유지보수성 및 성능 향상

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

**✅ 권장 방법 (Wrapper Script):**
```bash
# 체크섬 재생성 + Git 자동 스테이징
bash .claude/lib/update-checksums.sh

# 자동으로 수행:
# 1. 체크섬 생성 (올바른 -o 플래그 사용)
# 2. Git 스테이징
# 3. 변경사항 요약 표시
# 4. 다음 단계 가이드
```

**수동 방법 (고급 사용자):**
```bash
# 직접 체크섬 생성 (주의: -o 플래그 필수!)
bash .claude/lib/generate-checksums.sh -o .claude/.checksums.json --verbose

# 출력 예시
# ✓ Checksum manifest generated: .claude/.checksums.json
#   Version: 4.0.0
#   Files: 240
#   Generated at: 2025-01-18T10:00:00Z
```

**⚠️ 주의사항**: `-o` 플래그를 빠뜨리면 파일이 업데이트되지 않고 stdout으로만 출력됩니다. 이를 방지하려면 wrapper script 사용을 권장합니다.

**자세한 내용**: [Installation Verification Guide](.specify/specs/003-install-verification-improvement/quickstart.md)

## 💡 핵심 기능

### 3단계 자동 워크플로우

```bash
/triage "작업 설명"    # AI가 자동으로 Major/Minor/Micro 선택
/dashboard            # 실시간 메트릭스 모니터링
```

| 워크플로우      | 토큰 절감 | 대상                             |
| --------------- | --------- | -------------------------------- |
| **Micro** | 85%       | 타이포, 로그 제거 등 간단한 수정 |
| **Minor** | 75%       | 버그 수정, 기능 개선             |
| **Major** | 60%       | 신규 기능, 아키텍처 변경         |

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

# 📝 Notion Integration (v3.5.0)
/docu start        # Notion 기능 명세서 작업 시작
/docu list         # 진행 중인 작업 목록
/docu add          # 새 기능정의서 추가
/tracker add       # 프로젝트/이슈 추가
/tracker list      # 프로젝트 목록 조회

# 🗄️ Database Tools (v4.0.0)
/db-sync           # Production → Development DB 동기화
/prisma-migrate    # Prisma 스키마 자동 마이그레이션
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

.claude/architectures/     # 아키텍처 템플릿
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

**v4.0.0** | [GitHub](https://github.com/Liamns/claude-workflows) | Made with ❤️ for Claude Code
