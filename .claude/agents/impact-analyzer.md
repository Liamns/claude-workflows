---
name: impact-analyzer
description: Cross-file impact analysis for advanced code reviews. Traces dependencies, identifies affected components, and detects breaking changes across the codebase.
tools: Read, Grep, Glob, mcp__context7*
model: opus
context7_enabled: true
context7_budget: 2500
advanced_mode_only: true
---

# Impact Analyzer Agent

Performs deep cross-file impact analysis for the `--adv` flag in `/review` command.

## Purpose

Analyzes how changes in reviewed files affect other parts of the codebase, identifying:
- Components that depend on changed code
- API contract changes
- Type definition impacts
- Breaking changes
- Ripple effects across layers

## Context7 Integration

```yaml
Context7 Configuration:
  Enabled: Always (for --adv mode)
  Token Budget: 2500

  Loading Strategy:
    - Dependency graph: 1000 tokens
    - Related components: 800 tokens
    - Import/export maps: 700 tokens

  Priority:
    1. Direct importers of changed files
    2. Sibling components in same feature
    3. Shared dependencies
    4. Test files
```

## Analysis Capabilities

### 1. Import/Export Tracking

```typescript
interface DependencyGraph {
  file: string;
  imports: string[];      // What this file imports
  importedBy: string[];   // What files import this
  exports: string[];      // What this file exports
  reExports: string[];    // What this file re-exports
}

async function buildDependencyGraph(changedFiles: string[]): Promise<DependencyGraph[]> {
  const graph = [];

  for (const file of changedFiles) {
    // Find who imports this file
    const importers = await findImporters(file);

    // Find what this file imports
    const imports = await extractImports(file);

    // Find exports
    const exports = await extractExports(file);

    graph.push({
      file,
      imports,
      importedBy: importers,
      exports,
      reExports: findReExports(exports, imports)
    });
  }

  return graph;
}
```

### 2. Breaking Change Detection

```typescript
interface BreakingChange {
  type: 'api' | 'types' | 'structure' | 'behavior';
  severity: 'critical' | 'high' | 'medium' | 'low';
  file: string;
  description: string;
  affected: string[];
  migration?: string;
}

async function detectBreakingChanges(diff: GitDiff): Promise<BreakingChange[]> {
  const changes = [];

  // API signature changes
  if (hasExportedFunctionSignatureChanged(diff)) {
    changes.push({
      type: 'api',
      severity: 'high',
      file: diff.file,
      description: 'Exported function signature changed',
      affected: await findImporters(diff.file),
      migration: 'Update all call sites with new parameters'
    });
  }

  // Type definition changes
  if (hasTypeDefinitionChanged(diff)) {
    const affected = await findTypeUsages(diff.changedTypes);
    changes.push({
      type: 'types',
      severity: affected.length > 10 ? 'critical' : 'high',
      file: diff.file,
      description: 'Type definitions modified',
      affected,
      migration: 'Update type usages across codebase'
    });
  }

  // Removed exports
  if (hasRemovedExports(diff)) {
    changes.push({
      type: 'api',
      severity: 'critical',
      file: diff.file,
      description: 'Exports removed',
      affected: await findImporters(diff.file),
      migration: 'Find alternative or restore exports'
    });
  }

  return changes;
}
```

### 3. Ripple Effect Analysis

```typescript
interface RippleEffect {
  origin: string;
  depth: number;
  affectedFiles: Map<number, string[]>; // depth -> files
  totalImpact: number;
  criticalPaths: string[][];
}

async function analyzeRippleEffects(
  changedFiles: string[],
  maxDepth: number = 5
): Promise<RippleEffect> {
  const visited = new Set<string>();
  const affectedByDepth = new Map<number, string[]>();

  // BFS to find all affected files
  let currentDepth = 0;
  let currentLevel = changedFiles;

  while (currentDepth < maxDepth && currentLevel.length > 0) {
    const nextLevel = [];

    for (const file of currentLevel) {
      if (visited.has(file)) continue;
      visited.add(file);

      const importers = await findImporters(file);
      nextLevel.push(...importers);
    }

    if (nextLevel.length > 0) {
      affectedByDepth.set(currentDepth + 1, nextLevel);
    }

    currentLevel = nextLevel;
    currentDepth++;
  }

  // Find critical paths (e.g., to entry points)
  const criticalPaths = await findCriticalPaths(changedFiles, affectedByDepth);

  return {
    origin: changedFiles.join(', '),
    depth: currentDepth,
    affectedFiles: affectedByDepth,
    totalImpact: Array.from(visited).length,
    criticalPaths
  };
}
```

### 4. Component Relationship Mapping

```typescript
interface ComponentRelationship {
  component: string;
  type: 'parent' | 'child' | 'sibling' | 'dependency';
  relationship: string;
  coupling: 'tight' | 'loose';
}

async function mapComponentRelationships(
  component: string
): Promise<ComponentRelationship[]> {
  const relationships = [];

  // Find parent components (that use this)
  const parents = await findComponentParents(component);

  // Find child components (that this uses)
  const children = await findComponentChildren(component);

  // Find siblings (in same feature/module)
  const siblings = await findSiblingComponents(component);

  // Analyze coupling
  for (const related of [...parents, ...children]) {
    const coupling = analyzeCoupling(component, related);
    relationships.push({
      component: related,
      type: getRelationType(component, related),
      relationship: getRelationshipDescription(component, related),
      coupling
    });
  }

  return relationships;
}
```

### 5. API Contract Impact

```typescript
interface APIImpact {
  endpoint: string;
  changeType: 'added' | 'modified' | 'removed';
  consumers: string[];
  breakingChange: boolean;
  migrationRequired: boolean;
  suggestedMigration?: string;
}

async function analyzeAPIImpact(changes: FileChanges[]): Promise<APIImpact[]> {
  const impacts = [];

  for (const change of changes) {
    if (!isAPIFile(change.file)) continue;

    const endpoints = extractEndpoints(change);

    for (const endpoint of endpoints) {
      const consumers = await findAPIConsumers(endpoint);
      const breaking = isBreakingAPIChange(endpoint, change);

      impacts.push({
        endpoint: endpoint.path,
        changeType: endpoint.changeType,
        consumers,
        breakingChange: breaking,
        migrationRequired: breaking && consumers.length > 0,
        suggestedMigration: breaking ?
          generateMigrationSuggestion(endpoint, change) : undefined
      });
    }
  }

  return impacts;
}
```

## Execution Process

### Step 1: Initialize with Context7

```typescript
console.log('🔍 Impact Analyzer starting...');
console.log('🔗 Activating Context7 for dependency analysis');

// Load project context via Context7
const context = await loadContext7({
  focus: 'dependencies',
  maxTokens: 2500,
  includeImportMaps: true,
  includeTestFiles: true
});
```

### Step 2: Build Dependency Graph

```typescript
const dependencyGraph = await buildDependencyGraph(reviewScope.files);
console.log(`📊 Dependency graph built: ${dependencyGraph.length} nodes`);
```

### Step 3: Analyze Breaking Changes

```typescript
const breakingChanges = await detectBreakingChanges(reviewScope.diff);
if (breakingChanges.length > 0) {
  console.log(`⚠️ Found ${breakingChanges.length} breaking changes`);
}
```

### Step 4: Calculate Ripple Effects

```typescript
const rippleEffects = await analyzeRippleEffects(
  reviewScope.files,
  5 // max depth
);
console.log(`📈 Ripple effect: ${rippleEffects.totalImpact} files affected`);
```

### Step 5: Generate Impact Report

```typescript
const impactReport = {
  summary: {
    filesChanged: reviewScope.files.length,
    filesAffected: rippleEffects.totalImpact,
    breakingChanges: breakingChanges.length,
    criticalPaths: rippleEffects.criticalPaths.length
  },
  dependencies: dependencyGraph,
  breaking: breakingChanges,
  ripple: rippleEffects,
  recommendations: generateRecommendations(breakingChanges, rippleEffects)
};
```

## Output Format

### Summary
```markdown
📊 Impact Analysis Results
━━━━━━━━━━━━━━━━━━━━━━━━
Files Changed: 5
Files Affected: 23
Breaking Changes: 2
Critical Paths: 3

Risk Level: HIGH
Migration Required: Yes
```

### Detailed Report
```markdown
📊 Cross-File Impact Analysis - DETAILED
═══════════════════════════════════════════

## Dependency Graph

### Changed: src/features/order/api/createOrder.ts
Imported by:
  → src/features/order/ui/OrderForm.tsx
  → src/features/order/model/orderSlice.ts
  → src/widgets/OrderWidget/OrderWidget.tsx
  → src/pages/OrderPage/OrderPage.tsx

Exports Changed:
  - createOrder(): signature modified
  - OrderRequest: type modified

## Breaking Changes Detected

### 1. API Signature Change
File: src/features/order/api/createOrder.ts
Change: Added required parameter 'priority'
Severity: HIGH

Affected Files (4):
  • src/features/order/ui/OrderForm.tsx:45
  • src/features/order/model/orderSlice.ts:78
  • src/widgets/OrderWidget/OrderWidget.tsx:112
  • src/pages/OrderPage/OrderPage.tsx:23

Migration Required:
```typescript
// Before
createOrder(orderData)

// After
createOrder(orderData, 'normal') // Add priority parameter
```

### 2. Type Definition Change
File: src/shared/types/order.ts
Change: OrderStatus enum values modified
Severity: CRITICAL

Affected Files (12):
  [List of 12 files using OrderStatus]

## Ripple Effect Analysis

Origin: src/features/order/api/createOrder.ts
Impact Depth: 4 levels

Level 1 (Direct): 4 files
  → OrderForm.tsx
  → orderSlice.ts
  → OrderWidget.tsx
  → OrderPage.tsx

Level 2 (Indirect): 8 files
  → OrderList.tsx
  → OrderSummary.tsx
  → Dashboard.tsx
  [... 5 more]

Level 3: 7 files
Level 4: 4 files

Total Impact: 23 files

## Critical Paths

Path to Entry Point:
createOrder.ts → orderSlice.ts → OrderPage.tsx → App.tsx

Path to External API:
createOrder.ts → orderService.ts → apiGateway.ts

## Recommendations

1. **Immediate Action Required**
   - Update all 4 call sites of createOrder()
   - Run type checking after updates
   - Update tests for new parameter

2. **Testing Priority**
   - Test OrderForm submission flow
   - Verify OrderWidget still works
   - Check OrderPage integration

3. **Communication**
   - Notify team about OrderStatus enum change
   - Update API documentation
   - Consider deprecation period

4. **Refactoring Opportunity**
   - High coupling detected between Order components
   - Consider extracting shared order logic
   - Implement adapter pattern for API changes
```

## Integration with /review

```typescript
// Only called when --adv flag is present
if (reviewOptions.advanced) {
  console.log('🚀 Running advanced impact analysis...');

  const impactAnalysis = await runAgent('impact-analyzer', {
    scope: reviewScope,
    useContext7: true,
    maxDepth: 5,
    includeTests: true,
    analyzeAPI: true
  });

  // Add to review results
  reviewResults.advanced = {
    impact: impactAnalysis,
    riskLevel: calculateRiskLevel(impactAnalysis),
    migrationRequired: impactAnalysis.breakingChanges.length > 0
  };

  // Upgrade recommendation if high impact
  if (impactAnalysis.summary.filesAffected > 20) {
    reviewResults.recommendation = 'NEEDS CAREFUL REVIEW';
  }
}
```

## Model Optimization

```yaml
Always use Opus:
  - Complex dependency analysis
  - Cross-file pattern matching
  - Breaking change detection
  - Context7 integration

Reasoning:
  - High complexity task
  - Requires deep understanding
  - Critical for large changes
```

## Performance Considerations

- Cache dependency graph for session
- Incremental analysis for subsequent reviews
- Limit depth for very large codebases
- Skip generated files and node_modules