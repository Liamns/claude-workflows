#!/bin/bash
# generate-changelog.sh
# Conventional Commits 기반 CHANGELOG.md 생성
#
# 사용법:
#   bash generate-changelog.sh <new_version> <since_ref>
#
# 입력:
#   new_version  새 버전 (예: 3.2.0)
#   since_ref    이전 버전 참조 (예: v3.1.2 또는 HEAD~10)
#
# 출력:
#   CHANGELOG.md 업데이트 (기존 내용 앞에 새 섹션 추가)

set -euo pipefail

# 사용법 출력
usage() {
    cat <<EOF
Usage: generate-changelog.sh <new_version> <since_ref>

Generate CHANGELOG.md section from Conventional Commits.

Arguments:
  new_version    New version (X.Y.Z format)
  since_ref      Reference to compare from (tag or commit)

Output:
  Updates CHANGELOG.md with new version section

Commit Classification:
  Added      feat, feature commits
  Fixed      fix commits
  Changed    refactor, perf, style, chore commits
  Breaking   BREAKING CHANGE in body/footer

Examples:
  generate-changelog.sh 3.2.0 v3.1.2
  generate-changelog.sh 4.0.0 HEAD~20
EOF
}

# 인자 확인
if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
    exit 0
fi

if [ $# -lt 2 ]; then
    echo "ERROR: Missing arguments" >&2
    usage
    exit 1
fi

NEW_VERSION="$1"
SINCE_REF="$2"

# 버전 형식 검증
if ! echo "$NEW_VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    echo "ERROR: Invalid version format: $NEW_VERSION" >&2
    echo "       Expected format: X.Y.Z (e.g., 3.2.0)" >&2
    exit 1
fi

# CHANGELOG.md 존재 확인
if [ ! -f "CHANGELOG.md" ]; then
    echo "ERROR: CHANGELOG.md not found in current directory" >&2
    exit 1
fi

# Git 참조 확인
if ! git rev-parse "$SINCE_REF" >/dev/null 2>&1; then
    echo "ERROR: Invalid git reference: $SINCE_REF" >&2
    exit 1
fi

# 백업 생성
BACKUP_FILE="CHANGELOG.md.backup-$(date +%Y%m%d-%H%M%S)"
cp CHANGELOG.md "$BACKUP_FILE"

# 에러 처리 함수
error_exit() {
    echo "ERROR: $1" >&2
    if [ -f "$BACKUP_FILE" ]; then
        echo "Rolling back CHANGELOG.md from backup: $BACKUP_FILE" >&2
        cp "$BACKUP_FILE" CHANGELOG.md
        rm -f "$BACKUP_FILE"
    fi
    exit 1
}

# 커밋 메시지 가져오기 (subject + body)
# 형식: subject|body (| 구분자로 subject와 body 분리)
commits=$(git log --format="%s|%b" "$SINCE_REF"..HEAD 2>/dev/null)

if [ -z "$commits" ]; then
    echo "WARNING: No commits found between $SINCE_REF and HEAD" >&2
    echo "         CHANGELOG.md will not be updated" >&2
    rm -f "$BACKUP_FILE"
    exit 0
fi

# 섹션별 배열 (Added, Fixed, Changed, Breaking)
added_items=()
fixed_items=()
changed_items=()
breaking_items=()

# 디버그 모드
DEBUG="${DEBUG:-false}"

debug_log() {
    if [ "$DEBUG" = "true" ]; then
        echo "[DEBUG] $1" >&2
    fi
}

# 커밋 분석
debug_log "Analyzing commits from $SINCE_REF to HEAD..."

while IFS='|' read -r subject body; do
    # 빈 줄 건너뛰기
    [ -z "$subject" ] && continue

    debug_log "Processing: $subject"

    # BREAKING CHANGE 확인 (body에서)
    is_breaking=false
    if echo "$body" | grep -qE "BREAKING[ -]CHANGE:"; then
        is_breaking=true
        # BREAKING CHANGE 설명 추출
        breaking_desc=$(echo "$body" | grep -oP "BREAKING[ -]CHANGE:\s*\K.*" | head -1)
        if [ -n "$breaking_desc" ]; then
            breaking_items+=("$breaking_desc")
            debug_log "  → BREAKING: $breaking_desc"
        fi
    fi

    # Type과 Description 추출
    # 형식: type(scope): description 또는 type: description
    # 추가로 [TAG] 추출 (예: [F006], [EPIC-005])

    # Type 추출
    type=$(echo "$subject" | sed -E 's/^([a-z]+)(\(.+\))?:.*/\1/')

    # Description 추출 (type(scope): 이후 부분)
    description=$(echo "$subject" | sed -E 's/^[a-z]+(\([^)]+\))?:\s*//')

    # Tag 추출 ([F001], [EPIC-005] 등)
    tag=$(echo "$description" | grep -oP '\[([A-Z0-9-]+)\]' | head -1 || echo "")

    debug_log "  Type: $type, Desc: $description, Tag: $tag"

    # BREAKING이 아닌 경우 type에 따라 분류
    if [ "$is_breaking" = false ]; then
        case "$type" in
            feat|feature)
                added_items+=("$description")
                debug_log "  → Added"
                ;;
            fix)
                fixed_items+=("$description")
                debug_log "  → Fixed"
                ;;
            refactor|perf|style|chore)
                changed_items+=("$description")
                debug_log "  → Changed"
                ;;
            # docs, test 등은 CHANGELOG에 포함하지 않음
            *)
                debug_log "  → Skipped (type: $type)"
                ;;
        esac
    fi

done <<< "$commits"

# 날짜 (YYYY-MM-DD)
release_date=$(date +"%Y-%m-%d")

# CHANGELOG 섹션 생성
changelog_section=""
changelog_section+="## [$NEW_VERSION] - $release_date\n"
changelog_section+="\n"

# Breaking Changes (최우선)
if [ ${#breaking_items[@]} -gt 0 ]; then
    changelog_section+="### 💥 Breaking Changes\n"
    for item in "${breaking_items[@]}"; do
        changelog_section+="- $item\n"
    done
    changelog_section+="\n"
fi

# Added
if [ ${#added_items[@]} -gt 0 ]; then
    changelog_section+="### ✨ Added\n"
    for item in "${added_items[@]}"; do
        changelog_section+="- $item\n"
    done
    changelog_section+="\n"
fi

# Fixed
if [ ${#fixed_items[@]} -gt 0 ]; then
    changelog_section+="### 🐛 Fixed\n"
    for item in "${fixed_items[@]}"; do
        changelog_section+="- $item\n"
    done
    changelog_section+="\n"
fi

# Changed
if [ ${#changed_items[@]} -gt 0 ]; then
    changelog_section+="### 🔧 Changed\n"
    for item in "${changed_items[@]}"; do
        changelog_section+="- $item\n"
    done
    changelog_section+="\n"
fi

# 섹션이 비어있는지 확인
total_items=$((${#breaking_items[@]} + ${#added_items[@]} + ${#fixed_items[@]} + ${#changed_items[@]}))

if [ $total_items -eq 0 ]; then
    echo "WARNING: No relevant commits found for CHANGELOG" >&2
    echo "         (only docs, test, or unrecognized types)" >&2
    rm -f "$BACKUP_FILE"
    exit 0
fi

# CHANGELOG.md 업데이트 (기존 내용 앞에 새 섹션 삽입)
{
    echo "# Changelog"
    echo ""
    echo "All notable changes to this project will be documented in this file."
    echo ""
    echo "The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),"
    echo "and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)."
    echo ""
    echo -e "$changelog_section"

    # 기존 내용 추가 (헤더 부분 제외)
    # "## [" 로 시작하는 첫 번째 라인부터 끝까지
    sed -n '/^## \[/,$p' CHANGELOG.md

} > CHANGELOG.md.new || error_exit "Failed to generate new CHANGELOG.md"

# 새 파일로 교체
mv CHANGELOG.md.new CHANGELOG.md || error_exit "Failed to replace CHANGELOG.md"

# 백업 삭제
rm -f "$BACKUP_FILE"

echo "✓ CHANGELOG.md updated successfully"
echo "  Version: $NEW_VERSION"
echo "  Added: ${#added_items[@]} items"
echo "  Fixed: ${#fixed_items[@]} items"
echo "  Changed: ${#changed_items[@]} items"
echo "  Breaking: ${#breaking_items[@]} items"

exit 0
