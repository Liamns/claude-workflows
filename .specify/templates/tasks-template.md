# Tasks: {Feature Name}

## Task Format

```
- [ ] [T001] [P?] [Story?] Description /absolute/path/to/file
```

- `[TXXX]`: Task 번호 (001부터 시작)
- `[P]`: Parallelizable (병렬 실행 가능한 Task)
- `[Story]`: User Story ID (예: US1, US2)
- `/absolute/path`: 파일의 절대 경로

## Phase 1: Setup & Prerequisites

{초기 설정 및 전제조건}

- [ ] [T001] [P] Initialize directory structure /src/features/{feature-name}
- [ ] [T002] [P] Install dependencies (yarn add {packages})
- [ ] [T003] Create shared types /src/features/{feature-name}/model/types.ts
- [ ] [T004] Create constants /src/features/{feature-name}/config/constants.ts

## Phase 2: Foundation (Infrastructure BEFORE any user story)

{사용자 스토리 구현 전 필요한 기반 시설}

- [ ] [T005] [P] Setup API client /src/features/{feature-name}/api/client.ts
- [ ] [T006] [P] Create Zustand store /src/app/model/stores/{feature}Store.ts
- [ ] [T007] [P] Add validation schemas /src/features/{feature-name}/model/schemas.ts
- [ ] [T008] [P] Create utility functions /src/features/{feature-name}/lib/utils.ts

## Phase 3: User Story - [US1] {Story Name}

**Goal:** {독립적으로 완료 및 테스트 가능}
**Test Verification:** {검증 방법}

### Tests (Write FIRST - TDD)

- [ ] [T009] [US1] Contract tests /src/features/{feature-name}/api/__tests__/contract.test.ts
- [ ] [T010] [US1] Unit tests for validation /src/features/{feature-name}/model/__tests__/validation.test.ts
- [ ] [T011] [US1] Unit tests for business logic /src/features/{feature-name}/model/__tests__/use{Feature}.test.ts
- [ ] [T012] [US1] Integration tests /src/features/{feature-name}/__tests__/integration.test.tsx

### Implementation (AFTER tests)

- [ ] [T013] [P] [US1] Create Entity model /src/entities/{entity}/model/types.ts
- [ ] [T014] [P] [US1] Create Entity UI component /src/entities/{entity}/ui/{Component}.tsx
- [ ] [T015] [US1] Implement business logic hook /src/features/{feature-name}/model/use{Feature}.ts
- [ ] [T016] [US1] Create Feature UI components /src/features/{feature-name}/ui/{Component}.tsx
- [ ] [T017] [US1] Connect API integration /src/features/{feature-name}/api/{endpoint}.ts

## Phase 4: User Story - [US2] {Story Name}

**Goal:** {독립적으로 완료 및 테스트 가능}
**Test Verification:** {검증 방법}

### Tests (Write FIRST - TDD)

- [ ] [T018] [US2] Contract tests /src/features/{feature-name}/api/__tests__/{endpoint}.test.ts
- [ ] [T019] [US2] Unit tests /src/features/{feature-name}/model/__tests__/{module}.test.ts
- [ ] [T020] [US2] Integration tests /src/features/{feature-name}/__tests__/{scenario}.test.tsx

### Implementation (AFTER tests)

- [ ] [T021] [P] [US2] Create components /src/features/{feature-name}/ui/{Component}.tsx
- [ ] [T022] [US2] Implement logic /src/features/{feature-name}/model/{module}.ts
- [ ] [T023] [US2] API integration /src/features/{feature-name}/api/{endpoint}.ts

## Phase 5: User Story - [US3] {Story Name}

{위와 동일한 구조}

## Phase N: Polish & Documentation

{마무리 작업}

- [ ] [T050] [P] Add JSDoc comments to public APIs
- [ ] [T051] [P] Add prop-types or TypeScript interfaces for all components
- [ ] [T052] [P] Update feature README.md /src/features/{feature-name}/README.md
- [ ] [T053] [P] Create usage examples /src/features/{feature-name}/examples/
- [ ] [T054] Run full test suite (yarn test)
- [ ] [T055] Check test coverage (yarn test:coverage)
- [ ] [T056] Type check (yarn type-check)
- [ ] [T057] Lint check (yarn lint)
- [ ] [T058] Build verification (yarn build:dev)
- [ ] [T059] E2E tests (yarn test:e2e) - if applicable
- [ ] [T060] Update project CHANGELOG.md

## Quality Gates Checklist

### Pre-Implementation
- [ ] spec.md reviewed and approved
- [ ] plan.md reviewed and approved
- [ ] All dependencies installed

### During-Implementation
- [ ] FSD architecture rules followed
- [ ] Test-First approach applied
- [ ] Type safety maintained (no type errors)

### Post-Implementation
- [ ] All tests pass (100%)
- [ ] Test coverage ≥ 80%
- [ ] No type errors
- [ ] No lint errors
- [ ] Build succeeds
- [ ] Code review completed

## Notes

{추가 참고사항}

- Test-First 순서를 엄격히 지켜주세요 (Tests → Implementation)
- [P] 표시된 Task는 병렬로 실행 가능합니다
- 각 Phase 완료 후 checkpoint 수행을 권장합니다
