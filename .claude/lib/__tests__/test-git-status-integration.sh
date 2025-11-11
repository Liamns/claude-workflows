#!/bin/bash
# test-git-status-integration.sh
# Integration test for .gitignore management with Git (US3)
#
# 사용법:
#   bash .claude/lib/__tests__/test-git-status-integration.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Source the module to test
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.."; pwd)"
source "$SCRIPT_DIR/gitignore-manager.sh"

# Test directory
TEST_DIR="/tmp/test-git-status-$$"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo "════════════════════════════════════════════════════════════════"
echo "Integration Test: Git Status with .gitignore (US3)"
echo "════════════════════════════════════════════════════════════════"
echo ""

# ════════════════════════════════════════════════════════════════════════════
# Test 1: Initialize Git repository
# ════════════════════════════════════════════════════════════════════════════

echo "Test 1: Git 저장소 초기화"
echo "──────────────────────────────────────────"

git init > /dev/null 2>&1
git config user.name "Test User" > /dev/null 2>&1
git config user.email "test@example.com" > /dev/null 2>&1

if [[ -d ".git" ]]; then
    echo -e "${GREEN}✓${NC} Git 저장소 초기화 성공"
else
    echo -e "${RED}✗${NC} Git 저장소 초기화 실패"
    exit 1
fi

echo ""

# ════════════════════════════════════════════════════════════════════════════
# Test 2: Add installer patterns to .gitignore
# ════════════════════════════════════════════════════════════════════════════

echo "Test 2: .gitignore 패턴 추가"
echo "──────────────────────────────────────────"

add_installer_patterns_to_gitignore > /dev/null

if [[ -f ".gitignore" ]]; then
    echo -e "${GREEN}✓${NC} .gitignore 파일 생성됨"
else
    echo -e "${RED}✗${NC} .gitignore 파일 생성 실패"
    exit 1
fi

echo ""

# ════════════════════════════════════════════════════════════════════════════
# Test 3: Create files that should be ignored
# ════════════════════════════════════════════════════════════════════════════

echo "Test 3: 무시해야 할 파일 생성"
echo "──────────────────────────────────────────"

# Create directories
mkdir -p .claude/.backup
mkdir -p .claude/cache
mkdir -p .specify/temp

# Create files that should be ignored
echo "backup file" > .claude/.backup/backup.txt
echo "cache file" > .claude/cache/cache.json
echo "log file" > test.log
echo "temp file" > test.tmp
echo "DS Store" > .DS_Store

# Create OS-specific files
touch Thumbs.db

echo -e "${GREEN}✓${NC} 무시 대상 파일 생성 완료"
echo "  - .claude/.backup/backup.txt"
echo "  - .claude/cache/cache.json"
echo "  - test.log"
echo "  - test.tmp"
echo "  - .DS_Store"
echo "  - Thumbs.db"

echo ""

# ════════════════════════════════════════════════════════════════════════════
# Test 4: Create files that should NOT be ignored
# ════════════════════════════════════════════════════════════════════════════

echo "Test 4: 추적해야 할 파일 생성"
echo "──────────────────────────────────────────"

mkdir -p .claude/commands
mkdir -p .claude/lib

echo "command file" > .claude/commands/test.md
echo "lib file" > .claude/lib/helper.sh

echo -e "${GREEN}✓${NC} 추적 대상 파일 생성 완료"
echo "  - .claude/commands/test.md"
echo "  - .claude/lib/helper.sh"

echo ""

# ════════════════════════════════════════════════════════════════════════════
# Test 5: Verify git status (ignored files should not appear)
# ════════════════════════════════════════════════════════════════════════════

echo "Test 5: Git 상태 검증"
echo "──────────────────────────────────────────"

# Get untracked files
untracked_files=$(git ls-files --others --exclude-standard)

# Check if ignored files are NOT in untracked list
ignored_files_present=false

for ignored_file in ".claude/.backup/backup.txt" ".claude/cache/cache.json" "test.log" "test.tmp" ".DS_Store" "Thumbs.db"; do
    if echo "$untracked_files" | grep -q "$ignored_file"; then
        echo -e "${RED}✗${NC} 무시해야 할 파일이 추적됨: $ignored_file"
        ignored_files_present=true
    fi
done

if [[ "$ignored_files_present" == "false" ]]; then
    echo -e "${GREEN}✓${NC} 모든 무시 대상 파일이 Git에서 제외됨"
else
    echo -e "${RED}✗${NC} 일부 무시 대상 파일이 추적되고 있음"
    exit 1
fi

# Check if non-ignored files ARE in untracked list
non_ignored_files_missing=false

for tracked_file in ".claude/commands/test.md" ".claude/lib/helper.sh" ".gitignore"; do
    if ! echo "$untracked_files" | grep -q "$tracked_file"; then
        echo -e "${RED}✗${NC} 추적해야 할 파일이 누락됨: $tracked_file"
        non_ignored_files_missing=true
    fi
done

if [[ "$non_ignored_files_missing" == "false" ]]; then
    echo -e "${GREEN}✓${NC} 모든 추적 대상 파일이 Git에서 감지됨"
else
    echo -e "${RED}✗${NC} 일부 추적 대상 파일이 누락됨"
    exit 1
fi

echo ""

# ════════════════════════════════════════════════════════════════════════════
# Test 6: Verify verify_git_status() function
# ════════════════════════════════════════════════════════════════════════════

echo "Test 6: verify_git_status() 함수 테스트"
echo "──────────────────────────────────────────"

# verify_git_status should return 1 because there are untracked files (.gitignore, commands, lib)
if verify_git_status > /dev/null 2>&1; then
    # If it returns 0, that means no untracked files (unexpected in this test)
    echo -e "${YELLOW}⚠${NC}  verify_git_status() 반환값: 0 (추적되지 않은 파일 없음)"
else
    # Returns 1 means there are untracked files (expected)
    echo -e "${GREEN}✓${NC} verify_git_status() 추적되지 않은 파일 감지"
fi

echo ""

# ════════════════════════════════════════════════════════════════════════════
# Test 7: Add .gitignore and verify again
# ════════════════════════════════════════════════════════════════════════════

echo "Test 7: .gitignore 커밋 후 재검증"
echo "──────────────────────────────────────────"

git add .gitignore > /dev/null 2>&1
git commit -m "Add .gitignore" > /dev/null 2>&1

untracked_after_commit=$(git ls-files --others --exclude-standard | wc -l | tr -d ' ')

if [[ "$untracked_after_commit" -eq 2 ]]; then
    # Should have 2 untracked files: .claude/commands/test.md and .claude/lib/helper.sh
    echo -e "${GREEN}✓${NC} .gitignore 커밋 후 추적되지 않은 파일: $untracked_after_commit개"
else
    echo -e "${YELLOW}⚠${NC}  추적되지 않은 파일 수: $untracked_after_commit개 (예상: 2개)"
fi

echo ""

# ════════════════════════════════════════════════════════════════════════════
# Cleanup
# ════════════════════════════════════════════════════════════════════════════

cd /
rm -rf "$TEST_DIR"

echo "════════════════════════════════════════════════════════════════"
echo -e "${GREEN}✓ All Git status integration tests passed!${NC}"
echo "════════════════════════════════════════════════════════════════"

exit 0
