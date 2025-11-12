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
        echo "오류: 저장소 URL이 필요합니다" >&2
        return 1
    fi

    # Extract owner/repo from URL
    # URL format: https://github.com/owner/repo or https://github.com/owner/repo.git
    local owner_repo
    owner_repo=$(echo "$repo_url" | sed -E 's|https?://github.com/||; s|\.git$||')

    if [[ -z "$owner_repo" ]]; then
        echo "오류: 잘못된 GitHub URL입니다: $repo_url" >&2
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
        echo "오류: 체크섬 매니페스트를 찾을 수 없습니다: $manifest_file" >&2
        return 1
    fi

    # jq 사용 가능 여부 확인
    if command -v jq &> /dev/null; then
        # jq를 사용한 파싱 (권장)
        if ! jq empty "$manifest_file" 2>/dev/null; then
            echo "오류: 매니페스트의 JSON 형식이 잘못되었습니다" >&2
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
            echo "오류: 매니페스트에서 버전을 파싱할 수 없습니다" >&2
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
        echo "오류: 체크섬 매니페스트를 찾을 수 없습니다: $CHECKSUM_MANIFEST" >&2
        echo "       먼저 download_checksum_manifest()를 실행하세요." >&2
        return 1
    fi

    # 매니페스트 파싱
    local manifest_data
    if ! manifest_data=$(parse_checksum_manifest "$CHECKSUM_MANIFEST"); then
        echo "오류: 매니페스트 파싱 실패" >&2
        return 1
    fi

    # 검증 시작
    local total_files=0
    local passed_files=0
    local failed_files=0

    # 각 파일 검증
    while IFS='=' read -r file_path expected_checksum; do
        # Skip .checksums.json itself (self-referential checksum always fails)
        if [[ "$file_path" == ".claude/.checksums.json" ]]; then
            continue
        fi

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
# T021: GitHub Raw URL 생성
# ════════════════════════════════════════════════════════════════════════════

# GitHub 저장소의 파일에 대한 raw URL을 생성합니다.
#
# @param $1 file_path (파일 경로, 예: .claude/lib/test.sh)
# @param $2 repo_url (GitHub 저장소 URL, 예: https://github.com/owner/repo)
# @param $3 branch (브랜치 이름, 기본값: main)
# @return stdout에 raw URL 출력
#
# @example
#   url=$(generate_github_raw_url ".claude/lib/test.sh" "https://github.com/Liamns/claude-workflows" "main")
#   # Returns: https://raw.githubusercontent.com/Liamns/claude-workflows/main/.claude/lib/test.sh
generate_github_raw_url() {
    local file_path="$1"
    local repo_url="$2"
    local branch="${3:-main}"

    # 파라미터 검증
    if [[ -z "$file_path" ]]; then
        echo "오류: 파일 경로가 필요합니다" >&2
        return 1
    fi

    if [[ -z "$repo_url" ]]; then
        echo "오류: 저장소 URL이 필요합니다" >&2
        return 1
    fi

    # Extract owner/repo from URL
    # URL format: https://github.com/owner/repo or https://github.com/owner/repo.git
    local owner_repo
    owner_repo=$(echo "$repo_url" | sed -E 's|https?://github.com/||; s|\.git$||')

    if [[ -z "$owner_repo" ]]; then
        echo "오류: 잘못된 GitHub URL입니다: $repo_url" >&2
        return 1
    fi

    # Construct raw URL
    echo "https://raw.githubusercontent.com/$owner_repo/$branch/$file_path"
    return 0
}

# ════════════════════════════════════════════════════════════════════════════
# T022: 실패 파일 재다운로드
# ════════════════════════════════════════════════════════════════════════════

# 검증 실패한 파일들을 GitHub에서 재다운로드하여 복구합니다.
#
# @param $1 repo_url (GitHub 저장소 URL)
# @param $2 branch (브랜치 이름, 기본값: main)
# @return 0 모든 파일 복구 성공, 1 일부 파일 복구 실패
#
# @example
#   # First run verify_installation_with_checksum
#   if ! verify_installation_with_checksum; then
#       # Retry failed files
#       retry_failed_files "https://github.com/Liamns/claude-workflows" "main"
#   fi
retry_failed_files() {
    local repo_url="$1"
    local branch="${2:-main}"

    # 파라미터 검증
    if [[ -z "$repo_url" ]]; then
        echo "오류: 저장소 URL이 필요합니다" >&2
        return 1
    fi

    # 실패 파일 확인
    local failed_count=${#FAILED_FILES[@]}
    if [[ $failed_count -eq 0 ]]; then
        echo "ℹ️  복구할 파일이 없습니다 (모든 파일 검증 통과)"
        return 0
    fi

    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "파일 자동 복구 (${failed_count}개 파일)"
    echo "════════════════════════════════════════════════════════════════"
    echo ""

    # 복구 통계
    local recovered_count=0
    local still_failed_count=0
    local still_failed_files=()

    # 각 실패 파일 복구 시도
    for file_path in "${FAILED_FILES[@]}"; do
        echo "복구 시도: $file_path"

        # GitHub raw URL 생성
        local file_url
        if ! file_url=$(generate_github_raw_url "$file_path" "$repo_url" "$branch"); then
            echo "  ✗ URL 생성 실패"
            still_failed_files+=("$file_path")
            ((still_failed_count++))
            continue
        fi

        # 파일 다운로드 (3회 재시도, 30초 타임아웃)
        if download_file_with_retry "$file_url" "$file_path" 3 30; then
            # 체크섬 재검증
            local expected_checksum=""
            local manifest_data
            if manifest_data=$(parse_checksum_manifest "$CHECKSUM_MANIFEST"); then
                # Find checksum for this file
                while IFS='=' read -r manifest_file manifest_checksum; do
                    if [[ "$manifest_file" == "$file_path" ]]; then
                        expected_checksum="$manifest_checksum"
                        break
                    fi
                done <<< "$manifest_data"
            fi

            if [[ -n "$expected_checksum" ]]; then
                local actual_checksum
                if actual_checksum=$(calculate_sha256 "$file_path" 2>/dev/null); then
                    if [[ "$actual_checksum" == "$expected_checksum" ]]; then
                        echo "  ✓ 복구 성공 및 검증 통과"
                        ((recovered_count++))
                    else
                        echo "  ✗ 복구 후 체크섬 불일치"
                        still_failed_files+=("$file_path")
                        ((still_failed_count++))
                    fi
                else
                    echo "  ✗ 체크섬 계산 실패"
                    still_failed_files+=("$file_path")
                    ((still_failed_count++))
                fi
            else
                echo "  ⚠️  매니페스트에서 체크섬을 찾을 수 없음"
                still_failed_files+=("$file_path")
                ((still_failed_count++))
            fi
        else
            echo "  ✗ 다운로드 실패"
            still_failed_files+=("$file_path")
            ((still_failed_count++))
        fi
    done

    # 결과 요약
    echo ""
    echo "────────────────────────────────────────────────────────────────"
    echo "복구 결과: $recovered_count/$failed_count 성공"

    if [[ $still_failed_count -gt 0 ]]; then
        echo "⚠️  복구 실패: $still_failed_count개"
        echo ""
        echo "복구 실패 파일 목록:"
        for file in "${still_failed_files[@]}"; do
            echo "  - $file"
        done
        echo ""
        echo "다음을 확인하세요:"
        echo "  1. 인터넷 연결 상태"
        echo "  2. GitHub 저장소 접근 권한"
        echo "  3. 파일이 저장소에 존재하는지 확인: $repo_url/tree/$branch"
        echo "════════════════════════════════════════════════════════════════"
        return 1
    else
        echo "✅ 모든 파일 복구 성공"
        echo "════════════════════════════════════════════════════════════════"
        return 0
    fi
}

# ════════════════════════════════════════════════════════════════════════════
# END OF FILE
# ════════════════════════════════════════════════════════════════════════════
