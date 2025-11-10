#!/bin/bash
# validate-crossref.sh
# 교차 참조 검증 모듈 - 마크다운 링크 및 파일 참조 검증
# Phase 5 - User Story 3 구현

# Only set -e when running as script, not when sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set -e
fi

# 현재 스크립트 디렉토리
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 공통 유틸리티 로드 (이미 로드되지 않았다면)
if ! declare -f log_info > /dev/null 2>&1; then
    source "$SCRIPT_DIR/validation-utils.sh"
fi

# ============================================================
# 핵심 검증 함수
# ============================================================

# 모든 교차 참조 검증
validate_all_cross_references() {
    local search_dir="${1:-.claude}"
    local total_links=0
    local valid_links=0
    local broken_links=0
    local broken_list=()

    log_info "🔗 교차 참조 검증 중..."
    echo ""

    # 디렉토리 존재 확인
    if [[ ! -d "$search_dir" ]]; then
        log_error "디렉토리 없음: $search_dir"
        echo "{\"total\":0,\"valid\":0,\"broken\":0,\"brokenLinks\":[]}"
        return 1
    fi

    # 모든 마크다운 파일 검증
    while IFS= read -r md_file; do
        [[ ! -f "$md_file" ]] && continue

        # 개별 파일의 링크 검증
        local file_result=$(validate_single_file_links "$md_file")

        # 결과 파싱
        local file_total=$(echo "$file_result" | grep -o '"totalLinks":[0-9]*' | cut -d':' -f2)
        local file_valid=$(echo "$file_result" | grep -o '"validLinks":[0-9]*' | cut -d':' -f2)
        local file_broken=$(echo "$file_result" | grep -o '"brokenLinks":[0-9]*' | cut -d':' -f2)

        if [[ -n "$file_total" ]]; then
            total_links=$((total_links + file_total))
        fi
        if [[ -n "$file_valid" ]]; then
            valid_links=$((valid_links + file_valid))
        fi
        if [[ -n "$file_broken" ]]; then
            broken_links=$((broken_links + file_broken))
        fi

        # 깨진 링크가 있으면 기록
        if [[ -n "$file_broken" ]] && [[ $file_broken -gt 0 ]]; then
            broken_list+=("$md_file: $file_broken개")
        fi

    done < <(find "$search_dir" -name "*.md" -type f 2>/dev/null)

    echo ""
    log_info "  완료: $valid_links/$total_links 유효"

    # 깨진 링크 보고
    if [[ $broken_links -gt 0 ]]; then
        log_warning "  ⚠️  깨진 링크: $broken_links개"
        for item in "${broken_list[@]}"; do
            log_warning "    - $item"
        done
    else
        log_success "  ✓ 모든 링크 유효"
    fi

    # 유효율 계산
    local validity=100
    if [[ $total_links -gt 0 ]]; then
        validity=$((valid_links * 100 / total_links))
    fi

    log_info "  유효율: $validity%"

    # JSON 결과 반환
    local result="{\"totalLinks\":$total_links,\"validLinks\":$valid_links,\"brokenLinks\":$broken_links,\"validity\":$validity"

    # 깨진 링크 리스트 추가
    if command -v jq > /dev/null 2>&1; then
        local broken_json=$(printf '%s\n' "${broken_list[@]}" | jq -R . | jq -s .)
        result+=",\"brokenLinksList\":$broken_json}"
    else
        result+="}"
    fi

    echo "$result"

    # 깨진 링크가 없으면 성공
    if [[ $broken_links -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

# 개별 파일의 링크 검증
validate_single_file_links() {
    local file_path="$1"

    if [[ ! -f "$file_path" ]]; then
        echo "{\"error\":\"File not found\",\"totalLinks\":0,\"validLinks\":0,\"brokenLinks\":0}"
        return 1
    fi

    # 링크 추출
    local links=$(extract_markdown_links "$file_path")
    local total=0
    local valid=0
    local broken=0

    # 각 링크 검증
    while IFS= read -r link; do
        [[ -z "$link" ]] && continue
        [[ "$link" =~ ^http ]] && continue  # 외부 링크 건너뛰기
        [[ "$link" =~ ^# ]] && continue      # 앵커 링크 건너뛰기

        ((total++))

        # 상대 경로 해석 및 파일 존재 확인
        if validate_link "$file_path" "$link"; then
            ((valid++))
        else
            ((broken++))
        fi
    done <<< "$links"

    # 결과 JSON 반환
    echo "{\"filePath\":\"$file_path\",\"totalLinks\":$total,\"validLinks\":$valid,\"brokenLinks\":$broken}"

    return 0
}

# 마크다운 링크 추출
extract_markdown_links() {
    local file_path="$1"

    if [[ ! -f "$file_path" ]]; then
        return 1
    fi

    # [text](link) 형식의 링크 추출
    grep -oE '\[.*?\]\([^)]+\)' "$file_path" 2>/dev/null | sed 's/.*](\([^)]*\))/\1/' || true
}

# 링크 유효성 검증
validate_link() {
    local source_file="$1"
    local link="$2"

    # 상대 경로 해석
    local resolved_path=$(resolve_relative_path "$source_file" "$link")

    # 파일 존재 확인
    if [[ -f "$resolved_path" ]]; then
        return 0
    else
        return 1
    fi
}

# 상대 경로 해석
resolve_relative_path() {
    local source_file="$1"
    local relative_path="$2"

    # 소스 파일의 디렉토리
    local source_dir=$(dirname "$source_file")

    # 상대 경로 처리
    local resolved="$source_dir/$relative_path"

    # ../ 처리 (간단한 버전)
    while [[ "$resolved" == *"/../"* ]]; do
        resolved=$(echo "$resolved" | sed 's|/[^/]*/\.\./|/|')
    done

    # ./ 제거
    resolved=$(echo "$resolved" | sed 's|\./|/|g')

    echo "$resolved"
}

# ============================================================
# 보조 함수
# ============================================================

# 에이전트 참조 검증
validate_agent_references() {
    local agents_dir=".claude/agents"
    local total=0
    local valid=0

    log_info "  에이전트 참조 검증 중..."

    if [[ ! -d "$agents_dir" ]]; then
        log_warning "    ⚠️  에이전트 디렉토리 없음"
        return 0
    fi

    # 에이전트 파일 개수 확인
    while IFS= read -r agent_file; do
        ((total++))
        if [[ -f "$agent_file" ]]; then
            ((valid++))
        fi
    done < <(find "$agents_dir" -maxdepth 1 -name "*.md" -type f 2>/dev/null)

    log_info "    에이전트: $valid/$total 유효"

    return 0
}

# 스킬 참조 검증
validate_skill_references() {
    local skills_dir=".claude/skills"
    local total=0
    local valid=0

    log_info "  스킬 참조 검증 중..."

    if [[ ! -d "$skills_dir" ]]; then
        log_warning "    ⚠️  스킬 디렉토리 없음"
        return 0
    fi

    # SKILL.md 파일 개수 확인
    while IFS= read -r skill_file; do
        ((total++))
        if [[ -f "$skill_file" ]]; then
            ((valid++))
        fi
    done < <(find "$skills_dir" -name "SKILL.md" -type f 2>/dev/null)

    log_info "    스킬: $valid/$total 유효"

    return 0
}

# 깨진 링크 상세 보고
generate_broken_links_report() {
    local search_dir="${1:-.claude}"
    local report_file="${2:-broken-links-report.md}"

    log_info "깨진 링크 보고서 생성 중..."

    cat > "$report_file" << 'EOF'
# 깨진 링크 보고서

## 개요

이 보고서는 마크다운 파일에서 발견된 깨진 링크를 나열합니다.

## 깨진 링크 목록

EOF

    local found_broken=false

    # 모든 마크다운 파일 검사
    while IFS= read -r md_file; do
        [[ ! -f "$md_file" ]] && continue

        # 파일의 링크 추출
        local links=$(extract_markdown_links "$md_file")

        # 각 링크 검증
        while IFS= read -r link; do
            [[ -z "$link" ]] && continue
            [[ "$link" =~ ^http ]] && continue
            [[ "$link" =~ ^# ]] && continue

            # 링크 유효성 검증
            if ! validate_link "$md_file" "$link"; then
                found_broken=true
                echo "### $md_file" >> "$report_file"
                echo "- 깨진 링크: \`$link\`" >> "$report_file"
                echo "" >> "$report_file"
            fi
        done <<< "$links"

    done < <(find "$search_dir" -name "*.md" -type f 2>/dev/null)

    if [[ "$found_broken" == "false" ]]; then
        echo "깨진 링크가 발견되지 않았습니다. ✅" >> "$report_file"
    fi

    echo "" >> "$report_file"
    echo "---" >> "$report_file"
    echo "생성 시간: $(date)" >> "$report_file"

    log_info "  보고서 저장: $report_file"

    return 0
}

# ============================================================
# CLI 인터페이스 (직접 실행 시)
# ============================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║   교차 참조 검증 모듈                 ║"
    echo "║   Cross-reference Validation Module   ║"
    echo "╚════════════════════════════════════════╝"
    echo ""

    # 명령줄 인자
    SEARCH_DIR="${1:-.claude}"

    # 전체 검증 실행
    RESULTS=$(validate_all_cross_references "$SEARCH_DIR")

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "📊 검증 결과"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if command -v jq > /dev/null 2>&1; then
        echo "$RESULTS" | jq .
    else
        echo "$RESULTS"
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # 에이전트 및 스킬 참조 검증
    validate_agent_references
    validate_skill_references

    echo ""

    # 종료 코드 결정
    BROKEN=$(echo "$RESULTS" | grep -o '"brokenLinks":[0-9]*' | cut -d':' -f2)

    if [[ "$BROKEN" == "0" ]]; then
        log_success "✅ 모든 교차 참조 검증 통과"
        exit 0
    else
        log_warning "⚠️  일부 교차 참조 검증 실패 ($BROKEN개 깨진 링크)"
        exit 1
    fi
fi
