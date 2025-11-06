# Architecture

## System Overview

Claude Workflows is a multi-layered automation system designed to optimize token usage while maintaining code quality through intelligent task routing and specialized agents.

```mermaid
graph TD
    User[User Input] --> Triage[/triage Command]
    Triage --> |Complexity Analysis| Router{Workflow Router}

    Router --> |Score < 0| Micro[Micro Workflow]
    Router --> |Score 0-4| Minor[Minor Workflow]
    Router --> |Score > 4| Major[Major Workflow]

    Major --> SpecKit[Spec-Kit Process]
    SpecKit --> SubAgents[Sub-agents]
    SpecKit --> Skills[Skills]

    Minor --> QuickFixer[quick-fixer agent]
    Minor --> Skills

    Micro --> DirectEdit[Direct Edit]

    SubAgents --> Output[Quality Output]
    Skills --> Output
    DirectEdit --> Output
```

## Core Components

### 1. Workflow Layer

The workflow layer acts as the primary interface and orchestrator:

- **Triage System**: Intelligent routing based on task complexity
- **Major Workflow**: Full spec-driven development cycle
- **Minor Workflow**: Targeted improvements with minimal overhead
- **Micro Workflow**: Direct edits for trivial changes

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
Score < 0:  Micro (grammar, typos, logs)
Score 0-4:  Minor (bugs, improvements)
Score > 4:  Major (features, architecture)
```

## Quality Gates

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