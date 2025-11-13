#!/bin/bash
# retry-helper.sh
# 파일 다운로드 및 재시도 유틸리티
#
# 사용법:
#   source .claude/lib/retry-helper.sh
#
#   # 다운로드 도구 감지
#   tool=$(detect_download_tool)
#
#   # 파일 다운로드 (재시도 포함)
#   download_file_with_retry "https://example.com/file.txt" "/local/path/file.txt"
#
# 의존성:
#   - curl (preferred) 또는
#   - wget (fallback)

set -e

# ════════════════════════════════════════════════════════════════════════════
# 다운로드 도구 감지
# ════════════════════════════════════════════════════════════════════════════

# 다운로드 도구를 감지하고 사용 가능한 명령어를 반환합니다.
#
# @return string 다운로드 명령어 ("curl" | "wget")
# @exit 1 사용 가능한 도구가 없는 경우
#
# @example
#   tool=$(detect_download_tool)
#   echo "Using: $tool"
detect_download_tool() {
    # 우선순위 1: curl (preferred)
    if command -v curl &> /dev/null; then
        echo "curl"
        return 0
    fi

    # 우선순위 2: wget (fallback)
    if command -v wget &> /dev/null; then
        echo "wget"
        return 0
    fi

    # 사용 가능한 도구 없음
    echo "오류: 다운로드 도구를 찾을 수 없습니다 (curl, wget)" >&2
    echo "다음 중 하나를 설치하세요:" >&2
    echo "  macOS: curl (기본 설치됨)" >&2
    echo "  Linux: apt-get install curl  또는  apt-get install wget" >&2
    return 1
}

# ════════════════════════════════════════════════════════════════════════════
# 파일 다운로드 (재시도 포함)
# ════════════════════════════════════════════════════════════════════════════

# URL에서 파일을 다운로드하며, 실패 시 지수 백오프로 재시도합니다.
#
# @param $1 URL (다운로드할 파일의 URL)
# @param $2 dest (저장할 로컬 경로)
# @param $3 max_retries (선택, 기본값: 3)
# @param $4 timeout (선택, 초 단위, 기본값: 30)
# @return 0 성공, 1 실패
#
# @example
#   # 기본 사용법
#   download_file_with_retry "https://example.com/file.txt" "./file.txt"
#
#   # 커스텀 재시도 및 타임아웃
#   download_file_with_retry "https://example.com/file.txt" "./file.txt" 5 60
download_file_with_retry() {
    local url="$1"
    local dest="$2"
    local max_retries="${3:-3}"
    local timeout="${4:-30}"

    # 파라미터 검증
    if [[ -z "$url" ]]; then
        echo "오류: URL이 필요합니다" >&2
        return 1
    fi

    if [[ -z "$dest" ]]; then
        echo "오류: 저장 경로가 필요합니다" >&2
        return 1
    fi

    # 다운로드 도구 감지
    local tool
    if ! tool=$(detect_download_tool); then
        return 1
    fi

    # 상위 디렉토리 생성
    local dest_dir
    dest_dir="$(dirname "$dest")"
    if [[ ! -d "$dest_dir" ]]; then
        if ! mkdir -p "$dest_dir" 2>/dev/null; then
            echo "오류: 디렉토리 생성 실패: $dest_dir" >&2
            echo "       파일 쓰기 권한을 확인하세요" >&2
            return 1
        fi
    fi

    # 재시도 루프
    local retry_count=0
    local backoff=1  # 초 (지수 백오프)

    while [[ $retry_count -lt $max_retries ]]; do
        local exit_code=0

        # 다운로드 시도
        case "$tool" in
            "curl")
                # curl: -f (fail on HTTP error), -s (silent), -S (show error), -L (follow redirects)
                if curl -fsSL --max-time "$timeout" "$url" -o "$dest" 2>&1; then
                    echo "✓ 다운로드 성공: $url → $dest"
                    return 0
                fi
                exit_code=$?
                ;;
            "wget")
                # wget: -q (quiet), --timeout (timeout), -O (output file)
                if wget -q --timeout="$timeout" "$url" -O "$dest" 2>&1; then
                    echo "✓ 다운로드 성공: $url → $dest"
                    return 0
                fi
                exit_code=$?
                ;;
            *)
                echo "오류: 알 수 없는 다운로드 도구입니다: $tool" >&2
                return 1
                ;;
        esac

        # 재시도 로직
        ((retry_count++))

        if [[ $retry_count -lt $max_retries ]]; then
            echo "⚠️  다운로드 실패 (시도 $retry_count/$max_retries). ${backoff}초 후 재시도..."
            sleep "$backoff"
            backoff=$((backoff * 2))  # 지수 백오프: 1s → 2s → 4s
        else
            echo "오류: $max_retries회 시도 후 다운로드 실패: $url" >&2
            echo "       파일을 다운로드할 수 없습니다. 다음을 확인하세요:" >&2
            echo "       1. 인터넷 연결 상태" >&2
            echo "       2. URL 접근 가능 여부: $url" >&2
            echo "       3. 파일 쓰기 권한: $dest" >&2
            return 1
        fi
    done

    return 1
}

# ════════════════════════════════════════════════════════════════════════════
# END OF FILE
# ════════════════════════════════════════════════════════════════════════════
