#!/bin/bash
# session-manager.sh
# Workflow Session Manager - Compact 복원을 위한 워크플로우 상태 관리
# Compatible with bash 3.2+
#
# Usage: source .claude/lib/session-manager.sh
#
# Provides:
# - init_workflow_session: 워크플로우 세션 초기화
# - save_workflow_state: 현재 상태 저장
# - load_workflow_state: 저장된 상태 로드
# - add_critical_rule: 필수 규칙 추가
# - add_checkpoint: 체크포인트 추가
# - clear_workflow_state: 상태 초기화
# - restore_from_compact: Compact 후 복원

# Prevent multiple sourcing
if [[ -n "${CLAUDE_SESSION_MANAGER_LOADED:-}" ]]; then
    return 0
fi
CLAUDE_SESSION_MANAGER_LOADED=1

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh" 2>/dev/null || true

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Configuration
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SESSION_STATE_FILE="${SESSION_STATE_FILE:-.claude/cache/workflow-state.json}"
SESSION_BACKUP_DIR="${SESSION_BACKUP_DIR:-.claude/cache/session-backups}"

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Logging Functions (fallback if common.sh not available)
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if ! type log_info &>/dev/null; then
    log_info() { echo "[INFO] $*"; }
    log_error() { echo "[ERROR] $*" >&2; }
    log_success() { echo "[SUCCESS] $*"; }
    log_warn() { echo "[WARN] $*"; }
fi

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Session Initialization
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Initialize a new workflow session
# Arguments:
#   $1 - Workflow type (major, epic, minor, triage)
#   $2 - Feature/task name
#   $3 - Feature number (optional)
# Returns:
#   0 on success, 1 on failure
init_workflow_session() {
    local workflow_type="$1"
    local task_name="$2"
    local feature_number="${3:-}"

    if [[ -z "$workflow_type" ]] || [[ -z "$task_name" ]]; then
        log_error "Usage: init_workflow_session <workflow_type> <task_name> [feature_number]"
        return 1
    fi

    # Ensure cache directory exists
    mkdir -p "$(dirname "$SESSION_STATE_FILE")"
    mkdir -p "$SESSION_BACKUP_DIR"

    # Create initial state
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    local state
    state=$(jq -n \
        --arg workflow "$workflow_type" \
        --arg task "$task_name" \
        --arg number "$feature_number" \
        --arg started "$timestamp" \
        --arg updated "$timestamp" \
        '{
            workflow_type: $workflow,
            task_name: $task,
            feature_number: $number,
            started_at: $started,
            updated_at: $updated,
            current_step: 1,
            total_steps: 0,
            status: "in_progress",
            critical_rules: [],
            checkpoints: [],
            context: {}
        }')

    echo "$state" > "$SESSION_STATE_FILE"
    log_success "Workflow session initialized: $workflow_type - $task_name"
    return 0
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# State Management
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Save current workflow state
# Arguments:
#   $1 - Current step number
#   $2 - Step description
#   $3 - Additional context (JSON string, optional)
# Returns:
#   0 on success, 1 on failure
save_workflow_state() {
    local current_step="$1"
    local step_description="$2"
    local additional_context="${3:-"{}"}"

    if [[ ! -f "$SESSION_STATE_FILE" ]]; then
        log_error "No active session. Call init_workflow_session first."
        return 1
    fi

    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Validate context is valid JSON, default to empty object if not
    if ! echo "$additional_context" | jq . &>/dev/null; then
        additional_context="{}"
    fi

    # Update state using temp file approach for safety
    local updated_state
    updated_state=$(jq \
        --arg step "$current_step" \
        --arg desc "$step_description" \
        --arg updated "$timestamp" \
        ".current_step = (\$step | tonumber) |
         .step_description = \$desc |
         .updated_at = \$updated |
         .context = (.context + $additional_context)" \
        "$SESSION_STATE_FILE")

    echo "$updated_state" > "$SESSION_STATE_FILE"
    log_info "State saved: Step $current_step - $step_description"
    return 0
}

# Load workflow state
# Arguments: none
# Output: JSON state to stdout
# Returns:
#   0 on success, 1 if no state exists
load_workflow_state() {
    if [[ ! -f "$SESSION_STATE_FILE" ]]; then
        log_warn "No saved workflow state found"
        return 1
    fi

    cat "$SESSION_STATE_FILE"
    return 0
}

# Check if workflow session exists
# Returns:
#   0 if session exists, 1 if not
has_workflow_session() {
    [[ -f "$SESSION_STATE_FILE" ]]
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Critical Rules Management
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Add a critical rule that must be preserved after Compact
# Arguments:
#   $1 - Rule ID (unique identifier)
#   $2 - Rule description
#   $3 - Rule priority (1=highest)
# Returns:
#   0 on success, 1 on failure
add_critical_rule() {
    local rule_id="$1"
    local rule_description="$2"
    local priority="${3:-5}"

    if [[ ! -f "$SESSION_STATE_FILE" ]]; then
        log_error "No active session"
        return 1
    fi

    if [[ -z "$rule_id" ]] || [[ -z "$rule_description" ]]; then
        log_error "Usage: add_critical_rule <rule_id> <description> [priority]"
        return 1
    fi

    local updated_state
    updated_state=$(jq \
        --arg id "$rule_id" \
        --arg desc "$rule_description" \
        --arg pri "$priority" \
        '.critical_rules += [{
            id: $id,
            description: $desc,
            priority: ($pri | tonumber)
        }] | .critical_rules |= unique_by(.id)' \
        "$SESSION_STATE_FILE")

    echo "$updated_state" > "$SESSION_STATE_FILE"
    log_info "Critical rule added: $rule_id"
    return 0
}

# Get all critical rules
# Output: JSON array of rules
get_critical_rules() {
    if [[ ! -f "$SESSION_STATE_FILE" ]]; then
        echo "[]"
        return 1
    fi

    jq '.critical_rules | sort_by(.priority)' "$SESSION_STATE_FILE"
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Checkpoint Management
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Add a checkpoint for progress tracking
# Arguments:
#   $1 - Checkpoint name
#   $2 - Checkpoint data (JSON string)
# Returns:
#   0 on success, 1 on failure
add_checkpoint() {
    local checkpoint_name="$1"
    local checkpoint_data="${2:-{}}"

    if [[ ! -f "$SESSION_STATE_FILE" ]]; then
        log_error "No active session"
        return 1
    fi

    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    local updated_state
    updated_state=$(jq \
        --arg name "$checkpoint_name" \
        --arg ts "$timestamp" \
        --argjson data "$checkpoint_data" \
        '.checkpoints += [{
            name: $name,
            timestamp: $ts,
            data: $data
        }]' \
        "$SESSION_STATE_FILE")

    echo "$updated_state" > "$SESSION_STATE_FILE"
    log_info "Checkpoint added: $checkpoint_name"
    return 0
}

# Get latest checkpoint
# Output: JSON checkpoint object
get_latest_checkpoint() {
    if [[ ! -f "$SESSION_STATE_FILE" ]]; then
        echo "{}"
        return 1
    fi

    jq '.checkpoints | last // {}' "$SESSION_STATE_FILE"
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Compact Recovery
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Restore workflow context after Compact
# This function generates a recovery prompt for Claude
# Returns:
#   0 on success, 1 if no state to restore
restore_from_compact() {
    if [[ ! -f "$SESSION_STATE_FILE" ]]; then
        log_warn "No workflow state to restore"
        return 1
    fi

    local state
    state=$(cat "$SESSION_STATE_FILE")

    local workflow_type
    workflow_type=$(echo "$state" | jq -r '.workflow_type')

    local task_name
    task_name=$(echo "$state" | jq -r '.task_name')

    local current_step
    current_step=$(echo "$state" | jq -r '.current_step')

    local step_desc
    step_desc=$(echo "$state" | jq -r '.step_description // "Unknown"')

    local critical_rules
    critical_rules=$(echo "$state" | jq -r '.critical_rules[] | "  - [\(.id)] \(.description)"' 2>/dev/null || echo "  (없음)")

    local latest_checkpoint
    latest_checkpoint=$(echo "$state" | jq -r '.checkpoints | last | .name // "없음"')

    # Generate recovery prompt
    cat << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔄 워크플로우 세션 복원
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**워크플로우**: /${workflow_type}
**작업**: ${task_name}
**현재 단계**: Step ${current_step} - ${step_desc}
**마지막 체크포인트**: ${latest_checkpoint}

**⚠️ Critical Rules (반드시 준수)**:
${critical_rules}

**다음 액션**:
- 위 Critical Rules를 반드시 따르세요
- Step ${current_step}부터 계속 진행하세요
- 문서 생성/사용자 확인 단계를 건너뛰지 마세요

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF

    return 0
}

# Generate compact recovery instructions as JSON
# This can be included in Claude's context
get_recovery_context() {
    if [[ ! -f "$SESSION_STATE_FILE" ]]; then
        echo "{}"
        return 1
    fi

    jq '{
        recovery_needed: true,
        workflow_type: .workflow_type,
        task_name: .task_name,
        current_step: .current_step,
        step_description: .step_description,
        critical_rules: .critical_rules,
        latest_checkpoint: (.checkpoints | last),
        context: .context
    }' "$SESSION_STATE_FILE"
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Cleanup
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Clear workflow state (call when workflow completes)
# Arguments:
#   $1 - Archive flag (optional, "archive" to keep backup)
clear_workflow_state() {
    local archive_flag="${1:-}"

    if [[ ! -f "$SESSION_STATE_FILE" ]]; then
        return 0
    fi

    if [[ "$archive_flag" == "archive" ]]; then
        local timestamp
        timestamp=$(date +"%Y%m%d_%H%M%S")
        local backup_file="${SESSION_BACKUP_DIR}/workflow-state_${timestamp}.json"
        mv "$SESSION_STATE_FILE" "$backup_file"
        log_info "Session archived: $backup_file"
    else
        rm -f "$SESSION_STATE_FILE"
        log_info "Session cleared"
    fi

    return 0
}

# Mark workflow as completed
complete_workflow() {
    if [[ ! -f "$SESSION_STATE_FILE" ]]; then
        return 1
    fi

    local updated_state
    updated_state=$(jq \
        '.status = "completed" |
         .completed_at = (now | strftime("%Y-%m-%dT%H:%M:%SZ"))' \
        "$SESSION_STATE_FILE")

    echo "$updated_state" > "$SESSION_STATE_FILE"
    log_success "Workflow marked as completed"

    # Archive the completed session
    clear_workflow_state "archive"
    return 0
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Self-Test
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

run_session_manager_test() {
    echo "Running session-manager.sh self-test..."
    echo ""

    local tests_passed=0
    local tests_failed=0
    local test_state_file="/tmp/test-workflow-state.json"

    # Temporarily override state file for testing
    local orig_state_file="$SESSION_STATE_FILE"
    SESSION_STATE_FILE="$test_state_file"

    # Test 1: Initialize session
    echo "Test 1: init_workflow_session"
    if init_workflow_session "major" "test-feature" "001" &>/dev/null; then
        if [[ -f "$test_state_file" ]]; then
            echo "  ✅ PASS"
            ((tests_passed++))
        else
            echo "  ❌ FAIL: State file not created"
            ((tests_failed++))
        fi
    else
        echo "  ❌ FAIL: Function returned error"
        ((tests_failed++))
    fi

    # Test 2: Add critical rule
    echo "Test 2: add_critical_rule"
    if add_critical_rule "no_skip_docs" "문서 생성 단계 필수" 1 &>/dev/null; then
        local rule_count
        rule_count=$(jq '.critical_rules | length' "$test_state_file")
        if [[ "$rule_count" -eq 1 ]]; then
            echo "  ✅ PASS"
            ((tests_passed++))
        else
            echo "  ❌ FAIL: Rule not added"
            ((tests_failed++))
        fi
    else
        echo "  ❌ FAIL: Function returned error"
        ((tests_failed++))
    fi

    # Test 3: Save workflow state
    echo "Test 3: save_workflow_state"
    if save_workflow_state 2 "설계 단계" '{"design":"started"}' &>/dev/null; then
        local step
        step=$(jq -r '.current_step' "$test_state_file")
        if [[ "$step" -eq 2 ]]; then
            echo "  ✅ PASS"
            ((tests_passed++))
        else
            echo "  ❌ FAIL: Step not updated"
            ((tests_failed++))
        fi
    else
        echo "  ❌ FAIL: Function returned error"
        ((tests_failed++))
    fi

    # Test 4: Add checkpoint
    echo "Test 4: add_checkpoint"
    if add_checkpoint "design_complete" '{"files":["spec.md"]}' &>/dev/null; then
        local cp_count
        cp_count=$(jq '.checkpoints | length' "$test_state_file")
        if [[ "$cp_count" -eq 1 ]]; then
            echo "  ✅ PASS"
            ((tests_passed++))
        else
            echo "  ❌ FAIL: Checkpoint not added"
            ((tests_failed++))
        fi
    else
        echo "  ❌ FAIL: Function returned error"
        ((tests_failed++))
    fi

    # Test 5: Load workflow state
    echo "Test 5: load_workflow_state"
    local loaded_state
    loaded_state=$(load_workflow_state 2>/dev/null)
    if [[ -n "$loaded_state" ]]; then
        local workflow
        workflow=$(echo "$loaded_state" | jq -r '.workflow_type')
        if [[ "$workflow" == "major" ]]; then
            echo "  ✅ PASS"
            ((tests_passed++))
        else
            echo "  ❌ FAIL: Workflow type mismatch"
            ((tests_failed++))
        fi
    else
        echo "  ❌ FAIL: No state loaded"
        ((tests_failed++))
    fi

    # Test 6: Restore from compact
    echo "Test 6: restore_from_compact"
    local recovery
    recovery=$(restore_from_compact 2>/dev/null)
    if [[ "$recovery" == *"워크플로우 세션 복원"* ]]; then
        echo "  ✅ PASS"
        ((tests_passed++))
    else
        echo "  ❌ FAIL: Recovery output missing"
        ((tests_failed++))
    fi

    # Cleanup
    rm -f "$test_state_file"
    SESSION_STATE_FILE="$orig_state_file"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Results: $tests_passed passed, $tests_failed failed"

    if [[ $tests_failed -eq 0 ]]; then
        echo "All tests passed!"
        return 0
    else
        echo "Some tests failed!"
        return 1
    fi
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Main (for direct execution)
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        test)
            run_session_manager_test
            ;;
        init)
            if [[ $# -lt 3 ]]; then
                echo "Usage: $0 init <workflow_type> <task_name> [feature_number]"
                exit 1
            fi
            init_workflow_session "$2" "$3" "${4:-}"
            ;;
        save)
            if [[ $# -lt 3 ]]; then
                echo "Usage: $0 save <step_number> <description> [context_json]"
                exit 1
            fi
            save_workflow_state "$2" "$3" "${4:-{}}"
            ;;
        restore)
            restore_from_compact
            ;;
        status)
            if has_workflow_session; then
                load_workflow_state | jq .
            else
                echo "No active session"
            fi
            ;;
        clear)
            clear_workflow_state "${2:-}"
            ;;
        *)
            echo "Usage: $0 {test|init|save|restore|status|clear}"
            echo ""
            echo "Commands:"
            echo "  test                              - Run self-tests"
            echo "  init <type> <name> [number]       - Initialize session"
            echo "  save <step> <desc> [context]      - Save current state"
            echo "  restore                           - Show recovery prompt"
            echo "  status                            - Show current session"
            echo "  clear [archive]                   - Clear session"
            exit 1
            ;;
    esac
fi

# Export functions
export -f init_workflow_session
export -f save_workflow_state
export -f load_workflow_state
export -f has_workflow_session
export -f add_critical_rule
export -f get_critical_rules
export -f add_checkpoint
export -f get_latest_checkpoint
export -f restore_from_compact
export -f get_recovery_context
export -f clear_workflow_state
export -f complete_workflow
