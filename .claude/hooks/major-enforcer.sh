#!/bin/bash
# Major 워크플로우 실행 강제 검증 훅
# 이 스크립트는 /major 명령어 실행 전에 필수 조건을 확인합니다

set -e

FEATURE_DIR=".specify/features"

echo "🔍 Major 워크플로우 사전 검증 시작..."

# 1. Spec 파일 존재 여부 확인
if ! ls "$FEATURE_DIR"/*-*/spec.md 1>/dev/null 2>&1; then
    echo "❌ [차단] spec.md가 생성되지 않았습니다."
    echo "   Step 3: 문서 생성 단계를 완료해주세요."
    exit 2  # Exit code 2 = 실행 차단
fi

# 2. 플레이스홀더 확인
if grep -r "{placeholder}\|TODO:\|FIXME:" "$FEATURE_DIR"/*/spec.md 2>/dev/null; then
    echo "❌ [차단] spec.md에 미완성 플레이스홀더가 남아있습니다."
    echo "   문서를 완성한 후 다시 시도해주세요."
    exit 2
fi

# 3. Plan 파일 존재 여부 확인
if ! ls "$FEATURE_DIR"/*-*/plan.md 1>/dev/null 2>&1; then
    echo "❌ [차단] plan.md가 생성되지 않았습니다."
    exit 2
fi

# 4. Tasks 파일 존재 여부 확인
if ! ls "$FEATURE_DIR"/*-*/tasks.md 1>/dev/null 2>&1; then
    echo "❌ [차단] tasks.md가 생성되지 않았습니다."
    exit 2
fi

echo "✅ 모든 사전 검증 통과"
exit 0
