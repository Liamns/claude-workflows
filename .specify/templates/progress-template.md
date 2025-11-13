# Progress: {EPIC_NAME}

> Last Updated: {LAST_UPDATED}

## Summary

- **Total Features:** {TOTAL_FEATURES}
- **Completed:** {COMPLETED_COUNT} ✅
- **In Progress:** {IN_PROGRESS_COUNT} 🔄
- **Pending:** {PENDING_COUNT} ⬜
- **Completion Rate:** {COMPLETION_RATE}%

## Progress Bar

```
[{PROGRESS_BAR}] {COMPLETION_RATE}%
```

## Feature Status

### ✅ Completed
{완료된 Feature 목록 - 없으면 이 섹션 제거}

- [x] [001-{feature-name}](./features/001-{feature-name}/spec.md) - {Feature 이름}
  - **Completed:** {YYYY-MM-DD}
  - **Estimated:** {N}일 → **Actual:** {M}일

### 🔄 In Progress
{진행 중인 Feature 목록 - 없으면 이 섹션 제거}

- [ ] [002-{feature-name}](./features/002-{feature-name}/spec.md) - {Feature 이름}
  - **Started:** {YYYY-MM-DD}
  - **Progress:** {N}% complete
  - **Blockers:** {있다면 나열}

### ⬜ Pending
{대기 중인 Feature 목록 - 없으면 이 섹션 제거}

- [ ] [003-{feature-name}](./features/003-{feature-name}/spec.md) - {Feature 이름}
  - **Estimated:** {N}일
  - **Dependencies:** {의존하는 Feature ID}

- [ ] [004-{feature-name}](./features/004-{feature-name}/spec.md) - {Feature 이름}
  - **Estimated:** {N}일
  - **Dependencies:** None

## Timeline

- **Started:** {EPIC_START_DATE}
- **Current Phase:** Phase {N} ({Phase Name})
- **Estimated Completion:** {ESTIMATED_COMPLETION_DATE}
- **Actual Completion:** {ACTUAL_COMPLETION_DATE or TBD}

### Phase Progress

| Phase | Features | Status | Completion |
|-------|----------|--------|------------|
| Phase 1: {Name} | 001, 002 | ✅ Completed | 100% |
| Phase 2: {Name} | 003 | 🔄 In Progress | 60% |
| Phase 3: {Name} | 004, 005 | ⬜ Pending | 0% |

## Milestones

### M1: {Milestone Name}
- **Target Date:** {YYYY-MM-DD}
- **Status:** ✅ Completed / 🔄 In Progress / ⬜ Pending
- **Features:** 001, 002
- **Completion:** {YYYY-MM-DD or TBD}

### M2: {Milestone Name}
- **Target Date:** {YYYY-MM-DD}
- **Status:** ⬜ Pending
- **Features:** 001, 002, 003
- **Completion:** TBD

## Recent Activity

### {YYYY-MM-DD}
- ✅ Feature 001 완료
- 🚀 Feature 002 시작

### {YYYY-MM-DD}
- 🔧 Feature 002 진행 중 (30% → 60%)

## Blockers

{현재 진행을 막고 있는 이슈 목록 - 없으면 "None"}

- ❌ [Blocker 1]: {설명}
  - **Impact:** High / Medium / Low
  - **Action:** {해결 방안}

## Velocity

- **Average Days per Feature:** {N}일
- **Estimated Remaining Time:** {N}일
- **Projected Completion:** {YYYY-MM-DD}

## Notes

{진행 상황에 대한 추가 메모나 관찰 사항}

---

**자동 업데이트:**
이 파일은 Feature 완료 시 `update-epic-progress.sh`에 의해 자동 업데이트됩니다.
수동 수정 시 스크립트 재실행으로 덮어쓰기될 수 있습니다.
