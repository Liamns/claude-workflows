/**
 * Architecture Detection Tool
 * Automatically detects project architecture based on directory structure and dependencies
 */

import * as fs from 'fs';
import * as path from 'path';

export interface DetectionResult {
  detected: string | null;
  confidence: number;
  matches: string[];
  suggestions: string[];
}

export class ArchitectureDetector {
  private patterns = {
    // Frontend patterns
    'fsd': {
      paths: ['src/entities', 'src/features', 'src/widgets', 'src/pages', 'src/shared'],
      files: ['src/app/index.tsx', 'src/app/providers'],
      weight: 1.0
    },
    'atomic': {
      paths: ['src/components/atoms', 'src/components/molecules', 'src/components/organisms'],
      files: ['src/components/templates', 'src/components/pages'],
      weight: 1.0
    },
    'mvc': {
      paths: ['src/models', 'src/views', 'src/controllers'],
      files: ['src/presenters'],
      weight: 0.9
    },
    'micro-frontend': {
      paths: ['packages/', 'apps/', 'remotes/'],
      files: ['module-federation.config.js', 'webpack.config.js'],
      weight: 0.8
    },

    // Backend patterns
    'clean': {
      paths: ['src/domain', 'src/application', 'src/infrastructure', 'src/presentation'],
      files: ['src/domain/entities', 'src/application/useCases'],
      weight: 1.0
    },
    'hexagonal': {
      paths: ['src/core', 'src/core/ports', 'src/adapters'],
      files: ['src/adapters/inbound', 'src/adapters/outbound'],
      weight: 1.0
    },
    'ddd': {
      paths: ['src/boundedContexts', 'src/domain/aggregates', 'src/domain/valueObjects'],
      files: ['src/domain/events', 'src/domain/services'],
      weight: 1.0
    },
    'layered': {
      paths: ['src/presentation', 'src/business', 'src/data'],
      files: ['src/common'],
      weight: 0.8
    },
    'serverless': {
      paths: ['functions/', 'lambdas/', 'handlers/'],
      files: ['serverless.yml', 'serverless.json'],
      weight: 0.9
    },

    // Fullstack patterns
    'monorepo': {
      paths: ['packages/', 'apps/', 'libs/'],
      files: ['nx.json', 'turbo.json', 'lerna.json', 'rush.json'],
      weight: 1.0
    },
    'jamstack': {
      paths: ['src/pages', 'src/content', 'public/'],
      files: ['gatsby-config.js', 'next.config.js', '.eleventy.js'],
      weight: 0.9
    },
    'microservices': {
      paths: ['services/', 'api-gateway/', 'docker-compose.yml'],
      files: ['kubernetes/', '.dockerignore'],
      weight: 0.9
    }
  };

  constructor(private rootPath: string = process.cwd()) {}

  /**
   * Detect architecture from directory structure
   */
  async detect(): Promise<DetectionResult> {
    const scores: Map<string, number> = new Map();
    const matches: Map<string, string[]> = new Map();

    // Check each pattern
    for (const [arch, pattern] of Object.entries(this.patterns)) {
      let score = 0;
      const foundPaths: string[] = [];

      // Check directory paths
      for (const p of pattern.paths) {
        const fullPath = path.join(this.rootPath, p);
        if (this.exists(fullPath)) {
          score += pattern.weight;
          foundPaths.push(p);
        }
      }

      // Check files
      for (const f of pattern.files) {
        const fullPath = path.join(this.rootPath, f);
        if (this.exists(fullPath)) {
          score += pattern.weight * 0.5;
          foundPaths.push(f);
        }
      }

      if (score > 0) {
        scores.set(arch, score);
        matches.set(arch, foundPaths);
      }
    }

    // Find best match
    let bestMatch: string | null = null;
    let bestScore = 0;

    for (const [arch, score] of scores.entries()) {
      if (score > bestScore) {
        bestScore = score;
        bestMatch = arch;
      }
    }

    // Calculate confidence
    const confidence = bestMatch ? Math.min(bestScore / (this.patterns[bestMatch].paths.length * this.patterns[bestMatch].weight), 1) : 0;

    // Generate suggestions
    const suggestions = this.generateSuggestions(bestMatch, matches);

    return {
      detected: bestMatch,
      confidence,
      matches: matches.get(bestMatch!) || [],
      suggestions
    };
  }

  /**
   * Detect from package.json dependencies
   */
  async detectFromDependencies(): Promise<string | null> {
    const packageJsonPath = path.join(this.rootPath, 'package.json');

    if (!this.exists(packageJsonPath)) {
      return null;
    }

    try {
      const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf-8'));
      const deps = {
        ...packageJson.dependencies,
        ...packageJson.devDependencies
      };

      // Check for architecture-specific packages
      const architecturePackages = {
        'fsd': ['feature-sliced', '@feature-sliced/eslint-config'],
        'atomic': ['atomic-design', 'react-atomic-design'],
        'clean': ['clean-architecture', '@clean/core'],
        'hexagonal': ['hexagonal-architecture', 'ports-and-adapters'],
        'ddd': ['domain-driven-design', 'ddd-toolkit'],
        'monorepo': ['nx', 'turborepo', 'lerna', 'rush'],
        'jamstack': ['gatsby', 'next', '@11ty/eleventy'],
        'serverless': ['serverless', 'serverless-offline', '@serverless/components']
      };

      for (const [arch, packages] of Object.entries(architecturePackages)) {
        for (const pkg of packages) {
          if (deps[pkg]) {
            return arch;
          }
        }
      }
    } catch (error) {
      console.error('Error reading package.json:', error);
    }

    return null;
  }

  /**
   * Detect project type (frontend/backend/fullstack)
   */
  async detectProjectType(): Promise<string> {
    const indicators = {
      frontend: ['src/components', 'src/pages', 'src/views', 'public/index.html', 'src/App.tsx', 'src/App.jsx'],
      backend: ['src/controllers', 'src/routes', 'src/models', 'src/services', 'server.js', 'app.js'],
      mobile: ['ios/', 'android/', 'App.tsx', 'metro.config.js', 'app.json'],
      fullstack: ['frontend/', 'backend/', 'client/', 'server/', 'packages/']
    };

    const scores = {
      frontend: 0,
      backend: 0,
      mobile: 0,
      fullstack: 0
    };

    for (const [type, paths] of Object.entries(indicators)) {
      for (const p of paths) {
        if (this.exists(path.join(this.rootPath, p))) {
          scores[type as keyof typeof scores]++;
        }
      }
    }

    // Check for fullstack indicators
    if (scores.fullstack > 0 || (scores.frontend > 0 && scores.backend > 0)) {
      return 'fullstack';
    }

    // Return type with highest score
    const sorted = Object.entries(scores).sort((a, b) => b[1] - a[1]);
    return sorted[0][0];
  }

  /**
   * Full detection combining all methods
   */
  async fullDetection(): Promise<{
    projectType: string;
    architecture: DetectionResult;
    fromDependencies: string | null;
    recommendation: string;
  }> {
    const projectType = await this.detectProjectType();
    const architecture = await this.detect();
    const fromDependencies = await this.detectFromDependencies();

    // Generate recommendation
    let recommendation = '';
    if (architecture.detected && architecture.confidence > 0.7) {
      recommendation = `Detected ${architecture.detected} architecture with high confidence (${Math.round(architecture.confidence * 100)}%)`;
    } else if (fromDependencies) {
      recommendation = `Detected ${fromDependencies} from package dependencies`;
    } else if (architecture.detected) {
      recommendation = `Possibly ${architecture.detected} architecture (${Math.round(architecture.confidence * 100)}% confidence)`;
    } else {
      recommendation = 'No specific architecture detected. Consider choosing one based on your project needs.';
    }

    return {
      projectType,
      architecture,
      fromDependencies,
      recommendation
    };
  }

  private exists(path: string): boolean {
    try {
      fs.accessSync(path);
      return true;
    } catch {
      return false;
    }
  }

  private generateSuggestions(detected: string | null, matches: Map<string, string[]>): string[] {
    const suggestions: string[] = [];

    if (!detected) {
      suggestions.push('No architecture detected. Run /start to configure one.');
      return suggestions;
    }

    const pattern = this.patterns[detected];
    const foundPaths = matches.get(detected) || [];

    // Check missing directories
    for (const p of pattern.paths) {
      if (!foundPaths.includes(p)) {
        suggestions.push(`Missing directory: ${p}`);
      }
    }

    // Architecture-specific suggestions
    switch (detected) {
      case 'fsd':
        suggestions.push('Consider adding public API exports (index files) to each slice');
        break;
      case 'clean':
        suggestions.push('Ensure dependency inversion principle is followed');
        break;
      case 'ddd':
        suggestions.push('Define clear bounded contexts and aggregates');
        break;
      case 'atomic':
        suggestions.push('Maintain strict hierarchy: atoms → molecules → organisms');
        break;
    }

    return suggestions;
  }
}

// CLI interface
if (require.main === module) {
  const detector = new ArchitectureDetector();

  detector.fullDetection().then(result => {
    console.log('\n🔍 Architecture Detection Results\n');
    console.log(`📦 Project Type: ${result.projectType}`);
    console.log(`🏗️  Detected Architecture: ${result.architecture.detected || 'None'}`);
    console.log(`📊 Confidence: ${Math.round((result.architecture.confidence || 0) * 100)}%`);

    if (result.architecture.matches.length > 0) {
      console.log('\n✅ Found patterns:');
      result.architecture.matches.forEach(m => console.log(`  - ${m}`));
    }

    if (result.architecture.suggestions.length > 0) {
      console.log('\n💡 Suggestions:');
      result.architecture.suggestions.forEach(s => console.log(`  - ${s}`));
    }

    console.log(`\n🎯 ${result.recommendation}`);
  });
}