/**
 * File Collector
 *
 * Collects TypeScript files for validation based on patterns.
 */

import * as fs from 'fs/promises';
import * as path from 'path';
import { glob } from 'glob';

/**
 * Collect TypeScript files based on patterns
 *
 * @param patterns - Glob patterns to include (e.g., ['**\/*.ts', '**\/*.tsx'])
 * @param ignorePatterns - Glob patterns to exclude (e.g., ['**/node_modules/**'])
 * @returns Array of absolute file paths
 */
export async function collectFiles(
  patterns: string[],
  ignorePatterns: string[]
): Promise<string[]> {
  const allFiles: string[] = [];

  for (const pattern of patterns) {
    const files = await glob(pattern, {
      ignore: ignorePatterns,
      absolute: true,
      nodir: true,
    });

    allFiles.push(...files);
  }

  // Remove duplicates
  const uniqueFiles = Array.from(new Set(allFiles));

  // Filter only TypeScript files
  const tsFiles = uniqueFiles.filter(
    (file) => file.endsWith('.ts') || file.endsWith('.tsx')
  );

  return tsFiles;
}

/**
 * Check if file exists
 *
 * @param filePath - Path to check
 * @returns True if file exists
 */
export async function fileExists(filePath: string): Promise<boolean> {
  try {
    await fs.access(filePath);
    return true;
  } catch {
    return false;
  }
}

/**
 * Read file content
 *
 * @param filePath - Path to file
 * @returns File content as string
 */
export async function readFile(filePath: string): Promise<string> {
  try {
    return await fs.readFile(filePath, 'utf-8');
  } catch (error) {
    throw new Error(`Failed to read file ${filePath}: ${(error as Error).message}`);
  }
}
