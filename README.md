# 🤖 Claude Workflows

[![Version](https://img.shields.io/badge/version-2.5.0-blue.svg)](https://github.com/Liamns/claude-workflows)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Compatible-purple.svg)](https://claude.ai/code)

> Claude Code의 토큰 효율성을 극대화하면서 코드 품질을 보장하는 지능형 워크플로우 시스템

**📖 새로운 Claude 세션?** → [프로젝트 컨텍스트 문서](.claude/docs/PROJECT-CONTEXT.md) (5분이면 전체 파악)

## 🚀 Quick Start

```bash
# 1분 설치
curl -fsSL https://raw.githubusercontent.com/Liamns/claude-workflows/main/install.sh | bash
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
/test "요구사항"    # 테스트 자동 생성/실행
/review --staged    # 코드 리뷰
/commit            # 스마트 커밋
/dashboard         # 📊 실시간 메트릭스 대시보드
```

## 🏗️ 시스템 구성

- **6개 통합 Agents**: 최적화된 전문 AI (v2.4 통합)
- **13개 Skills**: 상황별 자동 활성화 패턴
- **12개 아키텍처 지원**: FSD, Clean, DDD 등

## 📁 프로젝트 구조

```
.claude/
├── commands/       # Slash 명령어
├── agents/        # Sub-agents
├── skills/        # 자동 활성화 스킬
└── config/        # 설정 파일

docs/              # 상세 문서
architectures/     # 아키텍처 템플릿
workflow-gates.json # 품질 게이트 설정
```

## 🎯 핵심 원칙

1. **토큰 효율성**: 작업별 60-85% 절감
2. **재사용 우선**: 기존 패턴/모듈 자동 검색
3. **품질 게이트**: 워크플로우별 자동 검증
4. **Test-First**: TDD 적용 (80%+ 커버리지)

## 📚 더 알아보기

### 핵심 문서
- [프로젝트 컨텍스트](.claude/docs/PROJECT-CONTEXT.md) - 전체 구조 이해 (필독)
- [아키텍처 가이드](ARCHITECTURE.md) - 시스템 설계
- [기여 가이드](CONTRIBUTING.md) - 개발 참여

### 상세 가이드
- [Sub-agents 가이드](.claude/docs/SUB-AGENTS-GUIDE.md)
- [Skills 가이드](.claude/docs/SKILLS-GUIDE.md)
- [모델 최적화](.claude/docs/MODEL-OPTIMIZATION-GUIDE.md)
- [개선 제안](.claude/docs/IMPROVEMENT-PROPOSALS.md)

### 예시 및 템플릿
- [사용 예시](EXAMPLES.md)
- [변경 이력](CHANGELOG.md)

## 🤝 기여

1. Fork & Clone
2. Feature branch 생성
3. `/test`로 테스트 작성
4. `/commit`으로 커밋
5. Pull Request

## 📝 라이선스

MIT License - 자유롭게 사용, 수정, 배포 가능

## 🙋 지원

- Issues: [GitHub Issues](https://github.com/Liamns/claude-workflows/issues)
- Wiki: [Notion 문서](https://www.notion.so/2a21e422ebe480c59138f5ca33cbf007)

---

**v2.5.0** | [GitHub](https://github.com/Liamns/claude-workflows) | Made with ❤️ for Claude Code