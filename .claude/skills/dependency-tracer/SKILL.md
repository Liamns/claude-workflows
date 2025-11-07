---
name: dependency-tracer
description: Maps and analyzes dependency relationships in the codebase. Detects circular dependencies, unused imports, and bundle impact for advanced reviews.
allowed-tools: Read, Grep, Glob, Bash(madge*), Bash(npx*)
context7_enabled: true
context7_budget: 1000
model_preference: sonnet
advanced_mode_only: true
---

# Dependency Tracer Skill

Maps dependency relationships and analyzes import/export patterns for the `--adv` mode in `/review`.

## Purpose

- Build dependency graphs
- Detect circular dependencies
- Find unused imports/exports
- Analyze bundle impact
- Identify tightly coupled modules

## Analysis Capabilities

### 1. Dependency Graph Construction

```typescript
interface DependencyNode {
  file: string;
  imports: string[];
  exports: string[];
  dependencies: Set<string>;
  dependents: Set<string>;
  level: number; // Distance from entry point
}

async function buildDependencyGraph(entryPoints: string[]): Promise<Map<string, DependencyNode>> {
  const graph = new Map<string, DependencyNode>();
  const queue = [...entryPoints];
  const visited = new Set<string>();
  let level = 0;

  while (queue.length > 0) {
    const currentLevel = queue.splice(0, queue.length);
    level++;

    for (const file of currentLevel) {
      if (visited.has(file)) continue;
      visited.add(file);

      const imports = await extractImports(file);
      const exports = await extractExports(file);

      const node: DependencyNode = {
        file,
        imports,
        exports,
        dependencies: new Set(imports),
        dependents: new Set(),
        level
      };

      graph.set(file, node);

      // Queue dependencies for next level
      for (const imp of imports) {
        if (!visited.has(imp)) {
          queue.push(imp);
        }
        // Update dependent's list
        if (graph.has(imp)) {
          graph.get(imp).dependents.add(file);
        }
      }
    }
  }

  return graph;
}
```

### 2. Circular Dependency Detection

```typescript
interface CircularDependency {
  cycle: string[];
  severity: 'critical' | 'high' | 'medium' | 'low';
  suggestion: string;
}

async function detectCircularDependencies(): Promise<CircularDependency[]> {
  // Using madge for accurate detection
  const result = await bash('npx madge --circular src/');
  const cycles = parseMadgeOutput(result);

  return cycles.map(cycle => ({
    cycle,
    severity: calculateCycleSeverity(cycle),
    suggestion: generateBreakingSuggestion(cycle)
  }));
}

function calculateCycleSeverity(cycle: string[]): string {
  // Critical: Core domain models
  if (cycle.some(f => f.includes('/domain/') || f.includes('/entities/'))) {
    return 'critical';
  }
  // High: Feature-level cycles
  if (cycle.some(f => f.includes('/features/'))) {
    return 'high';
  }
  // Medium: UI components
  if (cycle.some(f => f.includes('/components/') || f.includes('/ui/'))) {
    return 'medium';
  }
  return 'low';
}
```

### 3. Unused Import/Export Detection

```typescript
interface UnusedCode {
  file: string;
  type: 'import' | 'export';
  name: string;
  line: number;
}

async function findUnusedCode(scope: string[]): Promise<UnusedCode[]> {
  const unused: UnusedCode[] = [];

  for (const file of scope) {
    const content = await readFile(file);

    // Find unused imports
    const imports = extractImports(content);
    for (const imp of imports) {
      if (!isImportUsed(imp, content)) {
        unused.push({
          file,
          type: 'import',
          name: imp.name,
          line: imp.line
        });
      }
    }

    // Find unused exports
    const exports = extractExports(content);
    for (const exp of exports) {
      const users = await findExportUsers(file, exp.name);
      if (users.length === 0) {
        unused.push({
          file,
          type: 'export',
          name: exp.name,
          line: exp.line
        });
      }
    }
  }

  return unused;
}
```

### 4. Bundle Impact Analysis

```typescript
interface BundleImpact {
  file: string;
  directSize: number;
  totalSize: number; // Including dependencies
  treeShakeable: boolean;
  heavyDependencies: string[];
}

async function analyzeBundleImpact(files: string[]): Promise<BundleImpact[]> {
  const impacts: BundleImpact[] = [];

  for (const file of files) {
    const directSize = await getFileSize(file);
    const dependencies = await getAllDependencies(file);

    let totalSize = directSize;
    const heavyDeps = [];

    for (const dep of dependencies) {
      const depSize = await getFileSize(dep);
      totalSize += depSize;

      if (depSize > 50000) { // 50KB threshold
        heavyDeps.push({
          file: dep,
          size: depSize
        });
      }
    }

    impacts.push({
      file,
      directSize,
      totalSize,
      treeShakeable: await isTreeShakeable(file),
      heavyDependencies: heavyDeps
    });
  }

  return impacts;
}
```

### 5. Module Coupling Analysis

```typescript
interface CouplingMetrics {
  module: string;
  afferentCoupling: number;  // Number of modules that depend on this
  efferentCoupling: number;  // Number of modules this depends on
  instability: number;       // EC / (AC + EC)
  abstractness: number;       // Abstract classes/interfaces ratio
  mainSequence: number;       // Distance from ideal line
}

function analyzeCoupling(graph: Map<string, DependencyNode>): CouplingMetrics[] {
  const metrics: CouplingMetrics[] = [];

  for (const [module, node] of graph) {
    const ac = node.dependents.size;
    const ec = node.dependencies.size;
    const instability = ec / (ac + ec || 1);

    metrics.push({
      module,
      afferentCoupling: ac,
      efferentCoupling: ec,
      instability,
      abstractness: calculateAbstractness(module),
      mainSequence: Math.abs(instability + abstractness - 1)
    });
  }

  return metrics;
}
```

## Execution Process

### Step 1: Initialize Tracing

```bash
# Install/verify madge if needed
npx madge --version || npm install -g madge

# Generate initial dependency tree
npx madge src/ --json > .dependency-tree.json
```

### Step 2: Build Dependency Graph

```typescript
const entryPoints = await findEntryPoints(); // index.ts, main.ts, etc.
const graph = await buildDependencyGraph(entryPoints);
console.log(`📊 Dependency graph: ${graph.size} modules`);
```

### Step 3: Run Analyses

```typescript
// Parallel analysis for performance
const [circular, unused, bundleImpact, coupling] = await Promise.all([
  detectCircularDependencies(),
  findUnusedCode(reviewScope.files),
  analyzeBundleImpact(reviewScope.files),
  analyzeCoupling(graph)
]);
```

### Step 4: Generate Visualizations

```bash
# Generate dependency graph image (optional)
npx madge src/ --image dependency-graph.svg

# Generate circular dependency graph
npx madge src/ --circular --image circular.svg
```

## Output Format

### Summary
```markdown
🔍 Dependency Analysis
━━━━━━━━━━━━━━━━━━━━━
Modules Analyzed: 45
Total Dependencies: 234
Circular Dependencies: 2
Unused Imports: 8
Unused Exports: 3

Bundle Impact:
• Total Size: 145KB
• Heavy Dependencies: 2
```

### Detailed Report
```markdown
🔍 Dependency Analysis - DETAILED
═══════════════════════════════════════════

## Circular Dependencies Found (2)

### 1. Critical Cycle
```
src/features/order/model/orderSlice.ts
  ↓
src/features/order/api/orderApi.ts
  ↓
src/features/order/model/orderSlice.ts
```

**Impact**: Prevents tree-shaking, causes initialization issues
**Suggestion**: Extract shared types to separate file

### 2. Medium Cycle
```
src/components/Form/Form.tsx
  ↓
src/components/Form/Field.tsx
  ↓
src/components/Form/Form.tsx
```

**Impact**: UI rendering issues
**Suggestion**: Use dependency injection or context

## Unused Code (11 items)

### Unused Imports (8)
• src/features/order/OrderList.tsx:5 - `useState` (not used)
• src/features/order/OrderForm.tsx:8 - `useCallback` (not used)
[... 6 more]

### Unused Exports (3)
• src/utils/helpers.ts:45 - `formatPhone()` (no importers)
• src/utils/validation.ts:23 - `validateZipCode()` (no importers)
• src/types/legacy.ts:12 - `OldOrderType` (no importers)

**Recommendation**: Remove unused code to reduce bundle size

## Bundle Impact Analysis

### Heavy Dependencies
1. **moment.js** (290KB)
   Used by: src/utils/date.ts
   Alternative: date-fns (12KB for used functions)

2. **lodash** (71KB)
   Used by: src/utils/helpers.ts
   Alternative: lodash-es with tree-shaking

### File Impact
| File | Direct | Total | Tree-shakeable |
|------|--------|-------|----------------|
| OrderForm.tsx | 12KB | 95KB | ❌ (circular) |
| OrderList.tsx | 8KB | 45KB | ✅ |
| OrderApi.ts | 3KB | 78KB | ❌ (circular) |

## Coupling Metrics

### Highly Coupled Modules (Instability > 0.8)
• src/features/order/api/orderApi.ts - I=0.85
• src/services/httpClient.ts - I=0.92

### Stable Modules (Instability < 0.3)
• src/shared/types/order.ts - I=0.15
• src/entities/order/model.ts - I=0.22

**Recommendation**: Reduce coupling in API layer

## Dependency Graph Visualization

[Link to dependency-graph.svg]

Key Observations:
• Order feature has highest connectivity (15 connections)
• Shared utilities are well-isolated
• Authentication module is properly decoupled
```

## Integration with /review --adv

```typescript
// Only called with --adv flag
if (reviewOptions.advanced) {
  const dependencyAnalysis = await runSkill('dependency-tracer', {
    scope: reviewScope.files,
    detectCircular: true,
    analyzeBundle: true,
    analyzeCoupling: true,
    generateVisuals: false // Performance consideration
  });

  // Add to advanced results
  reviewResults.advanced.dependencies = {
    circular: dependencyAnalysis.circular,
    unused: dependencyAnalysis.unused,
    bundleImpact: dependencyAnalysis.bundleImpact,
    coupling: dependencyAnalysis.coupling
  };

  // Add recommendations
  if (dependencyAnalysis.circular.length > 0) {
    reviewResults.recommendations.push({
      priority: 'high',
      category: 'architecture',
      message: `Found ${dependencyAnalysis.circular.length} circular dependencies. Breaking these will improve bundle size and initialization.`
    });
  }
}
```

## Performance Optimization

- Cache dependency graph for unchanged files
- Use incremental analysis for git diffs
- Limit depth for very large codebases
- Skip node_modules and build directories

## Context7 Integration

```yaml
When Context7 enabled:
  Load:
    - Import/export maps
    - Module boundaries
    - Entry points

  Benefits:
    - Faster pattern matching
    - Better circular detection
    - Accurate coupling metrics
```