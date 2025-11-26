#!/bin/bash
# docu-start-pre.sh
# /docu-start 명령어 실행 전 검증

set -euo pipefail

CACHE_DIR=".claude/cache"

# 1. 캐시 디렉토리 확인/생성
if [ ! -d "$CACHE_DIR" ]; then
  mkdir -p "$CACHE_DIR"
  echo "📁 캐시 디렉토리 생성: $CACHE_DIR"
fi

# 2. active-tasks.json 초기화 확인
ACTIVE_TASKS="$CACHE_DIR/active-tasks.json"
if [ ! -f "$ACTIVE_TASKS" ]; then
  echo "[]" > "$ACTIVE_TASKS"
  echo "📄 active-tasks.json 초기화 완료"
fi

# 3. pending-commits.json 초기화 확인
PENDING_COMMITS="$CACHE_DIR/pending-commits.json"
if [ ! -f "$PENDING_COMMITS" ]; then
  echo "[]" > "$PENDING_COMMITS"
  echo "📄 pending-commits.json 초기화 완료"
fi

# 검증 성공
echo "✅ docu-start 준비 완료"
exit 0
