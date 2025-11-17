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

## 생성되는 문서

이 워크플로우는 Feature의 복잡도에 따라 **4-6개 문서**를 생성합니다:

### 필수 문서 (항상 생성)
- **spec.md**: 요구사항 정의
- **plan.md**: 통합 계획
- **tasks.md**: 실행 작업 (Prerequisites와 Setup Steps 포함)

### 조건부 문서
- **research.md**: complexity > 5일 때만 생성 (라이브러리 비교, 리스크 분석)
- **data-model.md**: entities.length > 0일 때만 생성 (TypeScript 인터페이스, Zod 스키마)
- **contracts/openapi.yaml**: API 통합 시 생성

### 제거된 문서
- ~~**quickstart.md**~~: tasks.md의 Phase 1로 통합됨

**토큰 절감 효과**:
- 간단한 Feature (complexity ≤ 5): 40% 절감 (3개 문서)
- 복잡한 Feature (complexity > 5): 20% 절감 (5-6개 문서)

## 사용 예시

### 예시 1: 간단한 Feature (3개 문서 생성)

```bash
/major "UI 텍스트 수정"
```

**생성된 문서:**
- ✅ spec.md - 요구사항 정의
- ✅ plan.md - 구현 계획
- ✅ tasks.md - 실행 작업 목록

**생략된 문서:**
- ⏭️ research.md (complexity=3 ≤ 5)
- ⏭️ data-model.md (entities=[])
- ⏭️ contracts/ (API 통합 없음)

**결과:**
- 💡 토큰 절감: 56% (7.0K → 3.1K)
- 📁 파일 수: 3개
- ⏱️ 생성 시간: ~2분

### 예시 2: 복잡한 Feature (6개 문서 생성)

```bash
/major "사용자 인증 시스템"
```

**생성된 문서:**
- ✅ spec.md - 요구사항 정의 (5.5K)
- ✅ research.md - 기술 조사 및 리스크 분석 (7.3K) ← complexity=7 > 5
- ✅ data-model.md - Entity 및 Zod 스키마 (8.3K) ← entities=3 > 0
- ✅ contracts/openapi.yaml - API 명세 (7.3K) ← API 통합
- ✅ plan.md - 통합 구현 계획 (9.9K)
- ✅ tasks.md - 45개 실행 작업 (11K)

**생략된 문서:**
- ⏭️ quickstart.md (tasks.md로 통합)

**결과:**
- 💡 토큰 절감: 17.6% (59.8K → 49.3K)
- 📁 파일 수: 6개
- ⏱️ 생성 시간: ~5분
- 📋 작업 개수: 45개 (7개 Phase로 구성)

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

#### Phase 6: 재사용성 검사 (자동 실행)

**실행 시점**: spec.md 작성 직전 (사용자 질문 완료 후)

**자동 실행**:
```bash
# 프로젝트 아키텍처 감지 및 재사용성 검사
bash .claude/lib/reusability/reusability-checker.sh -e all -t all "<작업명 키워드>"
```

**검색 결과 분석 및 적용**:
```markdown
🔍 Reusability Analysis Result:

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📱 Frontend (React)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ REUSE (95%): Button 컴포넌트
   → src/shared/ui/Button/Button.tsx
   → 그대로 import하여 사용

🔧 EXTEND (75%): useFormatDate 훅
   → src/shared/lib/dates/useFormatDate.ts
   → formatKoreanDate 추가 필요

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚙️  Backend (NestJS)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ REUSE (90%): AuthService 패턴
   → backend/src/auth/auth.service.ts
   → PrismaService injection 동일 패턴 사용

🆕 CREATE: OrderService
   → AuthService 패턴 참고하여 신규 작성

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 적용 계획:
1. Button, Input 컴포넌트는 기존 것 사용
2. useFormatDate 확장하여 formatKoreanDate 추가
3. OrderService는 AuthService 구조 참고하여 작성
4. Prisma 모델은 기존 패턴(id, createdAt, updatedAt) 따름
```

**재사용성 점수 기준**:
- **90-100% 유사**: ✅ REUSE - 기존 모듈 그대로 import하여 사용
- **70-89% 유사**: 🔧 EXTEND - 기존 모듈 확장하거나 wrapper 생성
- **50-69% 유사**: 📝 ADAPT - 패턴을 참고하여 작성
- **0-49% 유사**: 🆕 CREATE - 새로운 모듈 작성 (유사한 모듈 없음)

### 3단계: spec.md 생성

**🔴 매우 중요**: 다음 문서는 **반드시 한글로 작성**하세요. Overview, User Scenarios, Functional Requirements 등 모든 설명은 한글로 작성하되, 코드 예시, 파일 경로, 기술 용어는 영어를 유지하세요.

**📝 재사용성 검사 결과 반영**: spec.md 작성 시 위에서 발견한 재사용 가능 모듈 정보를 포함하세요.

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

## Reusability Analysis

**검색 대상**: {작업명 키워드}

**발견된 재사용 가능 모듈**:

### Frontend (React)
- ✅ **REUSE (95%)**: Button 컴포넌트
  - 경로: `src/shared/ui/Button/Button.tsx`
  - 사용방법: 그대로 import하여 사용
  - 예시: `<Button variant="primary" onClick={handleSubmit}>제출</Button>`

- 🔧 **EXTEND (75%)**: useFormatDate 훅
  - 경로: `src/shared/lib/dates/useFormatDate.ts`
  - 확장 필요: formatKoreanDate 함수 추가
  - 계획: 기존 훅에 새 포맷 옵션 추가

### Backend (NestJS)
- ✅ **REUSE (90%)**: AuthService 패턴
  - 경로: `backend/src/auth/auth.service.ts`
  - 참고사항: PrismaService injection 동일 패턴 사용

- 🆕 **CREATE**: OrderService
  - 참고 패턴: AuthService 구조 참고하여 작성
  - 이유: 기존 유사 서비스 없음 (유사도 <50%)

### 적용 계획
1. Button, Input 등 UI 컴포넌트는 shared/ui에서 재사용
2. 날짜 포맷 함수는 기존 유틸리티 확장
3. OrderService는 신규 작성하되 AuthService 구조 참고
4. Prisma 모델은 기존 패턴(id, createdAt, updatedAt) 준수

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

**🔴 매우 중요**: 다음 문서는 **반드시 한글로 작성**하세요. Existing Solutions Analysis, Technical Feasibility, Risks & Mitigation 등 모든 설명은 한글로 작성하되, 코드 예시, 라이브러리 이름, 파일 경로는 영어를 유지하세요.

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

**🔴 매우 중요**: 다음 문서들은 **반드시 한글로 작성**하세요. Entities, State Management, Setup Steps, Verification 등 모든 설명은 한글로 작성하되, 코드 예시, 타입 정의, 파일 경로, API 스펙은 영어를 유지하세요.

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

**🔴 매우 중요**: plan.md는 **반드시 한글로 작성**하세요. Technical Foundation, Constitution Check, Implementation Phases 등 모든 설명은 한글로 작성하되, 코드 예시, 라이브러리 이름, 파일 경로는 영어를 유지하세요.

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

**🔴 매우 중요**: tasks.md는 **반드시 한글로 작성**하세요. Task 설명, Phase 제목 등 모든 설명은 한글로 작성하되, 코드 예시, 파일 경로, 명령어는 영어를 유지하세요.

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

---

## 🔧 Implementation

이제 위의 프로세스를 실제로 실행하세요.

---

**🚨 중요: 반드시 읽고 따르세요 🚨**

이 섹션은 **실행 명령어**입니다. 다음 규칙을 **반드시** 준수하세요:

1. **Step 0-14를 순차적으로 실행**하세요. 단 하나의 Step도 건너뛸 수 없습니다.
2. **각 Step 완료 시 명시적으로 보고**하세요: "✅ Step X 완료"
3. **AskUserQuestion 도구를 반드시 사용**하세요 (Step 2, 3, 4, 7, 13.5)
4. **Write 도구로 파일을 반드시 생성**하세요:
   - spec.md (Step 6, 필수)
   - research.md (Step 8, complexity > 5일 때만)
   - data-model.md (Step 9, entities.length > 0일 때만)
   - contracts/openapi.yaml (Step 10, API 있을 때만)
   - plan.md (Step 12, 필수)
   - tasks.md (Step 13, 필수)
5. **각 문서는 이전에 생성된 문서를 참조**해야 합니다:
   - Read 도구로 이전 문서를 읽어서 내용 추출
   - 변수만 사용하지 말고 실제 파일 내용을 참조
6. **문서 미리보기 및 동의 요청 필수** (Step 13.5)
   - 배치 미리보기 생성
   - 각 문서별 미리보기 표시
   - Production 모드: 동의 요청 (AskUserQuestion)
   - Development 모드: 자동 승인 (미리보기만 표시)
7. **파일 생성 후 검증**하세요: 파일이 실제로 생성되었는지 확인

**이 규칙을 위반하면 워크플로우가 실패합니다.**

---

### Step 0: 사전 조건 확인

**Bash 도구로 디렉토리 확인**:
```
Bash:
- command: "test -d .specify && echo 'EXISTS' || echo 'MISSING'"
- description: "Check .specify directory"
```

**MISSING 인 경우**:
```markdown
⚠️ .specify 디렉토리가 없습니다.

먼저 프로젝트를 초기화하세요:
/start
```

워크플로우를 중단하고 사용자에게 /start 실행을 요청하세요.

**EXISTS 인 경우**: 다음 단계 계속 진행

✅ **Step 0 완료** - 사전 조건 확인 완료

### Step 1: Feature 브랜치 및 디렉토리 생성

사용자가 제공한 feature name을 `{featureName}` 변수에 저장하세요.

**Bash 도구로 다음 번호 찾기**:
```
Bash:
- command: "ls -d .specify/specs/*/ 2>/dev/null | sed 's/.*\\/\\([0-9]\\{3\\}\\)-.*/\\1/' | sort -n | tail -1"
- description: "Get latest feature number"
```

결과를 기반으로 다음 번호 계산: `{nextNumber} = result + 1` (또는 001 if empty)

**Bash 도구로 디렉토리 생성**:
```
Bash:
- command: "mkdir -p .specify/specs/{nextNumber}-{featureName} && mkdir -p .specify/specs/{nextNumber}-{featureName}/contracts"
- description: "Create feature directory"
```

**Bash 도구로 조건부 브랜치 생성 (Epic 감지)**:
```
Bash:
- command: "if [ ! -f ../../epic.md ]; then git checkout -b {nextNumber}-{featureName} 2>/dev/null || true; else echo 'Epic 내부: 브랜치 $(git branch --show-current) 유지'; fi"
- description: "Conditionally create branch (skip if inside Epic)"
```

생성된 디렉토리를 `{featureDir}` 변수에 저장: `.specify/specs/{nextNumber}-{featureName}`

✅ **Step 1 완료** - Feature 브랜치 및 디렉토리 생성 완료

### Step 2: 핵심 질문 (필수)

**🔴 필수**: 이 단계에서는 **반드시 AskUserQuestion 도구를 사용**해야 합니다.

**AskUserQuestion 도구 사용 - Block 1 (필수 질문)**:
```
질문 1: "이 기능의 핵심 목표는 무엇인가요?"
헤더: "기능 목표"
multiSelect: false
옵션:
  1. label: "새로운 기능 추가"
     description: "완전히 새로운 기능을 추가합니다"
  2. label: "기존 기능 확장"
     description: "기존 기능에 새로운 기능을 추가합니다"
  3. label: "다른 도메인과의 통합"
     description: "외부 API 또는 다른 모듈과 통합합니다"
  4. label: "아키텍처 변경/리팩토링"
     description: "코드 구조를 개선하거나 변경합니다"

질문 2: "핵심 사용자 시나리오를 자연어로 설명해주세요"
헤더: "사용자 시나리오"
multiSelect: false
옵션:
  1. label: "직접 입력하겠습니다"
     description: "Given-When-Then 형식으로 설명"
  2. label: "예시 참고: 로그인 기능"
     description: "사용자가 이메일/비밀번호 입력 → 인증 → 성공 시 대시보드 이동"
  3. label: "예시 참고: 결제 기능"
     description: "사용자가 상품 선택 → 결제 정보 입력 → 결제 완료 → 주문 확인"

질문 3: "비즈니스 목표와 성공 기준은 무엇인가요?"
헤더: "성공 기준"
multiSelect: false
옵션:
  1. label: "직접 입력하겠습니다"
     description: "측정 가능한 성공 기준을 입력"
  2. label: "표준 성능 기준 적용"
     description: "응답 시간 2초 이하, 성공률 95% 이상"
  3. label: "나중에 정의"
     description: "지금은 건너뛰고 나중에 clarify 단계에서 정의"
```

답변을 `{goal}`, `{userScenarios}`, `{businessObjectives}` 변수에 저장하세요.

**검증**: 다음 변수가 모두 채워졌는지 확인하세요:
- `{goal}` - 비어있으면 안됨
- `{userScenarios}` - 비어있으면 안됨
- `{businessObjectives}` - 비어있으면 안됨

✅ **Step 2 완료** - 핵심 질문 완료 및 답변 수집

### Step 3: 선택적 컨텍스트 수집

**AskUserQuestion 도구 사용 - Block 2 (선택적 질문 통합)**:
```
질문: "추가 컨텍스트를 제공하시겠습니까?"
헤더: "추가 정보"
multiSelect: true  ← 여러 항목 선택 가능
옵션:
  1. label: "영향받는 파일/모듈을 알고 있음"
     description: "수정이 필요한 파일 경로를 알고 있습니다"
  2. label: "참고할 기존 패턴이 있음"
     description: "유사한 기존 기능이나 패턴을 참고할 수 있습니다"
  3. label: "API 통합이 필요함"
     description: "외부 API 또는 백엔드 엔드포인트 호출이 필요합니다"
  4. label: "새 데이터 모델이 필요함"
     description: "새로운 Entity나 타입 정의가 필요합니다"
  5. label: "전역 상태 관리가 필요함"
     description: "Zustand/Redux 등 전역 상태 관리가 필요합니다"
  6. label: "특정 기술 스택 사용"
     description: "특정 라이브러리나 패턴을 사용해야 합니다"
```

선택된 항목에 따라 추가 질문:

**Option 1 선택 시**: "영향받는 파일 경로를 입력하세요" (텍스트 입력)
**Option 2 선택 시**: "참고할 기존 기능을 설명하세요" (텍스트 입력)
**Option 3 선택 시**: "API 엔드포인트와 Request/Response 구조를 알고 있나요?" (Y/N)
**Option 4 선택 시**: "주요 Entity 이름을 나열하세요" (예: User, Session, Token)
**Option 5 선택 시**: "어떤 상태를 관리해야 하나요?" (텍스트 입력)
**Option 6 선택 시**: "사용할 라이브러리를 나열하세요" (예: React Query, Zod)

답변을 `{affectedFiles}`, `{existingPatterns}`, `{apiDetails}`, `{entities}`, `{stateManagement}`, `{techStack}` 변수에 저장하세요.

### Step 4: 우선순위 설정

**AskUserQuestion 도구 사용**:
```
질문: "마감일이나 우선순위가 있나요?"
헤더: "우선순위"
multiSelect: false
옵션:
  1. label: "높음 (High Priority - P1)"
     description: "긴급하게 필요한 기능입니다"
  2. label: "중간 (Medium Priority - P2)"
     description: "일반적인 우선순위입니다"
  3. label: "낮음 (Low Priority - P3+)"
     description: "여유가 있을 때 진행합니다"
```

답변을 `{priority}` 변수에 저장하세요.

### Step 5: AI 자동 추정

수집된 정보를 바탕으로 다음을 추정하세요:

```typescript
function estimateComplexity(context) {
  let complexity = 0;

  // API 통합 +2
  if (context.apiDetails) complexity += 2;

  // 새 데이터 모델 +2
  if (context.entities && context.entities.length > 0) complexity += 2;

  // 전역 상태 관리 +1
  if (context.stateManagement) complexity += 1;

  // 영향받는 파일 수
  if (context.affectedFiles && context.affectedFiles.length > 5) complexity += 2;

  // 예상 소요 시간
  let estimatedDays;
  if (complexity <= 3) estimatedDays = "2-3일";
  else if (complexity <= 6) estimatedDays = "3-5일";
  else estimatedDays = "5+ 일";

  return {
    estimatedDays,
    newFiles: Math.max(5, complexity * 2),
    modifiedFiles: Math.max(2, Math.floor(complexity / 2)),
    unitTests: Math.max(4, complexity * 1.5),
    integrationTests: Math.max(1, Math.floor(complexity / 2))
  };
}
```

추정 결과를 사용자에게 보고:
```markdown
📊 작업 규모 분석 결과:
- 예상 소요시간: {estimatedDays}
- 신규 파일: ~{newFiles}개
- 수정 파일: ~{modifiedFiles}개
- 테스트 범위: 단위({unitTests}) + 통합({integrationTests})
- 권장 워크플로: Major ✅
```

### Step 6: spec.md 생성

**Write 도구로 spec.md 생성**:
```
Write:
- file_path: "{featureDir}/spec.md"
- content: """
# {featureName}

## Metadata
- Branch: {nextNumber}-{featureName}
- Created: {오늘 날짜 YYYY-MM-DD}
- Status: Draft
- Priority: {priority}
- Estimated Duration: {estimatedDays}

## Overview
{goal와 userScenarios를 바탕으로 1-2 paragraph 비기술적 요약 작성}

## User Scenarios & Testing

### [P1] Core Functionality

#### US1: {첫 번째 시나리오 이름}
**Given:** {전제조건 - userScenarios에서 추출}
**When:** {사용자 행동}
**Then:** {기대 결과}

**Test Verification:**
- [ ] {검증 항목 1}
- [ ] {검증 항목 2}

## Functional Requirements
{goal와 userScenarios를 바탕으로 기능 요구사항 생성}
- FR-001: {요구사항 설명}
- FR-002: {요구사항 설명}

## Key Entities
{entities 변수가 있으면 여기에 나열, 없으면 "TBD - Will be defined in clarify phase"}

### {Entity Name}
**Attributes:**
- id: string - Unique identifier
{entities에서 추출한 속성들}

**Relationships:**
{Entity 간 관계 설명}

**Validation Rules:**
{검증 규칙}

## Success Criteria
{businessObjectives 내용}

## Assumptions & Constraints

**Assumptions:**
{추정한 가정 사항들}

**Constraints:**
{techStack이 있으면 여기에 나열}
- Library: {techStack}
- Pattern: {existingPatterns}

## Open Questions
{불명확한 부분들을 나열 - Clarify 단계에서 처리 예정}
{apiDetails가 불완전하면 여기에 추가}
{entities가 없으면 여기에 추가}
"""
```

**파일 생성 검증**:
```
Read:
- file_path: "{featureDir}/spec.md"
- limit: 10
```

파일이 정상적으로 생성되었는지 확인하세요. 생성되지 않았다면 다시 Write 도구를 사용하세요.

✅ **Step 6 완료** - spec.md 생성 완료

### Step 7: Clarification (최대 5개 질문)

spec.md를 분석하여 Open Questions가 있는지 확인:

**Open Questions가 있는 경우**:

**AskUserQuestion 도구 사용**:
```
질문: "다음 불명확한 사항을 명확히 해주세요"
헤더: "Clarification"
multiSelect: false
옵션:
  1. label: "{Question 1}"
     description: "Critical Path 관련"
  2. label: "{Question 2}"
     description: "데이터 모델 관련"
  3. label: "{Question 3}"
     description: "API 계약 관련"
  4. label: "모두 나중에 정의"
     description: "지금은 건너뛰고 구현 중에 정의"
```

답변을 받아서 spec.md를 업데이트:

**Edit 도구로 spec.md 업데이트**:
```
Edit:
- file_path: "{featureDir}/spec.md"
- old_string: "## Open Questions\n{기존 내용}"
- new_string: "## Open Questions\n{업데이트된 내용 - 답변 반영}"
```

### Step 8: research.md 생성 (조건부)

**조건 확인**:
IF complexity > 5:
  - research.md 생성 진행
ELSE:
  - research.md 생략
  - "⏭️  research.md 생략 (complexity={complexity} ≤ 5). plan.md에서 리서치 내용을 직접 작성합니다." 출력
  - Step 9로 이동

**🔴 중요**: 먼저 spec.md를 읽어서 내용을 참조하세요.

**Read 도구로 spec.md의 Functional Requirements 섹션 읽기**:
```
Read:
- file_path: "{featureDir}/spec.md"
- offset: 60  # Functional Requirements 섹션 시작 예상 위치
- limit: 50   # FR-001 ~ FR-009 전체를 읽을 수 있는 범위
```

**참조 패턴 적용**:
1. spec.md의 Functional Requirements 섹션에서 FR-001 ~ FR-009의 **정확한 번호와 설명**을 추출
2. 요약하지 말고 **원문 그대로 복사** (Entity 이름, User Story ID 정확히 일치시켜야 함)
3. Key Entities, Success Criteria도 동일하게 추출

이 정보를 `{specFunctionalRequirements}`, `{specKeyEntities}`, `{specSuccessCriteria}` 변수에 저장하세요.

**중복 제거 원칙**:
- Requirements Summary는 spec.md FR을 **정확히 복사** (번호, 설명 일치율 100%)
- Library Options, Risks는 research.md에만 작성 (spec.md에 없는 새로운 내용)

**Write 도구로 research.md 생성**:
```
Write:
- file_path: "{featureDir}/research.md"
- content: """
# Research: {featureName}

> 이 문서는 spec.md의 요구사항을 기반으로 작성되었습니다.
> 참조: [spec.md](./spec.md)

## Requirements Summary (from spec.md)

### Functional Requirements
{spec.md에서 추출한 FR-001 ~ FR-009를 **원문 그대로 복사**}
- FR-001: {정확한 설명}
- FR-002: {정확한 설명}
- ...

### Key Entities
{spec.md의 Key Entities를 그대로 복사 - Entity 이름 100% 일치 필수}

## Existing Solutions Analysis

### Similar Implementations
{existingPatterns이 있으면 분석, 없으면:}
{specKeyEntities와 specFunctionalRequirements를 기반으로 프로젝트 내에서 Grep으로 유사 패턴 검색}

Grep:
- pattern: "{specKeyEntities 또는 specFunctionalRequirements에서 추출한 키워드}"
- output_mode: "files_with_matches"
- head_limit: 5

{검색 결과 분석 후 유사 구현 설명}

### Library Options
{techStack이 명시되었으면 해당 라이브러리 분석}
{없으면 Constitution에서 권장하는 라이브러리 사용}

| Library | Pros | Cons | Decision |
|---------|------|------|----------|
| React Query | Caching, 자동 재시도 | 학습 곡선 | ✅ |
| Zod | TypeScript 통합 | - | ✅ |

## Technical Feasibility
{추정된 complexity 기반으로 실현 가능성 평가}

## Risks & Mitigation
| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| API 응답 지연 | High | Medium | Timeout 설정, 로딩 상태 표시 |
{complexity가 높으면 추가 리스크 식별}
"""
```

**파일 생성 검증**:
```
Read:
- file_path: "{featureDir}/research.md"
- limit: 10
```

파일이 정상적으로 생성되었는지 확인하세요. 생성되지 않았다면 다시 Write 도구를 사용하세요.

✅ **Step 8 완료** - research.md 생성 완료 (spec.md를 참조하여 작성함)

### Step 9: data-model.md 생성 (조건부)

**조건 확인**:
IF entities.length > 0:
  - data-model.md 생성 진행
ELSE:
  - data-model.md 생략
  - "⏭️  data-model.md 생략 (entities=[])입니다." 출력
  - Step 10으로 이동

**Read 도구로 spec.md의 Key Entities 섹션 읽기**:
```
Read:
- file_path: "{featureDir}/spec.md"
- offset: 40  # Key Entities 섹션 시작 예상 위치
- limit: 30   # 모든 Entity 정의를 읽을 수 있는 범위
```

**참조 패턴 적용**:
1. spec.md의 Key Entities에서 **Entity 이름을 100% 정확히** 추출
   - 예: spec.md에 "Task"라고 정의되어 있으면 → interface Task (대소문자 정확히 일치)
2. 각 Entity의 **속성을 모두 포함** (누락 금지)
3. **추가 속성 최소화** - id, createdAt, updatedAt만 추가 (필수적인 경우에만 다른 속성 추가)
4. 명시적 참조 추가: "> 이 문서는 [spec.md](./spec.md)의 Key Entities를 기반으로 작성되었습니다."

**중복 제거 원칙**:
- TypeScript 인터페이스, Zod 스키마는 data-model.md에만 작성
- spec.md의 Entity 정의는 간단한 설명만 포함 (타입 정의 없음)

**Write 도구로 data-model.md 생성**:
```
Write:
- file_path: "{featureDir}/data-model.md"
- content: """
# Data Model: {featureName}

> 이 문서는 [spec.md](./spec.md)의 Key Entities를 기반으로 작성되었습니다.

## Entities

{entities 변수의 각 entity에 대해:}

### {Entity Name}
```typescript
interface {Entity} {
  id: string;
  {spec.md의 Key Entities에서 추출한 attributes}
  createdAt: Date;
  updatedAt: Date;
}
```

**Validation Schema (Zod):**
```typescript
import { z } from 'zod';

const {Entity}Schema = z.object({
  id: z.string().uuid(),
  {attributes에 대한 Zod 스키마}
  createdAt: z.date(),
  updatedAt: z.date(),
});

export type {Entity} = z.infer<typeof {Entity}Schema>;
```

## State Management

{stateManagement이 있으면:}

```typescript
// Zustand Store
import { create } from 'zustand';

interface {Entity}Store {
  {stateManagement에서 명시한 상태들}
  // Actions
  set{Entity}: (entity: {Entity}) => void;
  clear: () => void;
}

export const use{Entity}Store = create<{Entity}Store>((set) => ({
  {초기 상태}
  set{Entity}: (entity) => set({ ...entity }),
  clear: () => set({ {초기 상태} }),
}));
```

## API Types

{apiDetails가 있으면:}

```typescript
// Request Types
export interface {Feature}Request {
  {Request 구조}
}

// Response Types
export interface {Feature}Response {
  {Response 구조}
}

// Error Types
export interface {Feature}Error {
  code: string;
  message: string;
  details?: unknown;
}
```
"""
```

### Step 10: contracts/openapi.yaml 생성 (API 통합이 있는 경우만)

**apiDetails가 있는 경우에만 실행**:

**Write 도구로 openapi.yaml 생성**:
```
Write:
- file_path: "{featureDir}/contracts/openapi.yaml"
- content: """
openapi: 3.0.0
info:
  title: {featureName} API
  version: 1.0.0
  description: API contract for {featureName}

servers:
  - url: https://api.example.com/v1
    description: Production server

paths:
  {apiDetails에서 추출한 각 endpoint에 대해:}
  /{endpoint}:
    post:
      summary: {endpoint 설명}
      operationId: {operationId}
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/{Request}'
      responses:
        '200':
          description: Successful response
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/{Response}'
        '400':
          description: Bad request
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'

components:
  schemas:
    {Request}:
      type: object
      properties:
        {Request 속성들}
      required:
        {필수 속성들}

    {Response}:
      type: object
      properties:
        {Response 속성들}

    Error:
      type: object
      properties:
        code:
          type: string
        message:
          type: string
        details:
          type: object
"""
```

### Step 12: plan.md 생성

**Read 도구로 spec.md 읽기** (Constraints, Assumptions 섹션):
```
Read:
- file_path: "{featureDir}/spec.md"
- offset: 100  # Assumptions & Constraints 섹션 예상 위치
- limit: 30
```

**조건부 참조 읽기**:
```
IF research.md exists (complexity > 5):
  Read:
  - file_path: "{featureDir}/research.md"
  - offset: 30   # Library Options, Risks 섹션
  - limit: 80

  research.md에서 추출:
  - Library Options (Technical Foundation에 사용)
  - Risks & Mitigation (Implementation Phases에 반영)

IF data-model.md exists (entities.length > 0):
  Read:
  - file_path: "{featureDir}/data-model.md"
  - limit: 50    # Entity 구조 파악

  data-model.md에서 추출:
  - Entity 이름 및 관계 (Source Code Structure에 반영)
```

**참조 패턴 적용**:
- Technical Foundation 작성 시:
  - research.md가 있으면 → Library Options 참조
  - 없으면 → spec.md의 Constraints 기반으로 직접 작성
- Implementation Phases 작성 시:
  - research.md가 있으면 → Risks & Mitigation 반영
- Source Code Structure 작성 시:
  - data-model.md가 있으면 → Entity별 파일 구조 생성

**Write 도구로 plan.md 생성**:
```
Write:
- file_path: "{featureDir}/plan.md"
- content: """
# Implementation Plan: {featureName}

> 이 문서는 다음 문서들을 참조하여 작성되었습니다:
> - [spec.md](./spec.md) - 요구사항 및 성공 기준
{IF research.md exists:}
> - [research.md](./research.md) - 기술적 실현 가능성 및 리스크 분석
{IF data-model.md exists:}
> - [data-model.md](./data-model.md) - 데이터 구조 정의

## Technical Foundation

### Language/Version
- TypeScript 5.x
- React 18.x

### Primary Dependencies
{techStack이 있으면 여기에 나열:}
- {라이브러리1}: {버전}
- {라이브러리2}: {버전}
{없으면 Constitution 기준으로 자동 선택}

### Storage
{stateManagement이 있으면:}
- State: Zustand
- Persistence: localStorage (if needed)
{apiDetails가 있으면:}
- API: React Query
- Cache: React Query cache

### Testing Framework
- Unit: Vitest
- Integration: Testing Library
- E2E: Playwright (if needed)

## Constitution Check

| Article | Status | Violations | Justification | Alternatives Rejected |
|---------|--------|------------|---------------|---------------------|
| I: Library-First | ✅ | None | Using {techStack} | - |
| III: Test-First | ✅ | None | TDD approach | - |
| VIII: Anti-Abstraction | ✅ | None | Direct implementation | - |

## Phase 0: Research
{IF research.md exists (complexity > 5):}
[Link to research.md](./research.md)

**Key Findings:**
- {research.md에서 주요 발견 사항 요약}
{ELSE:}
**Key Findings** (from spec.md Constraints):
- {spec.md의 Constraints/Assumptions를 기반으로 직접 작성}

## Phase 1: Design Artifacts
{IF data-model.md exists (entities.length > 0):}
- [Data Model](./data-model.md)
{apiDetails가 있으면:}
- [API Contracts](./contracts/openapi.yaml)

## Source Code Structure

{아키텍처에 따라 FSD 구조 생성:}
```
src/
├── features/
│   └── {featureName}/
│       ├── model/
│       │   ├── types.ts          ({entities} 정의)
│       │   ├── schemas.ts        (Zod 스키마)
│       │   └── use{Feature}.ts   (비즈니스 로직 훅)
│       ├── api/
│       │   └── {endpoint}.ts     ({apiDetails} 구현)
│       ├── ui/
│       │   └── {Component}.tsx   (UI 컴포넌트)
│       └── __tests__/
│           ├── {feature}.test.ts
│           └── integration.test.tsx
{stateManagement이 있으면:}
├── app/
│   └── model/
│       └── stores/
│           └── {feature}Store.ts
```

## Implementation Phases
{실제 구현은 tasks.md에서 관리}
See [tasks.md](./tasks.md) for detailed task breakdown.

## Estimated Timeline
- Setup & Prerequisites: 0.5일
- Foundation: 1일
- User Story Implementation: {estimatedDays의 메인 시간}일
- Polish & Documentation: 0.5일

Total: {estimatedDays}
"""
```

### Step 13: tasks.md 생성

**Read 도구로 spec.md의 User Scenarios 섹션 읽기**:
```
Read:
- file_path: "{featureDir}/spec.md"
- offset: 10   # User Scenarios 섹션 시작
- limit: 60    # US1, US2, US3 전체
```

**Read 도구로 plan.md의 Implementation Phases 읽기**:
```
Read:
- file_path: "{featureDir}/plan.md"
- offset: 80   # Implementation Phases 섹션
- limit: 100   # 전체 Phase 구조 파악
```

**참조 패턴 적용**:
1. spec.md의 User Scenarios에서:
   - US1, US2, US3의 목표(Goal)와 검증 항목(Test Verification) 추출
   - 각 Phase 3, 4, 5... 의 제목과 테스트에 사용
2. plan.md의 Implementation Phases에서:
   - Technical Foundation → Phase 1 (Dependencies)
   - Source Code Structure → Phase 2-N (파일 경로)
   - Testing Strategy → Tests 섹션 (테스트 종류)
3. 명시적 참조:
   - 각 Phase에 User Story ID [US1], [US2] 표시
   - Goal과 Test Verification을 spec.md에서 정확히 복사

**Write 도구로 tasks.md 생성**:
```
Write:
- file_path: "{featureDir}/tasks.md"
- content: """
# Tasks: {featureName}

> 이 문서는 다음 문서들을 기반으로 작성되었습니다:
> - [spec.md](./spec.md) - User Scenarios (US1, US2, US3)
> - [plan.md](./plan.md) - Implementation Phases

## Task Format
- [ ] [T001] [P?] [Story?] Description /absolute/path/to/file
  - [P]: Parallelizable
  - [Story]: User Story ID (e.g., US1)

## Phase 1: Setup & Prerequisites

- [ ] [T001] [P] Initialize directory structure /src/features/{featureName}
- [ ] [T002] [P] Install dependencies
```bash
yarn add {techStack에서 추출한 패키지들}
```
- [ ] [T003] Create shared types /src/features/{featureName}/model/types.ts

## Phase 2: Foundation (Infrastructure BEFORE any user story)

- [ ] [T004] [P] Create Zod validation schemas /src/features/{featureName}/model/schemas.ts
{stateManagement이 있으면:}
- [ ] [T005] [P] Setup Zustand store /src/app/model/stores/{featureName}Store.ts
{apiDetails가 있으면:}
- [ ] [T006] [P] Setup API client /src/features/{featureName}/api/client.ts
- [ ] [T007] [P] Create API types /src/features/{featureName}/api/types.ts

## Phase 3: User Story - [US1] {첫 번째 사용자 시나리오}

**Goal:** {spec.md의 US1 목표}
**Test Verification:** {spec.md의 US1 검증 항목}

### Tests (Write FIRST - TDD)

- [ ] [T008] [US1] Contract tests /src/features/{featureName}/api/__tests__/contract.test.ts
  - Verify API request/response types
  - Mock API responses
  - Test error scenarios

- [ ] [T009] [US1] Unit tests for validation /src/features/{featureName}/model/__tests__/validation.test.ts
  - Test Zod schemas
  - Test edge cases
  - Test error messages

- [ ] [T010] [US1] Integration tests /src/features/{featureName}/__tests__/integration.test.tsx
  - Test complete user flow
  - Test loading states
  - Test error states

### Implementation (AFTER tests)

- [ ] [T011] [P] [US1] Create UI components /src/features/{featureName}/ui/{Component}.tsx
  - Main component
  - Sub-components
  - Loading states
  - Error states

- [ ] [T012] [US1] Implement business logic hook /src/features/{featureName}/model/use{Feature}.ts
  - Input validation
  - Business rules
  - State management integration

{apiDetails가 있으면:}
- [ ] [T013] [US1] Connect API integration /src/features/{featureName}/api/{endpoint}.ts
  - API call implementation
  - Error handling
  - Response transformation

## Phase 4: Polish & Documentation

- [ ] [T020] [P] Add JSDoc comments to public APIs
- [ ] [T021] [P] Update feature README
- [ ] [T022] Run full test suite
```bash
yarn test
```
- [ ] [T023] Type check
```bash
yarn type-check
```
- [ ] [T024] Build verification
```bash
yarn build:dev
```

## Progress Tracking

Total Tasks: {자동 계산}
Completed: 0
In Progress: 0
Remaining: {Total}

## Notes

{complexity가 높으면:}
⚠️ This is a complex feature. Consider breaking down into smaller iterations.

{apiDetails가 불완전하면:}
⚠️ API contract needs clarification. Update contracts/openapi.yaml before T013.
"""
```

**파일 생성 검증**:
```
Read:
- file_path: "{featureDir}/tasks.md"
- limit: 10
```

파일이 정상적으로 생성되었는지 확인하세요. 생성되지 않았다면 다시 Write 도구를 사용하세요.

✅ **Step 13 완료** - tasks.md 생성 완료 (spec.md의 User Stories 참조)

### Step 13.5: 문서 미리보기 및 동의 요청

**목적**: 파일 생성 전 사용자에게 문서 내용을 미리보기로 보여주고 동의를 받습니다.

**🔴 필수**: 이 단계는 모든 문서가 준비된 후 실제 파일 생성 전에 실행됩니다.

#### 13.5.1: 문서 컬렉션 생성

**Bash 도구로 document-collection.sh 사용**:
```
Bash:
- command: "source .claude/lib/document-preview/document-collection.sh && collection=$(create_document_collection 2>/dev/null) && echo \"$collection\""
- description: "Create document collection for Major feature files"
```

생성된 컬렉션 ID를 `{collectionId}` 변수에 저장하세요.

#### 13.5.2: 문서 컬렉션에 파일 추가

**필수 문서 추가**:
```
Bash:
- command: "source .claude/lib/document-preview/document-collection.sh && add_document_to_collection '{collectionId}' '{featureDir}/spec.md' 2>/dev/null && add_document_to_collection '{collectionId}' '{featureDir}/plan.md' 2>/dev/null && add_document_to_collection '{collectionId}' '{featureDir}/tasks.md' 2>/dev/null"
- description: "Add core Major documents to collection"
```

**조건부 문서 추가** (complexity > 5인 경우):
```
Bash:
- command: "if [ -n '{researchMdPath}' ]; then source .claude/lib/document-preview/document-collection.sh && add_document_to_collection '{collectionId}' '{featureDir}/research.md' 2>/dev/null; fi"
- description: "Add research.md if generated"
```

**조건부 문서 추가** (entities.length > 0인 경우):
```
Bash:
- command: "if [ -n '{dataModelPath}' ]; then source .claude/lib/document-preview/document-collection.sh && add_document_to_collection '{collectionId}' '{featureDir}/data-model.md' 2>/dev/null; fi"
- description: "Add data-model.md if generated"
```

**조건부 문서 추가** (API 통합이 있는 경우):
```
Bash:
- command: "if [ -n '{openApiPath}' ]; then source .claude/lib/document-preview/document-collection.sh && add_document_to_collection '{collectionId}' '{featureDir}/contracts/openapi.yaml' 2>/dev/null; fi"
- description: "Add openapi.yaml if generated"
```

#### 13.5.3: 배치 미리보기 생성

**Bash 도구로 batch-preview.sh 사용**:
```
Bash:
- command: "source .claude/lib/document-preview/batch-preview.sh && result=$(generate_batch_preview '{collectionId}' 300 2>/dev/null) && echo \"$result\""
- description: "Generate batch preview for all Major feature documents"
```

생성된 배치 결과 파일 경로를 `{batchResultFile}` 변수에 저장하세요.

#### 13.5.4: 미리보기 통계 확인

**Bash 도구로 통계 조회**:
```
Bash:
- command: "source .claude/lib/document-preview/batch-preview.sh && get_batch_preview_stats '{batchResultFile}' 2>/dev/null"
- description: "Get batch preview statistics"
```

통계를 사용자에게 보고:
```markdown
📊 문서 미리보기 통계:
- 총 문서 수: {total}
- 성공: {success}
- 실패: {failure}
```

#### 13.5.5: 각 문서 미리보기 및 동의 요청

**환경 확인**:
```
Bash:
- command: "echo ${CLAUDE_ENV:-production}"
- description: "Check environment mode"
```

환경 변수를 `{environment}` 변수에 저장하세요.

**각 문서에 대해 반복**:

1. **spec.md 미리보기**:
```
Bash:
- command: "source .claude/lib/document-preview/batch-preview.sh && get_document_preview_from_batch '{batchResultFile}' '{featureDir}/spec.md' 2>/dev/null"
- description: "Get spec.md preview"
```

미리보기를 사용자에게 표시:
```markdown
📄 spec.md 미리보기:

{미리보기 내용}
```

**Production 모드인 경우 동의 요청**:
```
IF {environment} == "production":
  AskUserQuestion:
    질문: "spec.md 파일을 생성하시겠습니까?"
    헤더: "파일 생성"
    multiSelect: false
    옵션:
      1. label: "승인"
         description: "파일 생성 진행"
      2. label: "수정 요청"
         description: "내용 수정 후 재생성"
      3. label: "거부"
         description: "파일 생성 취소"
ELSE:
  # Development 모드: 자동 승인
  동의 상태 = "승인"
  "ℹ️  Development 모드: spec.md 자동 승인" 출력
```

2. **research.md 미리보기** (complexity > 5인 경우):
```
IF complexity > 5:
  Bash:
  - command: "source .claude/lib/document-preview/batch-preview.sh && get_document_preview_from_batch '{batchResultFile}' '{featureDir}/research.md' 2>/dev/null"
  - description: "Get research.md preview"

  # 동일한 동의 요청 프로세스
```

3. **data-model.md 미리보기** (entities.length > 0인 경우):
```
IF entities.length > 0:
  Bash:
  - command: "source .claude/lib/document-preview/batch-preview.sh && get_document_preview_from_batch '{batchResultFile}' '{featureDir}/data-model.md' 2>/dev/null"
  - description: "Get data-model.md preview"

  # 동일한 동의 요청 프로세스
```

4. **contracts/openapi.yaml 미리보기** (API 통합이 있는 경우):
```
IF apiDetails exists:
  Bash:
  - command: "source .claude/lib/document-preview/batch-preview.sh && get_document_preview_from_batch '{batchResultFile}' '{featureDir}/contracts/openapi.yaml' 2>/dev/null"
  - description: "Get openapi.yaml preview"

  # 동일한 동의 요청 프로세스
```

5. **plan.md 미리보기**:
```
Bash:
- command: "source .claude/lib/document-preview/batch-preview.sh && get_document_preview_from_batch '{batchResultFile}' '{featureDir}/plan.md' 2>/dev/null"
- description: "Get plan.md preview"

# 동일한 동의 요청 프로세스
```

6. **tasks.md 미리보기**:
```
Bash:
- command: "source .claude/lib/document-preview/batch-preview.sh && get_document_preview_from_batch '{batchResultFile}' '{featureDir}/tasks.md' 2>/dev/null"
- description: "Get tasks.md preview"

# 동일한 동의 요청 프로세스
```

#### 13.5.6: 동의 결과 저장

각 문서의 동의 결과를 변수에 저장:
- `{specConsent}` - spec.md 동의 여부
- `{researchConsent}` - research.md 동의 여부 (조건부)
- `{dataModelConsent}` - data-model.md 동의 여부 (조건부)
- `{contractsConsent}` - openapi.yaml 동의 여부 (조건부)
- `{planConsent}` - plan.md 동의 여부
- `{tasksConsent}` - tasks.md 동의 여부

**Bash 도구로 동의 결과 저장** (consent-manager.sh 사용):
```
Bash:
- command: "source .claude/lib/document-preview/consent-manager.sh && record_consent '{featureDir}/spec.md' '{specConsent}' 'user-approved' 2>/dev/null"
- description: "Record spec.md consent"
```

각 문서에 대해 동일한 프로세스 반복.

#### 13.5.7: 동의 거부 처리

**거부된 문서 확인**:
```
거부된 문서 = [문서 for 문서 in [spec, research, dataModel, contracts, plan, tasks] if 동의 == "거부"]
수정 요청 문서 = [문서 for 문서 in [spec, research, dataModel, contracts, plan, tasks] if 동의 == "수정 요청"]
```

**거부/수정 요청이 있는 경우**:
```markdown
⚠️ 다음 문서가 거부되었습니다:
{거부된 문서 목록}

⚠️ 다음 문서의 수정이 요청되었습니다:
{수정 요청 문서 목록}

옵션:
1. 수정 요청 문서를 수정하고 다시 미리보기 (Step 6-13 재실행)
2. 승인된 문서만으로 계속 진행
3. 워크플로우 중단
```

**AskUserQuestion으로 다음 단계 결정**:
```
질문: "어떻게 진행하시겠습니까?"
헤더: "다음 단계"
multiSelect: false
옵션:
  1. label: "문서 수정 후 재생성"
     description: "거부/수정 요청된 문서를 수정하고 다시 생성합니다"
  2. label: "승인된 문서만 진행"
     description: "승인된 문서만 생성하고 계속 진행합니다"
  3. label: "워크플로우 중단"
     description: "Major 워크플로우를 중단합니다"
```

선택에 따라:
- **문서 수정 후 재생성**: Step 6으로 돌아가서 해당 문서 재생성
- **승인된 문서만 진행**: 승인된 문서만 생성하고 Step 14로 진행
- **워크플로우 중단**: 워크플로우 종료

#### 13.5.8: 컬렉션 정리

**Bash 도구로 배치 결과 정리**:
```
Bash:
- command: "source .claude/lib/document-preview/batch-preview.sh && cleanup_batch_result '{batchResultFile}' 2>/dev/null"
- description: "Cleanup batch preview results"
```

**Bash 도구로 컬렉션 삭제**:
```
Bash:
- command: "source .claude/lib/document-preview/document-collection.sh && delete_document_collection '{collectionId}' 2>/dev/null"
- description: "Delete document collection"
```

✅ **Step 13.5 완료** - 문서 미리보기 및 동의 요청 완료

### Step 14: 완료 보고

다음 형식으로 완료 보고를 출력하세요:

```markdown
✅ Major 워크플로 완료!

📁 생성된 파일:
.specify/specs/{nextNumber}-{featureName}/
├── spec.md                  ✅ (Specification)
{complexity > 5이면:}
├── research.md              ✅ (Technical Research)
{entities.length > 0이면:}
├── data-model.md            ✅ (Data Models & Schemas)
{apiDetails가 있으면:}
├── contracts/
│   └── openapi.yaml         ✅ (API Contracts)
├── plan.md                  ✅ (Implementation Plan)
└── tasks.md                 ✅ (Executable Tasks)

📊 작업 분석:
- Feature Number: {nextNumber}
- Branch: {nextNumber}-{featureName}
- Priority: {priority}
- Estimated Duration: {estimatedDays}
- Total Tasks: {tasks.md의 총 task 수}

📋 다음 단계:

1. **생성된 문서 검토** (권장):
   - spec.md 검토 및 필요시 수정
   - plan.md 검토 및 필요시 수정
   - tasks.md 검토 및 task 순서 조정

2. **즉시 구현 시작**:
   {tasks.md의 첫 번째 task를 직접 실행}
   예: "T001 Initialize directory structure 작업을 시작하시겠습니까?"

3. **브랜치 확인**:
   git branch  # {nextNumber}-{featureName} 브랜치 확인

💡 Tip:
- Constitution 체크 결과를 확인하세요 (plan.md)
- Test-First를 위해 tasks.md의 순서를 반드시 지켜주세요
- 각 User Story는 독립적으로 완료/테스트 가능해야 합니다
```

---

**중요 사항:**
- Step 0-14를 순차적으로 실행하세요
- 사전 조건 확인에서 실패하면 즉시 중단하고 /start 실행 안내
- 질문은 2개 블록으로 축소 (필수 3개 + 선택 통합)
- **조건부 파일 생성** (complexity와 entities에 따라 4-6개):
  1. spec.md (필수)
  2. research.md (complexity > 5일 때만)
  3. data-model.md (entities.length > 0일 때만)
  4. contracts/openapi.yaml (API 통합 시)
  5. plan.md (필수)
  6. tasks.md (필수)
- **참조 패턴 적용**: 각 문서는 Read 도구로 이전 문서를 참조하여 중복 제거
- 각 파일은 이전 단계의 변수를 참조하여 일관성 유지
- tasks.md는 실행 가능한 구체적 명령어 포함
