# 🤖 Claude Workflows

[![Version](https://img.shields.io/badge/version-2.3.0-blue.svg)](https://github.com/Liamns/claude-workflows)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Compatible-purple.svg)](https://claude.ai/code)
[![Architecture](https://img.shields.io/badge/Architecture-Multi--Support-orange.svg)](ARCHITECTURE-GUIDE.md)
[![Models](https://img.shields.io/badge/Models-Opus%2FSonnet%2FHaiku-green.svg)](docs/MODEL-OPTIMIZATION-GUIDE.md)

> Smart workflows for Claude Code with Comprehensive Code Review, Multi-Architecture Support & Intelligent Model Optimization

Claude Code를 통한 개발 효율성 극대화를 위한 지능형 워크플로우 시스템

## 🚀 Quick Start

### 1분 설치

```bash
# 현재 프로젝트에 설치
curl -fsSL https://raw.githubusercontent.com/Liamns/claude-workflows/main/install.sh | bash

# 또는 직접 클론
git clone https://github.com/Liamns/claude-workflows
cd claude-workflows
./install.sh /path/to/your/project
```

### 첫 명령어

```bash
# AI가 작업 복잡도를 자동 분석하여 최적 워크플로우 선택
/triage "타입 에러 수정"
→ Minor 워크플로우 자동 선택 (75% 토큰 절약)
```

## ✨ 새로운 기능 (v2.3.0)

### 📋 종합 코드 리뷰 시스템 (v2.3 신규)
**`/review` 명령어** - PR 없이도 언제든 코드 리뷰 수행
- **유연한 스코프**: 파일, 디렉토리, git diff, staged/unstaged 변경사항
- **Constitution 인식**: `/start`로 설정한 프로젝트 규칙 자동 적용
- **고급 분석 (--adv)**: 파일 간 영향도, 의존성 그래프, Breaking Changes
- **다양한 출력**: 요약(기본), 상세, JSON(CI/CD용)
- **지능형 보안 스캔**: OWASP Top 10, 민감 데이터, 의존성 취약점

```bash
# 기본 사용
/review src/features/order
/review --staged              # 커밋 전 검토
/review --diff main...HEAD    # 브랜치 차이

# 고급 분석
/review src/ --adv            # 심층 분석 모드

# 출력 형식
/review src/ --format json    # CI/CD 통합용
```

## ✨ 기존 기능 (v2.2.0)

### 🏗️ 다중 아키텍처 지원 (v2.2 신규)
**모든 프로젝트 타입 지원** - Frontend, Backend, Fullstack, Mobile
- **Frontend**: FSD, Atomic Design, MVC/MVP/MVVM, Micro Frontend
- **Backend**: Clean, Hexagonal, DDD, Layered, Serverless
- **Fullstack**: Monorepo, JAMstack, Microservices
- **자동 감지**: 기존 프로젝트 구조 자동 인식
- **마이그레이션**: 아키텍처 간 전환 도구 제공

### 🎯 지능형 모델 최적화 (v2.2 신규)
**Opus/Sonnet/Haiku 자동 전환** - 작업 복잡도에 따른 최적 모델 선택
- **복잡도 점수**: 파일 수, 변경 범위, Breaking Changes 자동 평가
- **Context7 통합**: Plan 단계에서 프로젝트 컨텍스트 선택적 로드 (3,000 토큰)
- **쿼터 관리**: Opus 한도 도달 시 자동 Sonnet 폴백
- **비용 절감**: 토큰 사용량 40-50% 감소, 품질 유지

## ✨ 기존 기능 (v2.0)

### 🔄 재사용성 우선 원칙 (신규)
**Article X** - 모든 코드 작성 시 기존 패턴과 모듈을 우선 검색하고 재사용
- **자동 검색**: `/triage` 실행 시 재사용 가능 모듈 자동 제시
- **패턴 일관성**: 새로운 "더 나은" 방법보다 기존 패턴 준수
- **중복 방지**: 유사 코드 감지 및 추출 제안
- **메트릭 추적**: 재사용률 60% 목표, 중복률 5% 이하 유지

### 🎯 `/triage` - 자동 워크플로우 선택
작업 설명을 입력하면 AI가 자동으로 Major/Minor/Micro 중 최적 워크플로우 선택
- **토큰 절약**: 잘못된 워크플로우 선택으로 인한 낭비 방지
- **스마트 분석**: 복잡도 점수 기반 자동 분류
- **재사용 모듈 검색**: 기존 컴포넌트와 패턴 자동 제시
- **추가 질문**: 애매한 경우 구체적 정보 요청

### 📝 `/commit` - 스마트 커밋
Git 변경사항을 분석하여 Conventional Commits 형식으로 자동 커밋
- **자동 타입 판단**: feat/fix/refactor 등 정확한 분류
- **Breaking Changes 감지**: 호환성 영향 자동 탐지
- **선택적 검증**: 타입체크, 린트, 테스트 실행 옵션

### 🔍 `/pr-review` - PR 자동 리뷰
GitHub PR을 자동으로 분석하고 코드 리뷰 수행
- **보안 검사**: XSS, SQL Injection 등 취약점 검사
- **성능 분석**: 메모리 누수, 불필요한 리렌더링 감지
- **아키텍처 검증**: FSD 규칙 준수 확인
- **터미널 출력**: GitHub 댓글 없이 로컬에서 결과 확인

## 📊 워크플로우 사용법

### 프로젝트 초기 설정
```bash
# 대화형 설정 (아키텍처 선택 포함)
/start

→ 프로젝트 타입 선택 (Frontend/Backend/Fullstack/Mobile)
→ 아키텍처 패턴 선택 (FSD/Clean/DDD/Atomic 등)
→ 모델 전략 선택 (Quality/Balanced/Aggressive)
```

### Major 워크플로 (신규 기능)
```bash
# 자동 선택 (권장)
/triage "사용자 인증 기능 추가"

# 직접 실행 + 모델 옵션
/major user-authentication --model=opus --use-context7
/major simple-feature --optimize-cost
```

### Minor 워크플로 (버그 수정/개선)
```bash
# 자동 선택
/triage "로그인 폼 검증 버그"

# 또는 직접 실행
/minor fix-login-validation
```

### Micro 워크플로 (빠른 수정)
```bash
/micro 로그인 버튼 텍스트 오타 수정
/micro console.log 제거
```

#### Sub-agents & Skills
- **Sub-agents**: 컨텍스트 격리된 전문 에이전트
- **Skills**: 자동으로 상황에 맞게 실행되는 패턴

## 📋 워크플로 분류

### 🚀 Major (Spec-Kit)
**대상**: 신규 기능 추가, 아키텍처 변경, API 엔드포인트 추가

**예상 토큰 절감**: 60%
**품질 레벨**: Highest

**Quality Gates**:
- ✅ **재사용성 검색** (필수) - 기존 모듈 우선 활용
- ✅ Spec 품질 검증
- ✅ 테스트 계획 수립
- ✅ FSD 아키텍처 준수
- ✅ TDD (80%+ 커버리지)
- ✅ 자동 코드 리뷰
- ✅ 빌드 성공

### 🔧 Minor (Lightweight)
**대상**: 버그 픽스, 기존 기능 개선, UI 스타일 변경

**예상 토큰 절감**: 75%
**품질 레벨**: High

**Quality Gates**:
- ✅ 문제 식별
- ✅ 최소 변경 원칙
- ✅ FSD 규칙 준수
- ✅ 타입 체크
- ✅ 관련 테스트 통과

### ⚡ Micro (Quick Fix)
**대상**: 타이포 수정, 주석, 로그 제거, 설정 파일

**예상 토큰 절감**: 85%
**품질 레벨**: Standard

**Quality Gates**:
- ✅ 문법 체크

## 🤖 Sub-agents (10개)

1. **architect**: 아키텍처 검증 (모든 아키텍처 지원, 모델 자동 선택)
2. **code-reviewer**: 종합 코드 리뷰 (보안, 성능, 품질)
3. **security-scanner**: 전문 보안 취약점 스캔 (OWASP Top 10)
4. **impact-analyzer**: 파일 간 영향도 분석 (--adv 모드 전용)
5. **quick-fixer**: 빠른 버그 수정 (Haiku 자동 다운그레이드)
6. **changelog-writer**: Git diff 분석 및 변경사항 문서화
7. **test-guardian**: TDD 적용 및 테스트 품질 관리
8. **api-designer**: API 계약 설계 (복잡한 API는 Opus 사용)
9. **mobile-specialist**: Capacitor 플랫폼 분기 및 네이티브 API 통합
10. **smart-committer**: Conventional Commits 자동 생성

## 🛠️ Skills (13개)

1. **reusability-enforcer**: 재사용 모듈 자동 검색 (Context7 통합)
2. **test-coverage-analyzer**: 테스트 커버리지 분석 및 갭 식별 (신규)
3. **code-metrics-collector**: 코드 복잡도, 중복률 메트릭 수집 (신규)
4. **dependency-tracer**: 의존성 그래프 및 순환 의존성 감지 (신규)
5. **component-creation**: 아키텍처별 컴포넌트 생성 (Context7 통합)
6. **api-integration**: httpClient 기반 API 통합 (Context7 통합)
7. **bug-fix-pattern**: 일관된 버그 수정 프로세스
8. **daily-changelog-notion**: Git 변경사항 Notion 자동화
9. **form-validation**: React Hook Form + Zod 검증
10. **platform-detection**: Capacitor 플랫폼 분기
11. **mobile-build**: Android/iOS 빌드 자동화
12. **commit-guard**: 커밋 전 검증 (3단계)
13. **fsd-component-creation**: FSD 컴포넌트 생성 (레거시)

## 📁 구조

```
.claude/
├── commands/                    # Slash Commands
│   ├── start.md                 # 프로젝트 초기화 (아키텍처 선택)
│   ├── triage.md                # 자동 워크플로우 선택
│   ├── review.md                # 종합 코드 리뷰 (신규)
│   ├── commit.md                # 스마트 커밋
│   ├── pr-review.md             # PR 자동 리뷰
│   └── major/minor/micro.md     # 워크플로우 명령
│
├── config/                      # 설정 파일 (신규)
│   ├── model-router.yaml        # 모델 선택 규칙
│   └── user-preferences.yaml    # 사용자 전략 설정
│
├── agents/                      # Sub-agents (10개)
│   ├── architect.md             # 아키텍처 검증 (다중 지원)
│   ├── code-reviewer.md         # 코드 리뷰 (개선됨)
│   ├── security-scanner.md      # 보안 스캔 (신규)
│   ├── impact-analyzer.md       # 영향도 분석 (신규)
│   └── ...
│
└── skills/                      # Skills (13개)
    ├── reusability-enforcer/    # Context7 통합
    ├── test-coverage-analyzer/  # 커버리지 분석 (신규)
    ├── code-metrics-collector/  # 메트릭 수집 (신규)
    ├── dependency-tracer/       # 의존성 추적 (신규)
    └── ...

architectures/                    # 아키텍처 시스템 (신규)
├── registry.json                # 아키텍처 레지스트리
├── base/
│   └── ArchitectureAdapter.ts   # 어댑터 인터페이스
├── frontend/                    # Frontend 아키텍처
│   ├── fsd/config.json
│   ├── atomic/config.json
│   ├── mvc/config.json
│   └── micro-frontend/
├── backend/                     # Backend 아키텍처
│   ├── clean/config.json
│   ├── hexagonal/config.json
│   ├── ddd/config.json
│   ├── layered/config.json
│   └── serverless/
├── fullstack/                   # Fullstack 아키텍처
│   ├── monorepo/
│   ├── jamstack/
│   └── microservices/
└── tools/                       # 아키텍처 도구
    ├── detector.ts              # 자동 감지
    └── migrator.ts              # 마이그레이션

.specify/                        # Spec-Kit 구조
├── config/                      # 프로젝트 설정 (신규)
│   ├── architecture.json        # 선택된 아키텍처
│   └── architecture-rules.json  # 커스텀 규칙
├── memory/constitution.md       # 프로젝트 거버넌스
└── specs/                       # Feature별 저장소

workflow-gates-v2.json           # 아키텍처별 품질 게이트
```

## 🎯 핵심 원칙

1. **Specification-Driven Development**: spec.md를 실행 가능한 1차 아티팩트로 사용
2. **워크플로 분류**: 작업 규모에 따라 Major/Minor/Micro로 분류하여 과도한 프로세스 방지
3. **컨텍스트 격리**: Sub-agents를 통한 독립적 컨텍스트 윈도우로 토큰 효율성 극대화
4. **Constitution-Based Governance**: 프로젝트별 불변 원칙 정의 (9개 Article)
5. **점진적 공개**: 메인 문서는 500줄 이하로 유지, 세부사항은 참조 파일로 분리
6. **병렬 실행**: [P] 표시된 Task 동시 실행으로 응답 속도 개선
7. **Test-First**: 테스트 작성 후 구현 (TDD)

## 📚 추가 문서

### Specification 구조
- **spec.md**: WHAT/WHY만 포함 (HOW 제외), User Scenarios 중심
- **plan.md**: 기술적 구현 계획, Constitution Check, Phase 0+1
- **tasks.md**: 실행 가능한 Task breakdown, Test-First 순서

### Constitution (거버넌스)
- **Article I**: Library-First (외부 라이브러리 우선)
- **Article III**: Test-First (TDD 적용)
- **Article VII**: Simplicity (≤3 projects initially)
- **Article VIII**: Anti-Abstraction (과도한 추상화 금지)
- **Article IX**: Integration-First Testing

### Task Format
```
[T001] [P?] [Story?] Description /absolute/path/to/file
```
- `[P]`: 병렬화 가능
- `[Story]`: User Story ID (US1, US2...)

## 🔧 커스터마이징

### FSD 아키텍처를 사용하지 않는 프로젝트

`workflow-gates.json`에서 FSD 관련 게이트를 비활성화:

```json
{
  "workflows": {
    "minor": {
      "gates": {
        "during-implementation": {
          "fsd-architecture": {
            "enabled": false
          }
        }
      }
    }
  }
}
```

### Notion 연동을 사용하지 않는 프로젝트

`daily-changelog-notion` Skill을 제거하거나 비활성화:

```bash
rm -rf .claude/skills/daily-changelog-notion
```

### 프로젝트별 Quality Gates 조정

`workflow-gates.json`의 각 워크플로 설정을 수정:

```json
{
  "workflows": {
    "major": {
      "gates": {
        "post-implementation": {
          "all-tests-pass": {
            "enabled": true,
            "required": false  // 필수에서 선택으로 변경
          }
        }
      }
    }
  }
}
```

## 📊 성과 지표

### 토큰 효율성
- **Major**: 60% 절감 (Spec-Kit 풀 프로세스 대비)
- **Minor**: 75% 절감 (전체 컨텍스트 로드 대비)
- **Micro**: 85% 절감 (AI 최소 개입)

### 품질 레벨
- **Major**: Highest (모든 Gates 통과)
- **Minor**: High (핵심 Gates 통과)
- **Micro**: Standard (기본 검증만)

## 🤝 기여

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 라이선스

MIT License - 자유롭게 사용, 수정, 배포 가능합니다.

## 📖 상세 문서

- [Notion Workflow 문서](https://www.notion.so/2a21e422ebe480c59138f5ca33cbf007)
- Constitution Template: `.specify/memory/constitution.md`
- Spec Template: `.specify/templates/spec-template.md`
- Plan Template: `.specify/templates/plan-template.md`
- Tasks Template: `.specify/templates/tasks-template.md`
- Workflow Gates: `workflow-gates.json`
- Slash Commands: `.claude/commands/*.md`

## 🙋‍♂️ 지원

- Issues: https://github.com/Liamns/claude-workflows/issues
- Discussions: https://github.com/Liamns/claude-workflows/discussions
