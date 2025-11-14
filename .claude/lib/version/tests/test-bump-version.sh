#!/bin/bash
# test-bump-version.sh
# bump-version.sh 테스트

set -euo pipefail

# 테스트 헬퍼 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helper.sh"

# 테스트 대상 스크립트
BUMP_SCRIPT="$SCRIPT_DIR/../bump-version.sh"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Testing: bump-version.sh"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ═══════════════════════════════════════════════════════════
# Test 1: patch 증가 (3.1.2 → 3.1.3)
# ═══════════════════════════════════════════════════════════
test_start "Patch bump: 3.1.2 → 3.1.3"

result=$(bash "$BUMP_SCRIPT" "3.1.2" "patch")
assert_equals "3.1.3" "$result" "Patch bump should increment patch version"

# ═══════════════════════════════════════════════════════════
# Test 2: minor 증가 (3.1.2 → 3.2.0)
# ═══════════════════════════════════════════════════════════
test_start "Minor bump: 3.1.2 → 3.2.0"

result=$(bash "$BUMP_SCRIPT" "3.1.2" "minor")
assert_equals "3.2.0" "$result" "Minor bump should reset patch to 0"

# ═══════════════════════════════════════════════════════════
# Test 3: major 증가 (3.1.2 → 4.0.0)
# ═══════════════════════════════════════════════════════════
test_start "Major bump: 3.1.2 → 4.0.0"

result=$(bash "$BUMP_SCRIPT" "3.1.2" "major")
assert_equals "4.0.0" "$result" "Major bump should reset minor and patch to 0"

# ═══════════════════════════════════════════════════════════
# Test 4: skip (버전 유지)
# ═══════════════════════════════════════════════════════════
test_start "Skip: 3.1.2 → 3.1.2"

result=$(bash "$BUMP_SCRIPT" "3.1.2" "skip")
assert_equals "3.1.2" "$result" "Skip should keep version unchanged"

# ═══════════════════════════════════════════════════════════
# Test 5: 0.0.0 버전 처리
# ═══════════════════════════════════════════════════════════
test_start "Bump from 0.0.0"

result=$(bash "$BUMP_SCRIPT" "0.0.0" "patch")
assert_equals "0.0.1" "$result" "Should handle 0.0.0 version"

result=$(bash "$BUMP_SCRIPT" "0.0.0" "minor")
assert_equals "0.1.0" "$result" "Should handle 0.0.0 version"

result=$(bash "$BUMP_SCRIPT" "0.0.0" "major")
assert_equals "1.0.0" "$result" "Should handle 0.0.0 version"

# ═══════════════════════════════════════════════════════════
# Test 6: 큰 숫자 처리
# ═══════════════════════════════════════════════════════════
test_start "Handle large version numbers"

result=$(bash "$BUMP_SCRIPT" "99.99.99" "patch")
assert_equals "99.99.100" "$result" "Should handle large numbers"

# ═══════════════════════════════════════════════════════════
# Test 7: 잘못된 버전 형식 에러
# ═══════════════════════════════════════════════════════════
test_start "Invalid version format should fail"

set +e
bash "$BUMP_SCRIPT" "3.1" "patch" 2>/dev/null
exit_code=$?
set -e
assert_exit_code 1 $exit_code "Invalid version format should exit with code 1"

# ═══════════════════════════════════════════════════════════
# Test 8: 잘못된 bump type 에러
# ═══════════════════════════════════════════════════════════
test_start "Invalid bump type should fail"

set +e
bash "$BUMP_SCRIPT" "3.1.2" "invalid" 2>/dev/null
exit_code=$?
set -e
assert_exit_code 1 $exit_code "Invalid bump type should exit with code 1"

# 테스트 요약
test_summary
