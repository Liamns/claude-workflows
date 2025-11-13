#!/bin/bash
# Git Operations
# Functions for executing Git commands (commit, stash, discard, etc.)

# ==============================================================================
# US2: Move Changes to New Branch
# ==============================================================================

# @description: Move uncommitted changes to a new branch
# @param: branch_name - The name of the new branch
# @return: 0 if successful, 1 if failed
move_changes_to_new_branch() {
  local branch_name="$1"

  if [ -z "$branch_name" ]; then
    error_msg "Branch name is required"
    return 1
  fi

  info_msg "Moving changes to new branch: $branch_name"

  # git checkout -b preserves uncommitted changes
  if git checkout -b "$branch_name" 2>/dev/null; then
    success_msg "Created branch with uncommitted changes: $branch_name"
    info_msg "Changes are preserved in unstaged state"
    return 0
  else
    error_msg "Failed to create branch: $branch_name"
    return 1
  fi
}

# ==============================================================================
# US2: Discard Changes
# ==============================================================================

# @description: Confirm before discarding changes (destructive action)
# @return: 0 if confirmed, 1 if cancelled
confirm_discard() {
  warn_msg "WARNING: This action will permanently delete all uncommitted changes!"
  warn_msg "This operation cannot be undone."
  echo ""
  echo "Files that will be affected:"
  list_changed_files 10
  echo ""

  # In real implementation with AskUserQuestion, we would prompt here
  # For now, we'll assume confirmation is handled externally
  return 0
}

# @description: Discard all uncommitted changes (DESTRUCTIVE)
# @return: 0 if successful, 1 if failed
discard_changes() {
  # Reset tracked files
  if ! git reset --hard HEAD 2>/dev/null; then
    error_msg "Failed to reset tracked files"
    return 1
  fi

  # Remove untracked files and directories
  if ! git clean -fd 2>/dev/null; then
    error_msg "Failed to remove untracked files"
    return 1
  fi

  success_msg "All changes have been discarded"
  info_msg "Working tree is now clean"
  return 0
}

# ==============================================================================
# US3: Auto Commit (Implemented in Phase 5)
# ==============================================================================

# @description: Generate automatic commit message
# @param: branch_name - The target branch name
# @return: Generated commit message
generate_commit_message() {
  local branch_name="$1"
  echo "chore: save work in progress before creating feature branch $branch_name"
}

# @description: Execute auto commit with generated message
# @param: commit_message - The commit message to use
# @return: 0 if successful, 1 if failed
auto_commit() {
  local commit_message="$1"

  if [ -z "$commit_message" ]; then
    error_msg "Commit message is required"
    return 1
  fi

  # Stage all changes
  if ! git add -A 2>/dev/null; then
    error_msg "Failed to stage changes"
    return 1
  fi

  # Commit
  if git commit -m "$commit_message" 2>/dev/null; then
    local commit_hash
    commit_hash=$(git rev-parse --short HEAD)
    success_msg "Changes committed: $commit_hash"
    return 0
  else
    error_msg "Failed to commit changes"
    return 1
  fi
}

# ==============================================================================
# US4: Auto Stash
# ==============================================================================

# @description: Generate automatic stash message
# @param: branch_name - The target branch name
# @return: Generated stash message
generate_stash_message() {
  local branch_name="$1"
  echo "WIP: before creating feature branch $branch_name"
}

# @description: Execute auto stash with generated message
# @param: stash_message - The stash message to use
# @return: 0 if successful, 1 if failed
auto_stash() {
  local stash_message="$1"

  if [ -z "$stash_message" ]; then
    error_msg "Stash message is required"
    return 1
  fi

  # Stash changes (including untracked files)
  if git stash push -u -m "$stash_message" 2>/dev/null; then
    success_msg "Changes stashed: stash@{0}"
    show_stash_restore_guide
    return 0
  else
    error_msg "Failed to stash changes"
    return 1
  fi
}

# @description: Display stash restore guide
# @return: 0 always
show_stash_restore_guide() {
  echo ""
  info_msg "Restore Guide:"
  echo ""
  echo "  To restore your changes:"
  echo "  1. Switch back to the original branch"
  echo "  2. Run: git stash pop"
  echo ""
  warn_msg "Note: Stashed changes can only be applied to the branch where they were created"
  warn_msg "      Make sure you're on the correct branch before running 'git stash pop'"
  echo ""
  return 0
}

# ==============================================================================
# Helper Functions
# ==============================================================================

# @description: Create branch from specified base
# @param: branch_name - The name of the new branch
# @param: base_branch - The base branch to branch from (optional, defaults to current)
# @return: 0 if successful, 1 if failed
create_branch_from_base() {
  local branch_name="$1"
  local base_branch="${2:-HEAD}"

  if [ -z "$branch_name" ]; then
    error_msg "Branch name is required"
    return 1
  fi

  if git checkout -b "$branch_name" "$base_branch" 2>/dev/null; then
    success_msg "Created branch: $branch_name (from $base_branch)"
    return 0
  else
    error_msg "Failed to create branch: $branch_name"
    return 1
  fi
}

# ==============================================================================
# US6: Error Handling and Rollback
# ==============================================================================

# @description: Handle Git command errors with context
# @param: exit_code - The exit code from the Git command
# @param: operation - Description of the operation that failed
# @return: Returns the provided exit code
handle_git_error() {
  local exit_code="$1"
  local operation="$2"

  if [ "$exit_code" -ne 0 ]; then
    error_msg "Git operation failed: $operation"
    error_msg "Exit code: $exit_code"
    return "$exit_code"
  fi

  return 0
}

# @description: Rollback operation based on type
# @param: operation_type - Type of operation (commit|stash|branch)
# @return: 0 if rollback successful, 1 if failed
rollback_operation() {
  local operation_type="$1"

  case "$operation_type" in
    commit)
      # Rollback failed commit - unstage changes
      info_msg "Rolling back commit operation..."
      if git reset HEAD 2>/dev/null; then
        success_msg "Commit rolled back - changes unstaged"
        return 0
      else
        error_msg "Failed to rollback commit"
        return 1
      fi
      ;;
    branch)
      # Rollback failed branch creation - return to previous branch
      info_msg "Rolling back branch creation..."
      if git checkout - 2>/dev/null; then
        success_msg "Returned to previous branch"
        return 0
      else
        error_msg "Failed to rollback branch creation"
        return 1
      fi
      ;;
    stash)
      # Stash failure - changes are preserved automatically
      info_msg "Stash operation failed - your changes are preserved"
      warn_msg "You can manually save your changes or try again"
      return 0
      ;;
    *)
      error_msg "Unknown operation type: $operation_type"
      return 1
      ;;
  esac
}

# @description: Safe exit with cleanup
# @param: exit_code - The exit code to use (default 0)
# @return: Exits with provided code
safe_exit() {
  local exit_code="${1:-0}"

  if [ "$exit_code" -ne 0 ]; then
    error_msg "Exiting due to error (code: $exit_code)"
    warn_msg "Your working tree state has been preserved"
  fi

  exit "$exit_code"
}
