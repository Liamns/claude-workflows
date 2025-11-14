#!/bin/bash
# sync-version-files.sh
# 5개 파일의 버전 정보를 새 버전으로 동기화
#
# 사용법:
#   bash sync-version-files.sh <new_version>
#
# 입력:
#   new_version  새 버전 (예: 3.2.0)
#
# 대상 파일:
#   1. .claude/.version
#   2. install.sh (INSTALLER_VERSION, TARGET_VERSION, 헤더)
#   3. .claude/.checksums.json (version, generatedAt)
#   4. README.md (버전 배지)
#   5. CHANGELOG.md (준비 - 실제 생성은 generate-changelog.sh)

set -euo pipefail

# 사용법 출력
usage() {
    cat <<EOF
Usage: sync-version-files.sh <new_version>

Synchronize version information across 5 files.

Arguments:
  new_version    New version (X.Y.Z format)

Files Updated:
  1. .claude/.version
  2. install.sh (3 locations)
  3. .claude/.checksums.json
  4. README.md (version badge)

Examples:
  sync-version-files.sh 3.2.0
EOF
}

# 인자 확인
if [ $# -eq 0 ]; then
    echo "ERROR: Missing new version argument" >&2
    usage
    exit 1
fi

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
    exit 0
fi

NEW_VERSION="$1"

# 버전 형식 검증
if ! echo "$NEW_VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    echo "ERROR: Invalid version format: $NEW_VERSION" >&2
    echo "       Expected format: X.Y.Z (e.g., 3.2.0)" >&2
    exit 1
fi

# 백업 디렉토리
BACKUP_DIR=".claude/.backup/version-sync-$(date +%Y%m%d-%H%M%S)"

# 에러 처리 함수
error_exit() {
    echo "ERROR: $1" >&2
    echo "Rolling back changes from backup: $BACKUP_DIR" >&2

    if [ -d "$BACKUP_DIR" ]; then
        cp -f "$BACKUP_DIR/.version" .claude/.version 2>/dev/null || true
        cp -f "$BACKUP_DIR/install.sh" install.sh 2>/dev/null || true
        cp -f "$BACKUP_DIR/.checksums.json" .claude/.checksums.json 2>/dev/null || true
        cp -f "$BACKUP_DIR/README.md" README.md 2>/dev/null || true
        echo "Rollback completed" >&2
    fi

    exit 1
}

# 백업 생성
echo "Creating backup: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
cp .claude/.version "$BACKUP_DIR/.version"
cp install.sh "$BACKUP_DIR/install.sh"
cp .claude/.checksums.json "$BACKUP_DIR/.checksums.json"
cp README.md "$BACKUP_DIR/README.md"

echo "Synchronizing version to: $NEW_VERSION"
echo ""

# ═══════════════════════════════════════════════════════════
# 1. .claude/.version 업데이트
# ═══════════════════════════════════════════════════════════

echo "[1/4] Updating .claude/.version..."
echo "$NEW_VERSION" > .claude/.version || error_exit "Failed to update .claude/.version"
echo "  ✓ .claude/.version → $NEW_VERSION"

# ═══════════════════════════════════════════════════════════
# 2. install.sh 업데이트 (3곳)
# ═══════════════════════════════════════════════════════════

echo "[2/4] Updating install.sh (3 locations)..."

# Line 4: 헤더 주석 (# Version: X.Y.Z - ...)
# 버전 번호만 변경, 나머지 텍스트는 유지
sed -i.bak -E "s/^# Version: [0-9]+\.[0-9]+\.[0-9]+/# Version: $NEW_VERSION/" install.sh || error_exit "Failed to update install.sh header"
echo "  ✓ install.sh:4 (header) → $NEW_VERSION"

# Line 16: INSTALLER_VERSION="X.Y.Z"
sed -i.bak -E "s/^INSTALLER_VERSION=\"[0-9]+\.[0-9]+\.[0-9]+\"/INSTALLER_VERSION=\"$NEW_VERSION\"/" install.sh || error_exit "Failed to update INSTALLER_VERSION"
echo "  ✓ install.sh:16 (INSTALLER_VERSION) → $NEW_VERSION"

# Line 17: TARGET_VERSION="X.Y.Z"
sed -i.bak -E "s/^TARGET_VERSION=\"[0-9]+\.[0-9]+\.[0-9]+\"/TARGET_VERSION=\"$NEW_VERSION\"/" install.sh || error_exit "Failed to update TARGET_VERSION"
echo "  ✓ install.sh:17 (TARGET_VERSION) → $NEW_VERSION"

# 백업 파일 정리 (macOS sed가 생성)
rm -f install.sh.bak

# ═══════════════════════════════════════════════════════════
# 3. .claude/.checksums.json 업데이트
# ═══════════════════════════════════════════════════════════

echo "[3/4] Updating .claude/.checksums.json..."

# ISO 8601 타임스탬프 생성
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# jq로 version, generatedAt 업데이트
if command -v jq >/dev/null 2>&1; then
    jq --arg ver "$NEW_VERSION" --arg ts "$TIMESTAMP" \
       '.version = $ver | .generatedAt = $ts' \
       .claude/.checksums.json > .claude/.checksums.json.tmp || error_exit "Failed to update checksums.json with jq"
    mv .claude/.checksums.json.tmp .claude/.checksums.json
    echo "  ✓ .claude/.checksums.json → version: $NEW_VERSION, generatedAt: $TIMESTAMP"
else
    echo "  ⚠ jq not found, skipping .claude/.checksums.json update (will be regenerated later)"
fi

# ═══════════════════════════════════════════════════════════
# 4. README.md 업데이트 (버전 배지)
# ═══════════════════════════════════════════════════════════

echo "[4/4] Updating README.md (version badge)..."

# 버전 배지 패턴: version-X.Y.Z-blue.svg
sed -i.bak -E "s/version-[0-9]+\.[0-9]+\.[0-9]+-blue\.svg/version-$NEW_VERSION-blue.svg/" README.md || error_exit "Failed to update README.md"
echo "  ✓ README.md → version-$NEW_VERSION-blue.svg"

# 백업 파일 정리
rm -f README.md.bak

# ═══════════════════════════════════════════════════════════
# 검증
# ═══════════════════════════════════════════════════════════

echo ""
echo "Verifying version synchronization..."

version_in_file=$(cat .claude/.version)
version_in_install_installer=$(grep 'INSTALLER_VERSION=' install.sh | sed -E 's/.*INSTALLER_VERSION="([^"]+)".*/\1/' || echo "")
version_in_install_target=$(grep 'TARGET_VERSION=' install.sh | sed -E 's/.*TARGET_VERSION="([^"]+)".*/\1/' || echo "")
version_in_checksums=$(jq -r '.version' .claude/.checksums.json 2>/dev/null || echo "")
version_in_readme=$(grep -oE 'version-[0-9]+\.[0-9]+\.[0-9]+' README.md | head -1 | sed 's/version-//')

# 모든 버전이 일치하는지 확인
errors=0

if [ "$version_in_file" != "$NEW_VERSION" ]; then
    echo "  ✗ .claude/.version: expected $NEW_VERSION, got $version_in_file"
    errors=$((errors + 1))
fi

if [ "$version_in_install_installer" != "$NEW_VERSION" ]; then
    echo "  ✗ install.sh INSTALLER_VERSION: expected $NEW_VERSION, got $version_in_install_installer"
    errors=$((errors + 1))
fi

if [ "$version_in_install_target" != "$NEW_VERSION" ]; then
    echo "  ✗ install.sh TARGET_VERSION: expected $NEW_VERSION, got $version_in_install_target"
    errors=$((errors + 1))
fi

if [ -n "$version_in_checksums" ] && [ "$version_in_checksums" != "$NEW_VERSION" ]; then
    echo "  ✗ .claude/.checksums.json: expected $NEW_VERSION, got $version_in_checksums"
    errors=$((errors + 1))
fi

if [ "$version_in_readme" != "$NEW_VERSION" ]; then
    echo "  ✗ README.md: expected $NEW_VERSION, got $version_in_readme"
    errors=$((errors + 1))
fi

if [ $errors -gt 0 ]; then
    error_exit "Version synchronization failed ($errors mismatches)"
fi

echo "  ✓ All files synchronized to $NEW_VERSION"
echo ""
echo "Success! Version synchronized across all files."
echo "Backup saved to: $BACKUP_DIR"

exit 0
