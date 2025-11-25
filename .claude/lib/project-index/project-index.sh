#!/usr/bin/env bash
# Project Indexing System - Main Script
# Epic 006 - Feature 004: Project Indexing and Caching
# Task: T004 - Basic skeleton with parameter parsing

set -euo pipefail

# Constants
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="/Users/hk/Documents/claude-workflow"
INDEX_FILE="$PROJECT_ROOT/.claude/cache/project-index.json"
VERSION="1.0.0"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Usage message
usage() {
    cat <<EOF
Project Indexing System v${VERSION}

Usage: bash project-index.sh [COMMAND] [OPTIONS]

Commands:
  --update          Create or update full project index
  --incremental     Perform incremental update (only changed files)
  --search QUERY    Search for files by name, exports, or imports
  --stats           Display index statistics
  --help            Show this help message

Examples:
  # Create initial index
  bash project-index.sh --update

  # Search for a component
  bash project-index.sh --search "UserCard"

  # View statistics
  bash project-index.sh --stats

  # Incremental update (typically called by Git hook)
  bash project-index.sh --incremental

Index file location: $INDEX_FILE
EOF
}

# Function: Full index update
update_index() {
    echo -e "${BLUE}🔄 Creating/updating project index...${NC}"

    # Source helper scripts
    source "$SCRIPT_DIR/scan-files.sh" || { echo -e "${RED}Error: scan-files.sh not found${NC}"; exit 1; }
    source "$SCRIPT_DIR/json-utils.sh" || { echo -e "${RED}Error: json-utils.sh not found${NC}"; exit 1; }

    local start_time=$(date +%s)

    # Scan files
    echo "  Scanning project files..."
    local files_data
    files_data=$(scan_project_files "$PROJECT_ROOT")

    # Create JSON index
    echo "  Creating JSON index..."
    create_index_json "$files_data" "$INDEX_FILE"

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    echo -e "${GREEN}✅ Index updated successfully in ${duration}s${NC}"
    echo "   Index file: $INDEX_FILE"
}

# Function: Incremental update
incremental_update() {
    echo -e "${BLUE}🔄 Performing incremental update...${NC}"

    if [ ! -f "$INDEX_FILE" ]; then
        echo -e "${YELLOW}⚠️  Index file not found. Running full update...${NC}"
        update_index
        return
    fi

    source "$SCRIPT_DIR/incremental-update.sh" || { echo -e "${RED}Error: incremental-update.sh not found${NC}"; exit 1; }

    local start_time=$(date +%s)

    # Perform incremental update
    perform_incremental_update "$PROJECT_ROOT" "$INDEX_FILE"

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    echo -e "${GREEN}✅ Incremental update completed in ${duration}s${NC}"
}

# Function: Search
search_index() {
    local query="$1"

    if [ ! -f "$INDEX_FILE" ]; then
        echo -e "${RED}❌ Index file not found. Please run --update first.${NC}"
        exit 1
    fi

    source "$SCRIPT_DIR/search.sh" || { echo -e "${RED}Error: search.sh not found${NC}"; exit 1; }

    echo -e "${BLUE}🔍 Searching for: \"$query\"${NC}"
    echo ""

    # Perform search
    search_in_index "$query" "$INDEX_FILE"
}

# Function: Stats
show_stats() {
    if [ ! -f "$INDEX_FILE" ]; then
        echo -e "${RED}❌ Index file not found. Please run --update first.${NC}"
        exit 1
    fi

    echo -e "${BLUE}📊 Index Statistics${NC}"
    echo ""
    echo "Index file: $INDEX_FILE"
    echo ""

    # Get stats using jq
    local total_files=$(jq '.files | length' "$INDEX_FILE")
    local total_dirs=$(jq '.directories | length' "$INDEX_FILE")
    local last_updated=$(jq -r '.lastUpdated' "$INDEX_FILE")
    local version=$(jq -r '.version' "$INDEX_FILE")

    echo "Version:        $version"
    echo "Last updated:   $last_updated"
    echo "Total files:    $total_files"
    echo "Total dirs:     $total_dirs"
    echo ""

    # File type breakdown
    echo "File types:"
    jq -r '.files | group_by(.type) | map({type: .[0].type, count: length}) | .[] | "  \(.type): \(.count)"' "$INDEX_FILE" 2>/dev/null || echo "  (no type data)"
}

# Main script logic
main() {
    # Check if no arguments
    if [ $# -eq 0 ]; then
        usage
        exit 0
    fi

    # Parse command
    case "$1" in
        --update)
            update_index
            ;;
        --incremental)
            incremental_update
            ;;
        --search)
            if [ -z "${2:-}" ]; then
                echo -e "${RED}Error: --search requires a query argument${NC}"
                echo ""
                usage
                exit 1
            fi
            search_index "$2"
            ;;
        --stats)
            show_stats
            ;;
        --help|-h)
            usage
            ;;
        *)
            echo -e "${RED}Error: Unknown command '$1'${NC}"
            echo ""
            usage
            exit 1
            ;;
    esac
}

# Run main
main "$@"
