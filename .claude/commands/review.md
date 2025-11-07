---
name: review
description: Review code in user-specified scope (files, directories, git diff ranges). Uses project constitution/architecture info if available, falls back to generic best practices. Supports --adv for extended analysis.
---

# /review - Intelligent Code Review System

## Overview

Comprehensive code review for any scope - files, directories, or git changes. Leverages project constitution and architecture information when available, with intelligent model selection and optional advanced analysis.

## Usage

```bash
# Review specific files
/review src/features/auth/LoginForm.tsx
/review "src/features/**/*.tsx"

# Review directory
/review src/features/order

# Review git changes
/review --diff HEAD~1..HEAD
/review --diff main...feature-branch
/review --staged       # Review staged changes
/review --unstaged     # Review working directory changes

# Advanced mode (extended analysis)
/review src/features/auth --adv
/review --diff main...HEAD --adv

# With specific focus areas
/review src/ --focus security,performance
/review src/ --focus reusability

# Output formats
/review src/ --format summary    # Default
/review src/ --format detailed
/review src/ --format json       # For CI/CD
```

## Process Flow

### Stage 1: Initialize & Context Loading

```typescript
// 1.1 Parse review scope
const scope = parseScope(args);
const isAdvanced = args.includes('--adv');
const format = args.match(/--format[= ](\w+)/)?.[1] || 'summary';
const focus = args.match(/--focus[= ]([\w,]+)/)?.[1]?.split(',');

// 1.2 Load project context
const hasConstitution = fileExists('.specify/memory/constitution.md');
const architecture = await loadArchitecture('.specify/config/architecture.json');
const projectContext = {
  hasConstitution,
  architecture: architecture || detectArchitecture(),
  activeArticles: hasConstitution ? parseConstitution() : [],
  reusabilityEnabled: hasActiveArticle('X')
};

// 1.3 Calculate complexity
const complexity = calculateComplexity(scope);
const model = selectModel(complexity);
const useContext7 = complexity > 10 || isAdvanced;

// 1.4 Notify user
console.log(`
═══════════════════════════════════════════════════════════
📋 Code Review Starting
═══════════════════════════════════════════════════════════
📊 Scope: ${scope.description}
🎯 Model: ${model} (Complexity: ${complexity})
🏗️ Architecture: ${projectContext.architecture || 'Generic'}
📜 Constitution: ${hasConstitution ? 'Active' : 'Not found'}
🔍 Mode: ${isAdvanced ? 'Advanced (--adv)' : 'Standard'}
${useContext7 ? '🔗 Context7: Enabled' : ''}
═══════════════════════════════════════════════════════════
`);
```

### Stage 2: Core Review Execution

#### 2.1 Constitution Compliance Check

```typescript
if (projectContext.hasConstitution) {
  console.log('\n📜 Checking Constitution Compliance...\n');

  // Article I - Library-First Principle
  if (hasActiveArticle('I')) {
    const libraryCompliance = await checkLibraryFirst(scope);
    reportArticleCompliance('I', 'Library-First', libraryCompliance);
  }

  // Article III - Test-First Imperative
  if (hasActiveArticle('III')) {
    const testCompliance = await checkTestFirst(scope);
    reportArticleCompliance('III', 'Test-First', testCompliance);
  }

  // Article X - Reusability-First Principle [CRITICAL]
  if (hasActiveArticle('X')) {
    console.log('🔄 Article X Active - Enforcing Reusability Checks');
    const reusabilityCheck = await enforceReusability(scope, {
      targetReuseRate: 60,
      maxDuplication: 5,
      useContext7
    });
    reportArticleCompliance('X', 'Reusability-First', reusabilityCheck);
  }
}
```

#### 2.2 Parallel Core Analysis

```typescript
console.log('\n🔍 Running Core Review Analysis...\n');

// Run agents in parallel for efficiency
const [securityResult, architectureResult, reusabilityResult] = await Promise.all([
  // Code Reviewer Agent - Security & Performance
  runCodeReviewerAgent(scope, {
    focus: focus || ['security', 'performance', 'quality'],
    model,
    format: 'structured'
  }),

  // Architect Agent - Architecture Compliance
  runArchitectAgent(scope, {
    architecture: projectContext.architecture,
    readOnly: true,
    checkBreakingChanges: true
  }),

  // Reusability Enforcer Skill
  projectContext.reusabilityEnabled ? runReusabilityEnforcer(scope, {
    searchExisting: true,
    calculateMetrics: true,
    suggestPatterns: true,
    useContext7: useContext7 && complexity > 10
  }) : null
]);
```

#### 2.3 Specialized Analysis

```typescript
const specializedResults = {};

// Security Deep Scan (if issues found or requested)
if (securityResult.hasIssues || focus?.includes('security')) {
  console.log('🔒 Running Security Deep Scan...');
  specializedResults.security = await runSecurityScanner(scope, {
    deepScan: true,
    checkDependencies: true,
    scanCredentials: true
  });
}

// Test Coverage Analysis (if test files changed)
if (scope.files.some(f => f.includes('.test.') || f.includes('.spec.'))) {
  console.log('🧪 Analyzing Test Coverage...');
  specializedResults.coverage = await runTestCoverageAnalyzer(scope, {
    targetCoverage: projectContext.hasConstitution ? 80 : 70,
    identifyGaps: true
  });
}

// Bug Pattern Detection
console.log('🐛 Checking for Bug Patterns...');
specializedResults.bugs = await runBugPatternDetector(scope, {
  patterns: ['null-check', 'async', 'type-error', 'react-hooks']
});
```

### Stage 3: Advanced Analysis (--adv flag)

```typescript
if (isAdvanced) {
  console.log('\n🚀 Running Advanced Analysis (--adv mode)...\n');

  // Enable Context7 for deep analysis
  if (!useContext7) {
    console.log('🔗 Activating Context7 for advanced mode...');
  }

  // Impact Analysis
  console.log('📊 Analyzing Cross-File Impact...');
  const impactAnalysis = await runImpactAnalyzer(scope, {
    useContext7: true,
    maxTokens: 2500,
    traceImports: true,
    detectBreakingChanges: true,
    findAffectedComponents: true
  });

  // Dependency Tracing
  console.log('🔍 Tracing Dependencies...');
  const dependencies = await runDependencyTracer(scope, {
    buildGraph: true,
    detectCircular: true,
    analyzeBundleImpact: true
  });

  // Pattern Extraction (for reusability)
  if (projectContext.reusabilityEnabled) {
    console.log('🎯 Extracting Reusable Patterns...');
    const patterns = await extractReusablePatterns(scope, {
      useContext7: true,
      suggestAbstractions: true,
      proposeSharedModules: true
    });
    specializedResults.patterns = patterns;
  }

  specializedResults.impact = impactAnalysis;
  specializedResults.dependencies = dependencies;
}
```

### Stage 4: Report Generation

#### 4.1 Summary Format (Default)

```typescript
if (format === 'summary') {
  generateSummaryReport({
    scope,
    complexity,
    model,
    constitution: projectContext.hasConstitution ? constitutionResults : null,
    security: securityResult,
    architecture: architectureResult,
    reusability: reusabilityResult,
    specialized: specializedResults,
    isAdvanced
  });
}
```

**Example Summary Output:**
```
═══════════════════════════════════════════════════════════
📋 Code Review Results: src/features/order
═══════════════════════════════════════════════════════════

📊 Scope:
• Files: 8 (+245 / -67 lines)
• Complexity: 9 (Medium)
• Model: Sonnet
• Architecture: FSD

🎯 Review Summary:
┌─────────────────┬────────┬──────────────────────────────┐
│ Category        │ Status │ Findings                     │
├─────────────────┼────────┼──────────────────────────────┤
│ 🔒 Security     │ ✅ Safe │ No vulnerabilities found     │
│ ⚡ Performance  │ ⚠️ Warn │ 2 optimization opportunities│
│ 🏗️ Architecture │ ✅ Good │ FSD compliant                │
│ 🎯 Type Safety  │ ⚠️ Warn │ 1 any usage detected         │
│ 🧪 Testing      │ ✅ Good │ Coverage: 85%                │
│ 📝 Quality      │ ✅ High │ Clean code structure         │
│ ♻️ Reusability  │ ⚠️ Issues│ 2 pattern violations        │
└─────────────────┴────────┴──────────────────────────────┘

📜 Constitution Compliance:
• Article I (Library-First): ✅ Compliant
• Article III (Test-First): ✅ Compliant (85% coverage)
• Article X (Reusability): ⚠️ 2 violations found

⚠️ Issues to Address: 5
❌ Critical Issues: 0

Overall: NEEDS WORK

💡 Top Recommendations:
1. Add useCallback to OrderForm.tsx:45 (Performance)
2. Use existing httpClient pattern in createOrder.ts:10
3. Extract validateAddress to shared/lib/validation

Run with --format detailed for full analysis
```

#### 4.2 Detailed Format

```typescript
if (format === 'detailed') {
  generateDetailedReport({
    // ... all results
    includeCodeSnippets: true,
    showFixSuggestions: true,
    includeMetrics: true
  });
}
```

#### 4.3 JSON Format (CI/CD)

```typescript
if (format === 'json') {
  const jsonReport = {
    review: {
      scope: {
        type: scope.type,
        paths: scope.paths,
        filesCount: scope.files.length,
        linesChanged: scope.stats
      },
      complexity: {
        score: complexity,
        level: getComplexityLevel(complexity),
        model: model
      },
      results: {
        security: securityResult,
        architecture: architectureResult,
        reusability: reusabilityResult,
        specialized: specializedResults
      },
      constitution: projectContext.hasConstitution ? {
        compliance: constitutionResults,
        violations: constitutionViolations
      } : null,
      recommendation: getOverallRecommendation(allResults),
      actionItems: categorizeActionItems(allIssues)
    }
  };

  console.log(JSON.stringify(jsonReport, null, 2));
}
```

## Model Selection Logic

```typescript
function selectModel(complexity: number): string {
  // Check user preferences
  const userStrategy = getUserPreference('model_strategy');

  // Check for quota
  const opusAvailable = checkOpusQuota();

  // Complexity-based selection
  if (complexity <= 5) {
    return 'haiku';
  } else if (complexity <= 11) {
    return userStrategy === 'quality' && opusAvailable ? 'opus' : 'sonnet';
  } else {
    return opusAvailable ? 'opus' : 'sonnet';
  }
}

function calculateComplexity(scope): number {
  let score = 0;

  // File count
  const fileCount = scope.files.length;
  if (fileCount <= 3) score += 1;
  else if (fileCount <= 10) score += 3;
  else score += 5;

  // Lines changed
  const linesChanged = scope.stats.added + scope.stats.removed;
  if (linesChanged > 500) score += 3;
  else if (linesChanged > 100) score += 2;
  else score += 1;

  // Architecture impact
  if (touchesPublicAPI(scope)) score += 5;
  if (touchesMultipleLayers(scope)) score += 4;
  if (hasBreakingChanges(scope)) score += 6;

  return score;
}
```

## Integration Points

### With /commit
```bash
# Auto-review before commit
/commit --with-review
→ Automatically runs: /review --staged
→ Shows issues before proceeding
```

### With /major workflow
```yaml
In major-implement stage:
  post_implementation:
    - auto_run: /review {implemented_files}
    - block_on: critical_issues
```

### CI/CD Pipeline
```yaml
# GitHub Actions example
- name: Run Code Review
  run: |
    claude /review --diff ${{ github.event.pull_request.base.sha }}...${{ github.event.pull_request.head.sha }} --format json > review.json

- name: Post Review Comment
  uses: actions/github-script@v6
  with:
    script: |
      const review = require('./review.json');
      // Post review results as PR comment
```

## Error Handling

### No Project Info
```
ℹ️ No project constitution found (.specify/memory/constitution.md)
ℹ️ Using generic best practices for review
ℹ️ Run /start to set up project-specific rules
```

### Quota Exhausted
```
⚠️ Opus quota exhausted, using Sonnet with enhanced analysis
ℹ️ Enhanced mode includes additional checklists and patterns
```

### Context7 Unavailable
```
⚠️ Context7 connection failed
↩️ Falling back to manual pattern search
ℹ️ This may take slightly longer...
```

## Tips & Best Practices

1. **Use --adv sparingly** - It's resource-intensive and best for critical reviews
2. **Focus areas** - Use --focus to speed up targeted reviews
3. **Regular reviews** - Run before each commit for best results
4. **Constitution setup** - Run /start to enable project-specific rules
5. **CI/CD integration** - Use JSON format for automated pipelines

## Related Commands

- `/pr-review` - Review GitHub pull requests
- `/commit` - Create commits with optional review
- `/start` - Set up project constitution
- `/triage` - Auto-select workflow based on task