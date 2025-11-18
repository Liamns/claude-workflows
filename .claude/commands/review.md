# /review - Intelligent Code Review System

## Overview

Comprehensive code review system analyzing security, quality, performance, and architectural compliance using the reviewer-unified agent.

This command provides:
1. **Multi-Level Analysis**: Basic syntax → Advanced security/performance
2. **Contextual Review**: Understands codebase patterns and architecture
3. **Actionable Feedback**: Specific issues with fix suggestions
4. **Quality Scoring**: Numerical ratings for maintainability and reliability

**Key Features:**
- OWASP Top 10 security scanning
- Performance bottleneck detection
- Architecture pattern compliance
- Dependency analysis and impact assessment
- Reusability suggestions from existing codebase

## Usage

```bash
/review [options] [path]
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `--staged` | Review only staged files | `false` |
| `--adv` | Advanced review (security + performance) | `false` |
| `--arch` | Architecture compliance check | `false` |
| `[path]` | Specific file or directory | Current directory |

### Basic Commands

```bash
/review                  # Review all changes
/review src/            # Review specific directory
/review --staged        # Review staged files only
/review --adv           # Deep security/performance analysis
/review --arch          # Architecture validation
```

## Examples

### Example 1: Basic Review

```bash
/review src/auth/login.ts
```

**Output:**
```
╔═══════════════════════════════════════╗
║     Code Review Report                ║
╚═══════════════════════════════════════╝

📁 File: src/auth/login.ts
📊 Quality Score: 85/100

✅ Strengths:
  - Clear function separation
  - Proper error handling
  - Type safety with TypeScript

⚠️  Issues Found:

1. [MEDIUM] Missing input validation
   Line 45: user.password
   → Add validation before processing user input

2. [LOW] Inconsistent naming
   Line 23: getUserData vs get_user_session
   → Use consistent camelCase naming

💡 Suggestions:
  - Consider using existing auth/validator.ts
  - Add unit tests for edge cases
```

### Example 2: Advanced Security Review

```bash
/review --adv src/api/
```

**Output:**
```
╔═══════════════════════════════════════╗
║  Advanced Security & Performance      ║
╚═══════════════════════════════════════╝

🔒 Security Scan (OWASP Top 10)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

❌ [HIGH] SQL Injection Risk
   File: api/users.ts:67
   Issue: Direct string concatenation in query
   Fix: Use parameterized queries

⚠️  [MEDIUM] XSS Vulnerability
   File: api/comments.ts:34
   Issue: Unsanitized user input in response
   Fix: Use DOMPurify or similar sanitizer

⚡ Performance Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️  [MEDIUM] N+1 Query Problem
   File: api/posts.ts:89
   Impact: 50+ DB queries for single request
   Fix: Use JOIN or eager loading

📊 Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Security Issues:   2 high, 1 medium
Performance:       1 medium, 3 low
Overall Score:     68/100
```

### Example 3: Architecture Compliance

```bash
/review --arch
```

**Output:**
```
╔═══════════════════════════════════════╗
║  Architecture Compliance Check        ║
╚═══════════════════════════════════════╝

🏗  Detected: Feature-Sliced Design (FSD)

✅ Compliant:
  - features/auth follows FSD structure
  - Proper layer separation (ui → model → api)
  - No forbidden cross-slice imports

❌ Violations:

1. features/posts/ui → features/user/model
   → Shared logic should move to entities/

2. widgets/header → features/auth/api
   → Widgets shouldn't import feature internals

📋 Recommendations:
  - Extract shared user logic to entities/user
  - Use public API from features/auth/index.ts
```

## Implementation

### Architecture

Uses **reviewer-unified** agent which combines:
- Code quality analysis
- Security scanning (OWASP Top 10)
- Performance profiling
- Impact analysis

### Dependencies

**Required:**
- reviewer-unified agent
- Grep/Read tools for code analysis

**Optional:**
- Architecture config: `.specify/config/architecture.json`
- Quality gates: `workflow-gates.json`
- npm audit for dependency scanning

### Workflow Steps

1. **Scope Detection**
   - Determine files to review (staged, path, or all)
   - Read architecture configuration
   - Load quality gate thresholds

2. **Analysis**
   - **Basic**: Syntax, naming, structure
   - **Advanced**: Security vulnerabilities, performance issues
   - **Architecture**: Pattern compliance, dependency rules

3. **Scoring**
   - Calculate quality score (0-100)
   - Identify critical/high/medium/low issues
   - Compare against quality gates

4. **Report Generation**
   - Format findings with severity levels
   - Provide specific line numbers and fixes
   - Suggest existing patterns to reuse

### Related Resources

- **Agent**: reviewer-unified.md
- **Skills**: reusability-enforcer, dependency-tracer
- **Config**: workflow-gates.json

## Process Flow

```
1. Parse Arguments
   ├─ --staged → Get staged files
   ├─ --adv    → Enable security/performance scan
   ├─ --arch   → Enable architecture validation
   └─ [path]   → Scan specific path

2. Load Context
   ├─ Read architecture config
   ├─ Load quality gates
   └─ Scan for existing patterns

3. Execute Review
   ├─ Basic: Syntax, naming, structure
   ├─ Security: OWASP Top 10 checks
   ├─ Performance: Bottleneck detection
   └─ Architecture: Pattern compliance

4. Generate Report
   ├─ Categorize by severity
   ├─ Add line numbers and context
   ├─ Suggest fixes
   └─ Calculate quality score
```

## Model Selection Logic

- **Basic Review**: Uses `haiku` for fast analysis
- **Advanced Review**: Uses `sonnet` for deep security/performance
- **Architecture Review**: Uses `sonnet` for pattern understanding

Auto-upgrades to `sonnet` when:
- Security issues detected
- Complex architectural patterns
- Performance optimization needed

## Integration Points

### With Workflows

```bash
# Before committing
/review --staged
/commit

# During feature development
/major "new feature"
# ... implementation ...
/review --adv     # Deep review before PR
/pr
```

### With Quality Gates

Respects thresholds from `workflow-gates.json`:
- Code quality: 80%+
- Test coverage: 80%+
- Security: No high/critical issues
- Performance: No blocking issues

### With Architecture Validation

Automatically enforces rules for:
- FSD (Feature-Sliced Design)
- Clean Architecture
- Hexagonal Architecture
- DDD (Domain-Driven Design)

## Error Handling

### "No files to review"
- **Cause**: Empty directory or no changes
- **Fix**: Stage files or specify valid path

### "Architecture config not found"
- **Cause**: Missing `.specify/config/architecture.json`
- **Fix**: Run `/start` to initialize or create manually

### "Quality gate failed"
- **Cause**: Score below threshold
- **Fix**: Address high/critical issues first, then retry

## Tips & Best Practices

### When to Use Each Mode

**Basic Review** (`/review`)
- Quick syntax and style check
- Before committing
- During development

**Advanced Review** (`/review --adv`)
- Before PR creation
- After adding security-sensitive code
- Performance-critical features

**Architecture Review** (`/review --arch`)
- After major refactoring
- New developer onboarding
- Quarterly codebase health check

### Optimal Workflow

```bash
# Development cycle
1. Implement feature
2. /review --staged          # Quick check
3. Fix issues
4. /review --adv            # Deep analysis
5. Address security/performance
6. /commit
7. /pr
```

### Performance Tips

- Review specific paths instead of entire codebase
- Use `--staged` for incremental reviews
- Run `--arch` only when needed (slower)

## Related Commands

- `/commit` - Auto-commit after review passes
- `/pr` - Create PR after successful review
- `/major` - Includes built-in review steps
- `/minor` - Includes targeted review

---

**Version**: 3.3.1
**Last Updated**: 2025-11-18
