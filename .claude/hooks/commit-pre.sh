#!/bin/bash
# /commit 명령어 PreHook
# 검증: staged 변경사항 존재, 민감 파일 경고

set -e

# 색상 정의
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# 1. Staged 변경사항 확인
STAGED=$(git diff --cached --name-only 2>/dev/null)
if [ -z "$STAGED" ]; then
    echo -e "${RED}❌ Error: No staged changes found${NC}"
    echo "💡 Hint: Use 'git add <file>' to stage changes first"
    exit 2
fi

# 2. 민감 파일 체크
SENSITIVE_PATTERNS="\.env$|\.env\.|credentials|secret|password|token|\.pem$|\.key$|\.p12$"
SENSITIVE_FILES=$(echo "$STAGED" | grep -iE "$SENSITIVE_PATTERNS" || true)
if [ -n "$SENSITIVE_FILES" ]; then
    echo -e "${YELLOW}⚠️  Warning: Potentially sensitive files detected:${NC}"
    echo "$SENSITIVE_FILES" | while read -r file; do
        echo "   - $file"
    done
    echo ""
    echo "💡 Consider adding these to .gitignore or removing from staging"
    echo ""
    # 경고만 출력 (차단하지 않음)
fi

# 3. 대용량 파일 체크 (10MB 이상)
LARGE_FILES=""
while IFS= read -r file; do
    if [ -f "$file" ]; then
        SIZE=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
        if [ "$SIZE" -gt 10485760 ]; then
            LARGE_FILES="$LARGE_FILES$file ($(echo "scale=1; $SIZE/1048576" | bc)MB)\n"
        fi
    fi
done <<< "$STAGED"

if [ -n "$LARGE_FILES" ]; then
    echo -e "${YELLOW}⚠️  Warning: Large files detected (>10MB):${NC}"
    echo -e "$LARGE_FILES"
    echo "💡 Consider using Git LFS for large files"
    echo ""
fi

# 성공
STAGED_COUNT=$(echo "$STAGED" | wc -l | tr -d ' ')
echo -e "${GREEN}✅ Pre-commit check passed${NC}"
echo "📝 Staged files: $STAGED_COUNT"
exit 0
