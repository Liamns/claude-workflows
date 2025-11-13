#!/bin/bash
# Branch State Handler
# Functions for handling different Git working tree states and user interactions

# Ensure git-status-checker.sh is sourced for message functions
# source "$(dirname "${BASH_SOURCE[0]}")/git-status-checker.sh"

# ==============================================================================
# US1: Clean State Handling
# ==============================================================================

# @description: Handle clean working tree state - create branch immediately
# @param: branch_name - The name of the branch to create
# @return: 0 if successful, 1 if failed
handle_clean_state() {
  local branch_name="$1"

  if [ -z "$branch_name" ]; then
    error_msg "Branch name is required"
    return 1
  fi

  # Display success message
  success_msg "Working tree is clean. Creating new branch..."

  # Create and checkout new branch
  if git checkout -b "$branch_name" 2>/dev/null; then
    success_msg "Branch created successfully: $branch_name"
    return 0
  else
    error_msg "Failed to create branch: $branch_name"
    error_msg "Branch may already exist or cannot be created."
    return 1
  fi
}

# ==============================================================================
# US2: Dirty State Handling
# ==============================================================================

# @description: Ask user for action when working tree is dirty
# @param: branch_name - The name of the branch to create
# @return: User choice (commit|move|stash|discard|cancel)
ask_user_action() {
  local branch_name="$1"

  # Display file summary
  display_git_status_summary

  # Check for untracked files and warn if present
  if [ ${#GIT_UNTRACKED_FILES[@]} -gt 0 ]; then
    warn_msg "Untracked files detected: ${#GIT_UNTRACKED_FILES[@]} files"
  fi

  # Check for sensitive files
  check_sensitive_files || true  # Continue even if sensitive files found

  echo ""
  info_msg "Choose how to handle uncommitted changes:"
  echo ""
  echo "  1. Commit and continue    - Commit changes to current branch"
  echo "  2. Move with changes      - Create new branch with uncommitted changes"
  echo "  3. Stash and continue     - Temporarily save changes"
  echo "  4. Discard and continue   - DELETE all changes (WARNING: cannot undo)"
  echo "  5. Cancel                 - Stop workflow"
  echo ""

  # TODO: In Phase 9, integrate with AskUserQuestion tool
  # For now, return a default action for testing
  echo "commit"
}

# @description: Handle dirty working tree state - provide user choices
# @param: branch_name - The name of the branch to create
# @return: 0 if successful, 1 if cancelled or failed
handle_dirty_state() {
  local branch_name="$1"

  if [ -z "$branch_name" ]; then
    error_msg "Branch name is required"
    return 1
  fi

  # Get user choice
  local user_choice
  user_choice=$(ask_user_action "$branch_name")

  # Execute based on user choice
  case "$user_choice" in
    commit)
      info_msg "Option 1: Commit and continue"
      # Generate commit message
      local commit_msg
      commit_msg=$(generate_commit_message "$branch_name")

      # Ask user to review commit message
      local reviewed_msg
      reviewed_msg=$(ask_commit_message_review "$commit_msg")

      # Check if user cancelled
      if [ -z "$reviewed_msg" ]; then
        warn_msg "Commit cancelled by user"
        return 1
      fi

      # Auto commit with reviewed message
      if auto_commit "$reviewed_msg"; then
        # Now create the new branch
        handle_clean_state "$branch_name"
        return $?
      else
        error_msg "Failed to commit changes"
        return 1
      fi
      ;;
    move|move-with-changes)
      info_msg "Option 2: Move with changes to new branch"
      move_changes_to_new_branch "$branch_name"
      return $?
      ;;
    stash)
      info_msg "Option 3: Stash and continue"
      # Generate stash message
      local stash_msg
      stash_msg=$(generate_stash_message "$branch_name")
      # Auto stash
      if auto_stash "$stash_msg"; then
        # Now create the new branch
        handle_clean_state "$branch_name"
        return $?
      else
        error_msg "Failed to stash changes"
        return 1
      fi
      ;;
    discard)
      warn_msg "Option 4: Discard and continue"
      # Confirm before discarding
      if confirm_discard; then
        if discard_changes; then
          # Now create the new branch
          handle_clean_state "$branch_name"
          return $?
        else
          error_msg "Failed to discard changes"
          return 1
        fi
      else
        info_msg "Discard cancelled by user"
        return 1
      fi
      ;;
    cancel|*)
      info_msg "Workflow cancelled by user"
      return 1
      ;;
  esac
}

# ==============================================================================
# US3: Commit with Review
# ==============================================================================

# @description: Ask user to review and confirm commit message
# @param: auto_generated_message - The automatically generated commit message
# @return: Final commit message or empty string if cancelled
ask_commit_message_review() {
  local auto_generated_message="$1"

  if [ -z "$auto_generated_message" ]; then
    error_msg "Commit message is required"
    return 1
  fi

  # Display the auto-generated message
  echo ""
  info_msg "Auto-generated commit message:"
  echo ""
  echo "  $auto_generated_message"
  echo ""

  # Display options
  info_msg "Choose an action:"
  echo ""
  echo "  1. Use this message    - Commit with the suggested message"
  echo "  2. Edit message        - Modify the commit message"
  echo "  3. Cancel              - Return to previous menu"
  echo ""

  # TODO: In Phase 9, integrate with AskUserQuestion tool
  # For now, return the auto-generated message (simulate "accept" action)
  #
  # Expected AskUserQuestion integration:
  # - Question: "Choose an action for the commit message:"
  # - Options:
  #   1. label: "Use this message", description: "Commit with the suggested message"
  #   2. label: "Edit message", description: "Modify the commit message"
  #   3. label: "Cancel", description: "Return to previous menu"
  #
  # Based on user selection:
  # - "Use this message" -> return auto_generated_message
  # - "Edit message" -> prompt for text input, return user's message
  # - "Cancel" or "Other" -> return empty string

  # Simulate default action (accept)
  echo "$auto_generated_message"
}

# ==============================================================================
# US2: Untracked Files Handling
# ==============================================================================

# @description: Display warning for untracked files
# @return: 0 always (warning only, doesn't block)
ask_untracked_files_handling() {
  if [ ${#GIT_UNTRACKED_FILES[@]} -gt 0 ]; then
    warn_msg "Untracked files will be included in the selected action:"
    for file in "${GIT_UNTRACKED_FILES[@]}"; do
      echo "  - $file"
    done
    echo ""
  fi
  return 0
}

# ==============================================================================
# US5: Parallel Work Support
# ==============================================================================

# @description: Warn user about parallel work scenario
# @param: current_branch - The current Feature branch name
# @param: new_branch - The new branch name being created
# @return: 0 always (warning only, doesn't block)
warn_parallel_work() {
  local current_branch="$1"
  local new_branch="$2"

  echo ""
  warn_msg "Parallel Work Detected!"
  echo ""
  echo "  You are currently on: $current_branch"
  echo "  Creating new branch:  $new_branch"
  echo ""
  info_msg "The new branch will be created from the Epic branch to avoid conflicts."
  info_msg "Your work on '$current_branch' will not be affected."
  echo ""

  return 0
}

# ==============================================================================
# Helper Functions
# ==============================================================================

# @description: Main entry point - detect state and route to appropriate handler
# @param: branch_name - The name of the branch to create
# @return: 0 if successful, 1 if failed
handle_branch_creation() {
  local branch_name="$1"

  if [ -z "$branch_name" ]; then
    error_msg "Branch name is required"
    return 1
  fi

  # US5: Check for parallel work scenario
  # Get current branch info
  get_branch_info

  # If we're on a Feature branch, create new branch from Epic branch
  if is_feature_branch "$BRANCH_NAME"; then
    local epic_branch
    epic_branch=$(find_epic_branch)

    if [ -n "$epic_branch" ]; then
      # Warn about parallel work
      warn_parallel_work "$BRANCH_NAME" "$branch_name"

      # Check git status
      if [ "$GIT_STATUS_CLEAN" = "true" ]; then
        # Clean state - create branch from Epic directly
        if create_branch_from_base "$branch_name" "$epic_branch"; then
          success_msg "Branch created from Epic: $branch_name"
          return 0
        else
          error_msg "Failed to create branch from Epic"
          return 1
        fi
      else
        # Dirty state - handle changes first, then create from Epic
        if handle_dirty_state "$branch_name"; then
          # After handling dirty state, create from Epic
          if create_branch_from_base "$branch_name" "$epic_branch"; then
            success_msg "Branch created from Epic: $branch_name"
            return 0
          else
            error_msg "Failed to create branch from Epic"
            return 1
          fi
        else
          return 1
        fi
      fi
    else
      warn_msg "Epic branch not found. Creating branch from current location."
      # Fall through to normal workflow
    fi
  fi

  # Normal workflow (not on Feature branch, or Epic not found)
  # Check git status (assumes check_git_status has been called)
  if [ "$GIT_STATUS_CLEAN" = "true" ]; then
    # US1: Clean state - create branch immediately
    handle_clean_state "$branch_name"
    return $?
  else
    # US2: Dirty state - provide user choices
    handle_dirty_state "$branch_name"
    return $?
  fi
}
