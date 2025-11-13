import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import * as fs from 'fs/promises';
import { loadConfig } from '../tools/config-loader';
import { collectFiles } from '../tools/file-collector';
import { parseImports } from '../tools/import-parser';
import { fsdLayerRule, fsdNamingRule } from '../tools/rules/fsd-rules';
import { runRules } from '../tools/rule-engine';
import { saveResult } from '../tools/result-saver';
import { buildDependencyGraph } from '../tools/dependency-graph';
import { detectCycles } from '../tools/cycle-detector';
import type { FileInfo, ArchitectureValidationResult } from '../types/validation-types';

describe('Full Validation Flow', () => {
  const testCacheDir = '.claude/cache/validation-reports-test';

  beforeAll(async () => {
    // Ensure test cache directory exists
    await fs.mkdir(testCacheDir, { recursive: true });
  });

  afterAll(async () => {
    // Clean up test cache
    try {
      await fs.rm(testCacheDir, { recursive: true, force: true });
    } catch (error) {
      // Ignore errors during cleanup
    }
  });

  it('should complete full validation flow', async () => {
    // 1. Load configuration
    const config = await loadConfig();
    expect(config).toBeDefined();
    expect(config.architectureType).toBeDefined();

    // 2. Collect files
    const filePaths = await collectFiles(
      ['**/*.ts', '**/*.tsx'],
      config.ignorePatterns
    );
    expect(filePaths).toBeInstanceOf(Array);

    // 3. Parse imports
    const files: FileInfo[] = await Promise.all(
      filePaths.slice(0, 10).map(async (path) => {
        // Only test first 10 files for performance
        try {
          const content = await fs.readFile(path, 'utf-8');
          return {
            path,
            content,
            imports: parseImports(content),
          };
        } catch {
          return {
            path,
            content: '',
            imports: [],
          };
        }
      })
    );

    expect(files.length).toBeGreaterThan(0);

    // 4. Run rules
    const rules = [fsdLayerRule, fsdNamingRule];
    const issues = await runRules(files, rules);
    expect(issues).toBeInstanceOf(Array);

    // 5. Build dependency graph and detect cycles
    const graph = buildDependencyGraph(files);
    expect(graph).toBeInstanceOf(Map);

    const cycles = detectCycles(graph);
    expect(cycles).toBeInstanceOf(Array);

    // 6. Create result
    const result: ArchitectureValidationResult = {
      valid: issues.filter(i => i.severity === 'error').length === 0,
      errors: issues.filter(i => i.severity === 'error'),
      warnings: issues.filter(i => i.severity === 'warning'),
      suggestions: [],
      checkedFiles: filePaths,
      timestamp: new Date(),
      duration: '0.5s',
      architectureType: config.architectureType,
    };

    expect(result).toBeDefined();
    expect(result.checkedFiles).toHaveLength(filePaths.length);
  });

  it('should save result to cache', async () => {
    const result: ArchitectureValidationResult = {
      valid: true,
      errors: [],
      warnings: [],
      suggestions: [],
      checkedFiles: ['test.ts'],
      timestamp: new Date(),
      duration: '0.1s',
      architectureType: 'fsd',
    };

    await saveResult(result);

    // Verify file was created
    const latestReport = await fs.readFile(
      '.claude/cache/validation-reports/latest.json',
      'utf-8'
    );
    const parsed = JSON.parse(latestReport);

    expect(parsed.valid).toBe(true);
    expect(parsed.architectureType).toBe('fsd');
  });

  it('should handle validation errors gracefully', async () => {
    const files: FileInfo[] = [
      {
        path: 'src/features/test/index.ts',
        content: 'import { Page } from "@/pages/home"',
        imports: [
          {
            source: '@/pages/home',
            line: 1,
            raw: 'import { Page } from "@/pages/home"',
          },
        ],
      },
    ];

    const issues = await runRules(files, [fsdLayerRule]);

    expect(issues.length).toBeGreaterThan(0);
    expect(issues[0].severity).toBe('error');
    expect(issues[0].rule).toBe('fsd-layer-no-upward-import');
  });

  it('should detect circular dependencies', async () => {
    const graph = new Map([
      ['A.ts', ['B.ts']],
      ['B.ts', ['C.ts']],
      ['C.ts', ['A.ts']],
    ]);

    const cycles = detectCycles(graph);

    expect(cycles.length).toBeGreaterThan(0);
    expect(cycles[0]).toContain('A.ts');
    expect(cycles[0]).toContain('B.ts');
    expect(cycles[0]).toContain('C.ts');
  });
});
