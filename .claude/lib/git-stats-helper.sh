#!/bin/bash
# Git Statistics Helper
# Provides functions to collect Git statistics for metrics dashboard

# Get today's commit statistics
git_stats_today() {
    local today=$(date +%Y-%m-%d)
    local commit_count=$(git log --oneline --since="$today 00:00" --until="$today 23:59" 2>/dev/null | wc -l | tr -d ' ')
    local files_changed=$(git diff --stat HEAD@{1.day.ago}..HEAD 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
    local insertions=$(git diff --stat HEAD@{1.day.ago}..HEAD 2>/dev/null | tail -1 | grep -oE '[0-9]+ insertion' | awk '{print $1}' || echo "0")
    local deletions=$(git diff --stat HEAD@{1.day.ago}..HEAD 2>/dev/null | tail -1 | grep -oE '[0-9]+ deletion' | awk '{print $1}' || echo "0")

    echo "{\"commits\":$commit_count,\"files\":${files_changed:-0},\"insertions\":${insertions:-0},\"deletions\":${deletions:-0}}"
}

# Get this week's commit statistics
git_stats_week() {
    local week_start=$(date -v-mon +%Y-%m-%d 2>/dev/null || date -d 'last monday' +%Y-%m-%d)
    local commit_count=$(git log --oneline --since="$week_start" 2>/dev/null | wc -l | tr -d ' ')

    echo "{\"commits\":$commit_count}"
}

# Get current branch statistics
git_stats_current_branch() {
    local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
    local ahead=$(git rev-list --count @{upstream}..HEAD 2>/dev/null || echo "0")
    local behind=$(git rev-list --count HEAD..@{upstream} 2>/dev/null || echo "0")

    echo "{\"branch\":\"$branch\",\"ahead\":$ahead,\"behind\":$behind}"
}

# Get uncommitted changes statistics
git_stats_uncommitted() {
    local staged=$(git diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
    local unstaged=$(git diff --numstat 2>/dev/null | wc -l | tr -d ' ')
    local untracked=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')

    echo "{\"staged\":$staged,\"unstaged\":$unstaged,\"untracked\":$untracked}"
}

# Get last commit information
git_stats_last_commit() {
    local hash=$(git log -1 --format=%h 2>/dev/null || echo "none")
    local message=$(git log -1 --format=%s 2>/dev/null | sed 's/"/\\"/g' || echo "No commits")
    local author=$(git log -1 --format=%an 2>/dev/null | sed 's/"/\\"/g' || echo "unknown")
    local time=$(git log -1 --format=%cr 2>/dev/null || echo "never")

    echo "{\"hash\":\"$hash\",\"message\":\"$message\",\"author\":\"$author\",\"time\":\"$time\"}"
}

# Get repository statistics (cached for performance)
git_stats_repo() {
    local cache_file=".claude/cache/git/repo-stats.json"
    local cache_ttl=300  # 5 minutes

    # Check cache
    if [ -f "$cache_file" ]; then
        local cache_age=$(($(date +%s) - $(stat -f %m "$cache_file" 2>/dev/null || stat -c %Y "$cache_file" 2>/dev/null)))
        if [ "$cache_age" -lt "$cache_ttl" ]; then
            cat "$cache_file"
            return 0
        fi
    fi

    # Collect fresh stats
    local total_commits=$(git rev-list --count HEAD 2>/dev/null || echo "0")
    local contributors=$(git shortlog -sn --all 2>/dev/null | wc -l | tr -d ' ')
    local branches=$(git branch -a 2>/dev/null | wc -l | tr -d ' ')
    local tags=$(git tag 2>/dev/null | wc -l | tr -d ' ')

    local result="{\"total_commits\":$total_commits,\"contributors\":$contributors,\"branches\":$branches,\"tags\":$tags}"

    # Save to cache
    mkdir -p "$(dirname "$cache_file")"
    echo "$result" > "$cache_file"

    echo "$result"
}

# Get detailed diff statistics for a specific commit or range
git_stats_diff() {
    local target="${1:-HEAD}"
    local files=$(git diff --stat "$target" 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
    local insertions=$(git diff --stat "$target" 2>/dev/null | tail -1 | grep -oE '[0-9]+ insertion' | awk '{print $1}' || echo "0")
    local deletions=$(git diff --stat "$target" 2>/dev/null | tail -1 | grep -oE '[0-9]+ deletion' | awk '{print $1}' || echo "0")

    echo "{\"files\":${files:-0},\"insertions\":${insertions:-0},\"deletions\":${deletions:-0}}"
}

# Get comprehensive Git statistics (all in one)
git_stats_all() {
    local today=$(git_stats_today)
    local week=$(git_stats_week)
    local branch=$(git_stats_current_branch)
    local uncommitted=$(git_stats_uncommitted)
    local last_commit=$(git_stats_last_commit)
    local repo=$(git_stats_repo)

    cat <<EOF
{
  "today": $today,
  "week": $week,
  "branch": $branch,
  "uncommitted": $uncommitted,
  "last_commit": $last_commit,
  "repository": $repo
}
EOF
}

# Get list of files changed in a specific commit
# Arguments:
#   $1 - Commit hash (default: HEAD)
# Output:
#   List of file paths (one per line)
# Returns:
#   0 on success
git_commit_files() {
    local commit_hash="${1:-HEAD}"
    git diff-tree --no-commit-id --name-only -r "$commit_hash" 2>/dev/null
}

# Export functions for use in other scripts
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
    export -f git_stats_today
    export -f git_stats_week
    export -f git_stats_current_branch
    export -f git_stats_uncommitted
    export -f git_stats_last_commit
    export -f git_stats_repo
    export -f git_stats_diff
    export -f git_stats_all
    export -f git_commit_files
fi
