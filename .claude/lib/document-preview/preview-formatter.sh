#!/bin/bash
# preview-formatter.sh
# 요약과 전문을 포맷팅하여 미리보기 생성
#
# 사용법:
#   source preview-formatter.sh
#   preview=$(format_preview "$summary" "$full_content")

# 요약과 전문을 포맷팅하여 미리보기 생성
format_preview() {
  local summary="$1"
  local full_content="$2"
  local color="${3:-}"  # Optional color parameter

  # 입력 검증
  if [ -z "$full_content" ]; then
    echo "[ERROR] full_content is required" >&2
    return 1
  fi

  # 요약이 비어있으면 전문만 표시
  if [ -z "$summary" ]; then
    cat <<EOF
## 📄 전문

$full_content
EOF
    return 0
  fi

  # 요약 + 구분선 + 전문 형식
  local preview
  preview=$(cat <<EOF
## 📝 요약

$summary

---

## 📄 전문

$full_content
EOF
)

  # 색상 적용 (optional)
  if [ -n "$color" ]; then
    echo "$preview {color=\"$color\"}"
  else
    echo "$preview"
  fi

  return 0
}

# 섹션 헤더 추가
add_section_headers() {
  local content="$1"
  local header_text="$2"
  local icon="${3:-📄}"

  echo "## $icon $header_text"
  echo ""
  echo "$content"
}

# 구분선 적용
apply_separators() {
  local before="$1"
  local after="$2"
  local separator="${3:----}"

  cat <<EOF
$before

$separator

$after
EOF
}

# 미리보기에 메타데이터 추가 (옵션)
add_metadata() {
  local preview="$1"
  local doc_type="$2"
  local timestamp="$3"

  cat <<EOF
_Document Type:_ **$doc_type**
_Generated:_ $timestamp

$preview
EOF
}

# 컬러 태그 제거 (plain text용)
remove_color_tags() {
  local content="$1"
  echo "$content" | sed 's/ {color="[^"]*"}//g'
}

# 미리보기 길이 제한 (선택적)
truncate_preview() {
  local preview="$1"
  local max_lines="${2:-100}"

  echo "$preview" | head -n "$max_lines"
}

# 스크립트가 직접 실행된 경우 (테스트용)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  if [ $# -lt 2 ]; then
    echo "Usage: $0 <summary> <full_content> [color]"
    echo "Example: $0 'This is summary' 'This is full content' 'blue'"
    exit 1
  fi

  summary="$1"
  full_content="$2"
  color="${3:-}"

  echo "=== Formatted Preview ==="
  format_preview "$summary" "$full_content" "$color"
  echo "==="
fi
