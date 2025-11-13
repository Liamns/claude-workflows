import { describe, it, expect } from 'vitest';
import { collectFiles } from '../tools/file-collector';
import { parseImports } from '../tools/import-parser';
import { fsdLayerRule, fsdNamingRule } from '../tools/rules/fsd-rules';
import { runRules } from '../tools/rule-engine';
import { buildDependencyGraph } from '../tools/dependency-graph';
import { detectCycles } from '../tools/cycle-detector';
import type { FileInfo } from '../types/validation-types';

describe('Performance Tests', () => {
  it('should collect files quickly', async () => {
    const startTime = Date.now();

    const files = await collectFiles(
      ['**/*.ts', '**/*.tsx'],
      ['**/node_modules/**', '**/__tests__/**']
    );

    const duration = Date.now() - startTime;

    expect(files).toBeInstanceOf(Array);
    expect(duration).toBeLessThan(5000); // Should complete within 5s
  });

  it('should parse imports efficiently', () => {
    const content = `
import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Button } from '@/shared/ui';
import { useAuth } from '@/features/auth';
import { User } from '@/entities/user';
    `.trim();

    const startTime = Date.now();

    for (let i = 0; i < 1000; i++) {
      parseImports(content);
    }

    const duration = Date.now() - startTime;

    expect(duration).toBeLessThan(1000); // 1000 parses within 1s
  });

  it('should run rules on large file set efficiently', async () => {
    // Create mock files
    const files: FileInfo[] = Array.from({ length: 100 }, (_, i) => ({
      path: `src/features/test${i}/index.ts`,
      content: 'export const test = 1;',
      imports: [
        {
          source: '@/shared/utils',
          line: 1,
          raw: 'import { utils } from "@/shared/utils"',
        },
      ],
    }));

    const startTime = Date.now();

    const issues = await runRules(files, [fsdLayerRule, fsdNamingRule]);

    const duration = Date.now() - startTime;

    expect(issues).toBeInstanceOf(Array);
    expect(duration).toBeLessThan(2000); // 100 files within 2s
  });

  it('should build dependency graph efficiently', () => {
    // Create mock files with many dependencies
    const files: FileInfo[] = Array.from({ length: 500 }, (_, i) => ({
      path: `src/file${i}.ts`,
      content: '',
      imports: Array.from({ length: 5 }, (_, j) => ({
        source: `@/file${(i + j + 1) % 500}`,
        line: j + 1,
        raw: `import { x } from "@/file${(i + j + 1) % 500}"`,
      })),
    }));

    const startTime = Date.now();

    const graph = buildDependencyGraph(files);

    const duration = Date.now() - startTime;

    expect(graph.size).toBe(500);
    expect(duration).toBeLessThan(1000); // Build graph within 1s
  });

  it('should detect cycles efficiently', () => {
    // Create a graph with multiple cycles
    const graph = new Map();

    // Create 100 nodes with various cycles
    for (let i = 0; i < 100; i++) {
      const dependencies: string[] = [];

      // Add some regular dependencies
      if (i > 0) dependencies.push(`node${i - 1}`);
      if (i < 99) dependencies.push(`node${i + 1}`);

      // Add some cycles
      if (i % 10 === 0 && i > 0) {
        dependencies.push(`node${i - 10}`); // Creates cycle
      }

      graph.set(`node${i}`, dependencies);
    }

    const startTime = Date.now();

    const cycles = detectCycles(graph);

    const duration = Date.now() - startTime;

    expect(cycles).toBeInstanceOf(Array);
    expect(duration).toBeLessThan(500); // Detect cycles within 0.5s
  });

  it('should handle real-world validation within acceptable time', async () => {
    const startTime = Date.now();

    // Simulate real validation flow
    const files = await collectFiles(
      ['**/*.ts', '**/*.tsx'],
      ['**/node_modules/**', '**/__tests__/**', '**/dist/**']
    );

    // Limit to reasonable number for test
    const limitedFiles = files.slice(0, Math.min(files.length, 200));

    const fileInfos: FileInfo[] = await Promise.all(
      limitedFiles.map(async (path) => {
        try {
          const fs = await import('fs/promises');
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

    const issues = await runRules(fileInfos, [fsdLayerRule, fsdNamingRule]);
    const graph = buildDependencyGraph(fileInfos);
    const cycles = detectCycles(graph);

    const duration = Date.now() - startTime;

    expect(issues).toBeInstanceOf(Array);
    expect(cycles).toBeInstanceOf(Array);

    // Real-world validation should complete within 10s for 200 files
    expect(duration).toBeLessThan(10000);
  }, 15000); // 15s timeout for this test
});
