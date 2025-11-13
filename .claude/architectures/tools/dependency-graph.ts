/**
 * Dependency Graph Builder
 *
 * Builds a dependency graph from TypeScript files for cycle detection.
 */

import * as path from 'path';
import type { FileInfo } from '../types/validation-types';

/**
 * Build dependency graph from file information
 *
 * @param files - Array of file information with imports
 * @returns Map of file paths to their dependencies
 */
export function buildDependencyGraph(files: FileInfo[]): Map<string, string[]> {
  const graph = new Map<string, string[]>();

  // Create a map of normalized paths for quick lookup
  const filePathMap = new Map<string, string>();
  for (const file of files) {
    const normalized = normalizePath(file.path);
    filePathMap.set(normalized, file.path);
  }

  for (const file of files) {
    const dependencies: string[] = [];

    for (const imp of file.imports) {
      const resolved = resolveImportPath(imp.source, file.path, filePathMap);
      if (resolved) {
        dependencies.push(resolved);
      }
    }

    graph.set(file.path, dependencies);
  }

  return graph;
}

/**
 * Resolve import path to absolute file path
 *
 * Handles:
 * - Path aliases (@/, @shared/, etc.)
 * - Relative imports (../, ./)
 * - Node modules (ignored)
 *
 * @param importSource - Import source string
 * @param fromFile - File containing the import
 * @param filePathMap - Map of normalized paths for lookup
 * @returns Resolved absolute path or null if external module
 */
function resolveImportPath(
  importSource: string,
  fromFile: string,
  filePathMap: Map<string, string>
): string | null {
  // Ignore node_modules and external packages
  if (!importSource.startsWith('.') && !importSource.startsWith('@/') && !importSource.startsWith('@')) {
    // Check if it's a scoped package
    if (!importSource.startsWith('@/')) {
      return null;
    }
  }

  let resolved: string;

  // Handle path aliases
  if (importSource.startsWith('@/')) {
    // @/ -> src/
    resolved = importSource.replace('@/', 'src/');
  } else if (importSource.startsWith('@shared/')) {
    resolved = importSource.replace('@shared/', 'src/shared/');
  } else if (importSource.startsWith('@features/')) {
    resolved = importSource.replace('@features/', 'src/features/');
  } else if (importSource.startsWith('@entities/')) {
    resolved = importSource.replace('@entities/', 'src/entities/');
  } else if (importSource.startsWith('@pages/')) {
    resolved = importSource.replace('@pages/', 'src/pages/');
  } else if (importSource.startsWith('.')) {
    // Handle relative imports
    const dir = path.dirname(fromFile);
    resolved = path.join(dir, importSource);
  } else {
    // External module
    return null;
  }

  // Normalize the path
  resolved = normalizePath(resolved);

  // Try to find matching file in filePathMap
  // Try exact match first
  if (filePathMap.has(resolved)) {
    return filePathMap.get(resolved)!;
  }

  // Try with .ts extension
  if (filePathMap.has(resolved + '.ts')) {
    return filePathMap.get(resolved + '.ts')!;
  }

  // Try with .tsx extension
  if (filePathMap.has(resolved + '.tsx')) {
    return filePathMap.get(resolved + '.tsx')!;
  }

  // Try with /index.ts
  if (filePathMap.has(resolved + '/index.ts')) {
    return filePathMap.get(resolved + '/index.ts')!;
  }

  // Try with /index.tsx
  if (filePathMap.has(resolved + '/index.tsx')) {
    return filePathMap.get(resolved + '/index.tsx')!;
  }

  // Could not resolve - might be external or missing file
  return null;
}

/**
 * Normalize file path for consistent comparison
 *
 * @param filePath - File path to normalize
 * @returns Normalized path
 */
function normalizePath(filePath: string): string {
  return filePath.replace(/\\/g, '/').replace(/\/$/, '');
}
