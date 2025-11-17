#!/bin/bash
# discover-commands.sh
# Scans .claude/commands/*.md files and extracts metadata

set -e

COMMANDS_DIR=".claude/commands"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if commands directory exists
if [ ! -d "$COMMANDS_DIR" ]; then
  echo "Error: Commands directory not found: $COMMANDS_DIR" >&2
  exit 1
fi

# Initialize JSON array
echo "["

first=true

# Find all .md files in commands directory
for command_file in "$COMMANDS_DIR"/*.md; do
  # Skip if no files found
  [ -e "$command_file" ] || continue

  # Extract command ID from filename (e.g., epic.md -> epic)
  command_id=$(basename "$command_file" .md)

  # Extract first heading as name (# Title)
  name=$(grep -m 1 '^# ' "$command_file" 2>/dev/null | sed 's/^# //' || echo "$command_id")

  # Extract description (first paragraph after title)
  description=$(awk '/^# /{flag=1; next} flag && /^[^#]/ && NF{print; exit}' "$command_file" 2>/dev/null || echo "No description available")

  # Clean description (remove markdown, limit length)
  description=$(echo "$description" | sed 's/[*_`]//g' | head -c 200)

  # Get file modification time
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    created_at=$(stat -f "%Sm" -t "%Y-%m-%dT%H:%M:%SZ" "$command_file" 2>/dev/null || echo "")
    updated_at=$(stat -f "%Sm" -t "%Y-%m-%dT%H:%M:%SZ" "$command_file" 2>/dev/null || echo "")
  else
    # Linux
    created_at=$(stat -c "%y" "$command_file" 2>/dev/null | cut -d'.' -f1 | sed 's/ /T/' || echo "")Z
    updated_at=$(stat -c "%y" "$command_file" 2>/dev/null | cut -d'.' -f1 | sed 's/ /T/' || echo "")Z
  fi

  # Add comma if not first element
  if [ "$first" = false ]; then
    echo ","
  fi
  first=false

  # Output JSON object (use jq for proper escaping if available)
  if command -v jq >/dev/null 2>&1; then
    jq -n \
      --arg id "$command_id" \
      --arg name "$name" \
      --arg desc "$description" \
      --arg file "$command_file" \
      --arg created "$created_at" \
      --arg updated "$updated_at" \
      '{
        id: $id,
        name: $name,
        description: $desc,
        filePath: $file,
        relatedSkills: [],
        relatedAgents: [],
        relatedScripts: [],
        createdAt: $created,
        updatedAt: $updated
      }' | sed 's/^/  /'
  else
    # Fallback without jq (manual JSON construction)
    cat <<EOF
  {
    "id": "$command_id",
    "name": "$name",
    "description": "$description",
    "filePath": "$command_file",
    "relatedSkills": [],
    "relatedAgents": [],
    "relatedScripts": [],
    "createdAt": "$created_at",
    "updatedAt": "$updated_at"
  }
EOF
  fi
done

echo ""
echo "]"
