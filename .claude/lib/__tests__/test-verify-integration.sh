#!/bin/bash
# test-verify-integration.sh
# Integration test for verify-with-checksum.sh complete workflow
#
# 사용법:
#   bash .claude/lib/__tests__/test-verify-integration.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get script directory before changing to test directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.."; pwd)"

# Test directory
TEST_DIR="/tmp/test-verify-integration-$$"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Source the script
source "$SCRIPT_DIR/verify-with-checksum.sh"

echo "════════════════════════════════════════════════════════════════"
echo "Integration Test: verify-with-checksum.sh"
echo "════════════════════════════════════════════════════════════════"
echo ""

# ════════════════════════════════════════════════════════════════════════════
# Setup test environment
# ════════════════════════════════════════════════════════════════════════════

echo "Test 1: 테스트 환경 설정"
echo "──────────────────────────────────────────"

# Create test files
mkdir -p .claude/commands
mkdir -p .claude/lib

echo "Test content 1" > .claude/commands/test1.md
echo "Test content 2" > .claude/lib/test2.sh
echo "Test content 3" > .claude/lib/test3.sh

# Calculate their checksums
checksum1=$(calculate_sha256 .claude/commands/test1.md)
checksum2=$(calculate_sha256 .claude/lib/test2.sh)
checksum3=$(calculate_sha256 .claude/lib/test3.sh)

# Create manifest
cat > .claude/.checksums.json << EOF
{
  "version": "2.6.0",
  "generatedAt": "2025-01-11T10:00:00Z",
  "files": {
    ".claude/commands/test1.md": "$checksum1",
    ".claude/lib/test2.sh": "$checksum2",
    ".claude/lib/test3.sh": "$checksum3"
  }
}
EOF

echo -e "${GREEN}✓${NC} 테스트 파일 및 매니페스트 생성"
echo ""

# ════════════════════════════════════════════════════════════════════════════
# Test 2: Parse manifest
# ════════════════════════════════════════════════════════════════════════════

echo "Test 2: 매니페스트 파싱"
echo "──────────────────────────────────────────"

manifest_data=$(parse_checksum_manifest .claude/.checksums.json)
line_count=$(echo "$manifest_data" | wc -l | tr -d ' ')

if [[ "$line_count" == "3" ]]; then
    echo -e "${GREEN}✓${NC} 매니페스트 파싱 성공 (3개 파일)"
else
    echo -e "${RED}✗${NC} 매니페스트 파싱 실패: $line_count개 파일 (예상: 3개)"
    exit 1
fi
echo ""

# ════════════════════════════════════════════════════════════════════════════
# Test 3: Verify valid files (all should pass)
# ════════════════════════════════════════════════════════════════════════════

echo "Test 3: 정상 파일 검증 (모두 통과 예상)"
echo "──────────────────────────────────────────"

if verify_installation_with_checksum; then
    echo -e "${GREEN}✓${NC} 모든 파일 검증 통과"
else
    echo -e "${RED}✗${NC} 파일 검증 실패 (예상치 못함)"
    exit 1
fi
echo ""

# ════════════════════════════════════════════════════════════════════════════
# Test 4: Verify with corrupted file (should fail)
# ════════════════════════════════════════════════════════════════════════════

echo "Test 4: 손상된 파일 검증 (실패 예상)"
echo "──────────────────────────────────────────"

# Corrupt one file
echo "CORRUPTED" > .claude/lib/test2.sh

# Reset arrays
VERIFICATION_FILES=()
VERIFICATION_STATUS=()
FAILED_FILES=()

if verify_installation_with_checksum; then
    echo -e "${RED}✗${NC} 손상된 파일이 통과됨 (예상치 못함)"
    exit 1
else
    echo -e "${GREEN}✓${NC} 손상된 파일 검증 실패 (예상대로)"

    # Check failed files
    failed_count=${#FAILED_FILES[@]}
    if [[ $failed_count -eq 1 ]]; then
        echo -e "${GREEN}✓${NC} 실패 파일 개수 정확 (1개)"
    else
        echo -e "${RED}✗${NC} 실패 파일 개수 불일치: $failed_count개 (예상: 1개)"
        exit 1
    fi

    # Check failed file name
    if [[ "${FAILED_FILES[0]}" == ".claude/lib/test2.sh" ]]; then
        echo -e "${GREEN}✓${NC} 실패 파일 이름 정확"
    else
        echo -e "${RED}✗${NC} 실패 파일 이름 불일치: ${FAILED_FILES[0]}"
        exit 1
    fi
fi
echo ""

# ════════════════════════════════════════════════════════════════════════════
# Test 5: Verify with missing file (should fail)
# ════════════════════════════════════════════════════════════════════════════

echo "Test 5: 누락된 파일 검증 (실패 예상)"
echo "──────────────────────────────────────────"

# Remove one file
rm -f .claude/lib/test3.sh

# Reset arrays
VERIFICATION_FILES=()
VERIFICATION_STATUS=()
FAILED_FILES=()

if verify_installation_with_checksum; then
    echo -e "${RED}✗${NC} 누락된 파일이 통과됨 (예상치 못함)"
    exit 1
else
    echo -e "${GREEN}✓${NC} 누락된 파일 검증 실패 (예상대로)"

    # Check failed files (should have 2: corrupted + missing)
    failed_count=${#FAILED_FILES[@]}
    if [[ $failed_count -eq 2 ]]; then
        echo -e "${GREEN}✓${NC} 실패 파일 개수 정확 (2개: 손상+누락)"
    else
        echo -e "${RED}✗${NC} 실패 파일 개수 불일치: $failed_count개 (예상: 2개)"
        exit 1
    fi
fi
echo ""

# ════════════════════════════════════════════════════════════════════════════
# Cleanup
# ════════════════════════════════════════════════════════════════════════════

cd /
rm -rf "$TEST_DIR"

echo "════════════════════════════════════════════════════════════════"
echo -e "${GREEN}✓ All integration tests passed!${NC}"
echo "════════════════════════════════════════════════════════════════"

exit 0
