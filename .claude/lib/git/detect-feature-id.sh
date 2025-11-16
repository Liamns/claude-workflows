#!/bin/bash
# .claude/lib/git/detect-feature-id.sh
# Feature ID 감지 공통 함수

# @description: spec.md 파일에서 Feature ID를 감지
# @param {string} spec_file - spec.md 파일 경로 (기본값: "spec.md")
# @return {string} - Feature ID (3자리 숫자) 또는 빈 문자열
# @example:
#   detect_feature_id "spec.md"           # 출력: "007"
#   detect_feature_id                     # 출력: "007" (기본값)
#   detect_feature_id "invalid.md"        # 출력: ""
detect_feature_id() {
  local spec_file="${1:-spec.md}"

  # 파일 존재 확인
  if [ ! -f "$spec_file" ]; then
    echo ""
    return 0
  fi

  # Feature ID 감지
  local feature_id
  feature_id=$(grep '^- Feature ID:' "$spec_file" | awk '{print $4}')

  # 결과 반환
  echo "$feature_id"
  return 0
}

# 직접 실행 시
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
  detect_feature_id "$@"
fi
