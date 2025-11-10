# 🤖 Claude Workflows

[![Version](https://img.shields.io/badge/version-2.6.0-blue.svg)](https://github.com/Liamns/claude-workflows)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Compatible-purple.svg)](https://claude.ai/code)
[![Validation](https://img.shields.io/badge/validation-automated-success.svg)](https://github.com/Liamns/claude-workflows)

> Claude Code의 토큰 효율성을 극대화하면서 코드 품질을 보장하는 지능형 워크플로우 시스템

**📖 새로운 Claude 세션?** → [프로젝트 컨텍스트 문서](.claude/docs/PROJECT-CONTEXT.md) (5분이면 전체 파악)

## 🆕 v2.6.0 주요 기능

### 핵심 개선사항
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
/triage "작업"      # ⭐ 자동 워크플로우 선택
/major "기능명"     # 신규 기능 개발 (60% 토큰 절감)
/minor "설명"       # 버그 수정, 개선 (75% 토큰 절감)
/micro "설명"       # 간단한 수정 (85% 토큰 절감)
/review --staged    # 코드 리뷰
/commit            # 스마트 커밋
/pr                # PR 자동 생성
/dashboard         # 📊 실시간 메트릭스 대시보드
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
