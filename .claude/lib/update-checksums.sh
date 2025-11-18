#!/bin/bash
# update-checksums.sh
# Wrapper script for generate-checksums.sh that handles git staging
# Prevents common mistakes like forgetting -o flag

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECKSUMS_FILE=".claude/.checksums.json"

echo "🔧 Regenerating checksums..."
echo ""

# Run checksum generator with -o flag (always writes to file)
if ! bash "$SCRIPT_DIR/generate-checksums.sh" -o "$CHECKSUMS_FILE" --verbose; then
    echo "❌ Failed to generate checksums"
    exit 1
fi

echo ""

# Check if in git repository
if git rev-parse --git-dir > /dev/null 2>&1; then
    if git diff --quiet "$CHECKSUMS_FILE" 2>/dev/null; then
        echo "ℹ️  No checksum changes detected"
    else
        echo "📝 Staging checksums file..."
        git add "$CHECKSUMS_FILE"

        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📊 Changes Summary:"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        git diff --stat --staged "$CHECKSUMS_FILE"

        # Count changed lines (approximates number of files updated)
        CHANGED_COUNT=$(git diff --staged "$CHECKSUMS_FILE" | grep -c "^+" | tail -1 || echo "0")

        echo ""
        echo "✓ Updated checksums for approximately $CHANGED_COUNT file(s)"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "💡 Next steps:"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "   1. Review changes: git diff --staged $CHECKSUMS_FILE"
        echo "   2. Commit: git commit -m 'chore: update checksums'"
        echo "   3. Push: git push"
        echo ""
    fi
else
    echo "✓ Checksums updated (not in git repository)"
fi

echo "✅ Done!"
