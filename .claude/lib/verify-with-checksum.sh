#!/bin/bash
# verify-with-checksum.sh
# 설치 파일 무결성 검증 (SHA256 체크섬 기반)
#
# 사용법:
#   source .claude/lib/verify-with-checksum.sh
#   download_checksum_manifest "$REPO_URL" "$REPO_BRANCH"
#   verify_installation_with_checksum
#
# 의존성:
#   - checksum-helper.sh
#   - retry-helper.sh
#   - jq (optional, fallback 있음)

set -e

# Load dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/checksum-helper.sh"
source "$SCRIPT_DIR/retry-helper.sh"

# ════════════════════════════════════════════════════════════════════════════
# 설정
# ════════════════════════════════════════════════════════════════════════════

# 체크섬 매니페스트 파일 경로
readonly CHECKSUM_MANIFEST=".claude/.checksums.json"

# 검증 결과를 저장할 parallel arrays (Bash 3.2+ compatible)
# VERIFICATION_FILES[i] → VERIFICATION_STATUS[i]
VERIFICATION_FILES=()
VERIFICATION_STATUS=()

# 실패한 파일 목록
FAILED_FILES=()

# ════════════════════════════════════════════════════════════════════════════
# T016: 체크섬 매니페스트 다운로드
# ════════════════════════════════════════════════════════════════════════════

# GitHub에서 체크섬 매니페스트를 다운로드합니다.
#
# @param $1 repo_url (GitHub 저장소 URL)
# @param $2 branch (브랜치 이름, 기본값: main)
# @return 0 성공, 1 실패
#
# @example
#   download_checksum_manifest "https://github.com/Liamns/claude-workflows" "main"
download_checksum_manifest() {
    local repo_url="$1"
    local branch="${2:-main}"

    # 파라미터 검증
    if [[ -z "$repo_url" ]]; then
        echo "ERROR: Repository URL is required" >&2
        return 1
    fi

    # Extract owner/repo from URL
    # URL format: https://github.com/owner/repo or https://github.com/owner/repo.git
    local owner_repo
    owner_repo=$(echo "$repo_url" | sed -E 's|https?://github.com/||; s|\.git$||')

    if [[ -z "$owner_repo" ]]; then
        echo "ERROR: Invalid GitHub URL: $repo_url" >&2
        return 1
    fi

    # Construct GitHub raw URL
    local manifest_url="https://raw.githubusercontent.com/$owner_repo/$branch/.claude/.checksums.json"

    echo "ℹ️  체크섬 매니페스트 다운로드 중..."
    echo "   URL: $manifest_url"

    # Download with retry
    if download_file_with_retry "$manifest_url" "$CHECKSUM_MANIFEST" 3 30; then
        echo "✓ 체크섬 매니페스트 다운로드 성공"
        return 0
    else
        echo "ERROR: 체크섬 매니페스트 다운로드 실패" >&2
        echo "       매니페스트가 GitHub 저장소에 포함되어 있는지 확인하세요: $manifest_url" >&2
        return 1
    fi
}

# ════════════════════════════════════════════════════════════════════════════
# T017: 체크섬 매니페스트 파싱
# ════════════════════════════════════════════════════════════════════════════

# 체크섬 매니페스트를 파싱하여 파일 → 체크섬 맵을 반환합니다.
#
# @param $1 manifest_file (매니페스트 파일 경로, 기본값: .claude/.checksums.json)
# @return stdout에 "file_path=checksum" 형식으로 출력
# @exit 0 성공, 1 실패
#
# @example
#   parse_checksum_manifest ".claude/.checksums.json"
parse_checksum_manifest() {
    local manifest_file="${1:-$CHECKSUM_MANIFEST}"

    # 파일 존재 확인
    if [[ ! -f "$manifest_file" ]]; then
        echo "ERROR: Checksum manifest not found: $manifest_file" >&2
        return 1
    fi

    # jq 사용 가능 여부 확인
    if command -v jq &> /dev/null; then
        # jq를 사용한 파싱 (권장)
        if ! jq empty "$manifest_file" 2>/dev/null; then
            echo "ERROR: Invalid JSON format in manifest" >&2
            return 1
        fi

        # Extract file → checksum pairs
        jq -r '.files | to_entries[] | "\(.key)=\(.value)"' "$manifest_file"
        return 0
    else
        # jq 없을 때 fallback (grep/sed)
        echo "⚠️  jq가 설치되지 않았습니다. Fallback 모드로 파싱합니다." >&2

        # Extract version (for validation)
        local version
        version=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$manifest_file" | cut -d'"' -f4)

        if [[ -z "$version" ]]; then
            echo "ERROR: Cannot parse version from manifest" >&2
            return 1
        fi

        # Extract file → checksum pairs (limited parsing)
        # Format: "file_path": "checksum",
        grep -o '"\..*/[^"]*"[[:space:]]*:[[:space:]]*"[^"]*"' "$manifest_file" | \
            sed 's/"//g; s/[[:space:]]*:[[:space:]]*/=/; s/,$//' || true

        return 0
    fi
}

# ════════════════════════════════════════════════════════════════════════════
# T018: 설치 파일 검증 (체크섬 기반)
# ════════════════════════════════════════════════════════════════════════════

# 체크섬을 사용하여 설치된 파일의 무결성을 검증합니다.
#
# @return 0 모든 파일 통과, 1 일부 파일 실패
#
# @example
#   verify_installation_with_checksum
verify_installation_with_checksum() {
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "파일 무결성 검증 (SHA256)"
    echo "════════════════════════════════════════════════════════════════"
    echo ""

    # 매니페스트 확인
    if [[ ! -f "$CHECKSUM_MANIFEST" ]]; then
        echo "ERROR: 체크섬 매니페스트를 찾을 수 없습니다: $CHECKSUM_MANIFEST" >&2
        echo "       먼저 download_checksum_manifest()를 실행하세요." >&2
        return 1
    fi

    # 매니페스트 파싱
    local manifest_data
    if ! manifest_data=$(parse_checksum_manifest "$CHECKSUM_MANIFEST"); then
        echo "ERROR: 매니페스트 파싱 실패" >&2
        return 1
    fi

    # 검증 시작
    local total_files=0
    local passed_files=0
    local failed_files=0

    # 각 파일 검증
    while IFS='=' read -r file_path expected_checksum; do
        ((total_files++))

        # 파일 존재 확인
        if [[ ! -f "$file_path" ]]; then
            echo "✗ $file_path ... MISSING"
            VERIFICATION_FILES+=("$file_path")
            VERIFICATION_STATUS+=("missing")
            FAILED_FILES+=("$file_path")
            ((failed_files++))
            continue
        fi

        # 체크섬 계산
        local actual_checksum
        if ! actual_checksum=$(calculate_sha256 "$file_path" 2>/dev/null); then
            echo "✗ $file_path ... ERROR (체크섬 계산 실패)"
            VERIFICATION_FILES+=("$file_path")
            VERIFICATION_STATUS+=("error")
            FAILED_FILES+=("$file_path")
            ((failed_files++))
            continue
        fi

        # 체크섬 비교
        if [[ "$actual_checksum" == "$expected_checksum" ]]; then
            echo "✓ $file_path ... PASS"
            VERIFICATION_FILES+=("$file_path")
            VERIFICATION_STATUS+=("pass")
            ((passed_files++))
        else
            echo "✗ $file_path ... FAIL"
            echo "  Expected: $expected_checksum"
            echo "  Actual:   $actual_checksum"
            VERIFICATION_FILES+=("$file_path")
            VERIFICATION_STATUS+=("fail")
            FAILED_FILES+=("$file_path")
            ((failed_files++))
        fi
    done <<< "$manifest_data"

    # 결과 요약
    echo ""
    echo "────────────────────────────────────────────────────────────────"
    echo "검증 결과: $passed_files/$total_files 통과"

    if [[ $failed_files -gt 0 ]]; then
        echo "⚠️  불일치 파일: $failed_files개"
        echo ""
        echo "불일치 파일 목록:"
        for file in "${FAILED_FILES[@]}"; do
            # Find status for this file
            local status=""
            for i in "${!VERIFICATION_FILES[@]}"; do
                if [[ "${VERIFICATION_FILES[$i]}" == "$file" ]]; then
                    status="${VERIFICATION_STATUS[$i]}"
                    break
                fi
            done
            echo "  - $file ($status)"
        done
        echo "════════════════════════════════════════════════════════════════"
        return 1
    else
        echo "✅ 모든 파일 검증 통과"
        echo "════════════════════════════════════════════════════════════════"
        return 0
    fi
}

# ════════════════════════════════════════════════════════════════════════════
# 불일치 파일 목록 반환
# ════════════════════════════════════════════════════════════════════════════

# 검증 실패한 파일 목록을 반환합니다.
#
# @return stdout에 파일 경로 목록 출력 (줄바꿈 구분)
#
# @example
#   failed_files=$(get_failed_files)
get_failed_files() {
    for file in "${FAILED_FILES[@]}"; do
        echo "$file"
    done
}

# ════════════════════════════════════════════════════════════════════════════
# END OF FILE
# ════════════════════════════════════════════════════════════════════════════
