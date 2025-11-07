---
name: test-coverage-analyzer
description: Analyzes test coverage and identifies gaps without enforcing TDD. Read-only analysis for code review purposes.
allowed-tools: Bash(yarn test*), Bash(yarn test:coverage), Read, Grep, Glob
context7_enabled: false
model_preference: haiku
---

# Test Coverage Analyzer Skill

Read-only test coverage analysis for code review. Unlike test-guardian agent, this skill only analyzes and reports without enforcement.

## Purpose

- Analyze test coverage metrics
- Identify untested code paths
- Suggest missing test cases
- Validate critical path coverage
- Track coverage trends

## Activation

Automatically activated when:
- `/review` command includes test files
- `--focus testing` flag is used
- Test-related changes detected in review scope

## Analysis Process

### Step 1: Coverage Metrics Collection

```bash
# Run coverage analysis
yarn test:coverage --silent

# Parse coverage report
cat coverage/coverage-summary.json
```

**Metrics Extracted:**
- Line coverage percentage
- Branch coverage percentage
- Function coverage percentage
- Statement coverage percentage
- Uncovered lines list

### Step 2: Gap Identification

```typescript
interface CoverageGap {
  file: string;
  lines: number[];
  type: 'line' | 'branch' | 'function';
  priority: 'critical' | 'high' | 'medium' | 'low';
  suggestion: string;
}

function identifyGaps(coverage: CoverageReport): CoverageGap[] {
  const gaps: CoverageGap[] = [];

  for (const file of coverage.files) {
    // Critical: Public API methods
    if (file.path.includes('/api/') && file.coverage < 90) {
      gaps.push({
        file: file.path,
        lines: file.uncoveredLines,
        type: 'function',
        priority: 'critical',
        suggestion: 'Add tests for public API endpoints'
      });
    }

    // High: Business logic
    if (file.path.includes('/services/') && file.coverage < 80) {
      gaps.push({
        file: file.path,
        lines: file.uncoveredLines,
        type: 'function',
        priority: 'high',
        suggestion: 'Add unit tests for business logic'
      });
    }

    // Medium: UI components
    if (file.path.includes('/components/') && file.coverage < 70) {
      gaps.push({
        file: file.path,
        lines: file.uncoveredLines,
        type: 'line',
        priority: 'medium',
        suggestion: 'Add component tests with user interactions'
      });
    }
  }

  return gaps;
}
```

### Step 3: Critical Path Validation

```yaml
Critical Paths to Check:
  Authentication:
    - Login flow
    - Token refresh
    - Logout
    - Permission checks

  Data Operations:
    - CRUD operations
    - Data validation
    - Error handling
    - Edge cases

  User Flows:
    - Happy path
    - Error scenarios
    - Loading states
    - Empty states
```

### Step 4: Test Quality Assessment

```typescript
function assessTestQuality(testFiles: string[]): TestQuality {
  const quality = {
    hasUnitTests: false,
    hasIntegrationTests: false,
    hasE2ETests: false,
    testTypes: [],
    recommendations: []
  };

  for (const file of testFiles) {
    const content = readFile(file);

    // Check test types
    if (content.includes('describe') && content.includes('it')) {
      quality.hasUnitTests = true;
    }

    if (content.includes('supertest') || content.includes('msw')) {
      quality.hasIntegrationTests = true;
    }

    if (content.includes('cypress') || content.includes('playwright')) {
      quality.hasE2ETests = true;
    }

    // Check for test quality issues
    if (!content.includes('expect')) {
      quality.recommendations.push(`${file}: Add assertions`);
    }

    if (content.includes('.only(')) {
      quality.recommendations.push(`${file}: Remove .only() before commit`);
    }

    if (content.includes('skip(')) {
      quality.recommendations.push(`${file}: Review skipped tests`);
    }
  }

  return quality;
}
```

## Output Format

### Summary Mode

```markdown
🧪 Test Coverage Analysis
━━━━━━━━━━━━━━━━━━━━━━━━
Overall Coverage: 76.5%
• Lines: 78.2%
• Branches: 72.1%
• Functions: 79.3%
• Statements: 76.5%

Status: ⚠️ Below target (80%)

Critical Gaps: 2
High Priority: 5
Medium Priority: 8
```

### Detailed Mode

```markdown
🧪 Test Coverage Analysis - DETAILED
═════════════════════════════════════════════

## Coverage Metrics
┌──────────────┬─────────┬────────┬──────────┐
│ Type         │ Current │ Target │ Status   │
├──────────────┼─────────┼────────┼──────────┤
│ Lines        │ 78.2%   │ 80%    │ ⚠️ Below │
│ Branches     │ 72.1%   │ 75%    │ ⚠️ Below │
│ Functions    │ 79.3%   │ 80%    │ ⚠️ Below │
│ Statements   │ 76.5%   │ 80%    │ ⚠️ Below │
└──────────────┴─────────┴────────┴──────────┘

## Critical Gaps (Fix Required)

### 1. src/features/auth/api/login.ts
Coverage: 45% (Target: 90%)
Uncovered Lines: 23-45, 67-89
Priority: 🔴 CRITICAL

Missing Tests:
• Error handling for network failures
• Token refresh logic
• Session timeout handling

Suggested Test:
```typescript
describe('login API', () => {
  it('should handle network errors gracefully', async () => {
    // Mock network error
    server.use(
      rest.post('/api/login', (req, res, ctx) => {
        return res.networkError('Failed to connect')
      })
    );

    // Test error handling
    await expect(login(credentials)).rejects.toThrow('Network error');
  });
});
```

### 2. src/features/payment/services/processPayment.ts
Coverage: 52% (Target: 85%)
Uncovered Lines: 34-67, 89-102
Priority: 🔴 CRITICAL

Missing Tests:
• Payment validation edge cases
• Retry logic
• Partial payment scenarios

## Test Quality Issues

⚠️ Found 3 quality issues:

1. **Skipped Tests**
   File: src/features/order/Order.test.tsx
   Line: 45
   Issue: Test marked as .skip()
   Action: Review and enable or remove

2. **Missing Assertions**
   File: src/features/cart/Cart.test.tsx
   Lines: 23, 67
   Issue: Test without expect() statements
   Action: Add meaningful assertions

3. **Focused Tests**
   File: src/features/user/User.test.tsx
   Line: 89
   Issue: .only() found
   Action: Remove before commit

## Recommendations

### Immediate Actions
1. Add tests for login error handling (Critical)
2. Cover payment processing edge cases (Critical)
3. Remove .only() and .skip() modifiers

### Coverage Improvements
• Focus on branch coverage (currently 72.1%)
• Add integration tests for API endpoints
• Test error boundaries and fallback UI

### Test Organization
• Consider extracting test utilities to shared/test-utils
• Add data-testid attributes for better E2E testing
• Document critical user flows that must be tested
```

## Integration with /review

When called from `/review` command:

```typescript
// In /review command
if (scope.hasTestFiles || focus.includes('testing')) {
  const coverageAnalysis = await runSkill('test-coverage-analyzer', {
    scope: scope.files,
    targetCoverage: constitution?.testCoverage || 80,
    format: reviewFormat,
    includeGaps: true,
    suggestTests: true
  });

  // Add to review results
  reviewResults.testing = {
    coverage: coverageAnalysis.metrics,
    gaps: coverageAnalysis.gaps,
    quality: coverageAnalysis.quality,
    status: coverageAnalysis.meetsTarget ? 'pass' : 'fail'
  };
}
```

## Constitution Integration

If Article III (Test-First) is active:

```yaml
Enhanced Checks:
  - Target coverage: 80% (vs 70% default)
  - Require tests for new files
  - Check test-to-code ratio
  - Validate TDD evidence (tests before implementation)
```

## Comparison with test-guardian

| Feature | test-guardian (Agent) | test-coverage-analyzer (Skill) |
|---------|----------------------|--------------------------------|
| Purpose | Enforce TDD in Major | Analyze coverage for review |
| Mode | Write/Enforce | Read-only |
| Blocking | Yes (blocks on failure) | No (reports only) |
| Coverage Target | 80% mandatory | Configurable |
| Test Creation | Creates test files | Suggests test cases |
| Model | Sonnet | Haiku |

## Error Handling

### No Coverage Reports
```
⚠️ No coverage reports found
ℹ️ Run 'yarn test:coverage' to generate coverage data
ℹ️ Skipping coverage analysis...
```

### Test Execution Failure
```
❌ Tests failed to run
ℹ️ Fix test errors before analyzing coverage:
  [Error details]
```

### Incomplete Coverage Data
```
⚠️ Coverage data incomplete
ℹ️ Some files missing from coverage report
ℹ️ Check jest.config.js collectCoverageFrom settings
```