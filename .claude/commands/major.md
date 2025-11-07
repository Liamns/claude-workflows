---
name: major
description: 신규 기능 개발을 위한 통합 워크플로우. 모든 단계를 자동으로 진행하며 상태 저장/재개 지원
---

# 🚀 Major - 통합 워크플로우 v2.0

신규 기능, API 엔드포인트, 아키텍처 변경 등 복잡한 작업을 체계적으로 진행합니다.
**개선**: 6개 명령어를 1개로 통합, 질문 10개→2개로 축소, 상태 자동 저장/재개

## 사용법

```bash
/major "기능 설명"

# 예시
/major "사용자 인증 시스템"
/major "결제 모듈 통합"
```

## 실행 순서

### 0단계: 사전 조건 확인

1. `.specify/` 디렉토리 존재 확인
   - 없으면 → `/start` 실행 안내
2. Constitution.md 존재 확인
   - 없으면 → `/start` 실행 안내
3. Git 저장소 확인
   - 없으면 → `git init` 실행 안내

### 1단계: Feature 브랜치 생성 및 초기화

**자동 실행**:
```bash
bash .specify/scripts/bash/create-new-feature.sh [feature-name]
```

**결과**:
- 브랜치: `001-feature-name` (자동 번호 부여)
- 디렉토리: `.specify/specs/001-feature-name/`
- 파일: `spec.md`, `plan.md`, `tasks.md` (템플릿에서 복사)

### 2단계: Specification (자동 생성)

**필수 질문 2개만** (기존 10개에서 대폭 축소)

#### 자동 상태 관리
```typescript
// .specify/state/current-major.json
{
  "featureName": "사용자 인증",
  "currentPhase": "spec",
  "progress": 25,
  "lastUpdated": "2024-11-07T14:00:00"
}
```

#### Phase 1: 핵심 질문만

**Q1: 기능 목표**
"이 기능의 핵심 목표는?"
- [ ] 새로운 기능 추가
- [ ] 기존 기능 확장
- [ ] 다른 도메인과의 통합
- [ ] 아키텍처 변경/리팩토링
- [ ] 기타: [입력]

**Q2: 사용자 시나리오**
"핵심 사용자 시나리오를 자연어로 설명해주세요:"
```
예시:
- 사용자가 로그인 페이지에서 이메일과 비밀번호를 입력한다
- 시스템이 인증 서버에 자격증명을 전송한다
- 성공 시 JWT 토큰을 받아 로컬에 저장하고 대시보드로 이동한다
- 실패 시 에러 메시지를 표시한다
```

**Q3: 비즈니스 목표**
"이 기능의 비즈니스 목표와 성공 기준은 무엇인가요?"
```
예시:
- 목표: 사용자가 안전하게 로그인할 수 있어야 함
- 성공 기준:
  - 로그인 성공률 95% 이상
  - 평균 응답 시간 2초 이하
  - 보안 표준(OWASP) 준수
```

#### Phase 2: 컨텍스트 수집

**Q4: 영향 범위**
"영향받는 파일/모듈을 알고 있나요? (알면 입력, 모르면 Enter)"
- 입력 예시: `src/features/auth/`, `src/shared/api/httpClient.ts`
- 비어있으면 → 자동 분석 진행

**Q5: 기존 코드 참조**
"참고할 기존 기능이나 패턴이 있나요? (있으면 입력, 없으면 Enter)"
- 입력 예시: "회원가입 기능과 유사한 구조"
- 비어있으면 → 건너뛰기

#### Phase 3: 기술적 범위

**Q6: API 통합**
"외부 API 또는 백엔드 엔드포인트 호출이 필요한가요?"
- Yes → "엔드포인트와 Request/Response 구조를 알고 있나요?"
  - 알고 있음 → 입력 받기
  - 모름 → "계약 설계 필요" 플래그 설정
- No → 건너뛰기

**Q7: 데이터 모델**
"새로운 Entity나 데이터 모델이 필요한가요?"
- Yes → "주요 Entity 이름을 나열해주세요"
  - 예시: User, Session, Token
- No → 건너뛰기

**Q8: 상태 관리**
"전역 상태 관리가 필요한가요?"
- Yes → "어떤 상태를 관리해야 하나요?"
  - 예시: 로그인 상태, 사용자 정보, 토큰
- No → 건너뛰기

#### Phase 4: 제약사항

**Q9: 기술 제약사항**
"특정 라이브러리나 패턴을 사용해야 하나요? (있으면 입력)"
- 예시: "React Query, Zustand, React Hook Form + Zod"
- 비어있으면 → Constitution 기준 자동 선택

**Q10: 마감일/우선순위**
"마감일이나 우선순위가 있나요?"
- 높음 (High Priority - [P1])
- 중간 (Medium Priority - [P2])
- 낮음 (Low Priority - [P3+])

#### Phase 5: AI 자동 추정

질문 응답을 기반으로 Claude가 다음을 자동 추정하고 보고합니다:

**자동 추정 항목**:
1. **예상 소요 시간**:
   - 2-3일 (Major)
   - 3-5일 (Major Complex)
   - 5+ 일 (Major Epic)

2. **파일 생성 수**:
   - 예상 신규 파일: 5-10개
   - 수정 파일: 2-5개

3. **테스트 필요 범위**:
   - 단위 테스트: N개
   - 통합 테스트: M개
   - E2E 테스트: 필요/불필요

4. **워크플로 확정**:
   ```
   📊 작업 규모 분석 결과:
   - 예상 소요시간: 3-4일
   - 신규 파일: ~8개
   - 수정 파일: ~3개
   - 테스트 범위: 단위(6) + 통합(2)
   - 권장 워크플로: Major ✅

   이대로 진행하시겠습니까? (y/N)
   ```

### 3단계: spec.md 생성

답변을 기반으로 `.specify/specs/NNN-feature-name/spec.md` 파일을 생성합니다.

**생성 구조**:
```markdown
# {Feature Name}

## Metadata
- Branch: {NNN-feature-name}
- Created: {YYYY-MM-DD}
- Status: Draft
- Priority: [P1/P2/P3+]
- Estimated Duration: {N일}

## Overview
{1-2 paragraph 비기술적 요약}

## User Scenarios & Testing

### [{Priority}] {Priority Label}

#### {Story ID}: {Story Name}
**Given:** {전제조건}
**When:** {사용자 행동}
**Then:** {기대 결과}

**Test Verification:**
- [ ] {검증 항목 1}
- [ ] {검증 항목 2}

## Functional Requirements
- FR-001: {요구사항 설명}
- FR-002: {요구사항 설명}

## Key Entities
### {Entity Name}
**Attributes:**
- {attribute}: {type} - {설명}

**Relationships:**
- {관계 설명}

**Validation Rules:**
- {검증 규칙}

## Success Criteria
{측정 가능한 성공 기준}

## Assumptions & Constraints
**Assumptions:**
- {가정 사항}

**Constraints:**
- {제약 사항}
- Library: {사용 라이브러리}
- Pattern: {적용 패턴}

## Open Questions
{해결되지 않은 질문들 - Clarify 단계에서 처리}
```

### 4단계: Clarification (최대 5개 질문)

spec.md를 분석하여 **모호하거나 불명확한 부분**을 식별하고 최대 5개의 고도로 타겟팅된 질문을 생성합니다.

**질문 우선순위**:
1. **Critical Path 불명확성**: 핵심 기능 흐름
2. **데이터 모델 모호성**: Entity 관계, 검증 규칙
3. **API 계약 불명확**: Request/Response 구조
4. **에러 처리 전략**: 실패 시나리오
5. **성능 요구사항**: 응답 시간, 제한사항

**질문 예시**:
```
Q1: 로그인 실패 시 재시도 횟수 제한이 있나요? (보안)
Q2: JWT 토큰의 만료 시간은 얼마나 되나요?
Q3: 비밀번호 찾기 기능도 이번에 포함하나요?
Q4: 소셜 로그인(Google, Kakao)도 지원하나요?
Q5: 로그인 세션은 어떻게 유지되나요? (localStorage, sessionStorage, httpOnly cookie?)
```

**답변 통합**:
- 답변을 spec.md의 해당 섹션에 통합
- Open Questions 섹션 업데이트

### 5단계: Plan 생성 (Phase 0 + Phase 1)

spec.md를 기반으로 `.specify/specs/NNN-feature-name/plan.md` 파일을 생성합니다.

#### Phase 0: Research

**생성 파일**: `research.md`

**내용**:
```markdown
# Research: {Feature Name}

## Existing Solutions Analysis
### Similar Implementations
{프로젝트 내 유사 기능 분석}

### Library Options
| Library | Pros | Cons | Decision |
|---------|------|------|----------|
| {lib1}  | ...  | ...  | ✅/❌    |

## Technical Feasibility
{기술적 실현 가능성 검토}

## Risks & Mitigation
| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| ...  | High   | Medium      | ...        |
```

#### Phase 1: Design Artifacts

**생성 파일**: `data-model.md`, `contracts/openapi.yaml`, `quickstart.md`

**data-model.md**:
```markdown
# Data Model: {Feature Name}

## Entities

### {Entity Name}
```typescript
interface {Entity} {
  id: string;
  // ... attributes
}
```

**Validation Schema (Zod):**
```typescript
const {Entity}Schema = z.object({
  id: z.string().uuid(),
  // ...
});
```

## State Management
```typescript
// Zustand Store
interface {Entity}Store {
  // ...
}
```

## API Types
```typescript
// Request/Response types
```
```

**contracts/openapi.yaml** (API 통합이 있는 경우):
```yaml
openapi: 3.0.0
info:
  title: {Feature Name} API
  version: 1.0.0
paths:
  /{endpoint}:
    post:
      summary: {설명}
      requestBody:
        # ...
      responses:
        200:
          # ...
```

**quickstart.md**:
```markdown
# Quickstart: {Feature Name}

## Prerequisites
- [ ] {전제조건 1}
- [ ] {전제조건 2}

## Setup Steps
1. {단계 1}
2. {단계 2}

## Verification
{동작 확인 방법}
```

#### plan.md 메인 파일

```markdown
# Implementation Plan: {Feature Name}

## Technical Foundation

### Language/Version
{구체적 값 또는 NEEDS CLARIFICATION}

### Primary Dependencies
- {라이브러리1}: {버전}
- {라이브러리2}: {버전}

### Storage
{데이터 저장 방식}

### Testing Framework
{테스트 프레임워크}

## Constitution Check

| Article | Status | Violations | Justification | Alternatives Rejected |
|---------|--------|------------|---------------|---------------------|
| I: Library-First | ✅ | None | Using React Query, Zustand | - |
| III: Test-First | ✅ | None | TDD with Vitest | - |
| VIII: Anti-Abstraction | ⚠️ | Custom hook abstraction | Reduces code duplication by 60% | Inline logic (too verbose) |

## Phase 0: Research
[Link to research.md](./research.md)

**Key Findings:**
- {주요 발견 사항}

## Phase 1: Design Artifacts
- [Data Model](./data-model.md)
- [API Contracts](./contracts/openapi.yaml)
- [Quickstart Guide](./quickstart.md)

## Source Code Structure
{프로젝트 구조}

## Implementation Phases
{실제 구현은 tasks.md에서 관리}
```

### 6단계: Tasks 생성

plan.md를 기반으로 실행 가능한 task breakdown을 생성합니다.

**tasks.md 구조**:
```markdown
# Tasks: {Feature Name}

## Task Format
- [ ] [T001] [P?] [Story?] Description /absolute/path/to/file
  - [P]: Parallelizable
  - [Story]: User Story ID (e.g., US1)

## Phase 1: Setup & Prerequisites
- [ ] [T001] [P] Initialize directory structure /src/features/{feature-name}
- [ ] [T002] [P] Install dependencies (yarn add {packages})
- [ ] [T003] Create shared types /src/features/{feature-name}/model/types.ts

## Phase 2: Foundation (Infrastructure BEFORE any user story)
- [ ] [T004] [P] Setup API client /src/features/{feature-name}/api/client.ts
- [ ] [T005] [P] Create Zustand store /src/app/model/stores/{feature}Store.ts
- [ ] [T006] [P] Add validation schemas /src/features/{feature-name}/model/schemas.ts

## Phase 3: User Story - [US1] {Story Name}

**Goal:** {독립적 완료/테스트 가능}
**Test Verification:** {검증 방법}

### Tests (Write FIRST - TDD)
- [ ] [T007] [US1] Contract tests /src/features/{feature-name}/api/__tests__/contract.test.ts
- [ ] [T008] [US1] Unit tests for validation /src/features/{feature-name}/model/__tests__/validation.test.ts
- [ ] [T009] [US1] Integration tests /src/features/{feature-name}/__tests__/integration.test.tsx

### Implementation (AFTER tests)
- [ ] [T010] [P] [US1] Create UI components /src/features/{feature-name}/ui/{Component}.tsx
- [ ] [T011] [US1] Implement business logic hook /src/features/{feature-name}/model/use{Feature}.ts
- [ ] [T012] [US1] Connect API integration /src/features/{feature-name}/api/{endpoint}.ts

## Phase 4: User Story - [US2] {Story Name}
...

## Phase N: Polish & Documentation
- [ ] [T050] [P] Add JSDoc comments to public APIs
- [ ] [T051] [P] Update README.md
- [ ] [T052] Run full test suite (yarn test)
- [ ] [T053] Type check (yarn type-check)
- [ ] [T054] Build verification (yarn build:dev)
```

### 7단계: 완료 보고 및 다음 단계

사용자에게 생성된 파일들을 보고하고 다음 옵션을 제시합니다:

```
✅ Major 워크플로 완료!

📁 생성된 파일:
.specify/specs/{NNN-feature-name}/
├── spec.md                  ✅ (Specification)
├── plan.md                  ✅ (Implementation Plan)
├── tasks.md                 ✅ (Executable Tasks)
├── research.md              ✅ (Phase 0 Research)
├── data-model.md            ✅ (Phase 1 Design)
├── quickstart.md            ✅ (Phase 1 Setup)
├── contracts/
│   └── openapi.yaml         ✅ (API Contracts)
└── checklists/
    └── requirements.md      ✅ (Quality Checklist)

📋 다음 단계:

1. **즉시 구현 시작** (권장):
   /major-implement

2. **수동 검토 후 구현**:
   - spec.md 검토 및 수정
   - plan.md 검토 및 수정
   - tasks.md 검토 및 수정
   - 준비되면: /major-implement

3. **단계별 실행**:
   - /major-implement --task T001
   - /major-implement --task T002
   - ...

💡 Tip:
- Constitution 위반이 있으면 justification을 꼭 확인하세요
- Test-First를 따르기 위해 tasks.md의 순서를 엄격히 지켜주세요
```

## Quality Gates (workflow-gates.json 기준)

### Pre-Implementation
- ✅ spec.md 품질 검증
- ✅ 테스트 계획 수립 (tasks.md에 포함)
- ✅ API 계약 정의 (필요 시)

### During-Implementation
- ✅ FSD 아키텍처 준수 (fsd-architect agent)
- ✅ Test-First 개발 (test-guardian agent)
- ✅ 타입 안전성 (yarn type-check)

### Post-Implementation
- ✅ 자동 코드 리뷰 (code-reviewer agent)
- ✅ 전체 테스트 통과 (yarn test)
- ✅ 빌드 성공 (yarn build:dev)

## 에러 처리

- `.specify/` 없음 → `/start` 실행 안내
- Constitution 없음 → `/start` 실행 안내
- Feature name 중복 → 기존 spec 덮어쓰기 여부 확인
- Git 브랜치 생성 실패 → 수동 브랜치 생성 안내
