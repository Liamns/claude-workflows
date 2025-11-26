#!/usr/bin/env bash
# Dependency verification script
# Epic 006 - Feature 004: Project Indexing and Caching
# Task: T003
# Verifies all dependencies and environment setup

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run dependency check
if ! bash "$SCRIPT_DIR/check-dependencies.sh"; then
    echo ""
    echo "❌ Dependency check failed. Cannot proceed."
    exit 1
fi

echo ""
echo "🔍 Verifying directory structure..."

# Check cache directory
CACHE_DIR="/Users/hk/Documents/claude-workflow/.claude/cache"
if [ ! -d "$CACHE_DIR" ]; then
    echo "⚠️  Cache directory does not exist, creating: $CACHE_DIR"
    mkdir -p "$CACHE_DIR"
    echo "✓ Cache directory created"
else
    echo "✓ Cache directory exists: $CACHE_DIR"
fi

# Check project-index directory
INDEX_DIR="/Users/hk/Documents/claude-workflow/.claude/lib/project-index"
if [ ! -d "$INDEX_DIR" ]; then
    echo "❌ Project index directory does not exist: $INDEX_DIR"
    exit 1
else
    echo "✓ Project index directory exists: $INDEX_DIR"
fi

# Check tests directory
TESTS_DIR="$INDEX_DIR/__tests__"
if [ ! -d "$TESTS_DIR" ]; then
    echo "⚠️  Tests directory does not exist, creating: $TESTS_DIR"
    mkdir -p "$TESTS_DIR"
    echo "✓ Tests directory created"
else
    echo "✓ Tests directory exists: $TESTS_DIR"
fi

echo ""
echo "✅ All dependencies and directory structure verified successfully!"
echo ""
echo "Next steps:"
echo "  1. Implement project-index.sh (T004)"
echo "  2. Implement file scanning logic (T005)"
echo "  3. Run tests after implementation"

exit 0
