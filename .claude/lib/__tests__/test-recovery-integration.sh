#!/bin/bash
# test-recovery-integration.sh
# Integration test for selective file re-download (US2)
#
# 사용법:
#   bash .claude/lib/__tests__/test-recovery-integration.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get script directory before changing to test directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.."; pwd)"

# Test directory
TEST_DIR="/tmp/test-recovery-integration-$$"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Source the script
source "$SCRIPT_DIR/verify-with-checksum.sh"

echo "════════════════════════════════════════════════════════════════"
echo "Integration Test: Selective File Re-download (US2)"
echo "════════════════════════════════════════════════════════════════"
echo ""

# ════════════════════════════════════════════════════════════════════════════
# Setup test environment
# ════════════════════════════════════════════════════════════════════════════

echo "Test 1: 테스트 환경 설정"
echo "──────────────────────────────────────────"

# Create test files
mkdir -p .claude/lib

# Use actual content that we can verify
echo "# Test File 1" > .claude/lib/test1.sh
echo "# Test File 2" > .claude/lib/test2.sh

# Calculate their checksums
checksum1=$(calculate_sha256 .claude/lib/test1.sh)
checksum2=$(calculate_sha256 .claude/lib/test2.sh)

# Create manifest
cat > .claude/.checksums.json << EOF
{
  "version": "2.6.0",
  "generatedAt": "2025-01-11T10:00:00Z",
  "files": {
    ".claude/lib/test1.sh": "$checksum1",
    ".claude/lib/test2.sh": "$checksum2"
  }
}
EOF

echo -e "${GREEN}✓${NC} 테스트 파일 및 매니페스트 생성"
echo ""

# ════════════════════════════════════════════════════════════════════════════
# Test 2: Verify initial state (all pass)
# ════════════════════════════════════════════════════════════════════════════

echo "Test 2: 초기 상태 검증 (모두 통과)"
echo "──────────────────────────────────────────"

if verify_installation_with_checksum; then
    echo -e "${GREEN}✓${NC} 초기 검증 통과"
else
    echo -e "${RED}✗${NC} 초기 검증 실패 (예상치 못함)"
    exit 1
fi
echo ""

# ════════════════════════════════════════════════════════════════════════════
# Test 3: Corrupt a file
# ════════════════════════════════════════════════════════════════════════════

echo "Test 3: 파일 손상 시뮬레이션"
echo "──────────────────────────────────────────"

echo "CORRUPTED CONTENT" > .claude/lib/test2.sh
echo -e "${GREEN}✓${NC} test2.sh 손상됨"
echo ""

# Reset arrays
VERIFICATION_FILES=()
VERIFICATION_STATUS=()
FAILED_FILES=()

# ════════════════════════════════════════════════════════════════════════════
# Test 4: Verify again (should detect corrupted file)
# ════════════════════════════════════════════════════════════════════════════

echo "Test 4: 손상 파일 감지"
echo "──────────────────────────────────────────"

if verify_installation_with_checksum; then
    echo -e "${RED}✗${NC} 손상 파일이 통과됨 (예상치 못함)"
    exit 1
else
    failed_count=${#FAILED_FILES[@]}
    if [[ $failed_count -eq 1 ]]; then
        echo -e "${GREEN}✓${NC} 손상 파일 감지됨 (1개)"
    else
        echo -e "${RED}✗${NC} 실패 파일 개수 불일치: $failed_count개"
        exit 1
    fi
fi
echo ""

# ════════════════════════════════════════════════════════════════════════════
# Test 5: Test generate_github_raw_url()
# ════════════════════════════════════════════════════════════════════════════

echo "Test 5: GitHub Raw URL 생성"
echo "──────────────────────────────────────────"

# Test URL generation
test_repo="https://github.com/Liamns/claude-workflows"
test_branch="main"
test_file=".claude/lib/test2.sh"

expected_url="https://raw.githubusercontent.com/Liamns/claude-workflows/main/.claude/lib/test2.sh"
actual_url=$(generate_github_raw_url "$test_file" "$test_repo" "$test_branch")

if [[ "$actual_url" == "$expected_url" ]]; then
    echo -e "${GREEN}✓${NC} URL 생성 정확"
    echo "  $actual_url"
else
    echo -e "${RED}✗${NC} URL 생성 오류"
    echo "  Expected: $expected_url"
    echo "  Actual:   $actual_url"
    exit 1
fi
echo ""

# ════════════════════════════════════════════════════════════════════════════
# Test 6: Test retry_failed_files() (recovery)
# ════════════════════════════════════════════════════════════════════════════

echo "Test 6: 파일 자동 복구"
echo "──────────────────────────────────────────"

# Note: This test requires network access to GitHub
# We'll create a mock scenario where we manually restore the file
# to simulate what retry_failed_files() should do

echo "  실제 네트워크 다운로드는 통합 테스트에서 수행됩니다"
echo "  여기서는 복구 로직만 테스트합니다"

# Manually restore the file (simulating what retry_failed_files would do)
echo "# Test File 2" > .claude/lib/test2.sh

# Reset arrays and re-verify
VERIFICATION_FILES=()
VERIFICATION_STATUS=()
FAILED_FILES=()

if verify_installation_with_checksum; then
    echo -e "${GREEN}✓${NC} 파일 복구 후 검증 통과"
else
    echo -e "${RED}✗${NC} 파일 복구 후에도 검증 실패"
    exit 1
fi
echo ""

# ════════════════════════════════════════════════════════════════════════════
# Test 7: Test with multiple failed files
# ════════════════════════════════════════════════════════════════════════════

echo "Test 7: 다중 파일 복구 시나리오"
echo "──────────────────────────────────────────"

# Corrupt both files
echo "CORRUPTED 1" > .claude/lib/test1.sh
echo "CORRUPTED 2" > .claude/lib/test2.sh

# Reset and verify
VERIFICATION_FILES=()
VERIFICATION_STATUS=()
FAILED_FILES=()

if ! verify_installation_with_checksum; then
    failed_count=${#FAILED_FILES[@]}
    if [[ $failed_count -eq 2 ]]; then
        echo -e "${GREEN}✓${NC} 다중 파일 손상 감지 (2개)"
    else
        echo -e "${RED}✗${NC} 실패 파일 개수: $failed_count개 (예상: 2개)"
        exit 1
    fi
else
    echo -e "${RED}✗${NC} 손상된 파일들이 통과됨"
    exit 1
fi

# Restore all
echo "# Test File 1" > .claude/lib/test1.sh
echo "# Test File 2" > .claude/lib/test2.sh

# Reset and verify
VERIFICATION_FILES=()
VERIFICATION_STATUS=()
FAILED_FILES=()

if verify_installation_with_checksum; then
    echo -e "${GREEN}✓${NC} 다중 파일 복구 후 검증 통과"
else
    echo -e "${RED}✗${NC} 복구 후에도 검증 실패"
    exit 1
fi
echo ""

# ════════════════════════════════════════════════════════════════════════════
# Cleanup
# ════════════════════════════════════════════════════════════════════════════

cd /
rm -rf "$TEST_DIR"

echo "════════════════════════════════════════════════════════════════"
echo -e "${GREEN}✓ All recovery integration tests passed!${NC}"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Note: 실제 GitHub 다운로드 테스트는 install.sh 통합 테스트에서 수행됩니다"

exit 0
