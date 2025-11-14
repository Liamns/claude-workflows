#!/bin/bash
# analyze-commits.sh
# Conventional Commits 분석하여 버전 타입 결정
#
# 사용법:
#   bash analyze-commits.sh "$commits"
#
# 입력: 커밋 메시지 (여러 줄, \n 구분)
# 출력: major | minor | patch | skip

set -euo pipefail

# 사용법 출력
usage() {
    cat <<EOF
Usage: analyze-commits.sh <commits>

Analyze Conventional Commits and determine version bump type.

Arguments:
  commits    Commit messages (newline-separated)

Output:
  major      BREAKING CHANGE detected
  minor      feat commits detected
  patch      fix commits detected
  skip       No version-relevant commits

Examples:
  # From git log
  commits=\$(git log --format=%s HEAD~5..HEAD)
  bash analyze-commits.sh "\$commits"

  # From PR
  commits=\$(git log --format="%s|%b" \$BASE_SHA..\$HEAD_SHA)
  bash analyze-commits.sh "\$commits"
EOF
}

# 인자 확인
if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
    exit 0
fi

commits="$1"

# 결과 변수
has_breaking=false
has_feat=false
has_fix=false

# 디버그 모드 (환경 변수로 활성화)
DEBUG="${DEBUG:-false}"

debug_log() {
    if [ "$DEBUG" = "true" ]; then
        echo "[DEBUG] $1" >&2
    fi
}

# 커밋 분석
debug_log "Analyzing commits..."

while IFS= read -r commit_msg; do
    # 빈 줄 건너뛰기
    [ -z "$commit_msg" ] && continue

    debug_log "Commit: $commit_msg"

    # BREAKING CHANGE 확인 (body 또는 footer)
    # 패턴: "BREAKING CHANGE:" 또는 "BREAKING-CHANGE:"
    if echo "$commit_msg" | grep -qE "BREAKING[ -]CHANGE:"; then
        has_breaking=true
        debug_log "  → BREAKING CHANGE detected"
        continue  # BREAKING 발견 시 더 이상 확인 불필요
    fi

    # Type 추출 (첫 줄의 type만 추출)
    # 형식: type(scope): subject 또는 type: subject
    type=$(echo "$commit_msg" | head -1 | sed -E 's/^([a-z]+)(\(.+\))?:.*/\1/')

    debug_log "  → Type: $type"

    # Type에 따라 플래그 설정
    case "$type" in
        feat|feature)
            has_feat=true
            debug_log "  → feat detected"
            ;;
        fix)
            has_fix=true
            debug_log "  → fix detected"
            ;;
        # docs, chore, style, refactor, test 등은 버전 증가 없음
        *)
            debug_log "  → non-version type ($type)"
            ;;
    esac

done <<< "$commits"

# 버전 타입 결정 (우선순위: BREAKING > feat > fix)
if [ "$has_breaking" = true ]; then
    echo "major"
    debug_log "Result: major (BREAKING CHANGE)"
elif [ "$has_feat" = true ]; then
    echo "minor"
    debug_log "Result: minor (feat)"
elif [ "$has_fix" = true ]; then
    echo "patch"
    debug_log "Result: patch (fix)"
else
    echo "skip"
    debug_log "Result: skip (no version-relevant commits)"
fi

exit 0
