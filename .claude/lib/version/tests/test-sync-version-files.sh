#!/bin/bash
# test-sync-version-files.sh
# sync-version-files.sh 테스트

set -euo pipefail

# 테스트 헬퍼 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helper.sh"

# 테스트 대상 스크립트
SYNC_SCRIPT="$SCRIPT_DIR/../sync-version-files.sh"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Testing: sync-version-files.sh"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 테스트 디렉토리 생성
TEST_DIR="/tmp/test-sync-version-$$"
mkdir -p "$TEST_DIR/.claude"

# Cleanup 함수
cleanup() {
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# ═══════════════════════════════════════════════════════════
# Setup: 테스트 파일 생성
# ═══════════════════════════════════════════════════════════
test_start "Setup test files"

# .claude/.version
echo "1.0.0" > "$TEST_DIR/.claude/.version"

# install.sh (간소화 버전)
cat > "$TEST_DIR/install.sh" <<'EOF'
#!/bin/bash
# Install Script
# Version: 1.0.0 - Installation script

INSTALLER_VERSION="1.0.0"
TARGET_VERSION="1.0.0"

echo "Installing..."
EOF

# .claude/.checksums.json
cat > "$TEST_DIR/.claude/.checksums.json" <<'EOF'
{
  "version": "1.0.0",
  "generatedAt": "2024-01-01T00:00:00Z",
  "files": {}
}
EOF

# README.md
cat > "$TEST_DIR/README.md" <<'EOF'
# Project

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)

Some content
EOF

echo "  ✓ Test files created"

# ═══════════════════════════════════════════════════════════
# Test 1: 버전 동기화 (1.0.0 → 2.0.0)
# ═══════════════════════════════════════════════════════════
test_start "Synchronize version files to 2.0.0"

cd "$TEST_DIR"
bash "$SYNC_SCRIPT" "2.0.0" >/dev/null 2>&1

# .claude/.version 확인
version_file=$(cat .claude/.version)
assert_equals "2.0.0" "$version_file" ".claude/.version should be updated"

# install.sh 확인
installer_version=$(grep 'INSTALLER_VERSION=' install.sh | sed -E 's/.*INSTALLER_VERSION="([^"]+)".*/\1/')
assert_equals "2.0.0" "$installer_version" "INSTALLER_VERSION should be updated"

target_version=$(grep 'TARGET_VERSION=' install.sh | sed -E 's/.*TARGET_VERSION="([^"]+)".*/\1/')
assert_equals "2.0.0" "$target_version" "TARGET_VERSION should be updated"

header_version=$(grep '# Version:' install.sh | sed -E 's/.*# Version: ([0-9.]+).*/\1/')
assert_equals "2.0.0" "$header_version" "Header version should be updated"

# .checksums.json 확인 (jq 사용 가능한 경우)
if command -v jq >/dev/null 2>&1; then
    checksums_version=$(jq -r '.version' .claude/.checksums.json)
    assert_equals "2.0.0" "$checksums_version" ".checksums.json version should be updated"
fi

# README.md 확인
readme_version=$(grep -oE 'version-[0-9.]+' README.md | head -1 | sed 's/version-//')
assert_equals "2.0.0" "$readme_version" "README.md badge should be updated"

# ═══════════════════════════════════════════════════════════
# Test 2: 백업 파일 생성 확인
# ═══════════════════════════════════════════════════════════
test_start "Backup files should be created"

# 백업 디렉토리 확인
backup_dir=$(find .claude/.backup -type d -name "version-sync-*" 2>/dev/null | head -1)

if [ -n "$backup_dir" ]; then
    echo "  ✓ Backup directory created: $backup_dir"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "  ✗ Backup directory not found"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))

# ═══════════════════════════════════════════════════════════
# Test 3: 잘못된 버전 형식 에러
# ═══════════════════════════════════════════════════════════
test_start "Invalid version format should fail"

set +e
bash "$SYNC_SCRIPT" "2.0" >/dev/null 2>&1
exit_code=$?
set -e
assert_exit_code 1 $exit_code "Invalid version format should exit with code 1"

# 테스트 요약
test_summary
