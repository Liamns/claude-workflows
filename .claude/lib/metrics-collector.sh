#!/bin/bash
# Metrics Collector
# Collects and manages workflow metrics for the dashboard

# Metrics directories
METRICS_DIR=".claude/cache/metrics"
WORKFLOW_HISTORY_DIR=".claude/cache/workflow-history"
CURRENT_SESSION_FILE="$METRICS_DIR/current-session.json"
SUMMARY_FILE="$METRICS_DIR/summary.json"

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/git-stats-helper.sh" 2>/dev/null || true
source "$SCRIPT_DIR/cache-helper.sh" 2>/dev/null || true

# Initialize metrics system
metrics_init() {
    mkdir -p "$METRICS_DIR" "$WORKFLOW_HISTORY_DIR"

    # Initialize current session if not exists
    if [ ! -f "$CURRENT_SESSION_FILE" ]; then
        cat > "$CURRENT_SESSION_FILE" <<EOF
{
  "session_start": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "session_id": "$(date +%s)",
  "workflow_type": null,
  "performance": {
    "execution_time_seconds": 0,
    "cache_hits": 0,
    "cache_misses": 0,
    "cache_hit_rate_percent": 0,
    "parallel_agents": 0,
    "parallel_success": true
  },
  "tokens": {
    "total_used": 0,
    "saved": 0,
    "efficiency_percent": 0
  },
  "quality": {
    "test_coverage_percent": 0,
    "type_check_passed": false,
    "lint_passed": false,
    "architecture_valid": false,
    "security_issues": 0
  },
  "productivity": {
    "tasks_completed": 0,
    "bugs_fixed": 0,
    "features_added": 0,
    "files_changed": 0,
    "lines_added": 0,
    "lines_removed": 0
  }
}
EOF
    fi

    # Initialize summary if not exists
    if [ ! -f "$SUMMARY_FILE" ]; then
        cat > "$SUMMARY_FILE" <<EOF
{
  "lifetime": {
    "total_workflows": 0,
    "total_tokens_used": 0,
    "total_tokens_saved": 0,
    "total_tasks_completed": 0,
    "total_bugs_fixed": 0,
    "total_features_added": 0,
    "first_run": null,
    "last_run": null
  },
  "averages": {
    "workflow_duration_seconds": 0,
    "cache_hit_rate_percent": 0,
    "parallel_success_rate_percent": 0,
    "test_coverage_percent": 0
  }
}
EOF
    fi
}

# Update a specific metric field in current session
metrics_update() {
    local path="$1"
    local value="$2"

    metrics_init

    # Use jq if available, otherwise use sed (basic update)
    if command -v jq &> /dev/null; then
        local temp=$(mktemp)
        jq "$path = $value" "$CURRENT_SESSION_FILE" > "$temp" && mv "$temp" "$CURRENT_SESSION_FILE"
    else
        # Fallback: manual JSON update (limited support)
        echo "Warning: jq not installed. Metrics update may be limited." >&2
    fi
}

# Increment a numeric metric
metrics_increment() {
    local path="$1"
    local increment="${2:-1}"

    metrics_init

    if command -v jq &> /dev/null; then
        local temp=$(mktemp)
        jq "$path = ($path + $increment)" "$CURRENT_SESSION_FILE" > "$temp" && mv "$temp" "$CURRENT_SESSION_FILE"
    fi
}

# Record workflow start
metrics_workflow_start() {
    local workflow_type="$1"

    metrics_init
    metrics_update '.workflow_type' "\"$workflow_type\""
    metrics_update '.session_start' "\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""
    metrics_update '.session_id' "\"$(date +%s)\""
}

# Record workflow end and save to history
metrics_workflow_end() {
    local status="${1:-success}"
    local duration="$2"

    metrics_init

    # Update execution time
    if [ -n "$duration" ]; then
        metrics_update '.performance.execution_time_seconds' "$duration"
    fi

    # Get session ID
    local session_id=$(jq -r '.session_id' "$CURRENT_SESSION_FILE" 2>/dev/null || date +%s)

    # Save to history
    local history_file="$WORKFLOW_HISTORY_DIR/workflow-${session_id}.json"
    cp "$CURRENT_SESSION_FILE" "$history_file"

    # Update summary
    metrics_update_summary

    # Reset current session for next workflow
    rm -f "$CURRENT_SESSION_FILE"
}

# Update summary statistics from current session
metrics_update_summary() {
    if ! command -v jq &> /dev/null; then
        return 0
    fi

    metrics_init

    local current=$(cat "$CURRENT_SESSION_FILE")
    local summary=$(cat "$SUMMARY_FILE")

    # Extract values
    local tokens_used=$(echo "$current" | jq -r '.tokens.total_used // 0')
    local tokens_saved=$(echo "$current" | jq -r '.tokens.saved // 0')
    local tasks=$(echo "$current" | jq -r '.productivity.tasks_completed // 0')
    local bugs=$(echo "$current" | jq -r '.productivity.bugs_fixed // 0')
    local features=$(echo "$current" | jq -r '.productivity.features_added // 0')

    # Update summary
    local temp=$(mktemp)
    echo "$summary" | jq \
        --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --argjson tokens "$tokens_used" \
        --argjson saved "$tokens_saved" \
        --argjson tasks "$tasks" \
        --argjson bugs "$bugs" \
        --argjson features "$features" \
        '
        .lifetime.total_workflows += 1 |
        .lifetime.total_tokens_used += $tokens |
        .lifetime.total_tokens_saved += $saved |
        .lifetime.total_tasks_completed += $tasks |
        .lifetime.total_bugs_fixed += $bugs |
        .lifetime.total_features_added += $features |
        .lifetime.last_run = $now |
        if .lifetime.first_run == null then .lifetime.first_run = $now else . end
        ' > "$temp" && mv "$temp" "$SUMMARY_FILE"
}

# Collect cache metrics from cache-helper.sh
metrics_collect_cache() {
    if [ -f ".claude/cache/metadata/stats.json" ]; then
        local cache_stats=$(cat ".claude/cache/metadata/stats.json")
        local hits=$(echo "$cache_stats" | jq -r '.cache_hits // 0' 2>/dev/null || echo "0")
        local misses=$(echo "$cache_stats" | jq -r '.cache_misses // 0' 2>/dev/null || echo "0")
        local tokens_saved=$(echo "$cache_stats" | jq -r '.tokens_saved_estimate // 0' 2>/dev/null || echo "0")

        metrics_update '.performance.cache_hits' "$hits"
        metrics_update '.performance.cache_misses' "$misses"
        metrics_update '.tokens.saved' "$tokens_saved"

        # Calculate hit rate
        local total=$((hits + misses))
        if [ "$total" -gt 0 ]; then
            local hit_rate=$((hits * 100 / total))
            metrics_update '.performance.cache_hit_rate_percent' "$hit_rate"
        fi
    fi
}

# Collect Git metrics
metrics_collect_git() {
    if command -v git &> /dev/null && [ -d .git ]; then
        local git_stats=$(git_stats_uncommitted 2>/dev/null || echo '{"staged":0,"unstaged":0,"untracked":0}')
        local files_changed=$(echo "$git_stats" | jq -r '(.staged + .unstaged + .untracked) // 0' 2>/dev/null || echo "0")

        metrics_update '.productivity.files_changed' "$files_changed"

        # Get lines changed if we have git diff
        local diff_stats=$(git_stats_diff 2>/dev/null || echo '{"insertions":0,"deletions":0}')
        local insertions=$(echo "$diff_stats" | jq -r '.insertions // 0' 2>/dev/null || echo "0")
        local deletions=$(echo "$diff_stats" | jq -r '.deletions // 0' 2>/dev/null || echo "0")

        metrics_update '.productivity.lines_added' "$insertions"
        metrics_update '.productivity.lines_removed' "$deletions"
    fi
}

# Record task completion
metrics_task_completed() {
    local task_type="${1:-task}"  # task, bug, feature

    metrics_init
    metrics_increment '.productivity.tasks_completed'

    case "$task_type" in
        bug)
            metrics_increment '.productivity.bugs_fixed'
            ;;
        feature)
            metrics_increment '.productivity.features_added'
            ;;
    esac
}

# Record quality check result
metrics_quality_check() {
    local check_type="$1"  # test_coverage, type_check, lint, architecture
    local result="$2"       # true/false or numeric value

    metrics_init

    case "$check_type" in
        test_coverage)
            metrics_update '.quality.test_coverage_percent' "$result"
            ;;
        type_check)
            metrics_update '.quality.type_check_passed' "$result"
            ;;
        lint)
            metrics_update '.quality.lint_passed' "$result"
            ;;
        architecture)
            metrics_update '.quality.architecture_valid' "$result"
            ;;
        security)
            metrics_update '.quality.security_issues' "$result"
            ;;
    esac
}

# Get daily metrics (today's completed workflows)
metrics_get_daily() {
    local today=$(date +%Y-%m-%d)
    local daily_file="$METRICS_DIR/daily-$today.json"

    if [ -f "$daily_file" ]; then
        cat "$daily_file"
    else
        # Aggregate from workflow history
        local total_workflows=0
        local total_tasks=0
        local total_bugs=0
        local total_features=0

        for workflow_file in "$WORKFLOW_HISTORY_DIR"/workflow-*.json; do
            [ -f "$workflow_file" ] || continue

            # Check if workflow is from today
            local session_start=$(jq -r '.session_start' "$workflow_file" 2>/dev/null | cut -d'T' -f1)
            if [ "$session_start" = "$today" ]; then
                total_workflows=$((total_workflows + 1))
                total_tasks=$((total_tasks + $(jq -r '.productivity.tasks_completed // 0' "$workflow_file" 2>/dev/null || echo "0")))
                total_bugs=$((total_bugs + $(jq -r '.productivity.bugs_fixed // 0' "$workflow_file" 2>/dev/null || echo "0")))
                total_features=$((total_features + $(jq -r '.productivity.features_added // 0' "$workflow_file" 2>/dev/null || echo "0")))
            fi
        done

        cat > "$daily_file" <<EOF
{
  "date": "$today",
  "workflows": $total_workflows,
  "tasks": $total_tasks,
  "bugs": $total_bugs,
  "features": $total_features
}
EOF
        cat "$daily_file"
    fi
}

# Export all current metrics as JSON
metrics_export() {
    metrics_init
    metrics_collect_cache
    metrics_collect_git

    cat "$CURRENT_SESSION_FILE"
}

# Reset current session
metrics_reset() {
    rm -f "$CURRENT_SESSION_FILE"
    metrics_init
    echo "Metrics reset successfully."
}

# Export functions
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
    export -f metrics_init
    export -f metrics_update
    export -f metrics_increment
    export -f metrics_workflow_start
    export -f metrics_workflow_end
    export -f metrics_update_summary
    export -f metrics_collect_cache
    export -f metrics_collect_git
    export -f metrics_task_completed
    export -f metrics_quality_check
    export -f metrics_get_daily
    export -f metrics_export
    export -f metrics_reset
fi
