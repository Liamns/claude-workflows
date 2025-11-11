#!/bin/bash
# generate-checksums.sh
# 설치 파일의 SHA256 체크섬 매니페스트를 생성합니다
#
# 사용법:
#   bash .claude/lib/generate-checksums.sh [options]
#
# 옵션:
#   -o, --output FILE    출력 파일 지정 (기본값: .claude/.checksums.json)
#   -v, --verbose        자세한 출력
#   -h, --help           도움말 표시
#
# 예제:
#   # 기본 사용 (stdout)
#   bash .claude/lib/generate-checksums.sh
#
#   # 파일로 저장
#   bash .claude/lib/generate-checksums.sh -o .claude/.checksums.json
#
#   # Verbose 모드
#   bash .claude/lib/generate-checksums.sh --verbose

set -e

# ════════════════════════════════════════════════════════════════════════════
# 설정
# ════════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.."; pwd)"

# 버전 정보 (install.sh와 동기화)
VERSION="2.6.0"

# 기본 출력 파일 (설정하지 않으면 stdout)
OUTPUT_FILE=""
VERBOSE=false

# 제외할 디렉토리 패턴
EXCLUDE_DIRS=(
    ".claude/.backup"
    ".claude/cache"
    ".specify/temp"
    ".git"
)

# 제외할 파일 패턴
EXCLUDE_FILES=(
    "*.log"
    "*.tmp"
    ".DS_Store"
    "Thumbs.db"
)

# ════════════════════════════════════════════════════════════════════════════
# 헬퍼 함수
# ════════════════════════════════════════════════════════════════════════════

# 도움말 출력
show_help() {
    cat << 'EOF'
Usage: generate-checksums.sh [options]

Generate SHA256 checksum manifest for Claude Workflows installation files.

Options:
  -o, --output FILE    Output file (default: stdout)
  -v, --verbose        Verbose output
  -h, --help           Show this help message

Examples:
  # Print to stdout
  bash .claude/lib/generate-checksums.sh

  # Save to file
  bash .claude/lib/generate-checksums.sh -o .claude/.checksums.json

  # Verbose mode
  bash .claude/lib/generate-checksums.sh --verbose -o .claude/.checksums.json

Output Format:
  {
    "version": "2.6.0",
    "generatedAt": "2025-01-11T10:00:00Z",
    "files": {
      ".claude/commands/major.md": "abc123...",
      ".claude/lib/cache-helper.sh": "def456...",
      ...
    }
  }
EOF
}

# Verbose 로그
log_verbose() {
    if [ "$VERBOSE" = true ]; then
        echo "  $*" >&2
    fi
}

# ════════════════════════════════════════════════════════════════════════════
# 파라미터 파싱
# ════════════════════════════════════════════════════════════════════════════

while [[ $# -gt 0 ]]; do
    case "$1" in
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Error: Unknown option: $1" >&2
            echo "Use --help for usage information" >&2
            exit 1
            ;;
    esac
done

# ════════════════════════════════════════════════════════════════════════════
# 체크섬 도구 감지
# ════════════════════════════════════════════════════════════════════════════

detect_sha256_tool() {
    if command -v shasum &> /dev/null; then
        echo "shasum -a 256"
    elif command -v sha256sum &> /dev/null; then
        echo "sha256sum"
    elif command -v openssl &> /dev/null; then
        echo "openssl dgst -sha256"
    else
        echo "ERROR: No SHA256 tool found (shasum, sha256sum, or openssl)" >&2
        exit 1
    fi
}

SHA256_TOOL=$(detect_sha256_tool)
log_verbose "Using SHA256 tool: $SHA256_TOOL"

# ════════════════════════════════════════════════════════════════════════════
# 체크섬 계산
# ════════════════════════════════════════════════════════════════════════════

calculate_checksum() {
    local file="$1"
    local checksum

    case "$SHA256_TOOL" in
        "shasum -a 256")
            checksum=$(shasum -a 256 "$file" | awk '{print $1}')
            ;;
        "sha256sum")
            checksum=$(sha256sum "$file" | awk '{print $1}')
            ;;
        "openssl dgst -sha256")
            checksum=$(openssl dgst -sha256 "$file" | awk '{print $NF}')
            ;;
    esac

    echo "$checksum"
}

# ════════════════════════════════════════════════════════════════════════════
# 파일 수집
# ════════════════════════════════════════════════════════════════════════════

cd "$PROJECT_ROOT"

log_verbose "Scanning files in .claude/ and .specify/..."

# find 명령 구성
FIND_EXCLUDE_ARGS=()

# 제외 디렉토리 추가
for dir in "${EXCLUDE_DIRS[@]}"; do
    FIND_EXCLUDE_ARGS+=(-path "./$dir" -prune -o)
done

# 제외 파일 추가
for pattern in "${EXCLUDE_FILES[@]}"; do
    FIND_EXCLUDE_ARGS+=(-name "$pattern" -prune -o)
done

# 파일 목록 수집
FILES=()
while IFS= read -r -d '' file; do
    # 상대 경로로 변환
    rel_path="${file#./}"
    FILES+=("$rel_path")
done < <(find .claude/ .specify/ "${FIND_EXCLUDE_ARGS[@]}" -type f -print0 | sort -z)

log_verbose "Found ${#FILES[@]} files"

# ════════════════════════════════════════════════════════════════════════════
# JSON 생성
# ════════════════════════════════════════════════════════════════════════════

# 현재 시간 (ISO 8601 형식)
GENERATED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

log_verbose "Calculating checksums..."

# JSON 시작
output_json() {
    echo "{"
    echo "  \"version\": \"$VERSION\","
    echo "  \"generatedAt\": \"$GENERATED_AT\","
    echo "  \"files\": {"

    # 파일 체크섬 계산
    local file_count=${#FILES[@]}
    local current=0
    local output_count=0
    local checksums_array=()

    # 먼저 모든 체크섬 계산
    for file in "${FILES[@]}"; do
        ((current++))

        if [ ! -f "$file" ]; then
            log_verbose "Skipping non-existent file: $file"
            continue
        fi

        local checksum
        checksum=$(calculate_checksum "$file")

        log_verbose "[$current/$file_count] $file: $checksum"

        # 배열에 저장
        checksums_array+=("$file|$checksum")
        ((output_count++))
    done

    # JSON 항목 출력
    local item_num=0
    for item in "${checksums_array[@]}"; do
        ((item_num++))
        local file_path="${item%%|*}"
        local file_checksum="${item##*|}"

        echo -n "    \"$file_path\": \"$file_checksum\""

        # 마지막 항목이 아니면 쉼표 추가
        if [ $item_num -lt $output_count ]; then
            echo ","
        else
            echo ""
        fi
    done

    # JSON 종료
    echo "  }"
    echo "}"
}

# ════════════════════════════════════════════════════════════════════════════
# 출력
# ════════════════════════════════════════════════════════════════════════════

if [ -n "$OUTPUT_FILE" ]; then
    log_verbose "Writing to: $OUTPUT_FILE"

    # 디렉토리 생성
    mkdir -p "$(dirname "$OUTPUT_FILE")"

    # 파일로 출력
    output_json > "$OUTPUT_FILE"

    if [ "$VERBOSE" = true ]; then
        echo ""
        echo "✓ Checksum manifest generated: $OUTPUT_FILE" >&2
        echo "  Version: $VERSION" >&2
        echo "  Files: ${#FILES[@]}" >&2
        echo "  Generated at: $GENERATED_AT" >&2
    fi
else
    # stdout으로 출력
    output_json
fi
