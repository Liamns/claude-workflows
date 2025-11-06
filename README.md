# Claude Code Workflows

배차킹 프로젝트의 개발 효율성, 품질, 토큰 최적화를 위한 재사용 가능한 Claude Code 워크플로 시스템입니다.

## 🚀 빠른 시작

### 설치

```bash
# 프로젝트 디렉토리에서 실행
curl -fsSL https://raw.githubusercontent.com/Liamns/claude-workflows/main/install.sh | bash

# 또는 수동 설치
git clone https://github.com/Liamns/claude-workflows.git /tmp/claude-workflows
cp -r /tmp/claude-workflows/agents .claude/
cp -r /tmp/claude-workflows/skills .claude/
cp /tmp/claude-workflows/workflow-gates.json .claude/
rm -rf /tmp/claude-workflows
```

### 사용법

설치 후 Claude Code에서 워크플로 명령어를 사용할 수 있습니다:

#### 프로젝트 초기 설정
```bash
/start    # .specify/ 디렉토리 및 Constitution 생성
```

#### Major 워크플로 (신규 기능)
```bash
# 통합 워크플로 (권장)
/major user-authentication

# 또는 단계별 실행
/major-specify user-authentication  # 1. Specification 생성
/major-clarify 001                  # 2. 질문을 통한 명확화 (선택)
/major-plan 001                     # 3. Implementation Plan 수립
/major-tasks 001                    # 4. Task Breakdown 생성
/major-implement 001                # 5. 자동 구현 (선택)
```

#### Minor 워크플로 (기능 개선/버그 수정)
```bash
/minor 001                          # 기존 feature 업데이트
/minor fix-login-validation         # 새 작업
```

#### Micro 워크플로 (빠른 수정)
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
