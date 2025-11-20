#!/bin/bash
# notion-sync-commits.sh
# Sync pending commits to Notion worklog subpages
# Compatible with bash 3.2+
#
# Usage: source .claude/lib/notion-sync-commits.sh
#        sync_pending_commits
#
# Provides:
# - sync_pending_commits: Process pending commits queue and sync to Notion

# Prevent multiple sourcing
if [[ -n "${CLAUDE_NOTION_SYNC_COMMITS_LOADED:-}" ]]; then
    return 0
fi
CLAUDE_NOTION_SYNC_COMMITS_LOADED=1

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/notion-work-history.sh"
source "${SCRIPT_DIR}/notion-utils.sh"

# Repository root
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo ".")"

# Pending commits file
readonly PENDING_COMMITS_FILE="${REPO_ROOT}/.claude/cache/pending-commits.json"
readonly FAILED_COMMITS_FILE="${REPO_ROOT}/.claude/cache/failed-commits.json"

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Main Sync Function
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Sync pending commits to Notion
# Arguments: None
# Returns: 0 on success
# Example:
#   sync_pending_commits
sync_pending_commits() {
    log_info "Starting pending commits sync..." >&2

    # Check file exists
    if [[ ! -f "$PENDING_COMMITS_FILE" ]]; then
        log_info "No pending commits to sync" >&2
        return 0
    fi

    # Read pending commits
    local pending
    pending=$(cat "$PENDING_COMMITS_FILE" 2>/dev/null || echo "[]")

    # Check if empty
    local count
    count=$(echo "$pending" | python3 -c "import json, sys; print(len(json.load(sys.stdin)))")

    if [[ "$count" -eq 0 ]]; then
        log_info "No pending commits" >&2
        return 0
    fi

    log_info "Syncing ${count} pending commits..." >&2

    # Group by page_id
    local page_ids
    page_ids=$(echo "$pending" | python3 -c "
import json, sys
data = json.load(sys.stdin)
page_ids = list(set(c['page_id'] for c in data))
for pid in page_ids:
    print(pid)
")

    # Initialize failed commits array
    local failed_commits="[]"

    # Process each page
    for page_id in $page_ids; do
        log_info "Processing page: ${page_id}" >&2

        # Get commits for this page
        local commits
        commits=$(echo "$pending" | python3 -c "
import json, sys
data = json.load(sys.stdin)
page_commits = [c for c in data if c['page_id'] == '${page_id}']
for c in page_commits:
    print(json.dumps(c, ensure_ascii=False))
" | jq -s '.')

        # Get or create worklog subpage
        local subpage_id
        if ! subpage_id=$(get_or_create_worklog_subpage "$page_id"); then
            log_error "Failed to get/create worklog subpage for ${page_id}" >&2
            # Save all commits for this page to failed list
            failed_commits=$(echo "$failed_commits" | jq ". + $commits")
            continue
        fi

        # Generate table entries
        local entries=""
        local page_failed=0
        while IFS= read -r commit_json; do
            # Parse commit data
            local date_time=$(echo "$commit_json" | jq -r '.commit_date + " " + .commit_time')
            local hash=$(echo "$commit_json" | jq -r '.commit_hash[:7]')
            local type=$(echo "$commit_json" | jq -r '.work_type')
            # Get first line of commit message
            local msg=$(echo "$commit_json" | jq -r '.commit_msg' | head -1)
            local files=$(echo "$commit_json" | jq -r '.files_changed')
            local ins=$(echo "$commit_json" | jq -r '.insertions')
            local del=$(echo "$commit_json" | jq -r '.deletions')
            local file_list=$(echo "$commit_json" | jq -r '.file_list | join("\n")')

            # Format entry
            local entry
            if ! entry=$(format_worklog_table_entry "$date_time" "$hash" "$type" "$msg" "$files" "$ins" "$del" "$file_list"); then
                log_error "Failed to format entry for commit ${hash}" >&2
                # Add to failed commits
                failed_commits=$(echo "$failed_commits" | jq ". + [$commit_json]")
                page_failed=1
                continue
            fi

            entries="${entries}${entry}
"
        done < <(echo "$commits" | jq -c '.[]')

        # Skip if all entries failed
        if [[ -z "$entries" ]] || [[ $page_failed -eq 1 ]]; then
            log_warning "No valid entries to sync for page ${page_id}" >&2
            continue
        fi

        # Append to table
        if ! append_to_worklog_table "$subpage_id" "$entries"; then
            log_error "Failed to append entries to ${subpage_id}" >&2
            # Save all commits for this page to failed list
            failed_commits=$(echo "$failed_commits" | jq ". + $commits")
            continue
        fi

        log_success "Synced commits to ${subpage_id}" >&2
    done

    # Save failed commits if any
    if [[ "$(echo "$failed_commits" | jq 'length')" -gt 0 ]]; then
        log_warning "Some commits failed to sync, saved to failed-commits.json" >&2
        echo "$failed_commits" | jq '.' > "$FAILED_COMMITS_FILE"
    fi

    # Clear pending file
    echo "[]" > "$PENDING_COMMITS_FILE"
    log_success "Pending commits sync completed" >&2

    return 0
}

# Export functions
export -f sync_pending_commits
