#!/usr/bin/env node
/**
 * Architecture Compliance Validator CLI
 *
 * Main entry point for validating architecture compliance.
 */

import * as fs from 'fs/promises';
import { loadConfig } from './config-loader';
import { collectFiles } from './file-collector';
import { parseImports } from './import-parser';
import { fsdLayerRule, fsdNamingRule } from './rules/fsd-rules';
import { cleanDependencyRule, cleanUseCaseRule } from './rules/clean-rules';
import { hexagonalPortsRule, hexagonalPortInterfaceRule } from './rules/hexagonal-rules';
import { runRules, filterRules } from './rule-engine';
import { saveResult } from './result-saver';
import { buildDependencyGraph } from './dependency-graph';
import { detectCycles, formatCycleReport } from './cycle-detector';
import type { FileInfo, ArchitectureValidationResult, ArchitectureRule } from '../types/validation-types';

async function main() {
  console.log('🏗️  Architecture Compliance Check...');

  try {
    // 1. Load configuration
    const config = await loadConfig();
    console.log(`📋 Configuration loaded: ${config.architectureType} architecture`);

    // 2. Collect files
    const filePaths = await collectFiles(['**/*.ts', '**/*.tsx'], config.ignorePatterns);

    if (filePaths.length === 0) {
      console.log('⚠️  No TypeScript files found to validate');
      process.exit(0);
    }

    console.log(`✅ Validating ${filePaths.length} files...`);

    const startTime = Date.now();

    // 3. Parse files and collect imports
    const files: FileInfo[] = await Promise.all(
      filePaths.map(async (path) => {
        try {
          const content = await fs.readFile(path, 'utf-8');
          return {
            path,
            content,
            imports: parseImports(content),
          };
        } catch (error) {
          console.warn(`⚠️  Could not read file ${path}: ${(error as Error).message}`);
          return {
            path,
            content: '',
            imports: [],
          };
        }
      })
    );

    // 4. Select rules based on architecture type
    let rules: ArchitectureRule[] = [];

    switch (config.architectureType) {
      case 'fsd':
        rules = [fsdLayerRule, fsdNamingRule];
        break;
      case 'clean':
        rules = [cleanDependencyRule, cleanUseCaseRule];
        break;
      case 'hexagonal':
        rules = [hexagonalPortsRule, hexagonalPortInterfaceRule];
        break;
      case 'auto':
        // Use all rules for auto-detection
        rules = [
          fsdLayerRule,
          fsdNamingRule,
          cleanDependencyRule,
          cleanUseCaseRule,
          hexagonalPortsRule,
          hexagonalPortInterfaceRule,
        ];
        break;
    }

    // 5. Filter rules based on configuration
    const filteredRules = filterRules(rules, config.enabledRules, config.disabledRules);

    // 6. Run validation rules
    const issues = await runRules(files, filteredRules);

    // 7. Check for circular dependencies
    console.log('🔄 Checking for circular dependencies...');
    const dependencyGraph = buildDependencyGraph(files);
    const cycles = detectCycles(dependencyGraph);

    if (cycles.length > 0) {
      console.log(formatCycleReport(cycles));

      // Add cycle issues to validation issues
      cycles.forEach(cycle => {
        issues.push({
          file: cycle[0],
          rule: 'circular-dependency',
          severity: 'error',
          message: `Circular dependency detected: ${cycle.join(' → ')}`,
          suggestion: 'Refactor to remove circular dependency by extracting shared code or using dependency injection',
        });
      });
    } else {
      console.log('✅ No circular dependencies found');
    }

    // 8. Aggregate results
    const errors = issues.filter(i => i.severity === 'error');
    const warnings = issues.filter(i => i.severity === 'warning');
    const duration = `${((Date.now() - startTime) / 1000).toFixed(1)}s`;

    const result: ArchitectureValidationResult = {
      valid: errors.length === 0,
      errors,
      warnings,
      suggestions: [],
      checkedFiles: filePaths,
      timestamp: new Date(),
      duration,
      architectureType: config.architectureType,
    };

    // 9. Save result to cache
    await saveResult(result);

    // 10. Print result
    printResult(result);

    // 11. Exit with appropriate code
    process.exit(result.valid ? 0 : 1);
  } catch (error) {
    console.error('❌ Validation failed with error:', error);
    process.exit(1);
  }
}

/**
 * Print validation result to console
 *
 * @param result - Validation result to print
 */
function printResult(result: ArchitectureValidationResult): void {
  console.log('\n' + '='.repeat(80));

  if (result.valid) {
    console.log(`✅ All checks passed! (${result.duration})`);
    console.log(`📊 ${result.checkedFiles.length} files checked`);

    if (result.warnings.length > 0) {
      console.log(`\n⚠️  Warnings (${result.warnings.length}):`);
      result.warnings.forEach((warning, i) => {
        console.log(`\n${i + 1}. ${warning.file}${warning.line ? `:${warning.line}` : ''}`);
        console.log(`   [${warning.rule}] ${warning.message}`);
        if (warning.suggestion) {
          console.log(`   💡 ${warning.suggestion}`);
        }
      });
    }
  } else {
    console.log(`❌ Validation failed! (${result.duration})`);
    console.log(`📊 ${result.checkedFiles.length} files checked`);

    console.log(`\n🔴 Errors (${result.errors.length}):`);
    result.errors.forEach((err, i) => {
      console.log(`\n${i + 1}. ${err.file}${err.line ? `:${err.line}` : ''}`);
      console.log(`   [${err.rule}] ${err.message}`);
      if (err.suggestion) {
        console.log(`   💡 ${err.suggestion}`);
      }
    });

    if (result.warnings.length > 0) {
      console.log(`\n⚠️  Warnings (${result.warnings.length}):`);
      result.warnings.forEach((warning, i) => {
        console.log(`\n${i + 1}. ${warning.file}${warning.line ? `:${warning.line}` : ''}`);
        console.log(`   [${warning.rule}] ${warning.message}`);
        if (warning.suggestion) {
          console.log(`   💡 ${warning.suggestion}`);
        }
      });
    }
  }

  console.log('='.repeat(80));
  console.log(`📁 Report saved to: .claude/cache/validation-reports/latest.json`);
}

// Run main function
main().catch((error) => {
  console.error('❌ Unexpected error:', error);
  process.exit(1);
});
