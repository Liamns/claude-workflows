# Roadmap: {EPIC_NAME}

## Feature Execution Order

{Feature 실행 순서를 Phase별로 그룹핑하여 작성합니다.}

### Phase 1: {Phase Name}

- **[001-{feature-name}](./features/001-{feature-name}/spec.md)**
  - **Description:** {Feature에 대한 간단한 설명}
  - **Dependencies:** None
  - **Parallelizable:** No
  - **Estimated:** {예: 3-5일}
  - **Priority:** P1
  - **Status:** ⬜ Pending

- **[002-{feature-name}](./features/002-{feature-name}/spec.md)**
  - **Description:** {Feature에 대한 간단한 설명}
  - **Dependencies:** None
  - **Parallelizable:** Yes (with 001)
  - **Estimated:** {예: 2-3일}
  - **Priority:** P1
  - **Status:** ⬜ Pending

### Phase 2: {Phase Name}

- **[003-{feature-name}](./features/003-{feature-name}/spec.md)**
  - **Description:** {Feature에 대한 간단한 설명}
  - **Dependencies:** 001, 002
  - **Parallelizable:** No
  - **Estimated:** {예: 4-6일}
  - **Priority:** P2
  - **Status:** ⬜ Pending

## Dependency Graph

```mermaid
graph TD
    A[001-{feature-name}] --> C[003-{feature-name}]
    B[002-{feature-name}] --> C
```

**Dependency 설명:**
- Feature 001과 002는 독립적으로 병렬 실행 가능
- Feature 003은 001과 002 완료 후 시작 가능

## Milestones

### M1: {Milestone Name}
- **Features:** 001, 002
- **Target:** Week 2
- **Success Criteria:**
  - [ ] Feature 001 완료 및 테스트 통과
  - [ ] Feature 002 완료 및 테스트 통과
  - [ ] 기본 통합 동작 확인
- **Status:** ⬜ Pending

### M2: {Milestone Name}
- **Features:** 001, 002, 003
- **Target:** Week 4
- **Success Criteria:**
  - [ ] 모든 Feature 완료
  - [ ] 전체 Epic 통합 테스트 통과
  - [ ] 성능 기준 충족
- **Status:** ⬜ Pending

## Execution Strategy

### 병렬 실행 가능 Features
- Feature 001과 002는 서로 의존하지 않으므로 동시 작업 가능
- 병렬 실행 시 예상 소요 시간: {N}일 절감

### 순차 실행 필수 Features
- Feature 003은 001, 002의 완료가 필수
- 의존성이 해결될 때까지 대기 필요

### 리스크 관리
- **High Risk Features:** {리스크가 높은 Feature 나열}
  - 조기 착수 권장
  - 더 많은 테스트 리소스 할당

- **Critical Path:** 001 → 003
  - 이 경로의 지연은 전체 Epic 지연으로 이어짐

## Phase Transition Criteria

### Phase 1 → Phase 2
- [ ] Feature 001 완료 및 검증
- [ ] Feature 002 완료 및 검증
- [ ] Phase 1 통합 테스트 통과

### Phase 2 → Completion
- [ ] Feature 003 완료 및 검증
- [ ] 전체 Epic 통합 테스트 통과
- [ ] Success Criteria 충족

## Notes

**의존성 변경 시:**
- roadmap.md 업데이트
- 순환 의존성 체크 (validate-epic.sh 실행)
- progress.md 재계산

**Feature 추가 시:**
- Feature 디렉토리 생성
- roadmap.md에 Feature 추가
- Dependency Graph 업데이트
- Milestone 조정
