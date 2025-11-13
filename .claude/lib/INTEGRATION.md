# Branch State Management - Integration Guide

이 가이드는 브랜치 생성 시 Git 상태 관리 기능을 기존 워크플로우에 통합하는 방법을 설명합니다.

## 개요

브랜치 상태 관리 라이브러리는 다음 기능을 제공합니다:
- 자동 Git 상태 확인 (clean/dirty)
- Dirty state 시 5가지 옵션 제공 (commit/move/stash/discard/cancel)
- 병렬 작업 지원 (Feature 브랜치에서 Epic 브랜치로 자동 분기)
- 에러 처리 및 자동 롤백

## 라이브러리 구성

```
.claude/lib/
├── git-status-checker.sh      # Git 상태 확인
├── branch-info-collector.sh   # 브랜치 정보 수집
├── branch-state-handler.sh    # 상태별 처리 로직
└── git-operations.sh           # Git 명령 실행
```

## 사용 방법

### 1. 기본 사용법

```bash
#!/bin/bash

# 라이브러리 로드
source .claude/lib/git-status-checker.sh
source .claude/lib/branch-info-collector.sh
source .claude/lib/branch-state-handler.sh
source .claude/lib/git-operations.sh

# Git 상태 확인
check_git_status

# 브랜치 생성 처리
handle_branch_creation "004-new-feature"
```

### 2. Major 워크플로우 통합

**위치**: `.claude/commands/major.md` - Step 1 이후

**기존 코드**:
```bash
bash .specify/scripts/bash/create-new-feature.sh [feature-name]
```

**권장 통합 방식**:
```bash
# 1. 라이브러리 로드
source .claude/lib/git-status-checker.sh
source .claude/lib/branch-info-collector.sh
source .claude/lib/branch-state-handler.sh
source .claude/lib/git-operations.sh

# 2. Git 상태 확인
check_git_status

# 3. 브랜치 생성 처리 (자동으로 상태 관리)
if ! handle_branch_creation "001-feature-name"; then
  echo "Branch creation cancelled or failed"
  exit 1
fi

# 4. 기존 워크플로우 계속
bash .specify/scripts/bash/create-new-feature.sh [feature-name]
```

### 3. create-epic.sh 통합

**위치**: `.specify/scripts/bash/create-epic.sh` - Line 269 근처

**기존 코드** (예상):
```bash
git checkout -b "$branch_name"
```

**권장 통합 방식**:
```bash
# 라이브러리 로드 (파일 상단에)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../../../.claude/lib"

source "$LIB_DIR/git-status-checker.sh"
source "$LIB_DIR/branch-info-collector.sh"
source "$LIB_DIR/branch-state-handler.sh"
source "$LIB_DIR/git-operations.sh"

# 브랜치 생성 시 (Line 269)
check_git_status

if ! handle_branch_creation "$branch_name"; then
  echo "Failed to create branch: $branch_name"
  exit 1
fi
```

## 주요 함수

### check_git_status()

Git 작업 트리의 현재 상태를 확인합니다.

**글로벌 변수 설정**:
- `GIT_STATUS_CLEAN`: true/false
- `GIT_MODIFIED_FILES`: 수정된 파일 배열
- `GIT_UNTRACKED_FILES`: 추적되지 않는 파일 배열
- `GIT_STAGED_FILES`: 스테이징된 파일 배열
- `GIT_HAS_CONFLICTS`: 충돌 여부

### handle_branch_creation(branch_name)

브랜치 생성을 처리합니다. Git 상태와 현재 브랜치를 자동으로 확인하여 적절한 처리를 수행합니다.

**매개변수**:
- `branch_name`: 생성할 브랜치 이름

**반환값**:
- `0`: 성공
- `1`: 실패 또는 취소

**동작**:
1. 현재 브랜치가 Feature 브랜치인지 확인
2. Feature 브랜치면 Epic 브랜치에서 분기 (US5)
3. Clean state면 즉시 브랜치 생성 (US1)
4. Dirty state면 사용자에게 옵션 제공 (US2)

### get_branch_info()

현재 브랜치 정보를 수집합니다.

**글로벌 변수 설정**:
- `BRANCH_NAME`: 현재 브랜치 이름
- `IS_FEATURE_BRANCH`: Feature 브랜치 여부
- `IS_EPIC_BRANCH`: Epic 브랜치 여부

## 시나리오별 처리

### 시나리오 1: Clean State

작업 트리가 깨끗한 상태에서 브랜치 생성

```bash
check_git_status

if [ "$GIT_STATUS_CLEAN" = "true" ]; then
  handle_branch_creation "004-new-feature"
  # 결과: 브랜치 즉시 생성
fi
```

### 시나리오 2: Dirty State

미커밋 변경사항이 있는 상태

```bash
check_git_status

if [ "$GIT_STATUS_CLEAN" = "false" ]; then
  handle_branch_creation "004-new-feature"
  # 결과: 사용자에게 5가지 옵션 제공
  #   1. Commit and continue
  #   2. Move with changes
  #   3. Stash and continue
  #   4. Discard and continue
  #   5. Cancel
fi
```

### 시나리오 3: Parallel Work

Feature 브랜치에서 다른 Feature 브랜치 생성

```bash
# 현재: 002-feature-auth 브랜치
get_branch_info

if is_feature_branch "$BRANCH_NAME"; then
  handle_branch_creation "003-new-feature"
  # 결과:
  #   1. Epic 브랜치 검색 (001-epic-*)
  #   2. Epic 브랜치에서 새 브랜치 생성
  #   3. 병렬 작업 경고 표시
fi
```

## AskUserQuestion 통합 (Phase 9 TODO)

현재 구현은 테스트용 기본값을 사용합니다. 실제 사용 시 AskUserQuestion 도구와 통합이 필요합니다.

**위치**:
- `branch-state-handler.sh:ask_user_action()` (Line 44-71)
- `branch-state-handler.sh:ask_commit_message_review()` (Line 157-197)

**통합 예시**:
```bash
ask_user_action() {
  local branch_name="$1"

  # Display file summary
  display_git_status_summary

  # Ask user via AskUserQuestion tool
  # TODO: Integrate with Claude's AskUserQuestion
  # For now, return default action
  echo "commit"
}
```

## 에러 처리

모든 함수는 적절한 exit code를 반환합니다:

```bash
if ! handle_branch_creation "$branch_name"; then
  echo "Failed to create branch"
  rollback_operation "branch"  # 자동 롤백
  safe_exit 1
fi
```

## 테스트

전체 테스트 스위트 실행:

```bash
cd .claude/__tests__

# 개별 테스트
bash us1-clean-state.test.sh
bash us2-dirty-state.test.sh
bash us3-commit-option.test.sh
bash us4-stash-option.test.sh
bash us5-parallel-work.test.sh
bash us6-error-handling.test.sh

# Foundation 테스트
bash git-status-checker.test.sh
bash branch-info-collector.test.sh
```

## 주의사항

1. **순서 중요**: 반드시 `check_git_status()`를 먼저 호출한 후 `handle_branch_creation()` 호출
2. **에러 처리**: 모든 함수의 반환값 확인 필수
3. **데이터 보존**: 라이브러리는 사용자 데이터를 절대 손실하지 않도록 설계됨
4. **병렬 작업**: Feature 브랜치에서 자동으로 Epic 브랜치를 찾아 분기

## 예제: 완전한 통합

```bash
#!/bin/bash
# Example: Complete integration

set -e

# Load libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/.claude/lib/git-status-checker.sh"
source "$SCRIPT_DIR/.claude/lib/branch-info-collector.sh"
source "$SCRIPT_DIR/.claude/lib/branch-state-handler.sh"
source "$SCRIPT_DIR/.claude/lib/git-operations.sh"

# Get branch name from argument
BRANCH_NAME="${1:-004-default-feature}"

# Check git status
check_git_status

# Handle branch creation
if ! handle_branch_creation "$BRANCH_NAME"; then
  error_msg "Branch creation failed or cancelled"
  safe_exit 1
fi

success_msg "Branch created successfully: $BRANCH_NAME"
success_msg "You can now continue with your workflow"
```

## 문의 및 지원

문제가 발생하면 테스트를 먼저 실행하여 라이브러리가 정상 작동하는지 확인하세요.

```bash
bash .claude/__tests__/us1-clean-state.test.sh
```

모든 테스트가 통과하면 라이브러리는 정상입니다.
