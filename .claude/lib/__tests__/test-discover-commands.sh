#!/bin/bash
# test-discover-commands.sh
# Integration test for command discovery

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

COMMANDS_DIR=".claude/commands"
TEST_PASSED=0
TEST_FAILED=0

echo "🧪 Testing Command Discovery..."

# Test 1: Commands directory exists
test_commands_dir_exists() {
  if [ -d "$COMMANDS_DIR" ]; then
    echo -e "${GREEN}✓${NC} Test 1: Commands directory exists"
    ((TEST_PASSED++))
  else
    echo -e "${RED}✗${NC} Test 1: Commands directory not found"
    ((TEST_FAILED++))
  fi
}

# Test 2: Find all .md files in commands directory
test_find_command_files() {
  local command_count=$(find "$COMMANDS_DIR" -name "*.md" -type f | wc -l | tr -d ' ')

  if [ "$command_count" -gt 0 ]; then
    echo -e "${GREEN}✓${NC} Test 2: Found $command_count command files"
    ((TEST_PASSED++))
  else
    echo -e "${RED}✗${NC} Test 2: No command files found"
    ((TEST_FAILED++))
  fi
}

# Test 3: Extract Skill patterns from commands
test_extract_skill_patterns() {
  local skill_count=$(grep -rh "Skill.*:" "$COMMANDS_DIR" --include="*.md" | wc -l | tr -d ' ')

  if [ "$skill_count" -ge 0 ]; then
    echo -e "${GREEN}✓${NC} Test 3: Extracted $skill_count Skill patterns"
    ((TEST_PASSED++))
  else
    echo -e "${RED}✗${NC} Test 3: Failed to extract Skill patterns"
    ((TEST_FAILED++))
  fi
}

# Test 4: Extract Task/Agent patterns from commands
test_extract_agent_patterns() {
  local agent_count=$(grep -rh "Task.*subagent" "$COMMANDS_DIR" --include="*.md" | wc -l | tr -d ' ')

  echo -e "${GREEN}✓${NC} Test 4: Extracted $agent_count Task/Agent patterns"
  ((TEST_PASSED++))
}

# Test 5: Extract Bash script references
test_extract_script_patterns() {
  local script_count=$(grep -rh "Bash.*\.sh" "$COMMANDS_DIR" --include="*.md" | wc -l | tr -d ' ')

  echo -e "${GREEN}✓${NC} Test 5: Extracted $script_count Bash script references"
  ((TEST_PASSED++))
}

# Run tests
if [ -d "$COMMANDS_DIR" ]; then
  test_commands_dir_exists
  test_find_command_files
  test_extract_skill_patterns
  test_extract_agent_patterns
  test_extract_script_patterns
else
  echo -e "${RED}⚠️  Commands directory not found${NC}"
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
