#!/bin/bash
# checksum-helper.sh
# SHA256 체크섬 계산 유틸리티
#
# 사용법:
#   source .claude/lib/checksum-helper.sh
#
#   # SHA256 도구 감지
#   tool=$(detect_sha256_tool)
#
#   # 파일 체크섬 계산
#   checksum=$(calculate_sha256 "/path/to/file")
#
# 의존성:
#   - shasum (macOS default) 또는
#   - sha256sum (Linux default) 또는
#   - openssl (universal fallback)

set -e

# Source common module for detect_sha256_tool function
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# ════════════════════════════════════════════════════════════════════════════
# SHA256 체크섬 계산
# ════════════════════════════════════════════════════════════════════════════

# 파일의 SHA256 체크섬을 계산합니다.
#
# @param $1 파일 경로 (절대 경로 또는 상대 경로)
# @return string 64자 hex string (예: "a1b2c3d4e5f6...")
# @exit 1 파일이 없거나 체크섬 계산 실패
#
# @example
#   checksum=$(calculate_sha256 "/path/to/file.txt")
#   echo "Checksum: $checksum"
calculate_sha256() {
    local file="$1"

    # 파일 경로 필수
    if [[ -z "$file" ]]; then
        echo "오류: 파일 경로가 필요합니다" >&2
        return 1
    fi

    # 파일 존재 확인
    if [[ ! -f "$file" ]]; then
        echo "오류: 파일을 찾을 수 없습니다: $file" >&2
        return 1
    fi

    # SHA256 도구 감지
    local tool
    if ! tool=$(detect_sha256_tool); then
        return 1
    fi

    # 체크섬 계산 (도구별 출력 형식 처리)
    local checksum
    case "$tool" in
        "shasum -a 256")
            # shasum 출력: "checksum  filename"
            checksum=$(shasum -a 256 "$file" 2>&1 | awk '{print $1}')
            ;;
        "sha256sum")
            # sha256sum 출력: "checksum  filename"
            checksum=$(sha256sum "$file" 2>&1 | awk '{print $1}')
            ;;
        "openssl dgst -sha256")
            # openssl 출력: "SHA256(filename)= checksum"
            checksum=$(openssl dgst -sha256 "$file" 2>&1 | awk '{print $NF}')
            ;;
        *)
            echo "오류: 알 수 없는 SHA256 도구입니다: $tool" >&2
            return 1
            ;;
    esac

    # 체크섬 검증 (64자 hex string)
    if [[ ! "$checksum" =~ ^[a-f0-9]{64}$ ]]; then
        echo "오류: 잘못된 체크섬 형식입니다: $checksum" >&2
        return 1
    fi

    echo "$checksum"
    return 0
}

# ════════════════════════════════════════════════════════════════════════════
# END OF FILE
# ════════════════════════════════════════════════════════════════════════════
