#!/bin/bash
# Unit Test: Plan Mode Context Extraction
# Tests keyword detection and message length validation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Helper function to run tests
run_test() {
  local test_name="$1"
  local test_command="$2"

  TESTS_RUN=$((TESTS_RUN + 1))

  echo -n "Testing: $test_name ... "

  if eval "$test_command"; then
    echo -e "${GREEN}PASS${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${RED}FAIL${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

# Helper function to check if text contains plan keywords
contains_plan_keyword() {
  local text="$1"
  local keywords=("계획" "plan" "phase" "단계" "step")

  for keyword in "${keywords[@]}"; do
    if echo "$text" | grep -qi "$keyword"; then
      return 0
    fi
  done

  return 1
}

# Helper function to check message length
is_long_enough() {
  local text="$1"
  local min_length=200

  if [ ${#text} -gt $min_length ]; then
    return 0
  else
    return 1
  fi
}

# Helper function to extract plan from text
extract_plan_from_context() {
  local text="$1"
  local has_keyword=false
  local is_long=false

  # Check keyword
  if contains_plan_keyword "$text"; then
    has_keyword=true
  fi

  # Check length
  if is_long_enough "$text"; then
    is_long=true
  fi

  # Check both conditions: keyword AND length
  if [ "$has_keyword" = true ] && [ "$is_long" = true ]; then
    echo "true"
  else
    echo "false"
  fi
}

echo "=================================================="
echo "Plan Mode Context Extraction - Unit Tests"
echo "=================================================="
echo ""

# Test 1: Korean keyword detection
run_test "Korean keyword '계획' detection" \
  "contains_plan_keyword '이것은 계획입니다'"

# Test 2: English keyword 'plan' detection
run_test "English keyword 'plan' detection" \
  "contains_plan_keyword 'This is a plan for the feature'"

# Test 3: English keyword 'phase' detection
run_test "English keyword 'phase' detection" \
  "contains_plan_keyword 'Phase 1: Setup'"

# Test 4: Korean keyword '단계' detection
run_test "Korean keyword '단계' detection" \
  "contains_plan_keyword '다음 단계로 진행합니다'"

# Test 5: English keyword 'step' detection
run_test "English keyword 'step' detection" \
  "contains_plan_keyword 'Step 1: Create files'"

# Test 6: Case insensitive detection
run_test "Case insensitive 'PLAN' detection" \
  "contains_plan_keyword 'THIS IS A PLAN'"

# Test 7: No keyword detection
run_test "No keyword - should fail" \
  "! contains_plan_keyword 'Just a random message without keywords'"

# Test 8: Message length > 200 chars
LONG_MESSAGE="This is a very long message that exceeds 200 characters. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris."
run_test "Message length > 200 chars" \
  "is_long_enough '$LONG_MESSAGE'"

# Test 9: Message length < 200 chars
SHORT_MESSAGE="This is short"
run_test "Message length < 200 chars - should fail" \
  "! is_long_enough '$SHORT_MESSAGE'"

# Test 10: Full extraction - keyword + long message
PLAN_MESSAGE="상세 계획을 작성합니다. Phase 1에서는 요구사항을 수집하고, Phase 2에서는 설계를 진행합니다. Phase 3에서는 구현을 시작하며, 각 단계마다 테스트를 작성합니다. 이 계획은 총 5일이 소요될 예정이며, TDD 원칙을 따릅니다. 각 컴포넌트는 재사용 가능하도록 설계되며, FSD 아키텍처를 준수합니다. 추가로 보안 검증 단계도 포함되며, 성능 테스트와 코드 리뷰 프로세스도 진행됩니다."
RESULT=$(extract_plan_from_context "$PLAN_MESSAGE")
run_test "Full extraction - keyword + length" \
  "[[ '$RESULT' == 'true' ]]"

# Test 11: Keyword only (too short)
SHORT_PLAN="계획"
RESULT=$(extract_plan_from_context "$SHORT_PLAN")
run_test "Keyword only (too short) - should fail" \
  "[[ '$RESULT' == 'false' ]]"

# Test 12: Long message without keywords
LONG_NO_KEYWORD="Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor."
RESULT=$(extract_plan_from_context "$LONG_NO_KEYWORD")
run_test "Long message without keywords - should fail" \
  "[[ '$RESULT' == 'false' ]]"

# Test 13: Empty string
RESULT=$(extract_plan_from_context "")
run_test "Empty string - should fail" \
  "[[ '$RESULT' == 'false' ]]"

# Test 14: Mixed Korean/English with plan keywords
MIXED_PLAN="Implementation plan for the new feature. Phase 1: 요구사항 수집. We will collect requirements from stakeholders. Phase 2: 설계 및 아키텍처 결정. This involves choosing the right tech stack. Phase 3: 구현 시작. We'll follow TDD principles throughout the development process."
RESULT=$(extract_plan_from_context "$MIXED_PLAN")
run_test "Mixed Korean/English plan - should pass" \
  "[[ '$RESULT' == 'true' ]]"

# Test 15: Multiple keywords in one message
MULTI_KEYWORD="This is the detailed plan with multiple phases. Step 1 covers the initial setup phase where we configure the development environment. 각 단계는 신중하게 계획되었습니다. Step 2 involves implementing the core features, and Step 3 focuses on testing and quality assurance. Each phase builds upon the previous one systematically."
RESULT=$(extract_plan_from_context "$MULTI_KEYWORD")
run_test "Multiple keywords in message - should pass" \
  "[[ '$RESULT' == 'true' ]]"

echo ""
echo "=================================================="
echo "Test Results"
echo "=================================================="
echo "Total Tests: $TESTS_RUN"
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
echo "=================================================="

if [ $TESTS_FAILED -eq 0 ]; then
  echo -e "${GREEN}✅ All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}❌ Some tests failed${NC}"
  exit 1
fi
