#!/usr/bin/env bash
#
# test-sync-architecture-registry.sh
# Tests for sync-architecture-registry.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")"
SYNC_SCRIPT="${LIB_DIR}/sync-architecture-registry.sh"

# Test utilities
TESTS_PASSED=0
TESTS_FAILED=0

pass() {
  echo "✓ $1"
  ((TESTS_PASSED++))
}

fail() {
  echo "✗ $1"
  echo "  Expected: $2"
  echo "  Got: $3"
  ((TESTS_FAILED++))
}

# Test 1: Script exists and is executable
test_script_exists() {
  if [[ -f "$SYNC_SCRIPT" ]] && [[ -x "$SYNC_SCRIPT" ]]; then
    pass "Script exists and is executable"
  else
    fail "Script exists and is executable" "executable file" "not found or not executable"
  fi
}

# Test 2: Help option works
test_help_option() {
  if bash "$SYNC_SCRIPT" --help &>/dev/null; then
    pass "Help option works"
  else
    fail "Help option works" "exit 0" "error"
  fi
}

# Test 3: Verify-only mode runs
test_verify_mode() {
  # This may fail if registry is out of sync, but should at least run
  if bash "$SYNC_SCRIPT" --verify-only 2>&1 | grep -q "Architecture Registry Sync Tool"; then
    pass "Verify mode executes"
  else
    fail "Verify mode executes" "output with title" "no output"
  fi
}

# Test 4: Registry file exists
test_registry_exists() {
  local registry_file="${LIB_DIR}/../architectures/registry.json"
  if [[ -f "$registry_file" ]]; then
    pass "Registry file exists"
  else
    fail "Registry file exists" "file at $registry_file" "not found"
  fi
}

# Test 5: Registry has required architectures
test_registry_content() {
  local registry_file="${LIB_DIR}/../architectures/registry.json"
  local required_archs=("fsd" "clean" "monorepo" "mvvm")
  local all_found=true

  for arch in "${required_archs[@]}"; do
    if ! grep -q "\"$arch\":" "$registry_file"; then
      all_found=false
      break
    fi
  done

  if $all_found; then
    pass "Registry contains required architectures"
  else
    fail "Registry contains required architectures" "all architectures" "missing some"
  fi
}

# Test 6: All config files exist
test_config_files_exist() {
  local registry_file="${LIB_DIR}/../architectures/registry.json"
  local all_exist=true

  # Extract config paths from registry
  local config_paths
  config_paths=$(grep "configPath" "$registry_file" | sed 's/.*"configPath"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')

  for path in $config_paths; do
    local full_path="${LIB_DIR}/../${path#.claude/}"
    if [[ ! -f "$full_path" ]]; then
      all_exist=false
      echo "  Missing: $full_path"
      break
    fi
  done

  if $all_exist; then
    pass "All registry config files exist"
  else
    fail "All registry config files exist" "all files exist" "missing files"
  fi
}

# Test 7: Invalid option returns error
test_invalid_option() {
  if bash "$SYNC_SCRIPT" --invalid-option 2>&1 | grep -q "Unknown option"; then
    pass "Invalid option is rejected"
  else
    fail "Invalid option is rejected" "error message" "no error"
  fi
}

# Run all tests
main() {
  echo "Testing sync-architecture-registry.sh..."
  echo ""

  test_script_exists
  test_help_option
  test_verify_mode
  test_registry_exists
  test_registry_content
  test_config_files_exist
  test_invalid_option

  echo ""
  echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed"

  if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "✓ All tests passed!"
    exit 0
  else
    echo "✗ Some tests failed"
    exit 1
  fi
}

main "$@"
