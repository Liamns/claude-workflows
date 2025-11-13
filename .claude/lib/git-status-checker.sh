#!/bin/bash
# Git Status Checker
# Functions for detecting Git working tree state

# ==============================================================================
# Global Variables (Set by check_git_status)
# ==============================================================================
GIT_STATUS_CLEAN=false
GIT_MODIFIED_FILES=()
GIT_UNTRACKED_FILES=()
GIT_STAGED_FILES=()
GIT_CURRENT_BRANCH=""
GIT_HAS_CONFLICTS=false

# ==============================================================================
# Color Functions
# ==============================================================================

# @description: Display success message in green
# @param: message - The message to display
success_msg() {
  local message="$1"
  echo -e "\033[0;32m ${message}\033[0m"
}

# @description: Display error message in red
# @param: message - The message to display
error_msg() {
  local message="$1"
  echo -e "\033[0;31m ${message}\033[0m"
}

# @description: Display warning message in yellow
# @param: message - The message to display
warn_msg() {
  local message="$1"
  echo -e "\033[1;33m  ${message}\033[0m"
}

# @description: Display info message in blue
# @param: message - The message to display
info_msg() {
  local message="$1"
  echo -e "\033[0;34m9 ${message}\033[0m"
}

# ==============================================================================
# Core Functions
# ==============================================================================

# @description: Check Git working tree status and populate global variables
# @return: Sets GIT_* global variables
check_git_status() {
  # Reset global variables
  GIT_STATUS_CLEAN=false
  GIT_MODIFIED_FILES=()
  GIT_UNTRACKED_FILES=()
  GIT_STAGED_FILES=()
  GIT_CURRENT_BRANCH=""
  GIT_HAS_CONFLICTS=false

  # Check if we're in a git repository
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    error_msg "Not a git repository"
    return 1
  fi

  # Get current branch
  GIT_CURRENT_BRANCH=$(git branch --show-current)

  # Get git status in porcelain format
  local status_output
  status_output=$(git status --porcelain)

  # Check if working tree is clean
  if [ -z "$status_output" ]; then
    GIT_STATUS_CLEAN=true
    return 0
  fi

  # Parse status output line by line
  while IFS= read -r line; do
    # Skip empty lines
    [ -z "$line" ] && continue

    # Extract status code (first 2 characters)
    local status_code="${line:0:2}"
    local file_path="${line:3}"

    # Detect conflicts (UU, AA, DD, AU, UA, DU, UD)
    if [[ "$status_code" =~ ^(UU|AA|DD|AU|UA|DU|UD) ]]; then
      GIT_HAS_CONFLICTS=true
      GIT_MODIFIED_FILES+=("$file_path")
    # Detect staged files (A , M , D , R , C )
    elif [[ "$status_code" =~ ^[AMDRC]. ]]; then
      GIT_STAGED_FILES+=("$file_path")
    # Detect modified but not staged ( M,  D)
    elif [[ "$status_code" =~ ^.[MD] ]]; then
      GIT_MODIFIED_FILES+=("$file_path")
    # Detect untracked files (??)
    elif [[ "$status_code" == "??" ]]; then
      GIT_UNTRACKED_FILES+=("$file_path")
    fi
  done <<< "$status_output"

  GIT_STATUS_CLEAN=false
  return 0
}

# @description: Count modified files (not staged)
# @return: Number of modified files
count_modified_files() {
  echo "${#GIT_MODIFIED_FILES[@]}"
}

# @description: Count untracked files
# @return: Number of untracked files
count_untracked_files() {
  echo "${#GIT_UNTRACKED_FILES[@]}"
}

# @description: Count staged files
# @return: Number of staged files
count_staged_files() {
  echo "${#GIT_STAGED_FILES[@]}"
}

# @description: List changed files (up to max_files)
# @param: max_files - Maximum number of files to list (default: 10)
# @return: List of file paths
list_changed_files() {
  local max_files="${1:-10}"
  local count=0

  # Combine all changed files
  local all_files=()
  all_files+=("${GIT_MODIFIED_FILES[@]}")
  all_files+=("${GIT_UNTRACKED_FILES[@]}")
  all_files+=("${GIT_STAGED_FILES[@]}")

  # Print up to max_files
  for file in "${all_files[@]}"; do
    if [ $count -ge $max_files ]; then
      echo "... and $((${#all_files[@]} - max_files)) more files"
      break
    fi
    echo "  $file"
    count=$((count + 1))
  done
}

# @description: Check for sensitive files that should not be committed
# @return: 0 if no sensitive files found, 1 if found
check_sensitive_files() {
  local sensitive_patterns=(
    "\.env$"
    "\.env\..*$"
    "credentials\.json$"
    "\.key$"
    "\.pem$"
    "\.p12$"
    "\.pfx$"
    "secret"
    "password"
    "token"
    "\.aws/credentials$"
    "\.ssh/id_"
  )

  local found_sensitive=false
  local sensitive_files=()

  # Check all changed files
  local all_files=()
  all_files+=("${GIT_MODIFIED_FILES[@]}")
  all_files+=("${GIT_UNTRACKED_FILES[@]}")
  all_files+=("${GIT_STAGED_FILES[@]}")

  for file in "${all_files[@]}"; do
    for pattern in "${sensitive_patterns[@]}"; do
      if echo "$file" | grep -qE "$pattern"; then
        sensitive_files+=("$file")
        found_sensitive=true
        break
      fi
    done
  done

  if [ "$found_sensitive" = true ]; then
    warn_msg "Sensitive files detected:"
    for file in "${sensitive_files[@]}"; do
      echo "    $file"
    done
    return 1
  fi

  return 0
}

# ==============================================================================
# Helper Functions
# ==============================================================================

# @description: Get total number of changed files
# @return: Total count
get_total_changed_files() {
  local total=0
  total=$((total + ${#GIT_MODIFIED_FILES[@]}))
  total=$((total + ${#GIT_UNTRACKED_FILES[@]}))
  total=$((total + ${#GIT_STAGED_FILES[@]}))
  echo "$total"
}

# @description: Display Git status summary
display_git_status_summary() {
  if [ "$GIT_STATUS_CLEAN" = true ]; then
    success_msg "Working tree is clean"
    return 0
  fi

  echo ""
  info_msg "Git Status Summary:"
  echo "  Current branch: $GIT_CURRENT_BRANCH"

  if [ ${#GIT_STAGED_FILES[@]} -gt 0 ]; then
    echo "  Staged files: ${#GIT_STAGED_FILES[@]}"
  fi

  if [ ${#GIT_MODIFIED_FILES[@]} -gt 0 ]; then
    echo "  Modified files: ${#GIT_MODIFIED_FILES[@]}"
  fi

  if [ ${#GIT_UNTRACKED_FILES[@]} -gt 0 ]; then
    echo "  Untracked files: ${#GIT_UNTRACKED_FILES[@]}"
  fi

  if [ "$GIT_HAS_CONFLICTS" = true ]; then
    error_msg "Conflicts detected!"
  fi

  echo ""
  echo "Changed files:"
  list_changed_files 10
  echo ""
}
