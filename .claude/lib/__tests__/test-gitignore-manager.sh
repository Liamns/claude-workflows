#!/bin/bash
# test-gitignore-manager.sh
# Unit tests for gitignore-manager.sh
#
# 사용법:
#   bash .claude/lib/__tests__/test-gitignore-manager.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Source the module to test
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.."; pwd)"
source "$SCRIPT_DIR/gitignore-manager.sh"

# Test directory
TEST_DIR="/tmp/test-gitignore-$$"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# ════════════════════════════════════════════════════════════════════════════
# Test helpers
# ════════════════════════════════════════════════════════════════════════════

assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"

    ((TESTS_RUN++))

    if [[ "$expected" == "$actual" ]]; then
        echo -e "${GREEN}✓${NC} $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $test_name"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_success() {
    local command="$1"
    local test_name="$2"

    ((TESTS_RUN++))

    if eval "$command" &> /dev/null; then
        echo -e "${GREEN}✓${NC} $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $test_name"
        echo "  Command failed: $command"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local test_name="$2"

    ((TESTS_RUN++))

    if [[ -f "$file" ]]; then
        echo -e "${GREEN}✓${NC} $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $test_name"
        echo "  File not found: $file"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_file_contains() {
    local file="$1"
    local pattern="$2"
    local test_name="$3"

    ((TESTS_RUN++))

    if grep -Fxq "$pattern" "$file" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $test_name"
        echo "  Pattern not found in $file: $pattern"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_file_not_contains() {
    local file="$1"
    local pattern="$2"
    local test_name="$3"

    ((TESTS_RUN++))

    if ! grep -Fxq "$pattern" "$file" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $test_name"
        echo "  Pattern found in $file (should not exist): $pattern"
        ((TESTS_FAILED++))
        return 1
    fi
}

# ════════════════════════════════════════════════════════════════════════════
# Test Suite
# ════════════════════════════════════════════════════════════════════════════

echo "════════════════════════════════════════════════════════════════"
echo "Test Suite: gitignore-manager.sh"
echo "════════════════════════════════════════════════════════════════"
echo ""

# ════════════════════════════════════════════════════════════════════════════
# Test 1: add_to_gitignore() creates .gitignore if missing
# ════════════════════════════════════════════════════════════════════════════

echo "Test Group: add_to_gitignore() - 파일 생성"
echo "──────────────────────────────────────────"

# Ensure no .gitignore exists
rm -f .gitignore

# Add a pattern
add_to_gitignore "*.log" > /dev/null

# Check file was created
assert_file_exists ".gitignore" ".gitignore 파일 자동 생성"

# Check pattern was added
assert_file_contains ".gitignore" "*.log" "패턴이 .gitignore에 추가됨"

echo ""

# ════════════════════════════════════════════════════════════════════════════
# Test 2: add_to_gitignore() prevents duplicates
# ════════════════════════════════════════════════════════════════════════════

echo "Test Group: add_to_gitignore() - 중복 방지"
echo "──────────────────────────────────────────"

# Count occurrences before
count_before=$(grep -Fx "*.log" .gitignore | wc -l | tr -d ' ')

# Try to add the same pattern again
add_to_gitignore "*.log" > /dev/null

# Count occurrences after
count_after=$(grep -Fx "*.log" .gitignore | wc -l | tr -d ' ')

assert_equals "$count_before" "$count_after" "중복 패턴 추가 방지"

echo ""

# ════════════════════════════════════════════════════════════════════════════
# Test 3: add_to_gitignore() adds different patterns
# ════════════════════════════════════════════════════════════════════════════

echo "Test Group: add_to_gitignore() - 다중 패턴"
echo "──────────────────────────────────────────"

add_to_gitignore "*.tmp" > /dev/null
add_to_gitignore ".DS_Store" > /dev/null
add_to_gitignore "node_modules/" > /dev/null

assert_file_contains ".gitignore" "*.tmp" "*.tmp 패턴 추가"
assert_file_contains ".gitignore" ".DS_Store" ".DS_Store 패턴 추가"
assert_file_contains ".gitignore" "node_modules/" "node_modules/ 패턴 추가"

echo ""

# ════════════════════════════════════════════════════════════════════════════
# Test 4: add_installer_patterns_to_gitignore() adds all patterns
# ════════════════════════════════════════════════════════════════════════════

echo "Test Group: add_installer_patterns_to_gitignore()"
echo "──────────────────────────────────────────"

# Start fresh
rm -f .gitignore

# Add all installer patterns
add_installer_patterns_to_gitignore > /dev/null

assert_file_exists ".gitignore" ".gitignore 파일 생성"

# Check section header (# Auto-generated is added when file is created)
if grep -q "# Auto-generated by Claude Workflows Installer" .gitignore || grep -q "# Claude Workflows Installer - Auto-generated" .gitignore; then
    echo -e "${GREEN}✓${NC} 섹션 헤더 존재"
    ((TESTS_RUN++))
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗${NC} 섹션 헤더 누락"
    ((TESTS_RUN++))
    ((TESTS_FAILED++))
fi

# Check key patterns are present
assert_file_contains ".gitignore" ".claude/.backup/" "백업 디렉토리 패턴"
assert_file_contains ".gitignore" ".claude/cache/" "캐시 디렉토리 패턴"
assert_file_contains ".gitignore" "*.log" "로그 파일 패턴"
assert_file_contains ".gitignore" ".DS_Store" "OS 특정 파일 패턴"

# Count total patterns
pattern_count=$(wc -l < .gitignore | tr -d ' ')
echo "  Total lines in .gitignore: $pattern_count"

echo ""

# ════════════════════════════════════════════════════════════════════════════
# Test 5: add_installer_patterns_to_gitignore() doesn't duplicate section
# ════════════════════════════════════════════════════════════════════════════

echo "Test Group: 섹션 헤더 중복 방지"
echo "──────────────────────────────────────────"

# Count section headers before (both formats)
section_count_before=$(grep -E "# (Auto-generated|Claude Workflows Installer)" .gitignore | wc -l | tr -d ' ')

# Run again
add_installer_patterns_to_gitignore > /dev/null

# Count section headers after
section_count_after=$(grep -E "# (Auto-generated|Claude Workflows Installer)" .gitignore | wc -l | tr -d ' ')

# Should be 1 (either format, only one header)
if [[ "$section_count_after" -eq 1 ]]; then
    echo -e "${GREEN}✓${NC} 섹션 헤더 중복 추가 방지 (헤더 수: $section_count_after)"
    ((TESTS_RUN++))
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗${NC} 섹션 헤더 중복 발견"
    echo "  Before: $section_count_before"
    echo "  After:  $section_count_after"
    ((TESTS_RUN++))
    ((TESTS_FAILED++))
fi

echo ""

# ════════════════════════════════════════════════════════════════════════════
# Test 6: Verify all INSTALLER_GITIGNORE_PATTERNS are added
# ════════════════════════════════════════════════════════════════════════════

echo "Test Group: 모든 표준 패턴 확인"
echo "──────────────────────────────────────────"

# Start fresh
rm -f .gitignore
add_installer_patterns_to_gitignore > /dev/null

# Check all required patterns
required_patterns=(
    ".claude/.backup/"
    ".claude/cache/"
    "*.log"
    "*.tmp"
    ".DS_Store"
    "Thumbs.db"
    ".idea/"
    ".vscode/"
)

all_present=true
for pattern in "${required_patterns[@]}"; do
    if ! grep -Fxq "$pattern" .gitignore; then
        echo -e "${RED}✗${NC} 누락된 패턴: $pattern"
        all_present=false
        ((TESTS_RUN++))
        ((TESTS_FAILED++))
    fi
done

if [[ "$all_present" == "true" ]]; then
    echo -e "${GREEN}✓${NC} 모든 필수 패턴 존재"
    ((TESTS_RUN++))
    ((TESTS_PASSED++))
fi

echo ""

# ════════════════════════════════════════════════════════════════════════════
# Test 7: Pattern format validation
# ════════════════════════════════════════════════════════════════════════════

echo "Test Group: 패턴 형식 검증"
echo "──────────────────────────────────────────"

# Check for proper formatting (no leading/trailing spaces)
if grep -E '^\s+' .gitignore > /dev/null; then
    echo -e "${RED}✗${NC} 패턴에 불필요한 공백 발견"
    ((TESTS_RUN++))
    ((TESTS_FAILED++))
else
    echo -e "${GREEN}✓${NC} 모든 패턴이 올바른 형식"
    ((TESTS_RUN++))
    ((TESTS_PASSED++))
fi

# Check no empty lines at the beginning
first_line=$(head -1 .gitignore)
if [[ -n "$first_line" ]]; then
    echo -e "${GREEN}✓${NC} 파일 시작에 빈 줄 없음"
    ((TESTS_RUN++))
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗${NC} 파일 시작에 빈 줄 존재"
    ((TESTS_RUN++))
    ((TESTS_FAILED++))
fi

echo ""

# ════════════════════════════════════════════════════════════════════════════
# Cleanup
# ════════════════════════════════════════════════════════════════════════════

cd /
rm -rf "$TEST_DIR"

echo "════════════════════════════════════════════════════════════════"
echo "Test Results"
echo "════════════════════════════════════════════════════════════════"
echo "Total:  $TESTS_RUN"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
else
    echo "Failed: $TESTS_FAILED"
fi
echo "════════════════════════════════════════════════════════════════"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    exit 1
fi
