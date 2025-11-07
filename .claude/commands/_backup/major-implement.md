# /major-implement - 자동 구현 (선택사항)

tasks.md의 Task를 순서대로 자동으로 구현합니다.

## 사용법

```
# 전체 Task 자동 구현
/major-implement [feature-number]

# 특정 Task만 구현
/major-implement [feature-number] --task T001
/major-implement [feature-number] --from T005 --to T010
```

예시:
```
/major-implement 001
/major-implement 001 --task T007
/major-implement 001 --from T007 --to T012
```

## 실행 내용

1. tasks.md 로드
2. 각 Task를 순서대로 실행:
   - [ ] → [실행 중] → [✅ 완료]
   - 파일 생성/수정
   - 각 Task 완료 후:
     - yarn type-check 실행
     - 관련 테스트 실행 (테스트 Task인 경우)

3. Quality Gates 자동 적용:
   - FSD 아키텍처 준수 (fsd-architect)
   - Test-First 강제 (test-guardian)
   - 타입 안전성 (yarn type-check)

## Test-First 강제

```
Phase 3: User Story - [US1]
  Tests:
    - [ ] [T007] [US1] Contract tests
    - [ ] [T008] [US1] Unit tests
    - [ ] [T009] [US1] Integration tests

  Implementation:
    - [ ] [T010] [P] [US1] UI component
    - [ ] [T011] [US1] Business logic hook
    - [ ] [T012] [US1] API integration
```

**강제 규칙**:
- T007, T008, T009가 완료되지 않으면 T010-T012 실행 불가
- 각 테스트는 실행하여 통과 확인

## 병렬화 ([P] Task)

```
- [ ] [T001] [P] Initialize directory
- [ ] [T002] [P] Install dependencies
- [ ] [T003] Create types
```

**[P] 표시된 Task는 병렬 실행 가능**:
- 동시에 여러 Task tool 호출
- 각각 독립적으로 완료

## 진행 상황 보고

```
📊 구현 진행 상황:

Phase 1: Setup & Prerequisites
  ✅ [T001] Initialize directory
  ✅ [T002] Install dependencies
  ✅ [T003] Create types

Phase 2: Foundation
  ✅ [T004] Setup API client
  ✅ [T005] Create Zustand store
  ⏳ [T006] Add validation schemas (진행 중...)

Progress: 5/25 Tasks (20%)
Estimated Time Remaining: 2-3 hours
```

## Quality Gates 적용

### During-Implementation
- ✅ FSD 아키텍처 (fsd-architect agent)
  - Entity 순수성 검증
  - Features Props 규칙 검증
  - 의존성 방향 검증

- ✅ Test-First (test-guardian agent)
  - 테스트 우선 작성 강제
  - 커버리지 80%+ 달성 확인

- ✅ 타입 안전성
  - 각 Task 완료 후 yarn type-check

### Post-Implementation
- ✅ 코드 리뷰 (code-reviewer agent)
  - 보안 취약점 검사
  - 성능 이슈 검사
  - 베스트 프랙티스 준수

- ✅ 전체 테스트 통과
  ```bash
  yarn test
  yarn test:critical
  ```

- ✅ 빌드 성공
  ```bash
  yarn build:dev
  ```

## 에러 처리

**Task 실행 실패 시**:
1. 에러 분석
2. 수정 제안
3. 사용자 확인 후 재시도 또는 건너뛰기

**Quality Gate 실패 시**:
1. 실패 원인 보고
2. 자동 수정 시도 (가능한 경우)
3. 수동 수정 안내

## 완료 보고

```
✅ 구현 완료!

📊 최종 결과:
- 완료된 Task: 25/25 (100%)
- 생성된 파일: 12개
- 수정된 파일: 3개
- 테스트: 15개 (모두 통과)
- 커버리지: 87%
- 타입 에러: 0개
- 빌드: ✅ 성공

📋 Quality Gates:
- ✅ FSD 아키텍처
- ✅ Test-First
- ✅ 타입 안전성
- ✅ 코드 리뷰
- ✅ 모든 테스트 통과
- ✅ 빌드 성공

📝 다음 단계:
1. Git commit:
   git add .
   git commit -m "feat: {feature-name}"

2. PR 생성:
   gh pr create --title "feat: {feature-name}"

3. Changelog 업데이트:
   /changelog
```

## 주의사항

- 자동 구현은 **완전히 신뢰할 수 없습니다**
- 각 Phase 완료 후 **수동 검토 권장**
- Critical한 기능은 **수동 구현 후 검증**
- 자동 구현 중 언제든지 **중단 및 수동 전환 가능**
