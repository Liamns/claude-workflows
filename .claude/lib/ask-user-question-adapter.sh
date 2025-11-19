#!/bin/bash
# AskUserQuestion Adapter
# Converts YAML prompts and shell menus to AskUserQuestion tool format
# Usage: Source this file and call conversion functions

# ==============================================================================
# Source Common Functions
# ==============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/git-status-checker.sh"

# ==============================================================================
# Dependencies Check
# ==============================================================================

# @description: Check if required tools are installed
check_dependencies() {
  local missing_deps=()

  if ! command -v yq &> /dev/null; then
    missing_deps+=("yq")
  fi

  if ! command -v jq &> /dev/null; then
    missing_deps+=("jq")
  fi

  if [ ${#missing_deps[@]} -gt 0 ]; then
    error_msg "Missing dependencies: ${missing_deps[*]}"
    error_msg "Install with: brew install ${missing_deps[*]}"
    return 1
  fi

  return 0
}

# ==============================================================================
# YAML to AskUserQuestion Conversion
# ==============================================================================

# @description: Convert YAML prompts to AskUserQuestion JSON format
# @param: yaml_file - Path to YAML config file
# @param: prompt_key - YAML key path (e.g., "prompts.initial_questions")
# @output: JSON string compatible with AskUserQuestion tool
# @example: convert_yaml_to_askuserquestion "triage.yaml" "prompts.initial_questions"
convert_yaml_to_askuserquestion() {
  local yaml_file="$1"
  local prompt_key="$2"

  # Validate inputs
  if [[ ! -f "$yaml_file" ]]; then
    error_msg "YAML file not found: $yaml_file"
    return 1
  fi

  if [[ -z "$prompt_key" ]]; then
    error_msg "Prompt key is required"
    return 1
  fi

  # Check dependencies
  check_dependencies || return 1

  # Extract prompts from YAML
  local prompts_json
  prompts_json=$(yq e ".${prompt_key}" "$yaml_file" -o=json 2>/dev/null)

  if [[ -z "$prompts_json" || "$prompts_json" == "null" ]]; then
    error_msg "Prompt key not found in YAML: $prompt_key"
    return 1
  fi

  # Convert to AskUserQuestion format
  local questions_json
  questions_json=$(echo "$prompts_json" | jq '[
    .[] | {
      question: .question,
      header: .header,
      multiSelect: (.multiSelect // false),
      options: [
        .options[] | {
          label: .label,
          description: .description
        }
      ]
    }
  ]')

  # Validate question count (1-4)
  local question_count
  question_count=$(echo "$questions_json" | jq 'length')

  if [[ $question_count -lt 1 || $question_count -gt 4 ]]; then
    error_msg "AskUserQuestion requires 1-4 questions, got: $question_count"
    return 1
  fi

  # Validate each question has 2-4 options
  local invalid_options
  invalid_options=$(echo "$questions_json" | jq '[.[] | select((.options | length) < 2 or (.options | length) > 4)] | length')

  if [[ $invalid_options -gt 0 ]]; then
    error_msg "Each question must have 2-4 options"
    return 1
  fi

  # Output formatted JSON
  echo "$questions_json" | jq '.'
  return 0
}

# ==============================================================================
# Shell Menu to AskUserQuestion Conversion
# ==============================================================================

# @description: Convert shell menu to AskUserQuestion JSON format
# @param: menu_title - Question text
# @param: menu_header - Short header (max 12 chars)
# @param: multi_select - true/false for multiSelect
# @param: options_array - Array of "label|description" strings
# @output: JSON string compatible with AskUserQuestion tool
# @example:
#   options=(
#     "커밋 후 계속|현재 변경사항을 커밋하고 워크플로우 계속"
#     "Stash 후 계속|변경사항을 stash하고 워크플로우 계속"
#   )
#   convert_shell_menu_to_askuserquestion \
#     "어떻게 처리하시겠습니까?" \
#     "Branch State" \
#     "false" \
#     "${options[@]}"
convert_shell_menu_to_askuserquestion() {
  local menu_title="$1"
  local menu_header="$2"
  local multi_select="$3"
  shift 3
  local options_array=("$@")

  # Validate inputs
  if [[ -z "$menu_title" ]]; then
    error_msg "Menu title is required"
    return 1
  fi

  if [[ -z "$menu_header" ]]; then
    error_msg "Menu header is required"
    return 1
  fi

  if [[ ${#menu_header} -gt 12 ]]; then
    error_msg "Menu header must be max 12 characters, got: ${#menu_header}"
    return 1
  fi

  if [[ "$multi_select" != "true" && "$multi_select" != "false" ]]; then
    error_msg "multi_select must be 'true' or 'false', got: $multi_select"
    return 1
  fi

  if [[ ${#options_array[@]} -lt 2 || ${#options_array[@]} -gt 4 ]]; then
    error_msg "Must have 2-4 options, got: ${#options_array[@]}"
    return 1
  fi

  # Check dependencies
  check_dependencies || return 1

  # Build options JSON array
  local options_json="[]"
  for option in "${options_array[@]}"; do
    # Split by | delimiter
    IFS='|' read -r label description <<< "$option"

    if [[ -z "$label" || -z "$description" ]]; then
      error_msg "Invalid option format (must be 'label|description'): $option"
      return 1
    fi

    # Add to JSON array
    options_json=$(echo "$options_json" | jq \
      --arg label "$label" \
      --arg desc "$description" \
      '. += [{label: $label, description: $desc}]')
  done

  # Build complete question JSON
  local question_json
  question_json=$(jq -n \
    --arg question "$menu_title" \
    --arg header "$menu_header" \
    --argjson multiSelect "$multi_select" \
    --argjson options "$options_json" \
    '[{
      question: $question,
      header: $header,
      multiSelect: $multiSelect,
      options: $options
    }]')

  # Output formatted JSON
  echo "$question_json" | jq '.'
  return 0
}

# ==============================================================================
# Response Formatting
# ==============================================================================

# @description: Parse AskUserQuestion response and format for script use
# @param: response_json - JSON response from AskUserQuestion tool
# @param: question_index - Which question to extract (0-based, default: 0)
# @output: Selected option label(s), one per line
# @example:
#   response='{"0": "Major"}'
#   format_askuserquestion_response "$response" 0
#   # Output: Major
format_askuserquestion_response() {
  local response_json="$1"
  local question_index="${2:-0}"

  # Validate inputs
  if [[ -z "$response_json" ]]; then
    error_msg "Response JSON is required"
    return 1
  fi

  # Check dependencies
  check_dependencies || return 1

  # Validate JSON format
  if ! echo "$response_json" | jq empty 2>/dev/null; then
    error_msg "Invalid JSON response"
    return 1
  fi

  # Extract response for specified question index
  local selected_values
  selected_values=$(echo "$response_json" | jq -r ".[\"$question_index\"] // empty")

  if [[ -z "$selected_values" ]]; then
    error_msg "No response found for question index: $question_index"
    return 1
  fi

  # Handle both single value (string) and multiple values (array)
  if echo "$selected_values" | jq -e 'type == "array"' >/dev/null 2>&1; then
    # Multiple selections (multiSelect: true)
    echo "$selected_values" | jq -r '.[]'
  else
    # Single selection
    echo "$selected_values"
  fi

  return 0
}

# ==============================================================================
# Utility Functions
# ==============================================================================

# @description: Generate Claude-friendly markdown for AskUserQuestion
# @param: questions_json - JSON array of questions
# @output: Markdown text to be added to .md command files
# @example: generate_askuserquestion_markdown "$questions_json"
generate_askuserquestion_markdown() {
  local questions_json="$1"

  if [[ -z "$questions_json" ]]; then
    error_msg "Questions JSON is required"
    return 1
  fi

  # Check dependencies
  check_dependencies || return 1

  # Validate JSON
  if ! echo "$questions_json" | jq empty 2>/dev/null; then
    error_msg "Invalid JSON"
    return 1
  fi

  cat << 'EOF'
## User Questions

Use the AskUserQuestion tool to collect user input:

```json
EOF

  echo "$questions_json" | jq '.'

  cat << 'EOF'
```

Process the response with:
```bash
response='{"0": "selected_option"}'
selected=$(format_askuserquestion_response "$response" 0)
```
EOF

  return 0
}

# @description: Validate AskUserQuestion JSON structure
# @param: questions_json - JSON to validate
# @return: 0 if valid, 1 if invalid
validate_askuserquestion_json() {
  local questions_json="$1"

  if [[ -z "$questions_json" ]]; then
    error_msg "Questions JSON is required"
    return 1
  fi

  # Check dependencies
  check_dependencies || return 1

  # Validate JSON syntax
  if ! echo "$questions_json" | jq empty 2>/dev/null; then
    error_msg "Invalid JSON syntax"
    return 1
  fi

  # Check if it's an array
  if ! echo "$questions_json" | jq -e 'type == "array"' >/dev/null 2>&1; then
    error_msg "Questions must be an array"
    return 1
  fi

  # Check question count (1-4)
  local question_count
  question_count=$(echo "$questions_json" | jq 'length')

  if [[ $question_count -lt 1 || $question_count -gt 4 ]]; then
    error_msg "Must have 1-4 questions, got: $question_count"
    return 1
  fi

  # Validate each question structure
  local validation_errors
  validation_errors=$(echo "$questions_json" | jq -r '
    .[] |
    select(
      (.question | type) != "string" or
      (.header | type) != "string" or
      (.multiSelect | type) != "boolean" or
      (.options | type) != "array" or
      (.options | length) < 2 or
      (.options | length) > 4
    ) |
    "Invalid question structure"
  ')

  if [[ -n "$validation_errors" ]]; then
    error_msg "$validation_errors"
    return 1
  fi

  # Validate header length (max 12 chars)
  local invalid_headers
  invalid_headers=$(echo "$questions_json" | jq -r '
    .[] |
    select((.header | length) > 12) |
    .header
  ')

  if [[ -n "$invalid_headers" ]]; then
    error_msg "Header too long (max 12 chars): $invalid_headers"
    return 1
  fi

  # Validate option structure
  local invalid_options
  invalid_options=$(echo "$questions_json" | jq -r '
    .[].options[] |
    select(
      (.label | type) != "string" or
      (.description | type) != "string"
    ) |
    "Invalid option structure"
  ')

  if [[ -n "$invalid_options" ]]; then
    error_msg "$invalid_options"
    return 1
  fi

  success_msg "AskUserQuestion JSON is valid"
  return 0
}

# ==============================================================================
# Self-Test
# ==============================================================================

# @description: Run self-tests for all functions
# @return: 0 if all tests pass, 1 if any test fails
run_self_tests() {
  local tests_passed=0
  local tests_failed=0

  info_msg "Running AskUserQuestion Adapter self-tests..."
  echo ""

  # Test 1: Dependency check
  echo "Test 1: Dependency check"
  if check_dependencies; then
    success_msg "✓ Dependencies OK"
    ((tests_passed++))
  else
    error_msg "✗ Dependencies missing"
    ((tests_failed++))
  fi
  echo ""

  # Test 2: Shell menu conversion
  echo "Test 2: Shell menu conversion"
  local test_options=(
    "Option A|Description for A"
    "Option B|Description for B"
    "Option C|Description for C"
  )
  local result
  result=$(convert_shell_menu_to_askuserquestion \
    "Test question?" \
    "Test Header" \
    "false" \
    "${test_options[@]}")

  if [[ $? -eq 0 ]] && validate_askuserquestion_json "$result"; then
    success_msg "✓ Shell menu conversion OK"
    ((tests_passed++))
  else
    error_msg "✗ Shell menu conversion failed"
    ((tests_failed++))
  fi
  echo ""

  # Test 3: Response formatting (single selection)
  echo "Test 3: Response formatting (single)"
  local test_response='{"0": "Major"}'
  local formatted
  formatted=$(format_askuserquestion_response "$test_response" 0)

  if [[ "$formatted" == "Major" ]]; then
    success_msg "✓ Response formatting (single) OK"
    ((tests_passed++))
  else
    error_msg "✗ Response formatting (single) failed: got '$formatted'"
    ((tests_failed++))
  fi
  echo ""

  # Test 4: Response formatting (multi selection)
  echo "Test 4: Response formatting (multi)"
  local test_response_multi='{"0": ["Option A", "Option B"]}'
  local formatted_multi
  formatted_multi=$(format_askuserquestion_response "$test_response_multi" 0)

  if [[ "$formatted_multi" == $'Option A\nOption B' ]]; then
    success_msg "✓ Response formatting (multi) OK"
    ((tests_passed++))
  else
    error_msg "✗ Response formatting (multi) failed"
    ((tests_failed++))
  fi
  echo ""

  # Test 5: JSON validation (valid)
  echo "Test 5: JSON validation (valid)"
  local valid_json='[{
    "question": "Test?",
    "header": "Test",
    "multiSelect": false,
    "options": [
      {"label": "A", "description": "Option A"},
      {"label": "B", "description": "Option B"}
    ]
  }]'

  if validate_askuserquestion_json "$valid_json" >/dev/null 2>&1; then
    success_msg "✓ JSON validation (valid) OK"
    ((tests_passed++))
  else
    error_msg "✗ JSON validation (valid) failed"
    ((tests_failed++))
  fi
  echo ""

  # Test 6: JSON validation (invalid - too many questions)
  echo "Test 6: JSON validation (invalid - 5 questions)"
  local invalid_json='[
    {"question": "Q1?", "header": "H1", "multiSelect": false, "options": [{"label": "A", "description": "A"}]},
    {"question": "Q2?", "header": "H2", "multiSelect": false, "options": [{"label": "A", "description": "A"}]},
    {"question": "Q3?", "header": "H3", "multiSelect": false, "options": [{"label": "A", "description": "A"}]},
    {"question": "Q4?", "header": "H4", "multiSelect": false, "options": [{"label": "A", "description": "A"}]},
    {"question": "Q5?", "header": "H5", "multiSelect": false, "options": [{"label": "A", "description": "A"}]}
  ]'

  if ! validate_askuserquestion_json "$invalid_json" >/dev/null 2>&1; then
    success_msg "✓ JSON validation (invalid) correctly rejected"
    ((tests_passed++))
  else
    error_msg "✗ JSON validation (invalid) incorrectly accepted"
    ((tests_failed++))
  fi
  echo ""

  # Summary
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Test Results: $tests_passed passed, $tests_failed failed"

  if [[ $tests_failed -eq 0 ]]; then
    success_msg "All tests passed! ✓"
    return 0
  else
    error_msg "Some tests failed! ✗"
    return 1
  fi
}

# ==============================================================================
# Main (for testing)
# ==============================================================================

# If script is executed directly (not sourced), run self-tests
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_self_tests
  exit $?
fi
