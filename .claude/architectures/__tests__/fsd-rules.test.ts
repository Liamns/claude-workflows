import { describe, it, expect } from 'vitest';
import { fsdLayerRule, fsdNamingRule } from '../tools/rules/fsd-rules';
import type { FileInfo } from '../types/validation-types';

describe('FSD Layer Rule', () => {
  it('should detect upward import violation', () => {
    const files: FileInfo[] = [{
      path: 'src/features/auth/index.ts',
      content: 'import { Page } from "@/pages/auth"',
      imports: [{ source: '@/pages/auth', line: 1, raw: 'import { Page } from "@/pages/auth"' }]
    }];

    const issues = fsdLayerRule.check(files);

    expect(issues.length).toBe(1);
    expect(issues[0].rule).toBe('fsd-layer-no-upward-import');
    expect(issues[0].severity).toBe('error');
  });

  it('should allow downward import', () => {
    const files: FileInfo[] = [{
      path: 'src/pages/auth/index.ts',
      content: 'import { useAuth } from "@/features/auth"',
      imports: [{ source: '@/features/auth', line: 1, raw: 'import { useAuth } from "@/features/auth"' }]
    }];

    const issues = fsdLayerRule.check(files);

    expect(issues.length).toBe(0);
  });

  it('should allow same-layer imports', () => {
    const files: FileInfo[] = [{
      path: 'src/features/auth/index.ts',
      content: 'import { helper } from "@/features/profile"',
      imports: [{ source: '@/features/profile', line: 1, raw: 'import { helper } from "@/features/profile"' }]
    }];

    const issues = fsdLayerRule.check(files);

    expect(issues.length).toBe(0);
  });

  it('should detect multiple violations', () => {
    const files: FileInfo[] = [{
      path: 'src/entities/user/index.ts',
      content: `
import { Page } from "@/pages/auth"
import { useAuth } from "@/features/auth"
      `,
      imports: [
        { source: '@/pages/auth', line: 2, raw: 'import { Page } from "@/pages/auth"' },
        { source: '@/features/auth', line: 3, raw: 'import { useAuth } from "@/features/auth"' }
      ]
    }];

    const issues = fsdLayerRule.check(files);

    expect(issues.length).toBe(2);
    expect(issues[0].rule).toBe('fsd-layer-no-upward-import');
    expect(issues[1].rule).toBe('fsd-layer-no-upward-import');
  });
});

describe('FSD Naming Rule', () => {
  it('should detect invalid hook naming', () => {
    const files: FileInfo[] = [{
      path: 'src/features/auth/hooks/auth.ts',
      content: 'export function getAuth() {}',
      imports: []
    }];

    const issues = fsdNamingRule.check(files);

    expect(issues.length).toBe(1);
    expect(issues[0].rule).toBe('fsd-naming-convention');
    expect(issues[0].message).toContain('use');
  });

  it('should allow valid hook naming', () => {
    const files: FileInfo[] = [{
      path: 'src/features/auth/hooks/useAuth.ts',
      content: 'export function useAuth() {}',
      imports: []
    }];

    const issues = fsdNamingRule.check(files);

    expect(issues.length).toBe(0);
  });

  it('should detect invalid store naming', () => {
    const files: FileInfo[] = [{
      path: 'src/entities/user/store/user.ts',
      content: 'export const store = {}',
      imports: []
    }];

    const issues = fsdNamingRule.check(files);

    expect(issues.length).toBe(1);
    expect(issues[0].message).toContain('Store');
  });

  it('should allow valid store naming', () => {
    const files: FileInfo[] = [{
      path: 'src/entities/user/store/userStore.ts',
      content: 'export const userStore = {}',
      imports: []
    }];

    const issues = fsdNamingRule.check(files);

    expect(issues.length).toBe(0);
  });
});
