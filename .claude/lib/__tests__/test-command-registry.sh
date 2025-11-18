#!/bin/bash
# test-command-registry.sh
# Unit test for registry schema validation

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

REGISTRY_FILE=".claude/registry/command-resource-mapping.json"
TEST_PASSED=0
TEST_FAILED=0

echo "🧪 Testing Command Registry Schema..."

# Test 1: Registry file exists
test_registry_exists() {
  if [ -f "$REGISTRY_FILE" ]; then
    echo -e "${GREEN}✓${NC} Test 1: Registry file exists"
    ((TEST_PASSED++))
  else
    echo -e "${RED}✗${NC} Test 1: Registry file does not exist"
    ((TEST_FAILED++))
  fi
}

# Test 2: JSON structure is valid
test_json_valid() {
  if jq empty "$REGISTRY_FILE" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Test 2: JSON structure is valid"
    ((TEST_PASSED++))
  else
    echo -e "${RED}✗${NC} Test 2: JSON structure is invalid"
    ((TEST_FAILED++))
  fi
}

# Test 3: Required top-level fields exist
test_required_fields() {
  local required_fields=("version" "lastUpdated" "commands" "skills" "agents" "scripts" "documentations")
  local all_present=true

  for field in "${required_fields[@]}"; do
    if ! jq -e ".$field" "$REGISTRY_FILE" > /dev/null 2>&1; then
      echo -e "${RED}✗${NC} Test 3: Missing required field: $field"
      all_present=false
    fi
  done

  if $all_present; then
    echo -e "${GREEN}✓${NC} Test 3: All required fields exist"
    ((TEST_PASSED++))
  else
    ((TEST_FAILED++))
  fi
}

# Test 4: Commands array has required fields
test_command_schema() {
  local command_count=$(jq '.commands | length' "$REGISTRY_FILE")

  if [ "$command_count" -eq 0 ]; then
    echo -e "${RED}✗${NC} Test 4: No commands found in registry"
    ((TEST_FAILED++))
    return
  fi

  # Check first command has required fields
  local required_fields=("id" "name" "filePath")
  local all_present=true

  for field in "${required_fields[@]}"; do
    if ! jq -e ".commands[0].$field" "$REGISTRY_FILE" > /dev/null 2>&1; then
      echo -e "${RED}✗${NC} Test 4: Command missing required field: $field"
      all_present=false
    fi
  done

  if $all_present; then
    echo -e "${GREEN}✓${NC} Test 4: Command schema is valid ($command_count commands)"
    ((TEST_PASSED++))
  else
    ((TEST_FAILED++))
  fi
}

# Test 5: relatedSkills references valid skill IDs
test_relationship_integrity() {
  # Get all skill IDs
  local skill_ids=$(jq -r '.skills[].id' "$REGISTRY_FILE" 2>/dev/null | sort | uniq)

  # Check if commands reference valid skills
  local invalid_refs=0
  for related_skill in $(jq -r '.commands[].relatedSkills[]' "$REGISTRY_FILE" 2>/dev/null | sort | uniq); do
    if ! echo "$skill_ids" | grep -q "^${related_skill}$"; then
      echo -e "${RED}  Invalid skill reference: $related_skill${NC}"
      ((invalid_refs++))
    fi
  done

  if [ $invalid_refs -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Test 5: Relationship integrity is valid"
    ((TEST_PASSED++))
  else
    echo -e "${RED}✗${NC} Test 5: Found $invalid_refs invalid skill references"
    ((TEST_FAILED++))
  fi
}

# Run tests only if registry file exists
if [ -f "$REGISTRY_FILE" ]; then
  test_registry_exists
  test_json_valid
  test_required_fields
  test_command_schema
  test_relationship_integrity
else
  echo -e "${RED}⚠️  Registry file not found. Skipping tests.${NC}"
  echo "   Run: bash .claude/lib/update-command-registry.sh to generate"
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
