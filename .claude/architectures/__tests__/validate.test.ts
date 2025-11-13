import { describe, it, expect, beforeEach } from 'vitest';
import { loadConfig } from '../tools/config-loader';
import { collectFiles } from '../tools/file-collector';
import { parseImports } from '../tools/import-parser';
import type { ValidationConfig } from '../types/validation-types';

describe('Configuration Loading', () => {
  it('should load config from file', async () => {
    // This test will pass when config-loader is implemented
    const config = await loadConfig('.claude/architectures/config.json');
    expect(config).toBeDefined();
    expect(config.architectureType).toBeDefined();
  });

  it('should use default config if file not found', async () => {
    const config = await loadConfig('non-existent.json');
    expect(config.architectureType).toBe('auto');
    expect(config.strictnessLevel).toBe('moderate');
  });

  it('should parse config with custom settings', async () => {
    // Test will verify custom config parsing
    const config = await loadConfig('.claude/architectures/config.json');
    expect(config.ignorePatterns).toBeInstanceOf(Array);
  });
});

describe('File Collection', () => {
  it('should collect TypeScript files', async () => {
    const files = await collectFiles(
      ['**/*.ts', '**/*.tsx'],
      ['**/node_modules/**', '**/__tests__/**']
    );
    expect(files).toBeInstanceOf(Array);
    expect(files.length).toBeGreaterThan(0);
  });

  it('should ignore patterns', async () => {
    const files = await collectFiles(
      ['**/*.ts'],
      ['**/__tests__/**', '**/node_modules/**']
    );
    expect(files.every(f => !f.includes('__tests__'))).toBe(true);
    expect(files.every(f => !f.includes('node_modules'))).toBe(true);
  });

  it('should filter by file extension', async () => {
    const files = await collectFiles(['**/*.ts'], ['**/node_modules/**']);
    expect(files.every(f => f.endsWith('.ts') || f.endsWith('.tsx'))).toBe(true);
  });
});

describe('Import Parsing', () => {
  it('should parse basic import statement', () => {
    const content = `import { useState } from 'react';`;
    const imports = parseImports(content);

    expect(imports).toHaveLength(1);
    expect(imports[0].source).toBe('react');
    expect(imports[0].line).toBe(1);
  });

  it('should parse multiple imports', () => {
    const content = `
import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Button } from '@/shared/ui';
    `.trim();

    const imports = parseImports(content);

    expect(imports).toHaveLength(3);
    expect(imports[0].source).toBe('react');
    expect(imports[1].source).toBe('@tanstack/react-query');
    expect(imports[2].source).toBe('@/shared/ui');
  });

  it('should handle import with line breaks', () => {
    const content = `
import {
  useState,
  useEffect
} from 'react';
    `.trim();

    const imports = parseImports(content);
    expect(imports).toHaveLength(1);
    expect(imports[0].source).toBe('react');
  });

  it('should skip non-import lines', () => {
    const content = `
const x = 1;
import { useState } from 'react';
// import { fake } from 'fake';
const y = 2;
    `.trim();

    const imports = parseImports(content);
    expect(imports).toHaveLength(1);
    expect(imports[0].source).toBe('react');
  });
});
