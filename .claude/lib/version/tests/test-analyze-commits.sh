#!/bin/bash
# test-analyze-commits.sh
# analyze-commits.sh 테스트

set -euo pipefail

# 테스트 헬퍼 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helper.sh"

# 테스트 대상 스크립트
ANALYZE_SCRIPT="$SCRIPT_DIR/../analyze-commits.sh"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Testing: analyze-commits.sh"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ═══════════════════════════════════════════════════════════
# Test 1: feat 커밋 → minor
# ═══════════════════════════════════════════════════════════
test_start "feat commit should return minor"

commits="feat: add new feature"
result=$(bash "$ANALYZE_SCRIPT" "$commits")

assert_equals "minor" "$result" "feat commit should return minor"

# ═══════════════════════════════════════════════════════════
# Test 2: fix 커밋 → patch
# ═══════════════════════════════════════════════════════════
test_start "fix commit should return patch"

commits="fix: resolve bug"
result=$(bash "$ANALYZE_SCRIPT" "$commits")

assert_equals "patch" "$result" "fix commit should return patch"

# ═══════════════════════════════════════════════════════════
# Test 3: BREAKING CHANGE → major
# ═══════════════════════════════════════════════════════════
test_start "BREAKING CHANGE should return major"

commits="feat: new API

BREAKING CHANGE: API endpoint changed"
result=$(bash "$ANALYZE_SCRIPT" "$commits")

assert_equals "major" "$result" "BREAKING CHANGE should return major"

# ═══════════════════════════════════════════════════════════
# Test 4: docs 커밋 → skip
# ═══════════════════════════════════════════════════════════
test_start "docs commit should return skip"

commits="docs: update README"
result=$(bash "$ANALYZE_SCRIPT" "$commits")

assert_equals "skip" "$result" "docs commit should return skip"

# ═══════════════════════════════════════════════════════════
# Test 5: 여러 커밋 (feat + fix) → minor
# ═══════════════════════════════════════════════════════════
test_start "Multiple commits (feat + fix) should return minor"

commits="feat: add feature
fix: fix bug
docs: update docs"
result=$(bash "$ANALYZE_SCRIPT" "$commits")

assert_equals "minor" "$result" "Multiple commits with feat should return minor"

# ═══════════════════════════════════════════════════════════
# Test 6: scope 포함 커밋
# ═══════════════════════════════════════════════════════════
test_start "Commit with scope should be parsed correctly"

commits="feat(api): add new endpoint"
result=$(bash "$ANALYZE_SCRIPT" "$commits")

assert_equals "minor" "$result" "feat with scope should return minor"

# ═══════════════════════════════════════════════════════════
# Test 7: 빈 커밋 → skip
# ═══════════════════════════════════════════════════════════
test_start "Empty commits should return skip"

commits=""
result=$(bash "$ANALYZE_SCRIPT" "$commits")

assert_equals "skip" "$result" "Empty commits should return skip"

# ═══════════════════════════════════════════════════════════
# Test 8: 우선순위 (BREAKING > feat > fix)
# ═══════════════════════════════════════════════════════════
test_start "Priority: BREAKING > feat > fix"

commits="feat: new feature
fix: bug fix

BREAKING CHANGE: API changed"
result=$(bash "$ANALYZE_SCRIPT" "$commits")

assert_equals "major" "$result" "BREAKING should have highest priority"

# 테스트 요약
test_summary
