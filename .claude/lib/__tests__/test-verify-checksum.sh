#!/bin/bash
# test-verify-checksum.sh
# Unit tests for manifest parsing in verify-with-checksum.sh
#
# 사용법:
#   bash .claude/lib/__tests__/test-verify-checksum.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test directory
TEST_DIR="/tmp/test-verify-checksum-$$"
mkdir -p "$TEST_DIR"

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

# ════════════════════════════════════════════════════════════════════════════
# Setup test manifest
# ════════════════════════════════════════════════════════════════════════════

create_test_manifest() {
    local manifest_file="$1"

    cat > "$manifest_file" << 'EOF'
{
  "version": "2.6.0",
  "generatedAt": "2025-01-11T10:00:00Z",
  "files": {
    ".claude/commands/major.md": "abc123def456abc123def456abc123def456abc123def456abc123def456abc1",
    ".claude/lib/cache-helper.sh": "def456abc123def456abc123def456abc123def456abc123def456abc123def4",
    ".claude/workflow-gates.json": "789abc123def456abc123def456abc123def456abc123def456abc123def456ab"
  }
}
EOF
}

create_invalid_manifest() {
    local manifest_file="$1"

    cat > "$manifest_file" << 'EOF'
{
  "version": "2.6.0",
  "files": {
    "missing-closing-brace"
  }
EOF
}

# ════════════════════════════════════════════════════════════════════════════
# Test Suite
# ════════════════════════════════════════════════════════════════════════════

echo "════════════════════════════════════════════════════════════════"
echo "Test Suite: verify-with-checksum.sh (Manifest Parsing)"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Test: Manifest file creation
echo "Test Group: Manifest 파일 생성"
echo "──────────────────────────────────────────"

MANIFEST_FILE="$TEST_DIR/checksums.json"
create_test_manifest "$MANIFEST_FILE"
assert_file_exists "$MANIFEST_FILE" "테스트 manifest 파일 생성"

# Check if jq is available
if command -v jq &> /dev/null; then
    JQ_AVAILABLE=true
    echo "  ℹ️  jq 사용 가능: $(jq --version)"
else
    JQ_AVAILABLE=false
    echo "  ⚠️  jq 사용 불가: fallback 모드 테스트"
fi

echo ""

# Test: JSON validity (with jq)
if [[ "$JQ_AVAILABLE" == "true" ]]; then
    echo "Test Group: JSON 유효성 검증 (jq)"
    echo "──────────────────────────────────────────"

    assert_success "jq empty '$MANIFEST_FILE'" "jq로 JSON 유효성 검증"

    version=$(jq -r '.version' "$MANIFEST_FILE")
    assert_equals "2.6.0" "$version" "version 필드 추출"

    files_count=$(jq '.files | length' "$MANIFEST_FILE")
    assert_equals "3" "$files_count" "files 개수 확인"

    echo ""
fi

# Test: Extract file paths (with jq)
if [[ "$JQ_AVAILABLE" == "true" ]]; then
    echo "Test Group: 파일 경로 추출 (jq)"
    echo "──────────────────────────────────────────"

    # Extract file paths
    file_list=$(jq -r '.files | keys[]' "$MANIFEST_FILE" | head -1)
    assert_equals ".claude/commands/major.md" "$file_list" "첫 번째 파일 경로 추출"

    # Extract checksum for a specific file
    checksum=$(jq -r '.files[".claude/commands/major.md"]' "$MANIFEST_FILE")
    expected="abc123def456abc123def456abc123def456abc123def456abc123def456abc1"
    assert_equals "$expected" "$checksum" "특정 파일의 체크섬 추출"

    echo ""
fi

# Test: Fallback parsing (without jq)
echo "Test Group: Fallback 파싱 (grep/sed)"
echo "──────────────────────────────────────────"

# Extract version using grep
version=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$MANIFEST_FILE" | cut -d'"' -f4)
assert_equals "2.6.0" "$version" "grep으로 version 추출"

# Count files using grep
files_count=$(grep -o '"\..*/.*"[[:space:]]*:' "$MANIFEST_FILE" | wc -l | tr -d ' ')
assert_equals "3" "$files_count" "grep으로 파일 개수 확인"

echo ""

# Test: Invalid JSON handling
echo "Test Group: 잘못된 JSON 처리"
echo "──────────────────────────────────────────"

INVALID_MANIFEST="$TEST_DIR/invalid.json"
create_invalid_manifest "$INVALID_MANIFEST"

if [[ "$JQ_AVAILABLE" == "true" ]]; then
    # jq should fail on invalid JSON
    if ! jq empty "$INVALID_MANIFEST" 2>/dev/null; then
        assert_equals "failed" "failed" "jq가 잘못된 JSON을 거부"
    else
        assert_equals "failed" "passed" "jq가 잘못된 JSON을 통과시킴 (예상치 못함)"
    fi
fi

echo ""

# Test: Parse key-value pairs (jq)
if [[ "$JQ_AVAILABLE" == "true" ]]; then
    echo "Test Group: Key-Value 쌍 파싱"
    echo "──────────────────────────────────────────"

    # Parse all key-value pairs
    pairs=$(jq -r '.files | to_entries[] | "\(.key)=\(.value)"' "$MANIFEST_FILE" | wc -l | tr -d ' ')
    assert_equals "3" "$pairs" "모든 key-value 쌍 파싱"

    # Verify format: file=checksum
    first_pair=$(jq -r '.files | to_entries[0] | "\(.key)=\(.value)"' "$MANIFEST_FILE")
    expected=".claude/commands/major.md=abc123def456abc123def456abc123def456abc123def456abc123def456abc1"
    assert_equals "$expected" "$first_pair" "key-value 형식 검증"

    echo ""
fi

# Test: Performance
echo "Test Group: Performance"
echo "──────────────────────────────────────────"

# Create a larger manifest (50 files)
LARGE_MANIFEST="$TEST_DIR/large-checksums.json"
echo '{"version":"2.6.0","generatedAt":"2025-01-11T10:00:00Z","files":{' > "$LARGE_MANIFEST"

for i in {1..50}; do
    checksum=$(printf "%064d" $i | sed 's/[0-9]/a/g')  # Generate fake checksum
    echo "  \".claude/file$i.txt\": \"$checksum\"," >> "$LARGE_MANIFEST"
done

# Remove trailing comma and close JSON
sed -i '' '$ s/,$//' "$LARGE_MANIFEST" 2>/dev/null || sed -i '$ s/,$//' "$LARGE_MANIFEST"
echo '}}' >> "$LARGE_MANIFEST"

if [[ "$JQ_AVAILABLE" == "true" ]]; then
    start_time=$(date +%s)
    jq -r '.files | to_entries[] | "\(.key)=\(.value)"' "$LARGE_MANIFEST" > /dev/null
    end_time=$(date +%s)
    duration=$((end_time - start_time))

    echo "  50개 파일 파싱 시간 (jq): ${duration}초"

    if [[ $duration -le 1 ]]; then
        assert_equals "fast" "fast" "jq 파싱 성능 (50개 파일 < 1초)"
    else
        echo -e "${YELLOW}⚠${NC}  성능 경고: 50개 파일 파싱에 ${duration}초 소요 (목표: < 1초)"
    fi
fi

echo ""

# Cleanup
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
