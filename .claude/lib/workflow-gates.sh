#!/bin/bash
# workflow-gates.sh
# Document Gate Validator - 워크플로우 필수 문서 검증
# Compatible with bash 3.2+
#
# Usage: source .claude/lib/workflow-gates.sh
#
# Provides:
# - validate_document_gate: 필수 문서 존재 확인
# - check_required_documents: 문서 목록 검증
# - get_gate_config: 워크플로우별 필수 문서 조회

# Prevent multiple sourcing
if [[ -n "${CLAUDE_WORKFLOW_GATES_LOADED:-}" ]]; then
    return 0
fi
CLAUDE_WORKFLOW_GATES_LOADED=1

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh" 2>/dev/null || true

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Configuration
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Minimum file size to be considered valid (bytes)
readonly MIN_DOC_SIZE=100

# Gate configuration per workflow type
declare -A GATE_CONFIG
GATE_CONFIG["major"]="spec.md plan.md tasks.md"
GATE_CONFIG["epic"]="epic.md roadmap.md"
GATE_CONFIG["minor"]="fix-analysis.md"

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
# Configuration Functions
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Get required documents for a workflow type
# Arguments:
#   $1 - Workflow type (major, epic, minor)
# Output:
#   Space-separated list of required documents
# Returns:
#   0 on success, 1 if workflow type unknown
get_gate_config() {
    local workflow_type="$1"

    if [[ -z "$workflow_type" ]]; then
        log_error "Workflow type is required"
        return 1
    fi

    local docs="${GATE_CONFIG[$workflow_type]:-}"

    if [[ -z "$docs" ]]; then
        log_error "Unknown workflow type: $workflow_type"
        log_error "Valid types: major, epic, minor"
        return 1
    fi

    echo "$docs"
    return 0
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Validation Functions
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Check if a single document exists and has minimum content
# Arguments:
#   $1 - Document path
# Output:
#   Validation result message
# Returns:
#   0 if valid, 1 if invalid
check_document() {
    local doc_path="$1"

    if [[ ! -f "$doc_path" ]]; then
        echo "NOT_FOUND"
        return 1
    fi

    local file_size
    file_size=$(wc -c < "$doc_path" 2>/dev/null | tr -d ' ')

    if [[ "$file_size" -lt "$MIN_DOC_SIZE" ]]; then
        echo "TOO_SMALL ($file_size bytes)"
        return 1
    fi

    echo "OK ($file_size bytes)"
    return 0
}

# Check all required documents
# Arguments:
#   $1 - Base directory (e.g., .specify/features/NNN-name/)
#   $@ - List of required document names
# Output:
#   Validation results for each document
# Returns:
#   0 if all valid, 1 if any invalid
check_required_documents() {
    local base_dir="$1"
    shift
    local docs=("$@")

    if [[ -z "$base_dir" ]]; then
        log_error "Base directory is required"
        return 1
    fi

    if [[ ${#docs[@]} -eq 0 ]]; then
        log_error "No documents to check"
        return 1
    fi

    local all_valid=true
    local missing_docs=()
    local invalid_docs=()

    echo ""
    echo "Document Gate 검증 중..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    for doc in "${docs[@]}"; do
        local doc_path="${base_dir}/${doc}"
        local result
        result=$(check_document "$doc_path")
        local status=$?

        if [[ $status -eq 0 ]]; then
            echo "  ✅ $doc - $result"
        else
            echo "  ❌ $doc - $result"
            all_valid=false
            if [[ "$result" == "NOT_FOUND" ]]; then
                missing_docs+=("$doc")
            else
                invalid_docs+=("$doc")
            fi
        fi
    done

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if $all_valid; then
        return 0
    else
        return 1
    fi
}

# Main validation function - Document Gate
# Arguments:
#   $1 - Workflow type (major, epic, minor)
#   $2 - Feature number (e.g., "005")
#   $3 - Feature name (e.g., "todo6-workflow-improvements")
# Output:
#   Gate validation result
# Returns:
#   0 if gate passes, 1 if gate fails
validate_document_gate() {
    local workflow_type="$1"
    local feature_number="$2"
    local feature_name="$3"

    # Validate inputs
    if [[ -z "$workflow_type" ]]; then
        log_error "Workflow type is required"
        return 1
    fi

    if [[ -z "$feature_number" ]]; then
        log_error "Feature number is required"
        return 1
    fi

    if [[ -z "$feature_name" ]]; then
        log_error "Feature name is required"
        return 1
    fi

    # Get required documents for this workflow
    local required_docs
    required_docs=$(get_gate_config "$workflow_type")
    if [[ $? -ne 0 ]]; then
        return 1
    fi

    # Convert to array
    local docs_array
    read -ra docs_array <<< "$required_docs"

    # Determine base directory
    local base_dir
    case "$workflow_type" in
        major|minor)
            base_dir=".specify/features/${feature_number}-${feature_name}"
            ;;
        epic)
            base_dir=".specify/epics/${feature_number}-${feature_name}"
            ;;
        *)
            base_dir=".specify/features/${feature_number}-${feature_name}"
            ;;
    esac

    log_info "Document Gate 검증: $workflow_type 워크플로우"
    log_info "검증 디렉토리: $base_dir"

    # Check if directory exists
    if [[ ! -d "$base_dir" ]]; then
        log_error "Feature 디렉토리가 존재하지 않습니다: $base_dir"
        return 1
    fi

    # Check all required documents
    if check_required_documents "$base_dir" "${docs_array[@]}"; then
        echo ""
        log_success "✅ Document Gate 검증 통과!"
        log_success "모든 필수 문서가 확인되었습니다."
        log_info "구현 단계로 진행할 수 있습니다."
        return 0
    else
        echo ""
        log_error "❌ Document Gate 검증 실패!"
        log_error "필수 문서가 누락되었거나 내용이 부족합니다."
        echo ""
        log_warn "구현 단계로 진행할 수 없습니다."
        log_warn "먼저 누락된 문서를 작성해주세요."
        echo ""
        log_info "필수 문서 목록 ($workflow_type):"
        for doc in "${docs_array[@]}"; do
            echo "  - $doc"
        done
        return 1
    fi
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Utility Functions
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# List all supported workflow types
list_workflow_types() {
    echo "Supported workflow types:"
    for key in "${!GATE_CONFIG[@]}"; do
        echo "  - $key: ${GATE_CONFIG[$key]}"
    done
}

# Generate gate skip warning (for emergency bypass)
warn_gate_bypass() {
    echo ""
    log_warn "⚠️  Document Gate를 우회하려고 합니다!"
    log_warn "이 작업은 기록됩니다."
    echo ""
    echo "Gate 우회 시 발생할 수 있는 문제:"
    echo "  - 기획 문서 없이 구현 시작"
    echo "  - 요구사항 누락 가능성"
    echo "  - 코드 리뷰 시 거부 가능성"
    echo ""
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Self-Test
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

run_workflow_gates_test() {
    echo "Running workflow-gates.sh self-test..."
    echo ""

    local tests_passed=0
    local tests_failed=0

    # Test 1: get_gate_config for major
    echo "Test 1: get_gate_config major"
    local major_docs
    major_docs=$(get_gate_config "major")
    if [[ "$major_docs" == "spec.md plan.md tasks.md" ]]; then
        echo "  ✅ PASS"
        ((tests_passed++))
    else
        echo "  ❌ FAIL: got '$major_docs'"
        ((tests_failed++))
    fi

    # Test 2: get_gate_config for unknown
    echo "Test 2: get_gate_config unknown"
    if ! get_gate_config "unknown" &>/dev/null; then
        echo "  ✅ PASS (correctly rejected)"
        ((tests_passed++))
    else
        echo "  ❌ FAIL (should have failed)"
        ((tests_failed++))
    fi

    # Test 3: check_document on non-existent file
    echo "Test 3: check_document non-existent"
    local result
    result=$(check_document "/nonexistent/file.md")
    if [[ "$result" == "NOT_FOUND" ]]; then
        echo "  ✅ PASS"
        ((tests_passed++))
    else
        echo "  ❌ FAIL: got '$result'"
        ((tests_failed++))
    fi

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
            run_workflow_gates_test
            ;;
        check)
            if [[ $# -lt 4 ]]; then
                echo "Usage: $0 check <workflow_type> <feature_number> <feature_name>"
                echo "Example: $0 check major 005 todo6-workflow-improvements"
                exit 1
            fi
            validate_document_gate "$2" "$3" "$4"
            ;;
        list)
            list_workflow_types
            ;;
        *)
            echo "Usage: $0 {test|check|list}"
            echo ""
            echo "Commands:"
            echo "  test                              - Run self-tests"
            echo "  check <type> <number> <name>      - Validate document gate"
            echo "  list                              - List workflow types"
            exit 1
            ;;
    esac
fi

# Export functions
export -f get_gate_config
export -f check_document
export -f check_required_documents
export -f validate_document_gate
export -f list_workflow_types
