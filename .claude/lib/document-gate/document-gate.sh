#!/usr/bin/env bash
# Document Gate - 문서 완성도 검증 시스템
# Feature 005: Epic 006 - Token Optimization Hybrid
#
# Usage: bash document-gate.sh <feature_directory>
#
# Validates:
# 1. File existence (spec.md, plan.md, tasks.md)
# 2. Template placeholders ({placeholder}, TODO:, FIXME:)
# 3. Required sections (file-specific)

set -euo pipefail

# ============================================
# Configuration
# ============================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Required files
REQUIRED_FILES=(
  "spec.md"
  "plan.md"
  "tasks.md"
)

# Placeholder patterns (regex)
PLACEHOLDER_PATTERNS=(
  '\{[^}]+\}'        # {placeholder}
  '\{\{[^}]+\}\}'    # {{placeholder}}
  'TODO:'            # TODO: marker
  'FIXME:'           # FIXME: marker
)

# Required sections for spec.md
SPEC_SECTIONS=(
  "## 📋 Feature 정보"
  "## 🎯 Overview"
  "## 🎬 User Scenarios & Testing"
  "## 🔍 Key Entities"
  "## ✅ Success Criteria"
)

# Required sections for plan.md
PLAN_SECTIONS=(
  "## Technical Foundation"
  "## Constitution Check"
  "## Phase 1: Design Artifacts"
  "## Implementation Phases"
  "## Performance Targets"
)

# Required sections for tasks.md
TASKS_SECTIONS=(
  "## Phase 1:"
  "### Tests (Write FIRST - TDD)"
  "### Implementation (AFTER tests)"
)

# ============================================
# Validation Functions (Stubs - to be implemented)
# ============================================

# Validate file existence
# Returns 0 if all files exist, 1 otherwise
validate_file_existence() {
  local feature_dir="$1"
  local missing_files=()

  for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$feature_dir/$file" ]; then
      missing_files+=("$file")
    fi
  done

  if [ ${#missing_files[@]} -gt 0 ]; then
    echo -e "${RED}✗${NC} Missing files:"
    for file in "${missing_files[@]}"; do
      echo -e "  - $file"
    done
    return 1
  fi

  echo -e "${GREEN}✓${NC} All required files present"
  return 0
}

# Validate placeholders
# Returns 0 if no placeholders found, 2 otherwise
validate_placeholders() {
  local feature_dir="$1"
  local has_placeholders=false
  # Improved pattern: match variable-like names only (alphanumeric + underscore)
  # - {placeholder}, {user_id}, {_var} etc.
  # - Excludes special chars like {, }, {1}, etc.
  local placeholder_pattern='\{[a-zA-Z_][a-zA-Z0-9_]*\}|\{\{[a-zA-Z_][a-zA-Z0-9_]*\}\}|TODO:|FIXME:'

  for file in "${REQUIRED_FILES[@]}"; do
    local file_path="$feature_dir/$file"

    # Skip if file doesn't exist (already checked in validate_file_existence)
    [ ! -f "$file_path" ] && continue

    # Process file line by line, excluding code blocks
    local in_code_block=false
    local line_num=0
    local file_has_matches=false

    while IFS= read -r line; do
      line_num=$((line_num + 1))

      # Detect code block start/end (lines starting with ```)
      if [[ $line =~ ^\`\`\` ]]; then
        if [ "$in_code_block" = true ]; then
          in_code_block=false
        else
          in_code_block=true
        fi
        continue
      fi

      # Skip lines inside code blocks
      if [ "$in_code_block" = true ]; then
        continue
      fi

      # Check for placeholder patterns (only outside code blocks)
      if [[ $line =~ $placeholder_pattern ]]; then
        if [ "$has_placeholders" = false ]; then
          echo -e "${RED}✗${NC} Template placeholders found:"
          has_placeholders=true
        fi
        if [ "$file_has_matches" = false ]; then
          echo -e "${YELLOW}  $file:${NC}"
          file_has_matches=true
        fi
        echo -e "    Line $line_num: ${line:0:80}..."
      fi
    done < "$file_path"
  done

  if [ "$has_placeholders" = true ]; then
    return 2
  fi

  echo -e "${GREEN}✓${NC} No template placeholders found"
  return 0
}

# Validate required sections
# Returns 0 if all sections present, 3 otherwise
validate_required_sections() {
  local feature_dir="$1"
  local has_missing=false
  local missing_sections=()

  # Validate spec.md sections
  if [ -f "$feature_dir/spec.md" ]; then
    for section in "${SPEC_SECTIONS[@]}"; do
      if ! grep -q "^$section" "$feature_dir/spec.md"; then
        missing_sections+=("spec.md: $section")
        has_missing=true
      fi
    done
  fi

  # Validate plan.md sections
  if [ -f "$feature_dir/plan.md" ]; then
    for section in "${PLAN_SECTIONS[@]}"; do
      if ! grep -q "^$section" "$feature_dir/plan.md"; then
        missing_sections+=("plan.md: $section")
        has_missing=true
      fi
    done
  fi

  # Validate tasks.md sections
  if [ -f "$feature_dir/tasks.md" ]; then
    for section in "${TASKS_SECTIONS[@]}"; do
      if ! grep -q "^$section" "$feature_dir/tasks.md"; then
        missing_sections+=("tasks.md: $section")
        has_missing=true
      fi
    done
  fi

  if [ "$has_missing" = true ]; then
    echo -e "${RED}✗${NC} Missing required sections:"
    for section in "${missing_sections[@]}"; do
      echo -e "  - $section"
    done
    return 3
  fi

  echo -e "${GREEN}✓${NC} All required sections present"
  return 0
}

# Generate validation report
generate_report() {
  local feature_dir="$1"
  local exit_code="$2"

  echo -e "${BLUE}==========================================${NC}"
  echo "Validation Summary"
  echo -e "${BLUE}==========================================${NC}"
  echo -e "Feature Directory: ${CYAN}$feature_dir${NC}"
  echo ""

  if [ "$exit_code" -eq 0 ]; then
    echo -e "${GREEN}✅ All validations passed:${NC}"
    echo "  ✓ File existence check"
    echo "  ✓ Placeholder detection"
    echo "  ✓ Required sections"
  else
    echo -e "${RED}❌ Validation failed:${NC}"
    if [ "$exit_code" -eq 1 ]; then
      echo "  ✗ Missing required files"
      echo ""
      echo "Action: Create missing files using Feature 003 templates"
    elif [ "$exit_code" -eq 2 ]; then
      echo "  ✗ Template placeholders found"
      echo ""
      echo "Action: Replace all {placeholders} with actual content"
      echo "        Remove all TODO: and FIXME: markers"
    elif [ "$exit_code" -eq 3 ]; then
      echo "  ✗ Missing required sections"
      echo ""
      echo "Action: Add missing sections to planning documents"
    fi
  fi
  echo ""
}

# ============================================
# Main Logic
# ============================================

main() {
  # Parse arguments
  if [ $# -eq 0 ]; then
    echo -e "${RED}Error: Feature directory required${NC}"
    echo "Usage: $0 <feature_directory>"
    echo ""
    echo "Example:"
    echo "  $0 .specify/epics/006/features/004/"
    exit 1
  fi

  local feature_dir="$1"

  # Validate directory exists
  if [ ! -d "$feature_dir" ]; then
    echo -e "${RED}Error: Directory not found: $feature_dir${NC}"
    exit 1
  fi

  echo -e "${BLUE}=========================================="
  echo "Document Gate - Validation Report"
  echo -e "==========================================${NC}"
  echo -e "Feature Directory: ${CYAN}$feature_dir${NC}"
  echo ""

  # Run validations (short-circuit on first failure)
  local exit_code=0

  # Step 1: File existence
  echo -e "${YELLOW}[1/3]${NC} Validating file existence..."
  if ! validate_file_existence "$feature_dir"; then
    exit_code=1
  fi

  # Step 2: Placeholders (only if step 1 passed)
  if [ "$exit_code" -eq 0 ]; then
    echo -e "${YELLOW}[2/3]${NC} Detecting template placeholders..."
    if ! validate_placeholders "$feature_dir"; then
      exit_code=2
    fi
  fi

  # Step 3: Required sections (only if steps 1 and 2 passed)
  if [ "$exit_code" -eq 0 ]; then
    echo -e "${YELLOW}[3/3]${NC} Validating required sections..."
    if ! validate_required_sections "$feature_dir"; then
      exit_code=3
    fi
  fi

  # Generate report
  echo ""
  generate_report "$feature_dir" "$exit_code"

  # Exit with appropriate code
  if [ "$exit_code" -eq 0 ]; then
    echo -e "${GREEN}✅ Document Gate Passed${NC}"
    echo ""
    echo "All planning documents are complete."
    echo "You may proceed to implementation."
    exit 0
  else
    echo -e "${RED}❌ Document Gate Failed${NC}"
    echo ""
    echo "Please complete the planning documents before proceeding."
    echo "See errors above for details."
    exit "$exit_code"
  fi
}

# Run main function (skip if sourced for testing)
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  main "$@"
fi
