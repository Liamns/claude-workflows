# /pr-review - Automated PR Review

## Overview

Automated pull request review with codebase context and intelligent analysis of specific PR changes.

This command:
1. **Fetches PR**: Downloads PR details using GitHub CLI
2. **Analyzes Changes**: Reviews diff and commit history
3. **Contextual Review**: Understands impact on existing codebase
4. **Provides Feedback**: Security, quality, architecture, performance analysis

**Key Features:**
- OWASP Top 10 security scanning
- Breaking change detection
- Performance impact analysis
- Architecture compliance check
- Reusability suggestions

## Usage

```bash
/pr-review <pr-number> [options]
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `<pr-number>` | PR number to review | Required |
| `--full` | Full detailed review | `false` |
| `--security` | Security-focused review | `false` |

### Basic Commands

```bash
/pr-review 42              # Review PR #42
/pr-review 42 --full       # Detailed review
/pr-review 42 --security   # Security-focused
```

## Examples

### Example 1: Basic PR Review

```bash
/pr-review 42
```

**Output:**
```
╔═══════════════════════════════════════╗
║   PR #42 Review                       ║
╚═══════════════════════════════════════╝

📋 PR Info
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Title: feat: Add user authentication
Author: @username
Files: 12 changed
+1,245 -89 lines

✅ Strengths
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Well-structured authentication flow
2. Comprehensive test coverage (92%)
3. Follows existing patterns in auth/

⚠️  Issues Found
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[MEDIUM] Missing rate limiting
  File: src/api/login.ts:45
  → Add rate limiting to prevent brute force

[LOW] Inconsistent error messages
  Files: src/auth/*.ts
  → Use centralized error messages

💡 Suggestions
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

- Consider using existing src/utils/validator.ts
- Add integration tests for token refresh flow

📊 Overall Assessment
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Score: 85/100
Recommendation: ✅ APPROVE with minor changes
```

### Example 2: Security-Focused Review

```bash
/pr-review 42 --security
```

**Output:**
```
╔═══════════════════════════════════════╗
║   Security Review - PR #42            ║
╚═══════════════════════════════════════╝

🔒 OWASP Top 10 Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

❌ [CRITICAL] Password Stored in Plain Text
   File: src/models/user.ts:67
   Issue: Passwords not hashed
   Fix: Use bcrypt with salt rounds >= 12

⚠️  [HIGH] SQL Injection Risk
   File: src/api/users.ts:123
   Issue: String concatenation in query
   Fix: Use parameterized queries

✅ [PASS] XSS Prevention
   All user inputs properly sanitized

✅ [PASS] CSRF Protection
   Tokens implemented correctly

🛡️  Additional Checks
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️  Dependencies: 2 vulnerabilities found
   - jsonwebtoken: Upgrade to 9.0.0+
   - express: Upgrade to 4.18.2+

📊 Security Score: 45/100
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Recommendation: ❌ REQUEST CHANGES
Critical issues must be fixed before merge
```

### Example 3: Full Detailed Review

```bash
/pr-review 42 --full
```

**Includes:**
- Code quality analysis
- Security scan
- Performance impact
- Architecture compliance
- Breaking changes detection
- Test coverage analysis
- Documentation completeness

## Implementation

### Architecture

Uses **reviewer-unified** agent which provides:
- Multi-level analysis (basic → advanced)
- Codebase context understanding
- Pattern matching against existing code
- Impact assessment

### Dependencies

**Required:**
- GitHub CLI (`gh`) for PR fetching
- reviewer-unified agent
- Git repository with remote

**Optional:**
- Architecture config: `.specify/config/architecture.json`
- Quality gates: `workflow-gates.json`
- npm audit for dependency scanning

### Workflow Steps

1. **Fetch PR Data**
   - Use `gh pr view <number>` for PR details
   - Get `gh pr diff <number>` for changes
   - Read commit messages

2. **Context Loading**
   - Load architecture configuration
   - Read quality gate thresholds
   - Scan existing patterns in codebase

3. **Analysis**
   - **Code Quality**: Style, structure, naming
   - **Security**: OWASP Top 10, dependency vulnerabilities
   - **Performance**: N+1 queries, memory leaks, inefficient algorithms
   - **Architecture**: Pattern compliance, layer violations
   - **Breaking Changes**: API changes, interface modifications

4. **Report Generation**
   - Categorize findings by severity
   - Provide line numbers and context
   - Suggest specific fixes
   - Calculate overall score

### Related Resources

- **Agent**: reviewer-unified.md
- **CLI**: GitHub CLI (`gh`)
- **Skills**: dependency-tracer, reusability-enforcer

## Review Criteria

### Code Quality (Weight: 30%)
- Readability and maintainability
- Consistent style and naming
- Proper error handling
- Code duplication

### Security (Weight: 30%)
- OWASP Top 10 vulnerabilities
- Authentication and authorization
- Input validation
- Dependency vulnerabilities

### Architecture (Weight: 20%)
- Pattern compliance (FSD, Clean, etc.)
- Layer separation
- Dependency rules
- Breaking changes

### Performance (Weight: 20%)
- Query optimization
- Algorithm efficiency
- Memory management
- Caching opportunities

## Review Grades

**90-100**: Excellent
- No major issues
- Best practices followed
- Comprehensive tests
- **Action**: Approve immediately

**75-89**: Good
- Minor improvements needed
- Overall solid implementation
- **Action**: Approve with comments

**60-74**: Acceptable
- Several issues to address
- Functional but needs refinement
- **Action**: Request changes (non-blocking)

**Below 60**: Needs Work
- Critical issues present
- Security or performance concerns
- **Action**: Request changes (blocking)

## Error Handling

### "PR not found"
- **Cause**: Invalid PR number or no access
- **Fix**: Verify PR number with `gh pr list`

### "gh not authenticated"
- **Cause**: GitHub CLI not logged in
- **Fix**: Run `gh auth login`

### "Cannot fetch PR diff"
- **Cause**: PR closed or merged
- **Fix**: Check PR status on GitHub

## Tips & Best Practices

### When to Use Each Mode

**Basic Review** (`/pr-review <number>`)
- Quick check before merging
- Standard PR review process
- Daily development workflow

**Security Focus** (`/pr-review <number> --security`)
- Authentication/authorization changes
- API endpoint additions
- External library integrations

**Full Review** (`/pr-review <number> --full`)
- Major features
- Before production deployment
- Quarterly code audits

### Integration with CI/CD

```bash
# In GitHub Actions
- name: Automated PR Review
  run: /pr-review ${{ github.event.pull_request.number }}
```

### Optimal Workflow

```bash
# As PR author
1. Create PR: /pr
2. Self-review: /pr-review <number>
3. Fix issues
4. Push updates

# As reviewer
1. Review: /pr-review <number> --full
2. Leave comments on GitHub
3. Approve or request changes
```

## Related Commands

- `/pr` - Create PR before review
- `/review` - Review local changes before PR
- `/commit` - Commit changes after addressing review
- `/major`, `/minor`, `/micro` - Include PR creation and review

---

**Version**: 3.3.1
**Last Updated**: 2025-11-18
