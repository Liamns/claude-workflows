/**
 * Base Architecture Adapter Interface
 * All architecture implementations must extend this interface
 */

export interface ValidationResult {
  valid: boolean;
  errors: string[];
  warnings: string[];
  suggestions: string[];
}

export interface FileTemplate {
  path: string;
  content: string;
  description: string;
}

export interface Pattern {
  name: string;
  description: string;
  example: string;
  when: string;
}

export interface AntiPattern {
  name: string;
  description: string;
  why: string;
  instead: string;
}

export interface Gate {
  name: string;
  enabled: boolean;
  required: boolean;
  check: () => Promise<boolean>;
  fix?: () => Promise<void>;
}

export interface ArchitectureConfig {
  name: string;
  type: 'frontend' | 'backend' | 'fullstack' | 'mobile';
  version: string;
  description: string;

  // Structure definition
  structure: {
    directories: Record<string, string>;
    namingConventions: Record<string, string>;
    fileExtensions: Record<string, string[]>;
  };

  // Dependencies rules
  dependencies: {
    allowed: Record<string, string[]>;
    forbidden: Record<string, string[]>;
    circular: boolean;
  };

  // Component types
  components: {
    types: string[];
    templates: Record<string, string>;
    generators: Record<string, any>;
  };
}

export abstract class ArchitectureAdapter {
  protected config: ArchitectureConfig;

  constructor(config: ArchitectureConfig) {
    this.config = config;
  }

  // Abstract methods that must be implemented
  abstract validateStructure(files: string[]): Promise<ValidationResult>;
  abstract generateComponent(type: string, name: string, options?: any): FileTemplate[];
  abstract checkDependencies(from: string, to: string): boolean;
  abstract suggestLocation(fileType: string, fileName: string): string;

  // Common methods with default implementations
  getName(): string {
    return this.config.name;
  }

  getType(): string {
    return this.config.type;
  }

  getPatterns(): Pattern[] {
    return [];
  }

  getAntiPatterns(): AntiPattern[] {
    return [];
  }

  getQualityGates(): {
    pre: Gate[];
    during: Gate[];
    post: Gate[];
  } {
    return {
      pre: [],
      during: [],
      post: []
    };
  }

  // Helper methods
  protected isValidPath(path: string): boolean {
    const allowedDirs = Object.keys(this.config.structure.directories);
    return allowedDirs.some(dir => path.startsWith(dir));
  }

  protected getFileType(path: string): string {
    const ext = path.split('.').pop();
    for (const [type, extensions] of Object.entries(this.config.structure.fileExtensions)) {
      if (extensions.includes(ext || '')) {
        return type;
      }
    }
    return 'unknown';
  }

  protected formatComponentName(name: string, type: string): string {
    const convention = this.config.structure.namingConventions[type];
    if (!convention) return name;

    switch (convention) {
      case 'PascalCase':
        return name.charAt(0).toUpperCase() + name.slice(1);
      case 'camelCase':
        return name.charAt(0).toLowerCase() + name.slice(1);
      case 'kebab-case':
        return name.replace(/([A-Z])/g, '-$1').toLowerCase();
      case 'snake_case':
        return name.replace(/([A-Z])/g, '_$1').toLowerCase();
      default:
        return name;
    }
  }
}