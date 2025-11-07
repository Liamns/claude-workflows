---
name: code-metrics-collector
description: Collects code quality metrics including cyclomatic complexity, lines of code, duplication percentage, and other quality indicators.
allowed-tools: Bash(cloc*), Bash(npx*), Grep, Read, Glob
model_preference: haiku
---

# Code Metrics Collector Skill

Collects comprehensive code quality metrics for review and analysis.

## Metrics Collected

### 1. Code Volume
- Lines of Code (LOC)
- Lines of Comments
- Blank lines
- Code-to-comment ratio
- Files count by type

### 2. Complexity Metrics
- Cyclomatic complexity
- Cognitive complexity
- Nesting depth
- Function length
- Class size

### 3. Duplication Metrics
- Duplicate code blocks
- Duplication percentage
- Similar code patterns
- Copy-paste detection

### 4. Quality Indicators
- TODO/FIXME comments
- Code smells
- Long methods (>50 lines)
- Large files (>300 lines)
- Deep nesting (>4 levels)

## Collection Process

### Step 1: Code Volume Analysis

```bash
# Using cloc for accurate counting
npx cloc src/ --json --exclude-dir=node_modules,dist,coverage

# Parse results
{
  "JavaScript": {
    "files": 120,
    "blank": 2500,
    "comment": 1800,
    "code": 15000
  },
  "TypeScript": {
    "files": 200,
    "blank": 3200,
    "comment": 2400,
    "code": 22000
  }
}
```

### Step 2: Complexity Analysis

```typescript
function calculateCyclomaticComplexity(code: string): number {
  let complexity = 1; // Base complexity

  // Decision points
  const decisionPatterns = [
    /if\s*\(/g,
    /else\s+if\s*\(/g,
    /case\s+/g,
    /for\s*\(/g,
    /while\s*\(/g,
    /catch\s*\(/g,
    /\?\s*.*\s*:/g,  // Ternary operator
    /&&/g,           // Logical AND
    /\|\|/g          // Logical OR
  ];

  for (const pattern of decisionPatterns) {
    const matches = code.match(pattern);
    complexity += matches ? matches.length : 0;
  }

  return complexity;
}

// Classify complexity
function getComplexityLevel(score: number): string {
  if (score <= 5) return 'Simple';
  if (score <= 10) return 'Moderate';
  if (score <= 20) return 'Complex';
  return 'Very Complex';
}
```

### Step 3: Duplication Detection

```typescript
function detectDuplication(files: string[]): DuplicationReport {
  const codeBlocks = new Map<string, string[]>();
  const duplicates = [];

  for (const file of files) {
    const content = readFile(file);
    const blocks = extractCodeBlocks(content, MIN_BLOCK_SIZE);

    for (const block of blocks) {
      const hash = hashCodeBlock(block);

      if (codeBlocks.has(hash)) {
        duplicates.push({
          hash,
          locations: [...codeBlocks.get(hash), file],
          lines: block.split('\n').length,
          content: block
        });
      } else {
        codeBlocks.set(hash, [file]);
      }
    }
  }

  return {
    duplicates,
    totalDuplicateLines: calculateTotalDuplicateLines(duplicates),
    duplicationPercentage: (totalDuplicateLines / totalLines) * 100
  };
}
```

### Step 4: Quality Indicators

```typescript
function collectQualityIndicators(scope: ReviewScope): QualityIndicators {
  const indicators = {
    todoComments: [],
    longMethods: [],
    largeFiles: [],
    deepNesting: [],
    codeSmells: []
  };

  for (const file of scope.files) {
    const content = readFile(file);
    const lines = content.split('\n');

    // TODO/FIXME detection
    lines.forEach((line, index) => {
      if (line.match(/TODO|FIXME|HACK|XXX/)) {
        indicators.todoComments.push({
          file,
          line: index + 1,
          content: line.trim()
        });
      }
    });

    // Long methods
    const methods = extractMethods(content);
    for (const method of methods) {
      if (method.lines > 50) {
        indicators.longMethods.push({
          file,
          method: method.name,
          lines: method.lines,
          complexity: method.complexity
        });
      }
    }

    // Large files
    if (lines.length > 300) {
      indicators.largeFiles.push({
        file,
        lines: lines.length
      });
    }

    // Deep nesting
    const maxNesting = calculateMaxNesting(content);
    if (maxNesting > 4) {
      indicators.deepNesting.push({
        file,
        depth: maxNesting
      });
    }
  }

  return indicators;
}
```

## Output Format

### Summary
```markdown
📊 Code Metrics Summary
━━━━━━━━━━━━━━━━━━━━━━
Total Files: 320
Total LOC: 37,000
Code-to-Comment: 15:1
Duplication: 4.2%

Complexity:
• Simple: 180 functions
• Moderate: 95 functions
• Complex: 35 functions
• Very Complex: 10 functions

Quality Issues:
• TODO comments: 23
• Long methods: 8
• Large files: 5
```

### Detailed JSON
```json
{
  "volume": {
    "files": 320,
    "loc": 37000,
    "comments": 2400,
    "blank": 5700,
    "languages": {
      "TypeScript": 22000,
      "JavaScript": 15000
    }
  },
  "complexity": {
    "average": 8.3,
    "median": 6,
    "max": 42,
    "distribution": {
      "simple": 180,
      "moderate": 95,
      "complex": 35,
      "veryComplex": 10
    }
  },
  "duplication": {
    "percentage": 4.2,
    "blocks": 15,
    "totalLines": 1554
  },
  "quality": {
    "todoComments": 23,
    "longMethods": 8,
    "largeFiles": 5,
    "deepNesting": 12,
    "codeSmells": 7
  }
}
```

## Integration with /review

```typescript
// Called from /review command
if (includeMetrics || format === 'detailed') {
  const metrics = await runSkill('code-metrics-collector', {
    scope: reviewScope.files,
    includeComplexity: true,
    includeDuplication: true,
    includeQuality: true
  });

  reviewResults.metrics = {
    volume: metrics.volume,
    complexity: metrics.complexity,
    duplication: metrics.duplication,
    quality: metrics.quality
  };

  // Add to recommendations
  if (metrics.duplication.percentage > 5) {
    reviewResults.recommendations.push({
      priority: 'medium',
      category: 'duplication',
      message: `High duplication (${metrics.duplication.percentage}%). Consider extracting shared code.`
    });
  }
}
```

## Thresholds & Recommendations

| Metric | Good | Warning | Critical |
|--------|------|---------|----------|
| Duplication | <3% | 3-5% | >5% |
| Cyclomatic Complexity | <10 | 10-20 | >20 |
| Method Length | <30 | 30-50 | >50 |
| File Length | <200 | 200-300 | >300 |
| Nesting Depth | <3 | 3-4 | >4 |
| Code-to-Comment | 10-20:1 | 5-10:1 or 20-30:1 | <5:1 or >30:1 |

## Performance Optimization

- Cache metrics for unchanged files
- Parallel processing for large codebases
- Incremental analysis for git diffs
- Skip binary and generated files