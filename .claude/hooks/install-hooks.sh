#!/bin/bash
# install-hooks.sh
# Pre-commit hook 설치 스크립트

set -e

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${BLUE}Pre-commit Hook 설치${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Git 저장소 확인
if [ ! -d .git ]; then
    echo -e "${YELLOW}⚠️  Git 저장소가 아닙니다${NC}"
    echo "   이 스크립트는 Git 저장소 루트에서 실행해야 합니다"
    exit 1
fi

# .git/hooks 디렉토리 확인
if [ ! -d .git/hooks ]; then
    echo "Creating .git/hooks directory..."
    mkdir -p .git/hooks
fi

# 기존 pre-commit hook 백업
if [ -f .git/hooks/pre-commit ]; then
    echo -e "${YELLOW}ℹ  기존 pre-commit hook 발견 - 백업 생성${NC}"
    backup_file=".git/hooks/pre-commit.backup.$(date +%Y%m%d-%H%M%S)"
    cp .git/hooks/pre-commit "$backup_file"
    echo "   백업 위치: $backup_file"
    echo ""
fi

# Hook 복사
echo -e "${BLUE}→ Hook 파일 복사 중...${NC}"
cp .claude/hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

echo ""
echo -e "${GREEN}✅ Pre-commit hook 설치 완료!${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}동작 방식:${NC}"
echo "  • .claude 디렉토리 변경 시 자동으로 문서 검증 실행"
echo "  • 검증 실패 시 커밋 차단"
echo "  • 검증 경고 시 커밋 허용 (일관성 점수 ≥ 70%)"
echo ""
echo -e "${BLUE}Bypass (권장하지 않음):${NC}"
echo "  git commit --no-verify"
echo ""
echo -e "${BLUE}제거:${NC}"
echo "  rm .git/hooks/pre-commit"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
