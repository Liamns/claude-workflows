/**
 * Result Saver
 *
 * Saves architecture validation results to cache directory.
 */

import * as fs from 'fs/promises';
import type { ArchitectureValidationResult } from '../types/validation-types';

/**
 * Save validation result to cache
 *
 * Saves both the latest result and a timestamped history file
 *
 * @param result - Validation result to save
 */
export async function saveResult(result: ArchitectureValidationResult): Promise<void> {
  const cacheDir = '.claude/cache/validation-reports';
  await fs.mkdir(cacheDir, { recursive: true });

  // Save latest result
  await fs.writeFile(
    `${cacheDir}/latest.json`,
    JSON.stringify(result, null, 2)
  );

  // Save history with timestamp
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  await fs.writeFile(
    `${cacheDir}/architecture-${timestamp}.json`,
    JSON.stringify(result, null, 2)
  );
}
