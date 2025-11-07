# /major-tasks - Task Breakdown 생성 (Step 4/4)

plan.md를 기반으로 실행 가능한 task breakdown을 생성합니다.

## 사용법

```
/major-tasks [feature-number]
```

예시:
```
/major-tasks 001
```

## 실행 내용

`/major`의 6단계를 독립적으로 실행:
1. plan.md 분석
2. User Story별 Task 그룹핑
3. Test-First 순서로 Task 배열
4. 병렬화 가능 Task 표시 ([P])
5. 절대 경로로 파일 위치 명시

## Task 형식

```
[T001] [P?] [Story?] Description /absolute/path/to/file
```

예시:
```
- [ ] [T001] [P] Initialize directory structure /src/features/auth
- [ ] [T007] [US1] Contract tests /src/features/auth/api/__tests__/contract.test.ts
- [ ] [T010] [P] [US1] Create UI component /src/features/auth/ui/LoginForm.tsx
```

## 생성 파일

```
.specify/specs/NNN-feature-name/
├── spec.md         (기존)
├── plan.md         (기존)
└── tasks.md        ✅
```

## Phase 구조

```
Phase 1: Setup & Prerequisites
Phase 2: Foundation (Infrastructure)
Phase 3: User Story - [US1]
  - Tests (Write FIRST)
  - Implementation (AFTER tests)
Phase 4: User Story - [US2]
  ...
Phase N: Polish & Documentation
```

## 다음 단계

```
/major-implement  # 자동 구현 시작 (선택)
```

또는 수동 구현:
```bash
# tasks.md를 보면서 순서대로 구현
cat .specify/specs/001-feature-name/tasks.md
```
