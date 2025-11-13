#!/bin/bash
# Branch Info Collector
# Functions for collecting and analyzing Git branch information

# ==============================================================================
# Global Variables (Set by get_branch_info)
# ==============================================================================
BRANCH_NAME=""
BRANCH_IS_FEATURE=false
BRANCH_IS_EPIC=false
BRANCH_PARENT_EPIC=""

# ==============================================================================
# Core Functions
# ==============================================================================

# @description: Get current branch information and populate global variables
# @return: Sets BRANCH_* global variables
get_branch_info() {
  # Reset global variables
  BRANCH_NAME=""
  BRANCH_IS_FEATURE=false
  BRANCH_IS_EPIC=false
  BRANCH_PARENT_EPIC=""

  # Check if we're in a git repository
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    return 1
  fi

  # Get current branch name
  BRANCH_NAME=$(git branch --show-current)

  # Check if current branch is empty (detached HEAD)
  if [ -z "$BRANCH_NAME" ]; then
    return 1
  fi

  # Check if it's an Epic branch (NNN-epic-*)
  if is_epic_branch "$BRANCH_NAME"; then
    BRANCH_IS_EPIC=true
    BRANCH_PARENT_EPIC=""
    return 0
  fi

  # Check if it's a Feature branch (NNN-*)
  if is_feature_branch "$BRANCH_NAME"; then
    BRANCH_IS_FEATURE=true
    # Try to find parent Epic branch
    BRANCH_PARENT_EPIC=$(find_epic_branch)
    return 0
  fi

  return 0
}

# @description: Check if a branch name matches Feature branch pattern (NNN-*)
# @param: branch_name - The branch name to check (optional, uses BRANCH_NAME if not provided)
# @return: 0 if feature branch, 1 if not
is_feature_branch() {
  local branch_name="${1:-$BRANCH_NAME}"

  # Feature branch pattern: NNN-* (but NOT NNN-epic-*)
  if echo "$branch_name" | grep -qE "^[0-9]{3}-" && ! echo "$branch_name" | grep -qE "^[0-9]{3}-epic-"; then
    return 0
  else
    return 1
  fi
}

# @description: Check if a branch name matches Epic branch pattern (NNN-epic-*)
# @param: branch_name - The branch name to check (optional, uses BRANCH_NAME if not provided)
# @return: 0 if epic branch, 1 if not
is_epic_branch() {
  local branch_name="${1:-$BRANCH_NAME}"

  # Epic branch pattern: NNN-epic-*
  if echo "$branch_name" | grep -qE "^[0-9]{3}-epic-"; then
    return 0
  else
    return 1
  fi
}

# @description: Find an Epic branch in the repository
# @return: Epic branch name if found, empty string if not found
find_epic_branch() {
  # List all branches and find one matching NNN-epic-* pattern
  local epic_branch
  epic_branch=$(git branch --list | grep -E "^\*?\s+[0-9]{3}-epic-" | sed 's/^[\* ]*//g' | head -1)

  echo "$epic_branch"
}

# @description: Calculate working tree state based on Git status
# @return: Sets WORKING_TREE_* global variables
calculate_working_tree_state() {
  # This function requires git-status-checker.sh to be sourced
  # Ensure check_git_status() has been called first

  local status="dirty"
  local total_files=0
  local requires_action=false
  local recommended_action=""

  # Check if GIT_STATUS_CLEAN is set
  if [ "$GIT_STATUS_CLEAN" = true ]; then
    status="clean"
    total_files=0
    requires_action=false
    recommended_action=""
  elif [ "$GIT_HAS_CONFLICTS" = true ]; then
    status="conflicted"
    total_files=$(get_total_changed_files 2>/dev/null || echo "0")
    requires_action=true
    recommended_action="resolve-conflicts"
  else
    status="dirty"
    total_files=$(get_total_changed_files 2>/dev/null || echo "0")
    requires_action=true

    # Recommend action based on file types
    if [ ${#GIT_STAGED_FILES[@]} -gt 0 ]; then
      recommended_action="commit"
    elif [ ${#GIT_MODIFIED_FILES[@]} -gt 0 ]; then
      recommended_action="commit"
    elif [ ${#GIT_UNTRACKED_FILES[@]} -gt 0 ]; then
      recommended_action="stash"
    else
      recommended_action="commit"
    fi
  fi

  # Export as global variables
  WORKING_TREE_STATUS="$status"
  WORKING_TREE_CHANGED_FILES="$total_files"
  WORKING_TREE_REQUIRES_ACTION="$requires_action"
  WORKING_TREE_RECOMMENDED_ACTION="$recommended_action"
}

# ==============================================================================
# Helper Functions
# ==============================================================================

# @description: Display branch information summary
display_branch_info() {
  echo ""
  echo "Branch Information:"
  echo "  Name: $BRANCH_NAME"

  if [ "$BRANCH_IS_EPIC" = true ]; then
    echo "  Type: Epic Branch"
  elif [ "$BRANCH_IS_FEATURE" = true ]; then
    echo "  Type: Feature Branch"
    if [ -n "$BRANCH_PARENT_EPIC" ]; then
      echo "  Parent Epic: $BRANCH_PARENT_EPIC"
    else
      echo "  Parent Epic: (not found)"
    fi
  else
    echo "  Type: Other"
  fi
  echo ""
}

# @description: Get branch type as string
# @return: "epic", "feature", or "other"
get_branch_type() {
  if [ "$BRANCH_IS_EPIC" = true ]; then
    echo "epic"
  elif [ "$BRANCH_IS_FEATURE" = true ]; then
    echo "feature"
  else
    echo "other"
  fi
}

# @description: Check if current branch is safe to create new branch from
# @return: 0 if safe, 1 if not safe (should branch from Epic instead)
is_safe_to_branch_from_current() {
  # If current branch is Epic, it's safe
  if [ "$BRANCH_IS_EPIC" = true ]; then
    return 0
  fi

  # If current branch is Feature and there's an Epic, should branch from Epic
  if [ "$BRANCH_IS_FEATURE" = true ] && [ -n "$BRANCH_PARENT_EPIC" ]; then
    return 1
  fi

  # For other branches (main, etc.), it's safe
  return 0
}

# @description: Get recommended branch base for new feature
# @return: Branch name to branch from
get_recommended_branch_base() {
  # If on Feature branch, recommend Epic branch
  if [ "$BRANCH_IS_FEATURE" = true ] && [ -n "$BRANCH_PARENT_EPIC" ]; then
    echo "$BRANCH_PARENT_EPIC"
    return 0
  fi

  # Otherwise, use current branch
  echo "$BRANCH_NAME"
  return 0
}
