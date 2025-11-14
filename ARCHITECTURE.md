# Architecture

## System Overview

Claude Workflows is a multi-layered automation system designed to optimize token usage while maintaining code quality through intelligent task routing and specialized agents.

```mermaid
graph TD
    User[User Input] --> Triage[/triage Command]
    Triage --> |Complexity Analysis| Router{Workflow Router}

    Router --> |Score < 0| Micro[Micro Workflow]
    Router --> |Score 0-4| Minor[Minor Workflow]
    Router --> |Score 5-9| Major[Major Workflow]
    Router --> |Score >= 10| Epic[Epic Workflow]

    Epic --> EpicSplit[3-5 Feature Split]
    EpicSplit --> MajorLoop[Major Workflow Loop]
    MajorLoop --> Progress[Auto Progress Tracking]

    Major --> SpecKit[Spec-Kit Process]
    SpecKit --> SubAgents[Sub-agents]
    SpecKit --> Skills[Skills]

    Minor --> QuickFixer[quick-fixer agent]
    Minor --> Skills

    Micro --> DirectEdit[Direct Edit]

    SubAgents --> Output[Quality Output]
    Skills --> Output
    DirectEdit --> Output
    Progress --> Output
```

## Core Components

### 1. Workflow Layer

The workflow layer acts as the primary interface and orchestrator:

- **Triage System**: Intelligent routing based on task complexity
- **Epic Workflow**: Large-scale project decomposition (10+ complexity)
- **Major Workflow**: Full spec-driven development cycle (5-9 complexity)
- **Minor Workflow**: Targeted improvements with minimal overhead (0-4 complexity)
- **Micro Workflow**: Direct edits for trivial changes (< 0 complexity)

### 2. Sub-agents Layer

Specialized AI agents with isolated contexts:

```
┌─────────────────────────────────────────┐
│           Main Claude Context           │
├─────────────────────────────────────────┤
│  ┌──────────┐  ┌──────────┐            │
│  │ Agent 1  │  │ Agent 2  │  ...       │
│  │ (Haiku)  │  │ (Sonnet) │            │
│  └──────────┘  └──────────┘            │
│   Isolated      Isolated                │
└─────────────────────────────────────────┘
```

**Key Properties**:
- Independent context windows
- Parallel execution capability (max 10)
- Model selection per agent (Haiku/Sonnet/Opus)
- Tool access control

### 3. Skills Layer

Dynamic instruction loading system:

```
Activation Flow:
1. Trigger Condition Met
2. SKILL.md Loaded (~30-50 tokens)
3. Full Instructions Expanded
4. Pattern Applied
5. Auto-deactivation
```

## Token Optimization Strategy

### Multi-level Caching

```python
cache_hierarchy = {
    "L1": "Recent Analysis Cache (5 min)",
    "L2": "Pattern Recognition Cache (15 min)",
    "L3": "Component Template Cache (session)"
}
```

### Context Compression

1. **Lazy Loading**: Skills load only when needed
2. **Context Pruning**: Remove irrelevant history
3. **Parallel Processing**: Multiple agents share workload
4. **Smart Defaults**: Pre-configured patterns reduce prompting

### Efficiency Metrics

| Component | Token Usage | Savings |
|-----------|-------------|---------|
| Direct Prompt | 100% (baseline) | 0% |
| Micro Workflow | 15% | 85% |
| Minor Workflow | 25% | 75% |
| Major Workflow | 40% | 60% |
| Epic Workflow | 50% | 50% |

## Workflow Decision Matrix

### Complexity Scoring Algorithm

```typescript
interface ComplexityFactors {
  keywords: Map<string, number>;
  fileCount: number;
  crossCutting: boolean;
  breaking: boolean;
  testing: boolean;
}

function calculateComplexity(request: string): number {
  let score = 0;

  // Keyword matching
  majorKeywords.forEach(keyword => {
    if (request.includes(keyword)) score += 3;
  });

  minorKeywords.forEach(keyword => {
    if (request.includes(keyword)) score += 1;
  });

  microKeywords.forEach(keyword => {
    if (request.includes(keyword)) score -= 2;
  });

  // Additional factors
  if (detectBreakingChange(request)) score += 5;
  if (requiresTests(request)) score += 2;
  if (crossCuttingConcern(request)) score += 3;

  return score;
}
```

### Routing Logic

```
Score < 0:   Micro (grammar, typos, logs)
Score 0-4:   Minor (bugs, improvements)
Score 5-9:   Major (features, architecture)
Score >= 10: Epic (large-scale systems, platforms)
```

## Quality Gates

### Epic Workflow Gates

```yaml
gates:
  decomposition:
    feature_count: 3-5
    feature_independence: true
    clear_boundaries: true

  roadmap:
    dependencies_acyclic: true  # DAG validation
    parallelization_identified: true
    milestones_defined: true

  feature_implementation:
    # Each Feature follows Major workflow
    spec_completeness: 90%
    test_coverage: 80%
    integration_tested: true

  epic_completion:
    all_features_completed: true
    integration_tests_pass: true
    performance_criteria_met: true
```

### Major Workflow Gates

```yaml
gates:
  specification:
    completeness: 90%
    clarity: high
    testable: true

  implementation:
    test_coverage: 80%
    type_safety: strict
    fsd_compliance: true

  review:
    security_scan: pass
    performance_check: pass
    accessibility: AA
```

### Minor Workflow Gates

```yaml
gates:
  analysis:
    problem_identified: true
    scope_limited: true

  implementation:
    type_check: pass
    related_tests: pass
    no_regression: true
```

### Micro Workflow Gates

```yaml
gates:
  syntax_check: pass
  no_logic_change: true
```

## Sub-agent Communication

### Task Tool Protocol

```typescript
interface TaskRequest {
  subagent_type: string;
  description: string;
  prompt: string;
  model?: 'haiku' | 'sonnet' | 'opus';
  resume?: string;  // Previous agent ID
}

interface TaskResponse {
  result: string;
  metadata: {
    tokens_used: number;
    execution_time: number;
    cache_hits: number;
  };
}
```

### Parallel Execution Pattern

```typescript
// Optimal parallel execution
const tasks = [
  Task({ subagent_type: 'api-designer', ... }),
  Task({ subagent_type: 'test-guardian', ... }),
  Task({ subagent_type: 'fsd-architect', ... })
];

const results = await Promise.all(tasks);
```

## Skill Activation Patterns

### Automatic Triggers

```yaml
bug-fix-pattern:
  triggers:
    - file_pattern: "*.tsx"
    - error_type: "TypeError"
    - context: "useState"

api-integration:
  triggers:
    - import: "httpClient"
    - pattern: "useQuery"
    - file: "api/*.ts"

form-validation:
  triggers:
    - import: "react-hook-form"
    - import: "zod"
    - component: "*Form.tsx"
```

### Skill Lifecycle

```
1. Detection     → Pattern matched
2. Activation    → SKILL.md loaded
3. Execution     → Instructions applied
4. Validation    → Quality check
5. Deactivation  → Context cleaned
```

## Performance Optimization

### Caching Strategy

```typescript
class WorkflowCache {
  private analysisCache = new Map();
  private templateCache = new Map();
  private resultCache = new LRU(100);

  async get(key: string): Promise<any> {
    // L1: Memory cache
    if (this.resultCache.has(key)) {
      return this.resultCache.get(key);
    }

    // L2: Analysis cache
    const analysisKey = this.getAnalysisKey(key);
    if (this.analysisCache.has(analysisKey)) {
      return this.regenerate(analysisKey);
    }

    // L3: Template cache
    return this.fromTemplate(key);
  }
}
```

### Batch Processing

```typescript
// Batch similar operations
const files = await batchProcess([
  { type: 'read', paths: [...] },
  { type: 'validate', schemas: [...] },
  { type: 'transform', rules: [...] }
]);
```

## Error Recovery

### Graceful Degradation

```
Major fails → Fallback to Minor
Minor fails → Fallback to Micro
Micro fails → Manual intervention
```

### Rollback Mechanism

```bash
# Automatic git stash on failure
on_error() {
  git stash save "workflow-backup-$(date +%s)"
  restore_previous_state()
  notify_user()
}
```

## Validation System (v2.6.0+)

### Architecture

The validation system ensures consistency between documentation and code, validates migration scenarios, and maintains system integrity.

```
┌─────────────────────────────────────────────────────┐
│              Validation System                      │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌──────────────────┐    ┌──────────────────┐     │
│  │  Documentation   │    │    Migration     │     │
│  │   Validation     │    │   Validation     │     │
│  │                  │    │                  │     │
│  │ • File existence │    │ • v1.0 → v2.6   │     │
│  │ • Cross-refs     │    │ • v2.4 → v2.6   │     │
│  │ • Consistency    │    │ • v2.5 → v2.6   │     │
│  └──────────────────┘    │ • Fresh install │     │
│           │              │ • Rollback test │     │
│           │              └──────────────────┘     │
│           │                       │               │
│           └───────────┬───────────┘               │
│                       │                           │
│              ┌────────▼─────────┐                 │
│              │  Report Generator│                 │
│              │                  │                 │
│              │ • JSON format    │                 │
│              │ • Markdown report│                 │
│              │ • Exit codes     │                 │
│              └──────────────────┘                 │
│                                                     │
├─────────────────────────────────────────────────────┤
│  Pre-commit Hook Integration                        │
│  • Auto-triggers on .claude/ changes                │
│  • Blocks commits on critical failures              │
│  • Warns on non-critical issues                     │
└─────────────────────────────────────────────────────┘
```

### Validation Modules

#### 1. Documentation Validation

```bash
# .claude/lib/validate-documentation.sh
validate_docs() {
  check_file_existence()    # All referenced files exist
  validate_links()          # Internal links valid
  check_consistency()       # Docs match code structure
  verify_examples()         # Code examples syntactically valid
}
```

#### 2. Migration Validation

```bash
# .claude/lib/validate-migration.sh
scenarios = [
  "v1.0 → v2.6 (Legacy upgrade)",
  "v2.4 → v2.6 (Recent upgrade)",
  "v2.5 → v2.6 (Incremental)",
  "Fresh install (New users)",
  "Rollback (Failure recovery)"
]

validate_scenario(from_version, to_version) {
  1. Setup test environment
  2. Simulate migration
  3. Verify critical files
  4. Check deprecated cleanup
  5. Test rollback capability
}
```

#### 3. Cross-reference Validation

```bash
# .claude/lib/validate-crossref.sh
validate_crossrefs() {
  scan_markdown_links()     # [text](path) syntax
  verify_skill_refs()       # Skills referenced exist
  check_agent_refs()        # Agents referenced exist
  validate_command_refs()   # Command paths valid
}
```

### Pre-commit Hook Flow

```
Git commit attempt
        │
        ▼
   .claude/ changed?
        │
    Yes │ No → Allow commit
        ▼
Run validate-system.sh --docs-only
        │
        ├─ Exit 0 → Allow commit ✅
        ├─ Exit 2 → Warn + Allow commit ⚠️
        └─ Exit 1 → Block commit ❌
                │
                ▼
        Show validation report
        Suggest fixes
```

### Validation Report Format

```markdown
═══════════════════════════════════════
📋 Validation Report
═══════════════════════════════════════

⏰ Timestamp: 2025-01-10T14:30:00Z
📊 Status: PASSED

📝 Documentation Validation
  ✅ All files exist (42/42)
  ✅ Cross-references valid (127/127)
  ✅ Examples syntactically correct

🔄 Migration Validation
  ✅ v1.0 → v2.6 scenario
  ✅ v2.4 → v2.6 scenario
  ✅ v2.5 → v2.6 scenario
  ✅ Fresh install scenario
  ✅ Rollback scenario

⚠️ Warnings (2)
  • .claude/commands/old.md referenced but deprecated
  • Consider updating example in README.md

═══════════════════════════════════════
💾 Full report: .claude/cache/validation-reports/20250110-143000.json
```

### Integration Points

#### Install Script Integration

```bash
# install.sh
main() {
  backup_existing_files()
  perform_migration()

  # Validation integrated (v2.6.0+)
  if [ -f ".claude/lib/validate-system.sh" ]; then
    run_validation || {
      rollback_from_backup()
      exit 1
    }
  fi

  cleanup_backup()
}
```

#### CI/CD Integration

```yaml
# .github/workflows/validate.yml
- name: Run validation
  run: |
    bash .claude/lib/validate-system.sh
    exit_code=$?
    if [ $exit_code -eq 1 ]; then
      echo "❌ Validation failed"
      exit 1
    elif [ $exit_code -eq 2 ]; then
      echo "⚠️ Validation warnings"
      exit 0
    fi
```

### Rollback Safety (v2.6.0)

```bash
# Automatic rollback on migration failure
rollback_from_backup() {
  local BACKUP_DIR=$1

  # Priority: Critical files first
  restore_file "workflow-gates.json"
  restore_file "config/"
  restore_file "cache/"

  # Then: Command files
  restore_file "commands/"

  # Finally: Documentation
  restore_file "docs/"
}
```

### Performance Characteristics

| Operation | Time | Cached |
|-----------|------|--------|
| Documentation validation | 2-3s | 0.5s |
| Migration validation | 10-15s | N/A |
| Cross-reference check | 1-2s | 0.3s |
| Full validation suite | 15-20s | 1-2s |

## Extensibility

### Adding New Workflows

```markdown
1. Create command file: `.claude/commands/new-workflow.md`
2. Define gates: `workflow-gates.json`
3. Add router logic: Update triage scoring
4. Test integration: Run all quality checks
```

### Adding New Sub-agents

```markdown
1. Create agent file: `.claude/agents/new-agent.md`
2. Define capabilities and tools
3. Set optimal model (haiku/sonnet/opus)
4. Add to workflow integration points
```

### Adding New Skills

```markdown
1. Create skill directory: `.claude/skills/new-skill/`
2. Write SKILL.md with triggers
3. Add templates and examples
4. Define activation patterns
```

## Monitoring & Analytics

### Token Usage Tracking

```typescript
interface UsageMetrics {
  workflow: string;
  tokens: {
    input: number;
    output: number;
    cached: number;
  };
  time: {
    start: Date;
    end: Date;
    duration: number;
  };
  quality: {
    tests_passed: boolean;
    type_check: boolean;
    user_satisfaction: number;
  };
}
```

### Performance Dashboard

```
┌─────────────────────────────────────┐
│      Workflow Performance (7d)      │
├─────────────────────────────────────┤
│ Major: ████████░░ 80% success      │
│ Minor: █████████░ 92% success      │
│ Micro: ██████████ 99% success      │
├─────────────────────────────────────┤
│ Avg Token Savings: 73%              │
│ Avg Completion Time: 4.2 min        │
│ Cache Hit Rate: 67%                 │
└─────────────────────────────────────┘
```

## Epic Workflow

### Overview

Epic Workflow is designed for large-scale projects (complexity >= 10) that require systematic decomposition and long-term tracking.

### Architecture

```
Epic Structure:
.specify/specs/NNN-epic-name/
├── epic.md               # Epic metadata and overview
├── roadmap.md            # Feature execution order & dependencies
├── progress.md           # Auto-updated progress tracking
└── features/
    ├── 001-feature-a/    # Each Feature = Major workflow
    │   ├── spec.md
    │   ├── plan.md
    │   └── tasks.md
    ├── 002-feature-b/
    └── 003-feature-c/
```

### Key Characteristics

1. **Decomposition**: Epic automatically splits into 3-5 independent Features
2. **Dependency Management**: DAG (Directed Acyclic Graph) validation prevents circular dependencies
3. **Progress Tracking**: Automatic completion rate calculation
4. **Feature Independence**: Each Feature can be developed, tested, and deployed separately

### Workflow Stages

```mermaid
graph LR
    A[/epic Command] --> B[AI Feature Decomposition]
    B --> C{User Review}
    C -->|Accept| D[Create Epic Structure]
    C -->|Modify| B
    D --> E[Feature 1: /major]
    E --> F[Feature 2: /major]
    F --> G[Feature 3: /major]
    G --> H[Epic Completion]
```

### Automation Scripts

- `create-epic.sh`: Initialize Epic directory structure
- `update-epic-progress.sh`: Auto-update progress.md on Feature completion
- `validate-epic.sh`: Verify Epic integrity (files, dependencies, Feature count)

### Best Practices

✅ **DO**:
- Break down Epic into 3-5 Features (recommended)
- Ensure Features are independently testable
- Define clear Feature boundaries
- Minimize inter-Feature dependencies

❌ **DON'T**:
- Create Epic for < 10 complexity tasks (use Major instead)
- Create > 6 Features (Epic becomes unmanageable)
- Allow circular dependencies
- Skip validate-epic.sh before committing

### Git Branch Strategy

Epic Workflow implements a **trunk-based development** pattern with Feature ID tagging for precise tracking.

#### Branch Structure

```
main
└── epic-branch (e.g., 005-epic-workflow-system-improvement)
    ├── [F001] commits (Feature 001)
    ├── [F002] commits (Feature 002)
    ├── [F003] commits (Feature 003)
    └── [F004] commits (Feature 004)
```

**Key Principles**:
- **Single Epic Branch**: All Features within an Epic use the same branch
- **Feature ID Tagging**: Commits are tagged with `[F{id}]` prefix (e.g., `[F001]`)
- **Git Log Tracking**: Feature progress tracked via `git log --grep="^\[F001\]"`
- **Backward Compatible**: Standalone Features outside Epic still create their own branches

#### Automatic Branch Detection

The `/major` workflow automatically detects Epic context:

```bash
# Epic Detection Logic
if [ ! -f ../../epic.md ]; then
  # Epic External: Create new feature branch
  git checkout -b {nextNumber}-{featureName}
else
  # Epic Internal: Stay on epic branch
  echo "Epic 내부: 브랜치 유지"
fi
```

#### Automatic Feature ID Tagging

The `/commit` workflow automatically tags commits inside Epic Features:

```bash
# Feature ID Detection
FEATURE_ID=$(grep '^- Feature ID:' spec.md | awk '{print $4}')

# Commit with Tag (if Feature ID exists)
git commit -m "[F${FEATURE_ID}] ${COMMIT_MESSAGE}"

# Example Output
[F001] feat(epic-005): implement Epic branch strategy
```

#### Progress Tracking Integration

The `update-epic-progress.sh` script uses dual tracking:

1. **tasks.md Checkboxes**: Task-level completion tracking
2. **Git Commits**: Code-level implementation tracking

```bash
# Feature Status Criteria
Completed  = tasks.md 100% AND commits exist
In Progress = tasks.md > 0% OR commits exist
Pending    = tasks.md 0% AND no commits
```

#### Benefits

✅ **Simplified History**:
- One epic branch instead of multiple feature branches
- Cleaner git log with Feature ID tags
- Easy to filter commits by Feature: `git log --grep="^\[F001\]"`

✅ **Better Tracking**:
- Feature progress visible in git log
- No manual progress updates needed
- Dual verification (tasks + commits)

✅ **Easier Merging**:
- Single merge to main branch
- All Features included in one PR
- Atomic Epic deployment

#### Example Workflow

```bash
# 1. Start Epic (creates epic branch)
/epic "Workflow System Improvement"
# Branch: 005-epic-workflow-system-improvement

# 2. Start Feature 001 (stays on epic branch)
cd .specify/specs/005-epic-workflow-system-improvement/features/001-epic-branch-strategy
/major "Epic Branch Strategy"
# Branch: 005-epic-workflow-system-improvement (unchanged)

# 3. Make changes and commit (auto-tagged)
echo "feature code" > code.ts
git add code.ts
/commit
# Commit: [F001] feat(epic-005): add feature code

# 4. Track progress (detects commits)
bash .specify/scripts/bash/update-epic-progress.sh ../..
# Output: Feature 001: 🔄 In Progress (0%, 1 commits)

# 5. Complete Epic and merge
git checkout main
git merge --no-ff 005-epic-workflow-system-improvement
# All [F001], [F002], [F003]... commits merged
```

#### Git Log Filtering

Query commits by Feature ID:

```bash
# All Feature 001 commits
git log --grep="^\[F001\]" --oneline

# All Epic commits
git log --grep="^\[F" --oneline

# Feature commit count
git log --all --grep="^\[F001\]" --oneline | wc -l
```

### Example Epic Flow

```bash
# Step 1: Triage detects Epic-level complexity
/triage "Build user authentication system"
# Output: Score 14 → Epic recommended

# Step 2: Create Epic with AI decomposition
/epic "User Authentication System"
# AI suggests: OAuth, JWT, Permissions

# Step 3: Implement each Feature
cd .specify/specs/001-epic-auth/features/001-oauth
/major "OAuth Integration"
# ... complete Feature 001

# Step 4: Track progress
bash .specify/scripts/bash/update-epic-progress.sh .specify/specs/001-epic-auth
# Output: 33% complete (1/3 Features)

# Step 5: Validate Epic
bash .specify/scripts/bash/validate-epic.sh .specify/specs/001-epic-auth
# Output: ✅ All checks passed

# Repeat Steps 3-5 for remaining Features
```

### Metrics

| Metric | Value |
|--------|-------|
| Avg Features per Epic | 4 |
| Avg Epic Duration | 2-3 weeks |
| Feature Success Rate | 95% |
| Epic Completion Rate | 87% |

---

## Security Considerations

### Input Sanitization

- Command injection prevention
- Path traversal protection
- Sensitive data detection
- API key masking

### Access Control

```yaml
permissions:
  read: [".claude", ".specify", "src"]
  write: ["src", "tests"]
  execute: ["yarn", "npm", "git"]
  restricted: [".env", ".git/config", "secrets"]
```

## Future Enhancements

### Planned Features

1. **ML-based Triage**: Learn from user corrections
2. **Custom Workflow Builder**: Visual workflow designer
3. **Team Sync**: Shared workflow configurations
4. **Plugin System**: Third-party integrations
5. **Metrics API**: Export usage data

### Research Areas

- Adaptive model selection
- Cross-project learning
- Real-time collaboration
- Voice command integration

---

For implementation details, see [CONTRIBUTING.md](CONTRIBUTING.md)