/**
 * Architecture Validation Type Definitions
 *
 * 이 파일은 아키텍처 검증 시스템의 핵심 타입을 정의합니다.
 */

import { z } from 'zod';

export type ValidationStatus = 'pass' | 'warning' | 'error';

export interface ValidationIssue {
  file: string;
  line?: number;
  rule: string;
  severity: 'error' | 'warning';
  message: string;
  suggestion?: string;
}

export interface ArchitectureValidationResult {
  valid: boolean;
  errors: ValidationIssue[];
  warnings: ValidationIssue[];
  suggestions: string[];
  checkedFiles: string[];
  timestamp: Date;
  duration: string;
  architectureType: string;
}

export interface ValidationConfig {
  architectureType: 'fsd' | 'clean' | 'hexagonal' | 'auto';
  strictnessLevel: 'strict' | 'moderate' | 'lenient';
  enabledRules: string[];
  disabledRules: string[];
  ignorePatterns: string[];
  maxFiles?: number;
}

export interface ArchitectureRule {
  id: string;
  name: string;
  description: string;
  severity: 'error' | 'warning';
  enabled: boolean;
  check: (files: FileInfo[]) => ValidationIssue[];
}

export interface FileInfo {
  path: string;
  content: string;
  imports: ImportStatement[];
}

export interface ImportStatement {
  source: string;
  line: number;
  raw: string;
}

// ============================================================================
// Zod Schemas
// ============================================================================

export const ValidationIssueSchema = z.object({
  file: z.string().min(1),
  line: z.number().optional(),
  rule: z.string().min(1),
  severity: z.enum(['error', 'warning']),
  message: z.string().min(1),
  suggestion: z.string().optional(),
});

export const ArchitectureValidationResultSchema = z.object({
  valid: z.boolean(),
  errors: z.array(ValidationIssueSchema),
  warnings: z.array(ValidationIssueSchema),
  suggestions: z.array(z.string()),
  checkedFiles: z.array(z.string()),
  timestamp: z.date(),
  duration: z.string(),
  architectureType: z.string(),
});

export const ValidationConfigSchema = z.object({
  architectureType: z.enum(['fsd', 'clean', 'hexagonal', 'auto']).default('auto'),
  strictnessLevel: z.enum(['strict', 'moderate', 'lenient']).default('moderate'),
  enabledRules: z.array(z.string()).default([]),
  disabledRules: z.array(z.string()).default([]),
  ignorePatterns: z.array(z.string()).default(['**/node_modules/**']),
  maxFiles: z.number().optional(),
});

// Default configuration
export const DEFAULT_CONFIG: ValidationConfig = {
  architectureType: 'auto',
  strictnessLevel: 'moderate',
  enabledRules: [],
  disabledRules: [],
  ignorePatterns: [
    '**/node_modules/**',
    '**/*.test.ts',
    '**/*.test.tsx',
    '**/*.spec.ts',
    '**/*.spec.tsx',
    '**/__tests__/**',
    '**/.claude/**',
  ],
};
