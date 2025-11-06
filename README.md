# 🤖 Claude Workflows

[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](https://github.com/Liamns/claude-workflows)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Compatible-purple.svg)](https://claude.ai/code)

> Smart workflows for Claude Code - Auto-triage, smart commits, and PR reviews

Claude Code를 통한 개발 효율성 극대화를 위한 스마트 워크플로우 시스템

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

## ✨ 새로운 기능 (v2.0.0)

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
/start    # .specify/ 디렉토리 및 Constitution 생성
```

### Major 워크플로 (신규 기능)
```bash
# 자동 선택 (권장)
/triage "사용자 인증 기능 추가"

# 또는 직접 실행
/major user-authentication
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

## 🤖 Sub-agents (7개)

1. **quick-fixer**: 빠른 버그 수정 및 코드 개선
2. **changelog-writer**: Git diff 분석 및 변경사항 문서화
3. **fsd-architect**: FSD 아키텍처 규칙 검증 및 가이드
4. **test-guardian**: TDD 적용 및 테스트 품질 관리
5. **api-designer**: API 계약 설계 및 통합 구현
6. **mobile-specialist**: Capacitor 플랫폼 분기 및 네이티브 API 통합
7. **code-reviewer**: 보안, 성능, 베스트 프랙티스 검증

## 🛠️ Skills (7개)

1. **bug-fix-pattern**: 일관된 버그 수정 프로세스
2. **daily-changelog-notion**: Git 변경사항을 Notion 형식으로 자동 정리
3. **fsd-component-creation**: FSD 규칙 준수 컴포넌트 자동 생성
4. **api-integration**: httpClient 기반 API 통합 자동화
5. **form-validation**: React Hook Form + Zod 검증 패턴
6. **platform-detection**: Capacitor 플랫폼 분기 자동화
7. **mobile-build**: Android/iOS 빌드 프로세스 자동화

## 📁 구조

```
.claude/
├── commands/                    # Slash Commands
│   ├── start.md                 # 프로젝트 초기화
│   ├── major.md                 # 통합 Major 워크플로
│   ├── major-specify.md         # Step 1: Specification
│   ├── major-clarify.md         # Step 2: Clarification
│   ├── major-plan.md            # Step 3: Plan
│   ├── major-tasks.md           # Step 4: Tasks
│   ├── major-implement.md       # Step 5: Implementation
│   ├── minor.md                 # Minor 워크플로
│   └── micro.md                 # Micro 워크플로
│
├── templates/                   # 문서 템플릿
│   ├── spec-template.md
│   ├── plan-template.md
│   └── tasks-template.md
│
├── agents/                      # Sub-agents (7개)
│   ├── quick-fixer.md
│   ├── changelog-writer.md
│   ├── fsd-architect.md
│   ├── test-guardian.md
│   ├── api-designer.md
│   ├── mobile-specialist.md
│   └── code-reviewer.md
│
└── skills/                      # Skills (7개)
    ├── bug-fix-pattern/
    ├── daily-changelog-notion/
    ├── fsd-component-creation/
    ├── api-integration/
    ├── form-validation/
    ├── platform-detection/
    └── mobile-build/

.specify/                        # Spec-Kit 구조
├── memory/
│   └── constitution.md          # 프로젝트 거버넌스
├── templates/
│   ├── spec-template.md
│   ├── plan-template.md
│   └── tasks-template.md
├── scripts/bash/
│   ├── common.sh
│   ├── create-new-feature.sh
│   └── check-prerequisites.sh
├── steering/                    # 선택사항
│   ├── product.md
│   ├── tech.md
│   └── structure.md
└── specs/                       # Feature별 저장소
    └── 001-feature-name/
        ├── spec.md
        ├── plan.md
        ├── tasks.md
        ├── research.md
        ├── data-model.md
        ├── contracts/
        └── checklists/

workflow-gates.json              # Quality Gates 설정
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
