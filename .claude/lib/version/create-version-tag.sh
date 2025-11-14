#!/bin/bash
# create-version-tag.sh
# Git 버전 태그 생성 및 푸시
#
# 사용법:
#   bash create-version-tag.sh <version> [message]
#
# 입력:
#   version    버전 (예: 3.2.0)
#   message    태그 메시지 (선택, 기본값: "Release v{version}")
#
# 출력:
#   Git 태그 생성 및 원격 저장소 푸시

set -euo pipefail

# 사용법 출력
usage() {
    cat <<EOF
Usage: create-version-tag.sh <version> [message]

Create and push a git version tag.

Arguments:
  version     Version to tag (X.Y.Z format)
  message     Optional tag message (default: "Release v{version}")

Output:
  Creates annotated git tag and pushes to origin

Tag Format:
  Tag name:    v{version}    (e.g., v3.2.0)
  Tag type:    annotated     (git tag -a)
  Push:        yes           (git push origin)

Examples:
  create-version-tag.sh 3.2.0
  create-version-tag.sh 3.2.0 "Release 3.2.0 - Feature 006 complete"
  create-version-tag.sh 4.0.0 "Major release - BREAKING CHANGES"
EOF
}

# 인자 확인
if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
    exit 0
fi

if [ $# -lt 1 ]; then
    echo "ERROR: Missing version argument" >&2
    usage
    exit 1
fi

VERSION="$1"
MESSAGE="${2:-Release v$VERSION}"

# 버전 형식 검증
if ! echo "$VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    echo "ERROR: Invalid version format: $VERSION" >&2
    echo "       Expected format: X.Y.Z (e.g., 3.2.0)" >&2
    exit 1
fi

# Git 저장소 확인
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "ERROR: Not a git repository" >&2
    exit 1
fi

# 변경사항 확인 (커밋되지 않은 변경사항이 있으면 경고)
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo "WARNING: You have uncommitted changes" >&2
    echo "         Consider committing or stashing them before creating a tag" >&2
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted by user" >&2
        exit 1
    fi
fi

# 태그 이름
TAG_NAME="v$VERSION"

# 태그 이미 존재하는지 확인
if git rev-parse "$TAG_NAME" >/dev/null 2>&1; then
    echo "ERROR: Tag $TAG_NAME already exists" >&2
    echo "       Use 'git tag -d $TAG_NAME' to delete it first" >&2
    exit 1
fi

# 원격 저장소 확인
if ! git remote get-url origin >/dev/null 2>&1; then
    echo "WARNING: No 'origin' remote configured" >&2
    echo "         Tag will be created locally only" >&2
    PUSH_TO_REMOTE=false
else
    PUSH_TO_REMOTE=true
fi

# 태그 생성
echo "Creating annotated tag: $TAG_NAME"
echo "Message: $MESSAGE"
echo ""

if ! git tag -a "$TAG_NAME" -m "$MESSAGE"; then
    echo "ERROR: Failed to create tag $TAG_NAME" >&2
    exit 1
fi

echo "✓ Tag $TAG_NAME created successfully"

# 원격 저장소에 푸시
if [ "$PUSH_TO_REMOTE" = true ]; then
    echo ""
    echo "Pushing tag to origin..."

    if git push origin "$TAG_NAME"; then
        echo "✓ Tag $TAG_NAME pushed to origin"
    else
        echo "ERROR: Failed to push tag to origin" >&2
        echo "       Tag created locally but not pushed" >&2
        echo "       You can push manually with: git push origin $TAG_NAME" >&2
        exit 1
    fi
fi

# 태그 정보 표시
echo ""
echo "Tag Details:"
git show "$TAG_NAME" --no-patch --format="  Commit:  %H%n  Author:  %an <%ae>%n  Date:    %ad%n  Message: %s"

exit 0
