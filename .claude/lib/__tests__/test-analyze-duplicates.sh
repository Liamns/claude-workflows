#!/bin/bash
# test-analyze-duplicates.sh
# Unit test for duplicate function detection

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

TEST_PASSED=0
TEST_FAILED=0

echo "🧪 Testing Duplicate Detection..."

# Test 1: analyze-duplicates.sh exists and is executable
test_script_exists() {
  if [ -f ".claude/lib/analyze-duplicates.sh" ] && [ -x ".claude/lib/analyze-duplicates.sh" ]; then
    echo -e "${GREEN}✓${NC} Test 1: analyze-duplicates.sh exists and is executable"
    ((TEST_PASSED++)) || true
  else
    echo -e "${RED}✗${NC} Test 1: analyze-duplicates.sh not found or not executable"
    ((TEST_FAILED++)) || true
  fi
}

# Test 2: Script can identify duplicate function names
test_find_duplicate_functions() {
  # Create temporary test files with duplicate functions
  mkdir -p /tmp/claude-test-duplicates

  cat > /tmp/claude-test-duplicates/script1.sh <<'EOF'
#!/bin/bash
function log_error() {
  echo "Error: $1" >&2
}

function validate_json() {
  jq empty "$1"
}
EOF

  cat > /tmp/claude-test-duplicates/script2.sh <<'EOF'
#!/bin/bash
function log_error() {
  echo "[ERROR] $1" >&2
}

function process_file() {
  cat "$1"
}
EOF

  # Run duplicate analyzer (expect it to find log_error as duplicate)
  if bash .claude/lib/analyze-duplicates.sh /tmp/claude-test-duplicates 2>/dev/null | grep -q "log_error"; then
    echo -e "${GREEN}✓${NC} Test 2: Can identify duplicate function names"
    ((TEST_PASSED++)) || true
  else
    echo -e "${RED}✗${NC} Test 2: Failed to identify duplicate functions"
    ((TEST_FAILED++)) || true
  fi

  # Cleanup
  rm -rf /tmp/claude-test-duplicates
}

# Test 3: Script outputs JSON format
test_json_output() {
  # Create test directory with one duplicate
  mkdir -p /tmp/claude-test-json

  cat > /tmp/claude-test-json/a.sh <<'EOF'
#!/bin/bash
function test_func() {
  echo "test"
}
EOF

  cat > /tmp/claude-test-json/b.sh <<'EOF'
#!/bin/bash
function test_func() {
  echo "test"
}
EOF

  # Check if output is valid JSON
  output=$(bash .claude/lib/analyze-duplicates.sh /tmp/claude-test-json 2>/dev/null || echo "[]")

  if echo "$output" | jq empty 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Test 3: Output is valid JSON"
    ((TEST_PASSED++)) || true
  else
    echo -e "${RED}✗${NC} Test 3: Output is not valid JSON"
    ((TEST_FAILED++)) || true
  fi

  # Cleanup
  rm -rf /tmp/claude-test-json
}

# Test 4: Script reports duplicate count
test_duplicate_count() {
  mkdir -p /tmp/claude-test-count

  # Create 3 scripts with same function
  for i in {1..3}; do
    cat > "/tmp/claude-test-count/script$i.sh" <<'EOF'
#!/bin/bash
function common_func() {
  return 0
}
EOF
  done

  # Analyze should show common_func appears 3 times
  output=$(bash .claude/lib/analyze-duplicates.sh /tmp/claude-test-count 2>/dev/null || echo "[]")
  count=$(echo "$output" | jq -r '.[] | select(.functionName == "common_func") | .count' 2>/dev/null || echo "0")

  if [ "$count" -eq 3 ]; then
    echo -e "${GREEN}✓${NC} Test 4: Correctly reports duplicate count (3)"
    ((TEST_PASSED++)) || true
  else
    echo -e "${RED}✗${NC} Test 4: Incorrect duplicate count (expected 3, got $count)"
    ((TEST_FAILED++)) || true
  fi

  # Cleanup
  rm -rf /tmp/claude-test-count
}

# Test 5: Script lists all files containing duplicate
test_file_list() {
  mkdir -p /tmp/claude-test-files

  cat > /tmp/claude-test-files/one.sh <<'EOF'
#!/bin/bash
function shared() { :; }
EOF

  cat > /tmp/claude-test-files/two.sh <<'EOF'
#!/bin/bash
function shared() { :; }
EOF

  output=$(bash .claude/lib/analyze-duplicates.sh /tmp/claude-test-files 2>/dev/null || echo "[]")
  files=$(echo "$output" | jq -r '.[] | select(.functionName == "shared") | .files[]' 2>/dev/null)

  file_count=$(echo "$files" | wc -l | tr -d ' ')

  if [ "$file_count" -eq 2 ]; then
    echo -e "${GREEN}✓${NC} Test 5: Lists all files containing duplicate"
    ((TEST_PASSED++)) || true
  else
    echo -e "${RED}✗${NC} Test 5: File list incorrect (expected 2 files, got $file_count)"
    ((TEST_FAILED++)) || true
  fi

  # Cleanup
  rm -rf /tmp/claude-test-files
}

# Run tests only if we're in the project root
if [ -d ".claude/lib" ]; then
  test_script_exists

  # Only run remaining tests if script exists
  if [ -f ".claude/lib/analyze-duplicates.sh" ]; then
    test_find_duplicate_functions
    test_json_output
    test_duplicate_count
    test_file_list
  fi
else
  echo -e "${RED}⚠️  Not in project root. Skipping tests.${NC}"
  exit 1
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test Results:"
echo -e "  ${GREEN}Passed:${NC} $TEST_PASSED"
echo -e "  ${RED}Failed:${NC} $TEST_FAILED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $TEST_FAILED -eq 0 ]; then
  echo -e "${GREEN}✓ All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}✗ Some tests failed${NC}"
  exit 1
fi
