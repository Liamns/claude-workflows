#!/bin/bash
# /pr 명령어 PreHook
# 검증: feature 브랜치, gh 인증

set -e

# 색상 정의
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# 1. 현재 브랜치 확인
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null)
if [ -z "$CURRENT_BRANCH" ]; then
    echo -e "${RED}❌ Error: Not in a git repository or detached HEAD${NC}"
    exit 2
fi

if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ]; then
    echo -e "${RED}❌ Error: Cannot create PR from '$CURRENT_BRANCH' branch${NC}"
    echo "💡 Hint: Create and switch to a feature branch first"
    echo "   git checkout -b feature/your-feature-name"
    exit 2
fi

# 2. Remote 설정 확인
REMOTE=$(git remote 2>/dev/null | head -1)
if [ -z "$REMOTE" ]; then
    echo -e "${RED}❌ Error: No remote repository configured${NC}"
    echo "💡 Hint: Add a remote with 'git remote add origin <url>'"
    exit 2
fi

# 3. Push 상태 확인 (경고만)
REMOTE_STATUS=$(git status -sb 2>/dev/null | head -1)
if echo "$REMOTE_STATUS" | grep -q "ahead"; then
    AHEAD_COUNT=$(echo "$REMOTE_STATUS" | grep -oE "ahead [0-9]+" | grep -oE "[0-9]+")
    echo -e "${YELLOW}⚠️  Warning: $AHEAD_COUNT local commit(s) not pushed to remote${NC}"
    echo "💡 The PR command will push these commits automatically"
    echo ""
fi

# 4. gh CLI 확인
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ Error: gh CLI not installed${NC}"
    echo "💡 Install with: brew install gh"
    exit 2
fi

# 5. gh 인증 확인
if ! gh auth status &> /dev/null 2>&1; then
    echo -e "${RED}❌ Error: gh CLI not authenticated${NC}"
    echo "💡 Run: gh auth login"
    exit 2
fi

# 성공
echo -e "${GREEN}✅ Pre-PR check passed${NC}"
echo "📌 Branch: $CURRENT_BRANCH"
echo "🔗 Remote: $REMOTE"
exit 0
