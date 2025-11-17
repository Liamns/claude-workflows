#!/bin/bash
# extract-resource-mappings.sh
# Extracts resource mappings (skills, agents, scripts) from command .md files

set -e

# Usage: extract_resource_mappings <command_file>
# Returns: JSON object with relatedSkills, relatedAgents, relatedScripts arrays

if [ $# -eq 0 ]; then
  echo "Usage: $0 <command_file>" >&2
  exit 1
fi

command_file="$1"

if [ ! -f "$command_file" ]; then
  echo "Error: File not found: $command_file" >&2
  exit 1
fi

# Extract Skill patterns
# Looks for: Skill("skill-name") or skill: "skill-name"
extract_skills() {
  local file="$1"

  # Pattern 1: Skill("skill-name") or Skill('skill-name')
  grep -oE 'Skill\(['\''"]([a-z0-9_-]+)['\''"]' "$file" 2>/dev/null | \
    sed -E 's/Skill\(['\''"]([a-z0-9_-]+)['\''"]/\1/' | \
    sort | uniq

  # Pattern 2: skill: "skill-name" in YAML-like frontmatter
  grep -oE 'skill:[ ]*['\''"]([a-z0-9_-]+)['\''"]' "$file" 2>/dev/null | \
    sed -E 's/skill:[ ]*['\''"]([a-z0-9_-]+)['\''"]/\1/' | \
    sort | uniq
}

# Extract Task/Agent patterns
# Looks for: Task(...subagent_type="agent-name"...)
extract_agents() {
  local file="$1"

  # Pattern: subagent_type="agent-name" or subagent_type='agent-name'
  grep -oE 'subagent_type[=:][ ]*['\''"]([a-z0-9_-]+)['\''"]' "$file" 2>/dev/null | \
    sed -E 's/subagent_type[=:][ ]*['\''"]([a-z0-9_-]+)['\''"]/\1/' | \
    sort | uniq
}

# Extract Bash script references
# Looks for: Bash("script.sh") or bash .claude/lib/script.sh
extract_scripts() {
  local file="$1"

  # Pattern 1: Bash("path/to/script.sh") or Bash('path/to/script.sh')
  grep -oE 'Bash\(['\''"]([^'\''"]+\.sh)['\''"]' "$file" 2>/dev/null | \
    sed -E 's/Bash\(['\''"]([^'\''"]+\.sh)['\''"]/\1/'

  # Pattern 2: bash .claude/lib/script.sh or sh .claude/lib/script.sh
  grep -oE '(bash|sh)\s+(\./)?\.claude/[^\s]+\.sh' "$file" 2>/dev/null | \
    awk '{print $2}' | sed 's|^\./||'

  # Pattern 3: source .claude/lib/script.sh
  grep -oE 'source\s+(\./)?\.claude/[^\s]+\.sh' "$file" 2>/dev/null | \
    awk '{print $2}' | sed 's|^\./||'
}

# Build JSON arrays
skills=$(extract_skills "$command_file")
agents=$(extract_agents "$command_file")
scripts=$(extract_scripts "$command_file")

# Convert to JSON arrays using jq if available
if command -v jq >/dev/null 2>&1; then
  # Use jq for proper JSON formatting
  skills_json=$(echo "$skills" | jq -R -s 'split("\n") | map(select(length > 0))')
  agents_json=$(echo "$agents" | jq -R -s 'split("\n") | map(select(length > 0))')
  scripts_json=$(echo "$scripts" | jq -R -s 'split("\n") | map(select(length > 0)) | unique')

  jq -n \
    --argjson skills "$skills_json" \
    --argjson agents "$agents_json" \
    --argjson scripts "$scripts_json" \
    '{
      relatedSkills: $skills,
      relatedAgents: $agents,
      relatedScripts: $scripts
    }'
else
  # Fallback: manual JSON construction
  echo "{"

  # Skills array
  echo '  "relatedSkills": ['
  first=true
  while IFS= read -r skill; do
    [ -z "$skill" ] && continue
    if [ "$first" = false ]; then echo ","; fi
    echo -n "    \"$skill\""
    first=false
  done <<< "$skills"
  echo ""
  echo '  ],'

  # Agents array
  echo '  "relatedAgents": ['
  first=true
  while IFS= read -r agent; do
    [ -z "$agent" ] && continue
    if [ "$first" = false ]; then echo ","; fi
    echo -n "    \"$agent\""
    first=false
  done <<< "$agents"
  echo ""
  echo '  ],'

  # Scripts array
  echo '  "relatedScripts": ['
  first=true
  scripts_unique=$(echo "$scripts" | sort | uniq)
  while IFS= read -r script; do
    [ -z "$script" ] && continue
    if [ "$first" = false ]; then echo ","; fi
    echo -n "    \"$script\""
    first=false
  done <<< "$scripts_unique"
  echo ""
  echo '  ]'

  echo "}"
fi
