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

# ════════════════════════════════════════════════════════════════════════════
# SHA256 도구 감지
# ════════════════════════════════════════════════════════════════════════════

# SHA256 도구를 감지하고 사용 가능한 명령어를 반환합니다.
#
# @return string SHA256 명령어 ("shasum -a 256" | "sha256sum" | "openssl dgst -sha256")
# @exit 1 사용 가능한 도구가 없는 경우
#
# @example
#   tool=$(detect_sha256_tool)
#   echo "Using: $tool"
detect_sha256_tool() {
    # 우선순위 1: shasum (macOS default)
    if command -v shasum &> /dev/null; then
        echo "shasum -a 256"
        return 0
    fi

    # 우선순위 2: sha256sum (Linux default)
    if command -v sha256sum &> /dev/null; then
        echo "sha256sum"
        return 0
    fi

    # 우선순위 3: openssl (universal fallback)
    if command -v openssl &> /dev/null; then
        echo "openssl dgst -sha256"
        return 0
    fi

    # 사용 가능한 도구 없음
    echo "오류: SHA256 도구를 찾을 수 없습니다 (shasum, sha256sum, openssl)" >&2
    echo "다음 중 하나를 설치하세요:" >&2
    echo "  macOS: shasum (기본 설치됨)" >&2
    echo "  Linux: apt-get install coreutils (sha256sum 포함)" >&2
    echo "  공통: openssl (대부분 기본 설치됨)" >&2
    return 1
}

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
