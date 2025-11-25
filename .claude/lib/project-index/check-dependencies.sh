#!/usr/bin/env bash
# Check and guide jq installation
# Epic 006 - Feature 004: Project Indexing and Caching
# Task: T001

set -euo pipefail

echo "🔍 Checking dependencies for Project Indexing System..."
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

all_ok=true

# Check jq
if command -v jq &> /dev/null; then
    jq_version=$(jq --version 2>&1 || echo "unknown")
    echo -e "${GREEN}✓${NC} jq is installed: $jq_version"
else
    echo -e "${RED}✗${NC} jq is NOT installed"
    echo ""
    echo "jq is required for JSON processing in the indexing system."
    echo ""
    echo "Installation instructions:"
    echo "  macOS:   brew install jq"
    echo "  Ubuntu:  sudo apt-get install jq"
    echo "  Other:   https://stedolan.github.io/jq/download/"
    echo ""
    all_ok=false
fi

# Check find
if command -v find &> /dev/null; then
    echo -e "${GREEN}✓${NC} find is available"
else
    echo -e "${RED}✗${NC} find is NOT available"
    all_ok=false
fi

# Check grep
if command -v grep &> /dev/null; then
    echo -e "${GREEN}✓${NC} grep is available"
else
    echo -e "${RED}✗${NC} grep is NOT available"
    all_ok=false
fi

# Check git
if command -v git &> /dev/null; then
    git_version=$(git --version 2>&1 || echo "unknown")
    echo -e "${GREEN}✓${NC} git is available: $git_version"
else
    echo -e "${RED}✗${NC} git is NOT available"
    all_ok=false
fi

echo ""

if [ "$all_ok" = true ]; then
    echo -e "${GREEN}✓ All dependencies are satisfied!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some dependencies are missing. Please install them before continuing.${NC}"
    exit 1
fi
