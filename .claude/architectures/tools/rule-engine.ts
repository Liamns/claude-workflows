/**
 * Rule Engine
 *
 * Executes architecture validation rules against files.
 */

import type { ArchitectureRule, FileInfo, ValidationIssue } from '../types/validation-types';

/**
 * Run all enabled rules against files
 *
 * @param files - Array of file information to validate
 * @param rules - Array of architecture rules to execute
 * @returns Array of all validation issues found
 */
export async function runRules(
  files: FileInfo[],
  rules: ArchitectureRule[]
): Promise<ValidationIssue[]> {
  const allIssues: ValidationIssue[] = [];

  for (const rule of rules) {
    if (rule.enabled) {
      try {
        const issues = rule.check(files);
        allIssues.push(...issues);
      } catch (error) {
        // Log error but continue with other rules
        console.error(`Error running rule ${rule.id}:`, error);
      }
    }
  }

  return allIssues;
}

/**
 * Filter rules based on configuration
 *
 * @param rules - All available rules
 * @param enabledRules - Array of rule IDs to enable (empty = all)
 * @param disabledRules - Array of rule IDs to disable
 * @returns Filtered array of rules
 */
export function filterRules(
  rules: ArchitectureRule[],
  enabledRules: string[],
  disabledRules: string[]
): ArchitectureRule[] {
  return rules.map(rule => {
    // If enabledRules is specified, only enable those rules
    if (enabledRules.length > 0) {
      return {
        ...rule,
        enabled: enabledRules.includes(rule.id),
      };
    }

    // Otherwise, enable all rules except disabled ones
    return {
      ...rule,
      enabled: !disabledRules.includes(rule.id),
    };
  });
}
