#!/bin/bash
# run-all-tests.sh
# 모든 테스트 실행

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "╔════════════════════════════════════════╗"
echo "║  Version Management - Test Suite      ║"
echo "╚════════════════════════════════════════╝"
echo ""

# 테스트 파일 목록
TEST_FILES=(
    "test-analyze-commits.sh"
    "test-bump-version.sh"
    "test-sync-version-files.sh"
)

# 테스트 결과 카운터
TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0

# 각 테스트 실행
for test_file in "${TEST_FILES[@]}"; do
    test_path="$SCRIPT_DIR/$test_file"

    if [ ! -f "$test_path" ]; then
        echo "⚠ Test file not found: $test_file"
        continue
    fi

    TOTAL_SUITES=$((TOTAL_SUITES + 1))

    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "Running: $test_file"
    echo "═══════════════════════════════════════════════════════════"

    # 테스트 실행
    if bash "$test_path"; then
        PASSED_SUITES=$((PASSED_SUITES + 1))
    else
        FAILED_SUITES=$((FAILED_SUITES + 1))
    fi
done

# 전체 요약
echo ""
echo "╔════════════════════════════════════════╗"
echo "║  Overall Test Summary                  ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "Test Suites:"
echo "  Total:  $TOTAL_SUITES"
echo "  Passed: $PASSED_SUITES"
echo "  Failed: $FAILED_SUITES"
echo ""

if [ $FAILED_SUITES -eq 0 ]; then
    echo "✓ All test suites passed!"
    exit 0
else
    echo "✗ Some test suites failed!"
    exit 1
fi
