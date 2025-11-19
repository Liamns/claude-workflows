#!/usr/bin/env bash
# find-unused-files.sh - 미사용 파일 찾기
# .md, .yaml, .sh 파일의 참조 체인을 추적하여 미사용 파일을 식별합니다

set -euo pipefail

# ============================================================================
# 설정
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
COMMANDS_DIR="${CLAUDE_DIR}/commands"
CONFIG_DIR="${CLAUDE_DIR}/commands-config"
LIB_DIR="${CLAUDE_DIR}/lib"

# ============================================================================
# 색상 코드
# ============================================================================

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# ============================================================================
# 로깅 함수
# ============================================================================

log_info() {
    echo -e "${BLUE}ℹ${NC} $*"
}

log_success() {
    echo -e "${GREEN}✓${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $*"
}

log_error() {
    echo -e "${RED}✗${NC} $*" >&2
}

# ============================================================================
# 참조 파일 추적
# ============================================================================

# .md 파일에서 참조하는 .yaml 파일 찾기
find_yaml_refs_from_md() {
    local md_file="$1"
    local yaml_refs=()

    # commands-config/*.yaml 패턴 찾기
    if [[ -f "$md_file" ]]; then
        while IFS= read -r line; do
            if [[ -n "$line" ]]; then
                yaml_refs+=("$line")
            fi
        done < <(grep -hoE "commands-config/[a-zA-Z0-9_-]+\.yaml" "$md_file" 2>/dev/null || true)
    fi

    # 중복 제거 및 출력
    if [[ ${#yaml_refs[@]} -gt 0 ]]; then
        printf '%s\n' "${yaml_refs[@]}" | sort -u
    fi
}

# .yaml 파일에서 참조하는 .sh 파일 찾기
find_sh_refs_from_yaml() {
    local yaml_file="$1"
    local sh_refs=()

    if [[ -f "$yaml_file" ]]; then
        # script.path 필드 찾기
        if command -v yq &> /dev/null; then
            local script_path
            script_path=$(yq eval '.script.path // ""' "$yaml_file" 2>/dev/null)
            if [[ -n "$script_path" ]]; then
                sh_refs+=("$script_path")
            fi
        else
            # yq 없이 grep 사용
            while IFS= read -r line; do
                if [[ -n "$line" ]]; then
                    sh_refs+=("$line")
                fi
            done < <(grep -A1 "^script:" "$yaml_file" 2>/dev/null | grep "path:" | sed 's/.*path:[[:space:]]*//' | tr -d '"' || true)
        fi

        # 다른 스크립트 참조 찾기 (hooks, shared_utilities 등)
        while IFS= read -r line; do
            if [[ -n "$line" ]]; then
                sh_refs+=("$line")
            fi
        done < <(grep -hoE "\.claude/[a-zA-Z0-9_/-]+\.sh" "$yaml_file" 2>/dev/null || true)
    fi

    # 중복 제거 및 출력
    if [[ ${#sh_refs[@]} -gt 0 ]]; then
        printf '%s\n' "${sh_refs[@]}" | sort -u
    fi
}

# .sh 파일에서 참조하는 .sh 파일 찾기
find_sh_refs_from_sh() {
    local sh_file="$1"
    local sh_refs=()

    if [[ -f "$sh_file" ]]; then
        # source 또는 . 명령어로 참조되는 스크립트 찾기
        while IFS= read -r line; do
            if [[ -n "$line" ]]; then
                sh_refs+=("$line")
            fi
        done < <(grep -hoE "(source|\.)[[:space:]]+[^[:space:]]+\.sh" "$sh_file" 2>/dev/null | sed -E 's/(source|\.)[[:space:]]+//' || true)
    fi

    # 중복 제거 및 출력
    if [[ ${#sh_refs[@]} -gt 0 ]]; then
        printf '%s\n' "${sh_refs[@]}" | sort -u
    fi
}

# ============================================================================
# 참조 체인 구축
# ============================================================================

build_reference_chain() {
    log_info "Building reference chain..."

    local referenced_files=()

    # 1단계: .md 파일에서 시작
    log_info "Step 1: Scanning .md files..."
    local md_count=0
    for md_file in "$COMMANDS_DIR"/*.md; do
        if [[ -f "$md_file" ]]; then
            referenced_files+=("$md_file")
            ((md_count++))

            # .md → .yaml 참조
            while IFS= read -r yaml_ref; do
                if [[ -n "$yaml_ref" ]]; then
                    local full_yaml_path="${CLAUDE_DIR}/${yaml_ref}"
                    referenced_files+=("$full_yaml_path")
                fi
            done < <(find_yaml_refs_from_md "$md_file")
        fi
    done
    log_info "  Found ${md_count} .md files"

    # 2단계: .yaml 파일 처리
    log_info "Step 2: Scanning .yaml files..."
    local yaml_count=0
    for yaml_file in "$CONFIG_DIR"/*.yaml; do
        if [[ -f "$yaml_file" ]]; then
            referenced_files+=("$yaml_file")
            ((yaml_count++))

            # .yaml → .sh 참조
            while IFS= read -r sh_ref; do
                if [[ -n "$sh_ref" ]]; then
                    # 상대 경로를 절대 경로로 변환
                    if [[ "$sh_ref" == .claude/* ]]; then
                        referenced_files+=("${CLAUDE_DIR}/${sh_ref#.claude/}")
                    else
                        referenced_files+=("${CLAUDE_DIR}/${sh_ref}")
                    fi
                fi
            done < <(find_sh_refs_from_yaml "$yaml_file")
        fi
    done
    log_info "  Found ${yaml_count} .yaml files"

    # 3단계: .sh 파일 처리
    log_info "Step 3: Scanning .sh files..."
    local sh_count=0
    for sh_file in "$LIB_DIR"/*.sh; do
        if [[ -f "$sh_file" ]]; then
            referenced_files+=("$sh_file")
            ((sh_count++))

            # .sh → .sh 참조
            while IFS= read -r sh_ref; do
                if [[ -n "$sh_ref" ]]; then
                    # 상대 경로 처리
                    local resolved_path
                    if [[ "$sh_ref" == /* ]]; then
                        resolved_path="$sh_ref"
                    elif [[ "$sh_ref" == ./* ]]; then
                        resolved_path="$(dirname "$sh_file")/${sh_ref#./}"
                    else
                        resolved_path="$(dirname "$sh_file")/$sh_ref"
                    fi
                    referenced_files+=("$resolved_path")
                fi
            done < <(find_sh_refs_from_sh "$sh_file")
        fi
    done
    log_info "  Found ${sh_count} .sh files"

    # 중복 제거 및 출력
    printf '%s\n' "${referenced_files[@]}" | sort -u
}

# ============================================================================
# 미사용 파일 식별
# ============================================================================

find_orphan_files() {
    log_info "Finding orphan files..."

    # 참조 체인 구축
    local referenced_files=()
    while IFS= read -r file; do
        referenced_files+=("$file")
    done < <(build_reference_chain)

    # 전체 파일 목록 (deprecated 디렉토리 제외)
    local all_files=()
    while IFS= read -r file; do
        all_files+=("$file")
    done < <(find "$CLAUDE_DIR" \( -name "*.md" -o -name "*.yaml" -o -name "*.sh" \) -type f | grep -E "/(commands|commands-config|lib)/" | grep -v "/deprecated/" || true)

    # 미사용 파일 식별
    local orphan_files=()
    for file in "${all_files[@]}"; do
        local is_referenced=false
        for ref_file in "${referenced_files[@]}"; do
            if [[ "$file" == "$ref_file" ]]; then
                is_referenced=true
                break
            fi
        done

        if [[ "$is_referenced" == "false" ]]; then
            orphan_files+=("$file")
        fi
    done

    # 결과 출력
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  File Reference Report${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  Total files:      ${MAGENTA}${#all_files[@]}${NC}"
    echo -e "  Referenced files: ${GREEN}${#referenced_files[@]}${NC}"
    echo -e "  Orphan files:     ${YELLOW}${#orphan_files[@]}${NC}"
    echo ""

    if [[ ${#orphan_files[@]} -gt 0 ]]; then
        echo -e "${YELLOW}Potentially Unused Files:${NC}"
        for file in "${orphan_files[@]}"; do
            # 상대 경로로 표시
            local rel_path="${file#$CLAUDE_DIR/}"
            echo -e "  ${YELLOW}⚠${NC} .claude/${rel_path}"
        done
        echo ""
        echo -e "${BLUE}Note:${NC} Claude가 이 목록을 보면 AskUserQuestion을 사용하여 다음 옵션을 제공해야 합니다:"
        echo "  1. 모두 아카이브 (.claude/deprecated/로 이동)"
        echo "  2. 개별 선택 (각 파일별로 확인)"
        echo "  3. 건너뛰기 (파일 유지)"
        echo ""
    else
        log_success "No orphan files found!"
    fi

    # 반환값: orphan_files 배열
    printf '%s\n' "${orphan_files[@]}"
}

# ============================================================================
# 미사용 파일 아카이브
# ============================================================================

archive_orphan_files() {
    log_info "Archiving orphan files..."

    local orphan_files=()
    while IFS= read -r file; do
        orphan_files+=("$file")
    done < <(find_orphan_files 2>/dev/null | grep "^/" || true)

    if [[ ${#orphan_files[@]} -eq 0 ]]; then
        log_success "No files to archive!"
        return 0
    fi

    local deprecated_dir="${CLAUDE_DIR}/deprecated"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local archive_dir="${deprecated_dir}/${timestamp}"

    # 아카이브 디렉토리 생성
    mkdir -p "$archive_dir"
    log_info "Created archive directory: $archive_dir"
    echo ""

    local archived_count=0
    local failed_count=0

    # 각 파일 이동
    for file in "${orphan_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            continue
        fi

        # 상대 경로 계산
        local rel_path="${file#$CLAUDE_DIR/}"
        local target_dir="$archive_dir/$(dirname "$rel_path")"
        local target_file="$archive_dir/$rel_path"

        # 대상 디렉토리 생성
        mkdir -p "$target_dir"

        # 파일 이동
        if mv "$file" "$target_file" 2>/dev/null; then
            echo -e "  ${GREEN}✓${NC} Archived: .claude/${rel_path}"
            ((archived_count++))
        else
            echo -e "  ${RED}✗${NC} Failed: .claude/${rel_path}"
            ((failed_count++))
        fi
    done

    # 빈 디렉토리 정리
    find "$CLAUDE_DIR" -type d -empty -delete 2>/dev/null || true

    # 결과 출력
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  Archive Complete${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  Archived:  ${GREEN}${archived_count}${NC} files"
    echo -e "  Failed:    ${RED}${failed_count}${NC} files"
    echo -e "  Location:  ${BLUE}${archive_dir}${NC}"
    echo ""

    if [[ $archived_count -gt 0 ]]; then
        log_success "Files archived successfully!"
        echo ""
        echo -e "${BLUE}Note:${NC} To restore files, copy them back from:"
        echo "  $archive_dir"
    fi
}

# ============================================================================
# 메인 함수
# ============================================================================

main() {
    local action="find"

    # 옵션 파싱
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --archive)
                action="archive"
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [options]"
                echo ""
                echo "Find and optionally archive unused files in .claude/"
                echo ""
                echo "Options:"
                echo "  --archive    Archive all orphan files to .claude/deprecated/"
                echo "  --help, -h   Show this help message"
                echo ""
                echo "Examples:"
                echo "  $0              # Find orphan files only"
                echo "  $0 --archive    # Archive all orphan files"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done

    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    if [[ "$action" == "archive" ]]; then
        echo -e "${CYAN}║${NC}  Archiving Unused Files${CYAN}║${NC}"
    else
        echo -e "${CYAN}║${NC}  Finding Unused Files${CYAN}║${NC}"
    fi
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    if [[ "$action" == "archive" ]]; then
        archive_orphan_files
    else
        find_orphan_files 2>&1 | grep -v "^/"
    fi
}

# 스크립트로 직접 실행된 경우만 main 호출
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
