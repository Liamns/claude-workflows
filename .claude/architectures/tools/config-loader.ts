/**
 * Configuration Loader
 *
 * Loads and validates architecture validation configuration.
 */

import * as fs from 'fs/promises';
import { ValidationConfig, ValidationConfigSchema, DEFAULT_CONFIG } from '../types/validation-types';

/**
 * Load validation configuration from file
 *
 * @param path - Path to config file (default: .claude/architectures/config.json)
 * @returns Validated configuration object
 */
export async function loadConfig(
  path: string = '.claude/architectures/config.json'
): Promise<ValidationConfig> {
  try {
    // Try to read config file
    const content = await fs.readFile(path, 'utf-8');
    const json = JSON.parse(content);

    // Validate and parse with Zod
    return ValidationConfigSchema.parse(json);
  } catch (error) {
    // If file doesn't exist or is invalid, return default config
    if ((error as NodeJS.ErrnoException).code === 'ENOENT') {
      // File not found - return default
      return DEFAULT_CONFIG;
    }

    // If JSON parse error or validation error, log and return default
    console.warn(`Warning: Failed to load config from ${path}, using defaults`);
    console.warn((error as Error).message);
    return DEFAULT_CONFIG;
  }
}

/**
 * Save configuration to file
 *
 * @param config - Configuration to save
 * @param path - Path to save config file
 */
export async function saveConfig(
  config: ValidationConfig,
  path: string = '.claude/architectures/config.json'
): Promise<void> {
  try {
    // Validate config
    const validated = ValidationConfigSchema.parse(config);

    // Ensure directory exists
    const dir = path.substring(0, path.lastIndexOf('/'));
    await fs.mkdir(dir, { recursive: true });

    // Save to file
    await fs.writeFile(path, JSON.stringify(validated, null, 2), 'utf-8');
  } catch (error) {
    throw new Error(`Failed to save config: ${(error as Error).message}`);
  }
}
