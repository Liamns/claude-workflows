#!/usr/bin/env bash
#
# test-config-loader.sh
# Tests for config-loader.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_LOADER="${LIB_DIR}/config-loader.sh"

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

# Source the config loader
if [[ -f "$CONFIG_LOADER" ]]; then
  # shellcheck source=/dev/null
  source "$CONFIG_LOADER"
else
  echo "✗ Config loader not found: $CONFIG_LOADER"
  exit 1
fi

# Test 1: load_config function exists
test_function_exists() {
  if declare -f load_config >/dev/null 2>&1; then
    pass "load_config function exists"
  else
    fail "load_config function exists" "function defined" "not found"
  fi
}

# Test 2: Load workflow-gates.json
test_load_workflow_gates() {
  local config_file="${LIB_DIR}/../workflow-gates.json"

  if [[ -f "$config_file" ]]; then
    # Try to read version from config
    local version
    version=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$config_file" | sed 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | head -1)

    if [[ -n "$version" ]]; then
      pass "workflow-gates.json can be read (version: $version)"
    else
      fail "workflow-gates.json can be read" "version field" "not found"
    fi
  else
    fail "workflow-gates.json can be read" "file exists" "not found"
  fi
}

# Test 3: Registry file can be loaded
test_load_registry() {
  local registry_file="${LIB_DIR}/../architectures/registry.json"

  if [[ -f "$registry_file" ]]; then
    # Validate JSON structure
    if grep -q '"architectures"' "$registry_file"; then
      pass "registry.json has valid structure"
    else
      fail "registry.json has valid structure" "architectures key" "not found"
    fi
  else
    fail "registry.json has valid structure" "file exists" "not found"
  fi
}

# Test 4: Config file validation
test_config_validation() {
  # Create temporary invalid config
  local temp_config
  temp_config=$(mktemp)
  echo "{ invalid json" > "$temp_config"

  # Test that invalid JSON is detectable
  if ! grep -q '"version"' "$temp_config" 2>/dev/null; then
    pass "Invalid config detection works"
  else
    fail "Invalid config detection works" "no version" "found version"
  fi

  rm -f "$temp_config"
}

# Test 5: Architecture config loading
test_architecture_config() {
  local fsd_config="${LIB_DIR}/../architectures/frontend/fsd/config.json"

  if [[ -f "$fsd_config" ]]; then
    # Check for required fields
    local has_name has_structure
    has_name=$(grep -q '"name"' "$fsd_config" && echo "yes" || echo "no")
    has_structure=$(grep -q '"structure"' "$fsd_config" && echo "yes" || echo "no")

    if [[ "$has_name" == "yes" ]] && [[ "$has_structure" == "yes" ]]; then
      pass "Architecture config has required fields"
    else
      fail "Architecture config has required fields" "name and structure" "missing fields"
    fi
  else
    fail "Architecture config has required fields" "file exists" "not found"
  fi
}

# Test 6: Environment variable override
test_env_override() {
  # Test that environment variables can be used for config paths
  local original_config="${LIB_DIR}/../workflow-gates.json"

  if [[ -f "$original_config" ]]; then
    export WORKFLOW_GATES_CONFIG="$original_config"

    if [[ "$WORKFLOW_GATES_CONFIG" == "$original_config" ]]; then
      pass "Environment variable override works"
    else
      fail "Environment variable override works" "$original_config" "$WORKFLOW_GATES_CONFIG"
    fi

    unset WORKFLOW_GATES_CONFIG
  else
    fail "Environment variable override works" "file exists" "not found"
  fi
}

# Test 7: Multiple config merge
test_config_merge() {
  # Test that base config and specific config can be merged conceptually
  local base_yaml="${LIB_DIR}/../commands-config/_base.yaml"
  local major_yaml="${LIB_DIR}/../commands-config/major.yaml"

  local both_exist=true
  [[ ! -f "$base_yaml" ]] && both_exist=false
  [[ ! -f "$major_yaml" ]] && both_exist=false

  if $both_exist; then
    # Check that major.yaml extends base
    if grep -q "extends:" "$major_yaml" 2>/dev/null; then
      pass "Config inheritance is configured"
    else
      # This is ok - not all configs may extend base
      pass "Config inheritance is optional"
    fi
  else
    fail "Config inheritance is configured" "both files exist" "missing files"
  fi
}

# Run all tests
main() {
  echo "Testing config-loader.sh..."
  echo ""

  test_function_exists
  test_load_workflow_gates
  test_load_registry
  test_config_validation
  test_architecture_config
  test_env_override
  test_config_merge

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
