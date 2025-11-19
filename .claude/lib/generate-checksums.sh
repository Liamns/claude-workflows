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

# Source common module for detect_sha256_tool function
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)"
source "$SCRIPT_DIR/common.sh"

# ════════════════════════════════════════════════════════════════════════════
# 설정
# ════════════════════════════════════════════════════════════════════════════
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.."; pwd)"

# 버전 정보 (.claude/.version 파일에서 읽기)
if [ -f "$PROJECT_ROOT/.claude/.version" ]; then
    VERSION=$(cat "$PROJECT_ROOT/.claude/.version" | tr -d '[:space:]')
else
    VERSION="3.3.2"  # fallback
fi

# 기본 출력 파일 (설정하지 않으면 stdout)
OUTPUT_FILE=""
VERBOSE=false

# 제외할 디렉토리 패턴
EXCLUDE_DIRS=(
    ".claude/.backup"
    ".claude/cache"
    ".claude/commands/_backup"
    ".claude/command/.backup"
    ".claude/agents/_deprecated"
    ".claude/deprecated"
    ".claude/__tests__"
    ".claude/lib/__tests__"
    ".claude/architectures/__tests__"
    ".claude/agents/code-reviewer/__tests__"
    ".claude/hooks"
    ".claude/metrics"
    ".specify/specs"
    ".specify/features"
    ".specify/temp"
    ".specify/memory"
    ".git"
    ".vscode"
    ".idea"
    "node_modules"
    ".claude/lib/node_modules"
)

# 제외할 파일 패턴
EXCLUDE_FILES=(
    "*.log"
    "*.tmp"
    "*.bak"
    "*.backup"
    "*.swp"
    "*.swo"
    "*~"
    "*.local.json"
    ".DS_Store"
    "Thumbs.db"
    ".claude/.version"
    ".claude/.checksums.json.backup"
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
# 체크섬 도구 감지 (common.sh에서 제공)
# ════════════════════════════════════════════════════════════════════════════

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

# 파일 수집 - find로 모두 찾은 후 grep으로 필터링
log_verbose "Collecting all files..."
ALL_FILES=()
while IFS= read -r -d '' file; do
    rel_path="${file#./}"
    ALL_FILES+=("$rel_path")
done < <(find .claude/ .specify/ -type f -print0 | sort -z)

log_verbose "Found ${#ALL_FILES[@]} total files, applying exclusions..."

# 제외 패턴 적용
FILES=()
for file in "${ALL_FILES[@]}"; do
    skip=false

    # 제외 디렉토리 체크
    for dir in "${EXCLUDE_DIRS[@]}"; do
        if [[ "$file" == "$dir/"* || "$file" == "./$dir/"* ]]; then
            log_verbose "Excluding (dir): $file"
            skip=true
            break
        fi
    done

    # 제외 파일 패턴 체크
    if [ "$skip" = false ]; then
        for pattern in "${EXCLUDE_FILES[@]}"; do
            # Glob pattern matching (*.ext) and literal string matching
            if [[ "$file" == $pattern ]] || [[ "$file" == *"$pattern" ]]; then
                log_verbose "Excluding (pattern): $file"
                skip=true
                break
            fi
        done
    fi

    # 추가
    if [ "$skip" = false ]; then
        FILES+=("$file")
    fi
done

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
