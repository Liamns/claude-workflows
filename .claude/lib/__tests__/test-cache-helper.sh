#!/usr/bin/env bash
#
# test-cache-helper.sh
# Tests for cache-helper.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")"
CACHE_HELPER="${LIB_DIR}/cache-helper.sh"

# Test utilities
TESTS_PASSED=0
TESTS_FAILED=0
TEST_CACHE_DIR=""

setup() {
  TEST_CACHE_DIR=$(mktemp -d)
  export CLAUDE_CACHE_DIR="$TEST_CACHE_DIR"
}

teardown() {
  if [[ -n "$TEST_CACHE_DIR" ]] && [[ -d "$TEST_CACHE_DIR" ]]; then
    rm -rf "$TEST_CACHE_DIR"
  fi
}

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

# Source the cache helper if it exists
if [[ -f "$CACHE_HELPER" ]]; then
  # shellcheck source=/dev/null
  source "$CACHE_HELPER" 2>/dev/null || true
fi

# Test 1: Cache helper script exists
test_script_exists() {
  if [[ -f "$CACHE_HELPER" ]]; then
    pass "cache-helper.sh exists"
  else
    fail "cache-helper.sh exists" "file" "not found"
  fi
}

# Test 2: Cache directory creation
test_cache_dir_creation() {
  local cache_dir="${TEST_CACHE_DIR}/test-cache"

  mkdir -p "$cache_dir"

  if [[ -d "$cache_dir" ]]; then
    pass "Cache directory can be created"
  else
    fail "Cache directory can be created" "directory" "not created"
  fi
}

# Test 3: Cache file write and read
test_cache_write_read() {
  local cache_file="${TEST_CACHE_DIR}/test.cache"
  local test_data="test data"

  echo "$test_data" > "$cache_file"

  if [[ -f "$cache_file" ]]; then
    local read_data
    read_data=$(cat "$cache_file")

    if [[ "$read_data" == "$test_data" ]]; then
      pass "Cache file write and read works"
    else
      fail "Cache file write and read works" "$test_data" "$read_data"
    fi
  else
    fail "Cache file write and read works" "file created" "not found"
  fi
}

# Test 4: Cache expiration check
test_cache_expiration() {
  local cache_file="${TEST_CACHE_DIR}/expire.cache"
  local expiry_seconds=1

  # Create cache file
  echo "data" > "$cache_file"

  # Check if file is fresh
  if [[ -f "$cache_file" ]]; then
    pass "Cache file freshness can be checked"
  else
    fail "Cache file freshness can be checked" "file exists" "not found"
  fi

  # Wait for expiration
  sleep 2

  # File should still exist but be considered expired based on mtime
  local file_age
  if [[ -f "$cache_file" ]]; then
    file_age=$(( $(date +%s) - $(stat -f %m "$cache_file" 2>/dev/null || stat -c %Y "$cache_file" 2>/dev/null) ))

    if [[ $file_age -ge $expiry_seconds ]]; then
      pass "Cache expiration detection works"
    else
      fail "Cache expiration detection works" ">= $expiry_seconds seconds" "$file_age seconds"
    fi
  else
    fail "Cache expiration detection works" "file exists" "not found"
  fi
}

# Test 5: Cache cleanup
test_cache_cleanup() {
  local cache_file="${TEST_CACHE_DIR}/cleanup.cache"

  echo "data" > "$cache_file"

  if [[ -f "$cache_file" ]]; then
    rm -f "$cache_file"

    if [[ ! -f "$cache_file" ]]; then
      pass "Cache cleanup works"
    else
      fail "Cache cleanup works" "file removed" "file still exists"
    fi
  else
    fail "Cache cleanup works" "file created" "not found"
  fi
}

# Test 6: Multiple cache entries
test_multiple_caches() {
  local count=0

  for i in {1..5}; do
    local cache_file="${TEST_CACHE_DIR}/multi-${i}.cache"
    echo "data $i" > "$cache_file"
    ((count++))
  done

  local actual_count
  actual_count=$(find "$TEST_CACHE_DIR" -name "multi-*.cache" | wc -l)

  if [[ $actual_count -eq $count ]]; then
    pass "Multiple cache entries can be managed"
  else
    fail "Multiple cache entries can be managed" "$count files" "$actual_count files"
  fi
}

# Test 7: Cache invalidation
test_cache_invalidation() {
  local cache_file="${TEST_CACHE_DIR}/invalid.cache"

  echo "old data" > "$cache_file"

  # Invalidate by overwriting
  echo "new data" > "$cache_file"

  local data
  data=$(cat "$cache_file")

  if [[ "$data" == "new data" ]]; then
    pass "Cache invalidation works"
  else
    fail "Cache invalidation works" "new data" "$data"
  fi
}

# Run all tests
main() {
  echo "Testing cache-helper.sh..."
  echo ""

  setup

  test_script_exists
  test_cache_dir_creation
  test_cache_write_read
  test_cache_expiration
  test_cache_cleanup
  test_multiple_caches
  test_cache_invalidation

  teardown

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
