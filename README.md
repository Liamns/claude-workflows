# 🤖 Claude Workflows

[![Version](https://img.shields.io/badge/version-3.1.2-blue.svg)](https://github.com/Liamns/claude-workflows)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Compatible-purple.svg)](https://claude.ai/code)
[![Validation](https://img.shields.io/badge/validation-automated-success.svg)](https://github.com/Liamns/claude-workflows)

> Claude Code의 토큰 효율성을 극대화하면서 코드 품질을 보장하는 지능형 워크플로우 시스템

**📖 새로운 Claude 세션?** → [프로젝트 컨텍스트 문서](.claude/docs/PROJECT-CONTEXT.md) (5분이면 전체 파악)

## 🆕 최신 업데이트 (v3.1.2)

### Epic 005: Workflow System Improvement
- **자동 아키텍처 검증** - FSD, Clean Architecture, Hexagonal, DDD 등 다중 패턴 지원
- **한글 문서화 강제** - 계획 문서 한글 작성 자동 검증 (60% 목표, 45% 통과)
- **Git 상태 자동 관리** - 브랜치 생성 시 commit/stash/discard 자동 처리
- **체크섬 검증 강화** - `.specify/` 디렉토리 포함, 자동 무결성 검증
- **Plan Mode 제거** - 실행 시간 30초-1분 단축, 수동 단계 제거

### Epic 001: Epic Workflow System
- **대규모 프로젝트 관리** - 복잡도 10+ 작업을 3-5개 Feature로 자동 분해
- **진행 상황 추적** - `progress.md`, `roadmap.md` 자동 업데이트
- **무결성 검증** - DAG 검증으로 순환 의존성 방지

**전체 변경 내역**: [CHANGELOG.md](CHANGELOG.md)

## 🚀 빠른 설치

```bash
# 원격 설치
curl -fsSL https://raw.githubusercontent.com/Liamns/claude-workflows/main/install.sh | bash

# 로컬 설치
bash install.sh

# 헬스 체크
bash install.sh --health-check
```

## 💡 핵심 명령어

### 자동 워크플로우 선택
```bash
/triage "작업 설명"    # AI가 자동으로 Major/Minor/Micro 선택
/dashboard            # 실시간 메트릭스 모니터링
```

### 워크플로우별 명령어
```bash
/start              # 프로젝트 초기화 (처음 한 번만)
/epic "작업명"      # 대규모 프로젝트 (복잡도 10+, Feature 분해)
/major "기능명"     # 신규 기능 개발 (60% 토큰 절감)
/minor "설명"       # 버그 수정, 개선 (75% 토큰 절감)
/micro "설명"       # 간단한 수정 (85% 토큰 절감)
```

### 코드 품질
```bash
/review --staged    # 코드 리뷰 (보안, 성능, 아키텍처)
/commit            # 스마트 커밋 (Conventional Commits)
/pr                # PR 자동 생성
```

## 🎯 주요 기능

### 토큰 효율성
| 워크플로우 | 토큰 절감 | 대상 |
|-----------|----------|------|
| **Micro** | 85% | 타이포, 로그 제거 등 간단한 수정 |
| **Minor** | 75% | 버그 수정, 기능 개선 |
| **Major** | 60% | 신규 기능, 아키텍처 변경 |
| **Epic**  | 40% | 대규모 프로젝트 (3-5개 Feature 분해) |

### 자동화 시스템
- **6개 전문 Agents**: 최적화된 역할별 AI (reviewer, architect, implementer 등)
- **15개 Skills**: 상황별 자동 활성화 (API 통합, Form 검증, FSD 컴포넌트 등)
- **품질 게이트**: 워크플로우별 자동 검증 (테스트, 타입 체크, 보안)
- **TDD 강제**: 80%+ 커버리지 목표

### 아키텍처 지원
- **FSD (Feature-Sliced Design)** - Domain-Centric 커스텀 규칙
- **Clean Architecture** - Layer 의존성 검증
- **Hexagonal Architecture** - Port/Adapter 패턴
- **DDD, Atomic Design, MVC** - 다중 패턴 동시 지원

## 🔒 보안 & 검증

### 자동 파일 무결성 검증
```bash
# 설치 시 자동 실행: 152개 핵심 파일의 SHA256 체크섬 검증
bash .claude/lib/verify-with-checksum.sh

# 전체 시스템 검증
bash .claude/lib/validate-system.sh

# Pre-commit Hook 설치
bash .claude/hooks/install-hooks.sh
```

### Validation 항목
- ✅ 문서-코드 일관성
- ✅ 순환 의존성 검출
- ✅ 아키텍처 규칙 준수
- ✅ 한글 문서화 비율
- ✅ 파일 무결성 (SHA256)

## 📁 프로젝트 구조

```
.claude/
├── commands/          # Slash 명령어 (/triage, /major 등)
├── agents/           # 전문 AI agents (6개)
├── skills/           # 자동 활성화 스킬 (15개)
├── lib/              # 핵심 라이브러리
│   ├── version/      # 버전 관리 자동화 (Feature 006)
│   ├── validate-*.sh # 검증 스크립트
│   └── metrics/      # 메트릭스 수집
└── config/           # 설정 파일

.specify/specs/       # Epic/Feature 명세
.github/workflows/    # CI/CD 자동화
architectures/        # 아키텍처 템플릿
workflow-gates.json   # 품질 게이트 설정
```

## 🔄 마이그레이션 & 업그레이드

### 지원 시나리오
- **v1.0 → v3.1**: 레거시 시스템 완전 업그레이드
- **v2.x → v3.1**: 증분 마이그레이션 (기존 설정 보존)
- **자동 롤백**: 실패 시 백업에서 복구

### 업그레이드
```bash
# 자동 버전 감지 및 마이그레이션
bash install.sh

# 백업 위치
ls .claude/.backup/install-*/
```

## 📚 더 알아보기

### 핵심 문서
- [프로젝트 컨텍스트](.claude/docs/PROJECT-CONTEXT.md) - 5분 빠른 시작
- [Epic Workflow 가이드](.specify/specs/001-epic-workflow-system/INTEGRATION.md)
- [아키텍처 검증](.specify/specs/002-architecture-compliance-check/quickstart.md)
- [설치 검증 가이드](.specify/specs/003-install-verification-improvement/quickstart.md)

### Slash 명령어
```bash
/help              # 전체 명령어 목록
/triage --help     # Triage 사용법
/major --help      # Major 워크플로우 가이드
/dashboard         # 실시간 대시보드
```

### 관련 링크
- [GitHub Repository](https://github.com/Liamns/claude-workflows)
- [Issue Tracker](https://github.com/Liamns/claude-workflows/issues)
- [Changelog](CHANGELOG.md)
- [License](LICENSE)

## 🤝 Contributing

워크플로우 개선, 버그 리포트, 문서 업데이트 환영합니다!

```bash
# Epic 브랜치에서 Feature 개발
git checkout 005-epic-workflow-system-improvement
git checkout -b 006-new-feature

# Conventional Commits 사용
git commit -m "feat(workflow): add new automation [F007]"
```

## 📊 성과

- **토큰 절감**: 평균 60-85%
- **개발 속도**: 2-3배 향상
- **코드 품질**: 자동 검증으로 일관성 100%
- **테스트 커버리지**: 80%+ 강제
- **문서화**: 한글 45%+ 자동 검증

---

**Made with ❤️ by Claude Code Community**
