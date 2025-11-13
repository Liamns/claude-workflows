/**
 * Import Parser
 *
 * Parses import statements from TypeScript files.
 */

import type { ImportStatement } from '../types/validation-types';

/**
 * Parse import statements from file content
 *
 * @param content - File content as string
 * @returns Array of parsed import statements
 */
export function parseImports(content: string): ImportStatement[] {
  const imports: ImportStatement[] = [];
  const lines = content.split('\n');

  let i = 0;
  while (i < lines.length) {
    const line = lines[i];
    const trimmed = line.trim();

    // Skip comments and non-import lines
    if (trimmed.startsWith('//') || trimmed.startsWith('/*') || !trimmed.startsWith('import')) {
      i++;
      continue;
    }

    // Check if this is a complete import statement
    if (trimmed.includes('from')) {
      // Single line import
      const match = trimmed.match(/from\s+['"]([^'"]+)['"]/);
      if (match) {
        imports.push({
          source: match[1],
          line: i + 1, // 1-indexed
          raw: trimmed,
        });
      }
      i++;
    } else {
      // Multi-line import - collect until we find 'from'
      let multilineImport = trimmed;
      const startLine = i;
      i++;

      while (i < lines.length) {
        const nextLine = lines[i].trim();
        multilineImport += ' ' + nextLine;

        if (nextLine.includes('from')) {
          // Found the end of the import
          const match = multilineImport.match(/from\s+['"]([^'"]+)['"]/);
          if (match) {
            imports.push({
              source: match[1],
              line: startLine + 1, // 1-indexed
              raw: multilineImport,
            });
          }
          i++;
          break;
        }
        i++;
      }
    }
  }

  return imports;
}
