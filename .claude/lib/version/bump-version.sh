#!/bin/bash
# bump-version.sh
# Semantic Versioning 버전 증가
#
# 사용법:
#   bash bump-version.sh <current_version> <bump_type>
#
# 입력:
#   current_version  현재 버전 (예: 3.1.2)
#   bump_type        증가 타입 (major|minor|patch|skip)
#
# 출력:
#   새 버전 (예: 3.2.0)

set -euo pipefail

# 사용법 출력
usage() {
    cat <<EOF
Usage: bump-version.sh <current_version> <bump_type>

Bump semantic version based on type.

Arguments:
  current_version    Current version (X.Y.Z format)
  bump_type          Bump type (major|minor|patch|skip)

Output:
  New version string

Bump Rules:
  major  X+1.0.0    (BREAKING CHANGE)
  minor  X.Y+1.0    (new feature)
  patch  X.Y.Z+1    (bug fix)
  skip   X.Y.Z      (no change)

Examples:
  bump-version.sh 3.1.2 minor   # → 3.2.0
  bump-version.sh 3.1.2 major   # → 4.0.0
  bump-version.sh 3.1.2 patch   # → 3.1.3
  bump-version.sh 3.1.2 skip    # → 3.1.2
EOF
}

# 인자 확인
if [ $# -lt 2 ]; then
    echo "ERROR: Missing arguments" >&2
    usage
    exit 1
fi

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
    exit 0
fi

version="$1"
bump_type="$2"

# 버전 형식 검증 (X.Y.Z)
if ! echo "$version" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    echo "ERROR: Invalid version format: $version" >&2
    echo "       Expected format: X.Y.Z (e.g., 3.1.2)" >&2
    exit 1
fi

# Bump 타입 검증
case "$bump_type" in
    major|minor|patch|skip)
        # Valid
        ;;
    *)
        echo "ERROR: Invalid bump type: $bump_type" >&2
        echo "       Expected: major, minor, patch, or skip" >&2
        exit 1
        ;;
esac

# 버전 분해 (MAJOR.MINOR.PATCH)
major=$(echo "$version" | cut -d. -f1)
minor=$(echo "$version" | cut -d. -f2)
patch=$(echo "$version" | cut -d. -f3)

# 버전 증가
case "$bump_type" in
    major)
        major=$((major + 1))
        minor=0
        patch=0
        ;;
    minor)
        minor=$((minor + 1))
        patch=0
        ;;
    patch)
        patch=$((patch + 1))
        ;;
    skip)
        # No change
        ;;
esac

# 새 버전 출력
new_version="${major}.${minor}.${patch}"
echo "$new_version"

exit 0
