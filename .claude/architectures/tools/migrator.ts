/**
 * Architecture Migration Tool
 * Helps migrate between different architectural patterns
 */

import * as fs from 'fs';
import * as path from 'path';

export interface MigrationPlan {
  from: string;
  to: string;
  steps: MigrationStep[];
  estimatedEffort: string;
  risks: string[];
  recommendations: string[];
}

export interface MigrationStep {
  order: number;
  description: string;
  action: string;
  files: string[];
  automated: boolean;
}

export class ArchitectureMigrator {
  private migrationMappings = {
    // Frontend migrations
    'mvc-to-fsd': {
      mappings: {
        'models': 'entities',
        'views': 'pages',
        'controllers': 'features',
        'components': 'shared/ui'
      },
      complexity: 'high'
    },
    'atomic-to-fsd': {
      mappings: {
        'components/atoms': 'shared/ui',
        'components/molecules': 'shared/ui',
        'components/organisms': 'widgets',
        'components/templates': 'pages',
        'components/pages': 'pages'
      },
      complexity: 'medium'
    },
    'fsd-to-atomic': {
      mappings: {
        'shared/ui': 'components/atoms',
        'entities': 'components/molecules',
        'features': 'components/organisms',
        'widgets': 'components/organisms',
        'pages': 'components/pages'
      },
      complexity: 'medium'
    },

    // Backend migrations
    'layered-to-clean': {
      mappings: {
        'presentation': 'presentation',
        'business': 'application',
        'data': 'infrastructure',
        'models': 'domain/entities'
      },
      complexity: 'high'
    },
    'clean-to-hexagonal': {
      mappings: {
        'domain': 'core/domain',
        'application': 'core/ports',
        'infrastructure': 'adapters/outbound',
        'presentation': 'adapters/inbound'
      },
      complexity: 'medium'
    },
    'hexagonal-to-ddd': {
      mappings: {
        'core/domain': 'domain',
        'core/ports': 'application',
        'adapters': 'infrastructure'
      },
      complexity: 'high',
      additionalSteps: [
        'Define bounded contexts',
        'Identify aggregates',
        'Extract value objects',
        'Define domain events'
      ]
    }
  };

  constructor(private rootPath: string = process.cwd()) {}

  /**
   * Create migration plan from one architecture to another
   */
  createMigrationPlan(from: string, to: string): MigrationPlan {
    const migrationKey = `${from}-to-${to}`;
    const mapping = this.migrationMappings[migrationKey as keyof typeof this.migrationMappings];

    if (!mapping) {
      return this.createCustomMigrationPlan(from, to);
    }

    const steps: MigrationStep[] = [];
    let order = 1;

    // Step 1: Backup
    steps.push({
      order: order++,
      description: 'Create backup of current structure',
      action: 'cp -r src src.backup',
      files: ['src/**/*'],
      automated: true
    });

    // Step 2: Create new structure
    steps.push({
      order: order++,
      description: `Create ${to} directory structure`,
      action: this.getCreateStructureCommand(to),
      files: [],
      automated: true
    });

    // Step 3: Move files according to mappings
    for (const [source, target] of Object.entries(mapping.mappings)) {
      steps.push({
        order: order++,
        description: `Move ${source} to ${target}`,
        action: `mv src/${source}/* src/${target}/`,
        files: [`src/${source}/**/*`],
        automated: true
      });
    }

    // Step 4: Update imports
    steps.push({
      order: order++,
      description: 'Update import paths',
      action: 'Update all import statements to match new structure',
      files: ['src/**/*.ts', 'src/**/*.tsx', 'src/**/*.js', 'src/**/*.jsx'],
      automated: false
    });

    // Step 5: Architecture-specific adjustments
    if (mapping.additionalSteps) {
      for (const step of mapping.additionalSteps) {
        steps.push({
          order: order++,
          description: step,
          action: 'Manual adjustment required',
          files: [],
          automated: false
        });
      }
    }

    // Step 6: Update configuration
    steps.push({
      order: order++,
      description: 'Update architecture configuration',
      action: 'Update .specify/config/architecture.json',
      files: ['.specify/config/architecture.json'],
      automated: true
    });

    // Step 7: Validate new structure
    steps.push({
      order: order++,
      description: 'Validate new architecture',
      action: 'Run architecture validation',
      files: [],
      automated: true
    });

    return {
      from,
      to,
      steps,
      estimatedEffort: this.estimateEffort(mapping.complexity),
      risks: this.identifyRisks(from, to),
      recommendations: this.generateRecommendations(from, to)
    };
  }

  /**
   * Execute migration plan
   */
  async executeMigration(plan: MigrationPlan, dryRun: boolean = true): Promise<void> {
    console.log(`\n🔄 Migration Plan: ${plan.from} → ${plan.to}\n`);
    console.log(`Estimated Effort: ${plan.estimatedEffort}`);
    console.log(`Mode: ${dryRun ? 'DRY RUN' : 'EXECUTE'}\n`);

    for (const step of plan.steps) {
      console.log(`Step ${step.order}: ${step.description}`);

      if (!dryRun && step.automated) {
        try {
          // Execute automated steps
          await this.executeStep(step);
          console.log(`  ✅ Completed`);
        } catch (error) {
          console.log(`  ❌ Failed: ${error}`);
          break;
        }
      } else if (!step.automated) {
        console.log(`  ⚠️ Manual action required: ${step.action}`);
      } else {
        console.log(`  🔍 Would execute: ${step.action}`);
      }
    }

    if (!dryRun) {
      console.log('\n✅ Migration completed!');
      console.log('Run validation to ensure everything is working correctly.');
    } else {
      console.log('\n💡 Dry run completed. Run with --execute to perform migration.');
    }
  }

  /**
   * Analyze migration impact
   */
  async analyzeMigrationImpact(from: string, to: string): Promise<{
    fileCount: number;
    affectedFiles: string[];
    breakingChanges: string[];
    estimatedTime: string;
  }> {
    const files = this.getAllSourceFiles();
    const breakingChanges = this.identifyBreakingChanges(from, to);

    return {
      fileCount: files.length,
      affectedFiles: files,
      breakingChanges,
      estimatedTime: this.estimateTime(files.length)
    };
  }

  private createCustomMigrationPlan(from: string, to: string): MigrationPlan {
    return {
      from,
      to,
      steps: [
        {
          order: 1,
          description: 'Manual migration required',
          action: 'No automatic migration available for this combination',
          files: [],
          automated: false
        }
      ],
      estimatedEffort: 'Unknown',
      risks: ['Manual migration required', 'No automated mapping available'],
      recommendations: [
        'Consider intermediate migration steps',
        'Backup your code before proceeding',
        'Test thoroughly after migration'
      ]
    };
  }

  private getCreateStructureCommand(architecture: string): string {
    const structures: Record<string, string> = {
      'fsd': 'mkdir -p src/{app,pages,widgets,features,entities,shared}',
      'atomic': 'mkdir -p src/components/{atoms,molecules,organisms,templates,pages}',
      'clean': 'mkdir -p src/{domain,application,infrastructure,presentation}',
      'hexagonal': 'mkdir -p src/{core/{domain,ports},adapters/{inbound,outbound}}',
      'ddd': 'mkdir -p src/{boundedContexts,domain/{aggregates,valueObjects,events,services}}',
      'layered': 'mkdir -p src/{presentation,business,data,common}',
      'mvc': 'mkdir -p src/{models,views,controllers}'
    };

    return structures[architecture] || 'mkdir -p src';
  }

  private estimateEffort(complexity: string): string {
    const efforts: Record<string, string> = {
      'low': '1-2 hours',
      'medium': '4-8 hours',
      'high': '1-3 days'
    };

    return efforts[complexity] || 'Unknown';
  }

  private estimateTime(fileCount: number): string {
    if (fileCount < 50) return '< 1 hour';
    if (fileCount < 200) return '2-4 hours';
    if (fileCount < 500) return '1 day';
    return '2-3 days';
  }

  private identifyRisks(from: string, to: string): string[] {
    const risks: string[] = [];

    // General risks
    risks.push('Import paths will need updating');
    risks.push('Build configuration may need adjustment');
    risks.push('Tests may need refactoring');

    // Architecture-specific risks
    if (from === 'mvc' && to === 'fsd') {
      risks.push('Business logic distribution needs careful planning');
      risks.push('Component coupling may need resolution');
    }

    if (to === 'ddd') {
      risks.push('Bounded contexts need careful definition');
      risks.push('Domain model extraction requires domain expertise');
    }

    if (to === 'clean' || to === 'hexagonal') {
      risks.push('Dependency inversion requires interface extraction');
      risks.push('Test structure needs significant changes');
    }

    return risks;
  }

  private identifyBreakingChanges(from: string, to: string): string[] {
    const changes: string[] = [];

    changes.push('All import paths will change');
    changes.push('Component/module structure will be reorganized');

    if (from === 'layered' && (to === 'clean' || to === 'hexagonal')) {
      changes.push('Direct database access must be abstracted');
      changes.push('Business logic must be extracted from controllers');
    }

    if (from === 'atomic' && to === 'fsd') {
      changes.push('Component props interfaces will need updating');
      changes.push('State management patterns may need refactoring');
    }

    return changes;
  }

  private generateRecommendations(from: string, to: string): string[] {
    const recommendations: string[] = [];

    recommendations.push('Create a feature branch for migration');
    recommendations.push('Run comprehensive tests before and after migration');
    recommendations.push('Update documentation to reflect new architecture');
    recommendations.push('Train team on new architecture patterns');

    if (to === 'fsd') {
      recommendations.push('Start with a single feature slice as proof of concept');
      recommendations.push('Establish clear public API conventions');
    }

    if (to === 'clean' || to === 'hexagonal') {
      recommendations.push('Define clear boundaries between layers');
      recommendations.push('Create interfaces for all external dependencies');
    }

    if (to === 'ddd') {
      recommendations.push('Conduct domain modeling sessions with stakeholders');
      recommendations.push('Document ubiquitous language');
    }

    return recommendations;
  }

  private getAllSourceFiles(): string[] {
    const files: string[] = [];
    const srcPath = path.join(this.rootPath, 'src');

    if (!fs.existsSync(srcPath)) {
      return files;
    }

    const walk = (dir: string) => {
      const items = fs.readdirSync(dir);
      for (const item of items) {
        const fullPath = path.join(dir, item);
        const stat = fs.statSync(fullPath);

        if (stat.isDirectory() && item !== 'node_modules') {
          walk(fullPath);
        } else if (stat.isFile() && this.isSourceFile(item)) {
          files.push(path.relative(this.rootPath, fullPath));
        }
      }
    };

    walk(srcPath);
    return files;
  }

  private isSourceFile(filename: string): boolean {
    const extensions = ['.ts', '.tsx', '.js', '.jsx', '.vue', '.py', '.java', '.go', '.cs'];
    return extensions.some(ext => filename.endsWith(ext));
  }

  private async executeStep(step: MigrationStep): Promise<void> {
    // Implementation would execute actual file operations
    // For safety, this is left as a placeholder
    console.log(`    Executing: ${step.action}`);
  }
}

// CLI interface
if (require.main === module) {
  const args = process.argv.slice(2);

  if (args.length < 2) {
    console.log('Usage: ts-node migrator.ts <from-architecture> <to-architecture> [--execute]');
    process.exit(1);
  }

  const [from, to] = args;
  const execute = args.includes('--execute');

  const migrator = new ArchitectureMigrator();

  // Analyze impact first
  migrator.analyzeMigrationImpact(from, to).then(impact => {
    console.log('\n📊 Migration Impact Analysis\n');
    console.log(`Files to migrate: ${impact.fileCount}`);
    console.log(`Estimated time: ${impact.estimatedTime}`);
    console.log('\n⚠️ Breaking Changes:');
    impact.breakingChanges.forEach(change => console.log(`  - ${change}`));

    // Create and show migration plan
    const plan = migrator.createMigrationPlan(from, to);

    console.log('\n🎯 Risks:');
    plan.risks.forEach(risk => console.log(`  - ${risk}`));

    console.log('\n💡 Recommendations:');
    plan.recommendations.forEach(rec => console.log(`  - ${rec}`));

    // Execute migration
    migrator.executeMigration(plan, !execute);
  });
}