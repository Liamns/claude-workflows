#!/bin/bash
# test-validate-json-string.sh
# Unit tests for validate_json_string() function

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Source the module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../notion-utils.sh"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper
run_test() {
    local test_name="$1"
    local test_cmd="$2"
    local expected_result="$3"  # 0 for success, 1 for failure

    ((TESTS_RUN++))

    if eval "$test_cmd" &>/dev/null; then
        actual_result=0
    else
        actual_result=1
    fi

    if [[ $actual_result -eq $expected_result ]]; then
        echo -e "${GREEN}✓${NC} $test_name"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} $test_name (expected $expected_result, got $actual_result)"
        ((TESTS_FAILED++))
    fi
}

echo "=== validate_json_string() Unit Tests ==="
echo ""

# Test 1: Valid JSON object
run_test "Valid JSON object" \
    'validate_json_string "{\"key\": \"value\"}"' \
    0

# Test 2: Valid JSON array
run_test "Valid JSON array" \
    'validate_json_string "[1, 2, 3]"' \
    0

# Test 3: Valid empty JSON object
run_test "Valid empty JSON object" \
    'validate_json_string "{}"' \
    0

# Test 4: Invalid JSON (malformed)
run_test "Invalid JSON (malformed)" \
    'validate_json_string "{key: value}"' \
    1

# Test 5: Invalid JSON (trailing comma)
run_test "Invalid JSON (trailing comma)" \
    'validate_json_string "{\"key\": \"value\",}"' \
    1

# Test 6: Empty string
run_test "Empty string" \
    'validate_json_string ""' \
    1

# Test 7: Valid JSON with special characters
run_test "Valid JSON with special characters" \
    'validate_json_string "{\"msg\": \"Hello\\nWorld\"}"' \
    0

# Test 8: Valid nested JSON
run_test "Valid nested JSON" \
    'validate_json_string "{\"outer\": {\"inner\": \"value\"}}"' \
    0

echo ""
echo "=== Test Summary ==="
echo "Tests run: $TESTS_RUN"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
    exit 1
else
    echo "All tests passed!"
    exit 0
fi
