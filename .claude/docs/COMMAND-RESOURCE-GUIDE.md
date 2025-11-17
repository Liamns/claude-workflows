# Command-Resource Relationship Guide

**Version**: 1.0.0
**Last Updated**: 2025-11-17
**Part of**: Feature 001 - Command-Centered Structure Optimization

## 📋 Overview

This guide explains how commands, skills, agents, and scripts are organized and related within the Claude Workflows system. Understanding these relationships helps maintain consistency and enables effective resource discovery.

## 🗺️ Resource Architecture

```
.claude/
├── commands/          # Slash commands (user-facing)
│   └── *.md           # Command documentation (template-compliant)
├── skills/            # Reusable skill modules
│   └── */skill.md     # Skill definitions
├── agents/            # Specialized sub-agents
│   └── */agent.md     # Agent configurations
├── lib/               # Helper scripts
│   └── *.sh           # Utility scripts
└── registry/
    └── command-resource-mapping.json  # Central registry
```

## 📊 Registry Structure

### Central Registry Location
```
.claude/registry/command-resource-mapping.json
```

### Registry Schema

```json
{
  "version": "1.0.0",
  "lastUpdated": "2025-11-17T12:00:00Z",
  "templateSystemVersion": "1.0.0",

  "commands": [
    {
      "id": "command-name",
      "name": "Display Name",
      "description": "What this command does",
      "filePath": ".claude/commands/command-name.md",
      "relatedSkills": ["skill-id-1", "skill-id-2"],
      "relatedAgents": ["agent-type-1"],
      "relatedScripts": [".claude/lib/script-name.sh"],
      "createdAt": "2025-11-17T08:00:00Z",
      "updatedAt": "2025-11-17T08:00:00Z"
    }
  ],

  "skills": [...],
  "agents": [...],
  "scripts": [...],
  "documentations": [...]
}
```

## 🔗 Relationship Types

### 1. Command → Skill
**When**: Command delegates specific tasks to a skill

**Example**:
- `/major` → `reusability-enforcer` (checks for reusable code)
- `/minor` → `bug-fix-pattern` (detects common bug patterns)

**How to Define**:
```json
{
  "id": "major",
  "relatedSkills": [
    "reusability-enforcer",
    "fsd-component-creation",
    "api-integration"
  ]
}
```

### 2. Command → Agent
**When**: Command uses specialized agents for processing

**Example**:
- `/review` → `code-reviewer` (performs code analysis)
- `/minor` → `fsd-architect` (validates architecture)

**How to Define**:
```json
{
  "id": "review",
  "relatedAgents": [
    "code-reviewer",
    "security-scanner"
  ]
}
```

### 3. Command → Script
**When**: Command executes helper scripts

**Example**:
- `/commit` → `.claude/lib/git/detect-feature-id.sh`
- `/dashboard` → `.claude/lib/dashboard-generator.sh`

**How to Define**:
```json
{
  "id": "commit",
  "relatedScripts": [
    ".claude/lib/git/detect-feature-id.sh"
  ]
}
```

### 4. Skill ↔ Agent
**Bidirectional**: Skills can invoke agents, agents can use skills

**Example**:
- `fsd-component-creation` ↔ `architect-unified`

### 5. Script → Script
**Dependency**: Scripts can source other scripts

**Example**:
- All scripts → `.claude/lib/common.sh` (shared utilities)

## 📝 Command Documentation Template

Each command must include a **Related Resources** section in its Implementation:

```markdown
## Implementation

### Related Resources

- **Skills**:
  - `reusability-enforcer`: Checks for reusable code before implementation
  - `fsd-component-creation`: Creates FSD-compliant components

- **Agents**:
  - `architect-unified`: Validates architecture compliance
  - `code-reviewer`: Performs comprehensive code review

- **Scripts**:
  - `.claude/lib/metrics-collector.sh`: Collects workflow metrics
  - `.claude/lib/cache-helper.sh`: Manages caching operations
```

## 🔍 Discovery Patterns

### Finding Related Resources for a Command

1. **Check command documentation**:
   ```bash
   cat .claude/commands/major.md | grep -A 10 "Related Resources"
   ```

2. **Query registry**:
   ```bash
   cat .claude/registry/command-resource-mapping.json | \
     jq '.commands[] | select(.id=="major") | .relatedSkills'
   ```

3. **Search for usage in code**:
   ```bash
   grep -r "skill: \"reusability-enforcer\"" .claude/commands/
   ```

### Finding Commands Using a Resource

1. **For skills**:
   ```bash
   jq '.commands[] | select(.relatedSkills[] | contains("bug-fix"))' \
     .claude/registry/command-resource-mapping.json
   ```

2. **For agents**:
   ```bash
   jq '.commands[] | select(.relatedAgents[] | contains("code-reviewer"))' \
     .claude/registry/command-resource-mapping.json
   ```

3. **For scripts**:
   ```bash
   jq '.commands[] | select(.relatedScripts[] | contains("git"))' \
     .claude/registry/command-resource-mapping.json
   ```

## 🎯 Current Mappings

### Workflow Commands

#### `/major` - Major Workflow
- **Skills**: `reusability-enforcer`, `fsd-component-creation`, `api-integration`
- **Agents**: `architect-unified`, `implementer-unified`, `reviewer-unified`
- **Scripts**: `.claude/lib/metrics-collector.sh`, `.claude/lib/cache-helper.sh`

#### `/minor` - Minor Workflow
- **Skills**: `bug-fix-pattern`, `form-validation`
- **Agents**: `fsd-architect`, `quick-fixer`
- **Scripts**: `.claude/lib/cache-helper.sh`

#### `/micro` - Micro Workflow
- **Skills**: (none - intentionally minimal)
- **Agents**: `quick-fixer`
- **Scripts**: `.claude/lib/cache-helper.sh`

#### `/epic` - Epic Workflow
- **Skills**: `parallel-orchestrator`, `smart-cache`
- **Agents**: (delegates to major/minor workflows)
- **Scripts**: `.specify/scripts/bash/*.sh`

### Git Commands

#### `/commit` - Smart Commit
- **Skills**: `commit-guard`
- **Agents**: `smart-committer`
- **Scripts**: `.claude/lib/git/detect-feature-id.sh`

#### `/pr` - Pull Request
- **Skills**: (none)
- **Agents**: `documenter-unified`
- **Scripts**: `.claude/lib/git-stats-helper.sh`

#### `/pr-review` - PR Review
- **Skills**: (none)
- **Agents**: `code-reviewer`, `security-scanner`
- **Scripts**: (GitHub CLI)

### Review Commands

#### `/review` - Code Review
- **Skills**: `test-coverage-analyzer`, `code-metrics-collector`
- **Agents**: `reviewer-unified`, `security-scanner`, `impact-analyzer`
- **Scripts**: `.claude/lib/cache-helper.sh`

### Utility Commands

#### `/triage` - Workflow Selector
- **Skills**: (decision logic only)
- **Agents**: (none)
- **Scripts**: `.claude/lib/metrics-collector.sh`

#### `/dashboard` - Metrics Dashboard
- **Skills**: `smart-cache`
- **Agents**: (none)
- **Scripts**: `.claude/lib/dashboard-generator.sh`, `.claude/lib/metrics-collector.sh`

#### `/start` - Project Initialization
- **Skills**: (none)
- **Agents**: (none)
- **Scripts**: `.specify/scripts/bash/*.sh`

## 🛠️ Maintenance Guidelines

### Adding a New Command

1. **Create command file**:
   ```bash
   bash .claude/lib/create-new-command.sh my-command
   ```

2. **Define relationships** in command's Implementation section:
   ```markdown
   ### Related Resources
   - **Skills**: skill-name
   - **Agents**: agent-type
   - **Scripts**: script-path
   ```

3. **Update registry** (manual for now):
   ```json
   {
     "id": "my-command",
     "relatedSkills": ["skill-name"],
     "relatedAgents": ["agent-type"],
     "relatedScripts": ["script-path"]
   }
   ```

### Updating Relationships

1. **Update command documentation** first
2. **Update registry** to match
3. **Verify consistency**:
   ```bash
   # Check all commands reference valid resources
   bash .claude/lib/verify-resource-references.sh
   ```

### Removing Resources

1. **Find dependencies**:
   ```bash
   jq '.commands[] | select(.relatedSkills[] | contains("skill-name"))' \
     .claude/registry/command-resource-mapping.json
   ```

2. **Update all dependent commands**
3. **Remove resource**
4. **Update registry**

## 📈 Metrics & Analytics

### Resource Usage Statistics

```bash
# Most used skills
jq '.commands[].relatedSkills[]' .claude/registry/command-resource-mapping.json | \
  sort | uniq -c | sort -rn

# Most used agents
jq '.commands[].relatedAgents[]' .claude/registry/command-resource-mapping.json | \
  sort | uniq -c | sort -rn

# Commands without related resources
jq '.commands[] | select(.relatedSkills==[] and .relatedAgents==[] and .relatedScripts==[]) | .id' \
  .claude/registry/command-resource-mapping.json
```

### Dependency Graph

```mermaid
graph TD
    major[/major] --> reuse[reusability-enforcer]
    major --> fsd[fsd-component-creation]
    major --> arch[architect-unified]

    minor[/minor] --> bug[bug-fix-pattern]
    minor --> quick[quick-fixer]

    review[/review] --> reviewer[code-reviewer]
    review --> security[security-scanner]

    commit[/commit] --> guard[commit-guard]
    commit --> detect[detect-feature-id.sh]
```

## 🔧 Troubleshooting

### Common Issues

**Issue**: Registry out of sync with documentation
- **Solution**: Run manual verification and update registry

**Issue**: Circular dependencies
- **Solution**: Review dependency chain, refactor if needed

**Issue**: Missing resource references
- **Solution**: Add placeholders, implement gradually

## 📚 References

### Related Documentation
- [Template System Guide](./FEATURE-001-SUMMARY.md)
- [Skills Guide](.claude/docs/SKILLS-GUIDE.md)
- [Agents Guide](.claude/docs/SUB-AGENTS-GUIDE.md)

### Registry Tools
- **Validator**: (future) `.claude/lib/validate-registry.sh`
- **Generator**: (future) `.claude/lib/generate-registry.sh`
- **Sync**: (future) `.claude/lib/sync-registry.sh`

---

**Note**: The registry is currently maintained manually. Future enhancements will include automated sync between command documentation and the registry.
