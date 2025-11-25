#!/usr/bin/env bash
# Install Git post-commit hook
# Epic 006 - Feature 004: Project Indexing and Caching
# Task: T019 - Create post-commit hook in .git/hooks/

set -euo pipefail

PROJECT_ROOT="/Users/hk/Documents/claude-workflow"
HOOK_FILE="$PROJECT_ROOT/.git/hooks/post-commit"
INDEX_SCRIPT="$PROJECT_ROOT/.claude/lib/project-index/project-index.sh"

echo "🔧 Installing Git post-commit hook for project indexing..."
echo ""

# Check if .git directory exists
if [ ! -d "$PROJECT_ROOT/.git" ]; then
    echo "❌ Error: Not a Git repository: $PROJECT_ROOT"
    exit 1
fi

# Check if hook already exists
if [ -f "$HOOK_FILE" ]; then
    echo "⚠️  Warning: post-commit hook already exists"
    echo "   Backing up to: $HOOK_FILE.backup"
    cp "$HOOK_FILE" "$HOOK_FILE.backup"
fi

# Create hook script
cat > "$HOOK_FILE" <<'EOF'
#!/usr/bin/env bash
# Auto-generated post-commit hook for project indexing
# Epic 006 - Feature 004: Project Indexing and Caching

PROJECT_ROOT="/Users/hk/Documents/claude-workflow"
INDEX_SCRIPT="$PROJECT_ROOT/.claude/lib/project-index/project-index.sh"

# Run incremental update in background to avoid delaying commit
if [ -f "$INDEX_SCRIPT" ]; then
    bash "$INDEX_SCRIPT" --incremental > /dev/null 2>&1 &
fi
EOF

# Make hook executable
chmod +x "$HOOK_FILE"

echo "✅ Git hook installed successfully!"
echo ""
echo "Hook location: $HOOK_FILE"
echo ""
echo "The hook will automatically update the project index after each commit."
echo "Updates run in the background to avoid slowing down commits."
echo ""
echo "Test it: make a commit and check the index with:"
echo "  bash .claude/lib/project-index/project-index.sh --stats"
