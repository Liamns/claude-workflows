#!/bin/bash
# update-command-registry.sh
# Generates command-resource mapping registry

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

REGISTRY_FILE=".claude/registry/command-resource-mapping.json"
LIB_DIR=".claude/lib"

echo -e "${BLUE}🔄 Updating Command-Resource Registry...${NC}"

# Check dependencies
if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required but not installed" >&2
  exit 1
fi

# Ensure registry directory exists
mkdir -p .claude/registry

# Step 1: Discover all commands
echo -e "${BLUE}📋 Discovering commands...${NC}"
commands_json=$(bash "$LIB_DIR/discover-commands.sh")

# Step 2: Extract resource mappings for each command
echo -e "${BLUE}🔗 Extracting resource mappings...${NC}"
enriched_commands=$(echo "$commands_json" | jq -c '.[]' | while read -r cmd; do
  file_path=$(echo "$cmd" | jq -r '.filePath')

  # Extract mappings
  mappings=$(bash "$LIB_DIR/extract-resource-mappings.sh" "$file_path")

  # Merge mappings into command object
  echo "$cmd" | jq --argjson mappings "$mappings" '. + $mappings'
done | jq -s '.')

# Step 3: Build skills inventory
echo -e "${BLUE}🛠️  Building skills inventory...${NC}"
skills_json=$(
  if [ -d ".claude/skills" ]; then
    for skill_dir in .claude/skills/*/; do
      [ -e "$skill_dir" ] || continue
      skill_id=$(basename "$skill_dir")
      # Convert kebab-case to Title Case
      skill_name=$(echo "$skill_id" | tr '-' ' ' | sed 's/\b\(.\)/\u\1/g')

      # Extract description from README if exists
      description=""
      if [ -f "$skill_dir/README.md" ]; then
        description=$(awk '/^# /{flag=1; next} flag && /^[^#]/ && NF{print; exit}' "$skill_dir/README.md" | sed 's/[*_`]//g' | head -c 200)
      fi
      [ -z "$description" ] && description="Skill: $skill_name"

      # Get timestamp
      if [[ "$OSTYPE" == "darwin"* ]]; then
        created_at=$(stat -f "%Sm" -t "%Y-%m-%dT%H:%M:%SZ" "$skill_dir" 2>/dev/null || echo "")
        updated_at=$(stat -f "%Sm" -t "%Y-%m-%dT%H:%M:%SZ" "$skill_dir" 2>/dev/null || echo "")
      else
        created_at="$(stat -c "%y" "$skill_dir" 2>/dev/null | cut -d'.' -f1 | sed 's/ /T/')Z"
        updated_at="$(stat -c "%y" "$skill_dir" 2>/dev/null | cut -d'.' -f1 | sed 's/ /T/')Z"
      fi

      # Find which commands use this skill
      used_by=$(echo "$enriched_commands" | jq -r --arg skill_id "$skill_id" \
        '[.[] | select(.relatedSkills[]? == $skill_id) | .id] | unique')

      jq -n \
        --arg id "$skill_id" \
        --arg name "$skill_name" \
        --arg desc "$description" \
        --arg dir "$skill_dir" \
        --arg created "$created_at" \
        --arg updated "$updated_at" \
        --argjson used "$used_by" \
        '{
          id: $id,
          name: $name,
          description: $desc,
          directoryPath: $dir,
          usedByCommands: $used,
          createdAt: $created,
          updatedAt: $updated
        }'
    done | jq -s '.'
  else
    echo "[]"
  fi
)

# Step 4: Build agents inventory
echo -e "${BLUE}🤖 Building agents inventory...${NC}"
agents_json=$(
  if [ -d ".claude/agents" ]; then
    for agent_dir in .claude/agents/*/; do
      [ -e "$agent_dir" ] || continue
      agent_id=$(basename "$agent_dir")
      # Convert kebab-case to Title Case
      agent_name=$(echo "$agent_id" | tr '-' ' ' | sed 's/\b\(.\)/\u\1/g')

      # Extract description
      description=""
      if [ -f "$agent_dir/README.md" ]; then
        description=$(awk '/^# /{flag=1; next} flag && /^[^#]/ && NF{print; exit}' "$agent_dir/README.md" | sed 's/[*_`]//g' | head -c 200)
      fi
      [ -z "$description" ] && description="Agent: $agent_name"

      # Get timestamp
      if [[ "$OSTYPE" == "darwin"* ]]; then
        created_at=$(stat -f "%Sm" -t "%Y-%m-%dT%H:%M:%SZ" "$agent_dir" 2>/dev/null || echo "")
        updated_at=$(stat -f "%Sm" -t "%Y-%m-%dT%H:%M:%SZ" "$agent_dir" 2>/dev/null || echo "")
      else
        created_at="$(stat -c "%y" "$agent_dir" 2>/dev/null | cut -d'.' -f1 | sed 's/ /T/')Z"
        updated_at="$(stat -c "%y" "$agent_dir" 2>/dev/null | cut -d'.' -f1 | sed 's/ /T/')Z"
      fi

      # Find which commands use this agent
      used_by=$(echo "$enriched_commands" | jq -r --arg agent_id "$agent_id" \
        '[.[] | select(.relatedAgents[]? == $agent_id) | .id] | unique')

      jq -n \
        --arg id "$agent_id" \
        --arg name "$agent_name" \
        --arg type "$agent_id" \
        --arg desc "$description" \
        --arg dir "$agent_dir" \
        --arg created "$created_at" \
        --arg updated "$updated_at" \
        --argjson used "$used_by" \
        '{
          id: $id,
          name: $name,
          type: $type,
          description: $desc,
          directoryPath: $dir,
          usedByCommands: $used,
          createdAt: $created,
          updatedAt: $updated
        }'
    done | jq -s '.'
  else
    echo "[]"
  fi
)

# Step 5: Build scripts inventory
echo -e "${BLUE}📝 Building scripts inventory...${NC}"
all_script_paths=$(echo "$enriched_commands" | jq -r '.[] | .relatedScripts[]?' | sort | uniq)

scripts_json=$(
  echo "$all_script_paths" | while read -r script_path; do
    [ -z "$script_path" ] && continue
    [ ! -f "$script_path" ] && continue

    script_id=$(basename "$script_path" .sh)
    # Convert kebab-case to Title Case
    script_name=$(echo "$script_id" | tr '-' ' ' | sed 's/\b\(.\)/\u\1/g')

    # Determine category based on path
    if [[ "$script_path" == *"/__tests__/"* ]]; then
      category="test"
    elif [[ "$script_path" == *"/hooks/"* ]]; then
      category="hooks"
    elif [[ "$script_path" == *"/agents/"* ]]; then
      category="agent-specific"
    else
      category="lib"
    fi

    # Extract description from first comment block
    description=$(grep -m 1 '^# ' "$script_path" 2>/dev/null | sed 's/^# //' || echo "Script: $script_name")

    # Get timestamp
    if [[ "$OSTYPE" == "darwin"* ]]; then
      created_at=$(stat -f "%Sm" -t "%Y-%m-%dT%H:%M:%SZ" "$script_path" 2>/dev/null || echo "")
      updated_at=$(stat -f "%Sm" -t "%Y-%m-%dT%H:%M:%SZ" "$script_path" 2>/dev/null || echo "")
    else
      created_at="$(stat -c "%y" "$script_path" 2>/dev/null | cut -d'.' -f1 | sed 's/ /T/')Z"
      updated_at="$(stat -c "%y" "$script_path" 2>/dev/null | cut -d'.' -f1 | sed 's/ /T/')Z"
    fi

    # Find usage
    used_by_commands=$(echo "$enriched_commands" | jq -r --arg script "$script_path" \
      '[.[] | select(.relatedScripts[]? == $script) | .id] | unique')

    jq -n \
      --arg id "$script_id" \
      --arg name "$script_name" \
      --arg file "$script_path" \
      --arg cat "$category" \
      --arg desc "$description" \
      --arg created "$created_at" \
      --arg updated "$updated_at" \
      --argjson used "$used_by_commands" \
      '{
        id: $id,
        name: $name,
        filePath: $file,
        category: $cat,
        description: $desc,
        usedByCommands: $used,
        usedBySkills: [],
        usedByAgents: [],
        createdAt: $created,
        updatedAt: $updated
      }'
  done | jq -s '.'
)

# Step 6: Build documentations inventory
echo -e "${BLUE}📚 Building documentations inventory...${NC}"
documentations_json=$(echo "$enriched_commands" | jq '[.[] | {
  id: .id,
  commandId: .id,
  filePath: .filePath,
  sections: [],
  templateCompliance: false,
  createdAt: .createdAt,
  updatedAt: .updatedAt
}]')

# Step 7: Assemble final registry
echo -e "${BLUE}🔧 Assembling registry...${NC}"
registry=$(jq -n \
  --argjson commands "$enriched_commands" \
  --argjson skills "$skills_json" \
  --argjson agents "$agents_json" \
  --argjson scripts "$scripts_json" \
  --argjson docs "$documentations_json" \
  --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
  '{
    version: "1.0.0",
    lastUpdated: $timestamp,
    commands: $commands,
    skills: $skills,
    agents: $agents,
    scripts: $scripts,
    documentations: $docs
  }')

# Step 8: Save registry
echo "$registry" | jq '.' > "$REGISTRY_FILE"

# Step 9: Display summary
command_count=$(echo "$registry" | jq '.commands | length')
skill_count=$(echo "$registry" | jq '.skills | length')
agent_count=$(echo "$registry" | jq '.agents | length')
script_count=$(echo "$registry" | jq '.scripts | length')

echo ""
echo -e "${GREEN}✓ Registry updated successfully!${NC}"
echo -e "  ${BLUE}Commands:${NC} $command_count"
echo -e "  ${BLUE}Skills:${NC} $skill_count"
echo -e "  ${BLUE}Agents:${NC} $agent_count"
echo -e "  ${BLUE}Scripts:${NC} $script_count"
echo -e "  ${BLUE}File:${NC} $REGISTRY_FILE"
echo ""

# Step 10: Validate with Zod schema (if available)
if [ -f "$LIB_DIR/validate-registry-schema.js" ] && command -v node >/dev/null 2>&1; then
  echo -e "${BLUE}🔍 Validating registry schema...${NC}"
  if node "$LIB_DIR/validate-registry-schema.js" "$REGISTRY_FILE"; then
    echo -e "${GREEN}✓ Schema validation passed${NC}"
  else
    echo -e "${YELLOW}⚠️  Schema validation failed (but registry was still generated)${NC}"
  fi
fi

exit 0
