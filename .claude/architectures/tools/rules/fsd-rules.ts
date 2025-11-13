/**
 * FSD (Feature-Sliced Design) Architecture Rules
 *
 * Validates FSD layer hierarchy and naming conventions.
 */

import type { ArchitectureRule, FileInfo, ValidationIssue } from '../../types/validation-types';

/**
 * FSD layer hierarchy from top to bottom
 * Higher layers can import from lower layers, but not vice versa
 */
const layerOrder = ['app', 'processes', 'pages', 'widgets', 'features', 'entities', 'shared'];

/**
 * Get the FSD layer from a file path
 *
 * @param filePath - Absolute or relative file path
 * @returns Layer name or 'unknown'
 */
function getLayer(filePath: string): string {
  for (const layer of layerOrder) {
    if (filePath.includes(`/${layer}/`)) {
      return layer;
    }
  }
  return 'unknown';
}

/**
 * FSD Layer Rule: Prevent upward imports
 *
 * Lower layers cannot import from higher layers.
 * Example: entities cannot import from features or pages
 */
export const fsdLayerRule: ArchitectureRule = {
  id: 'fsd-layer-no-upward-import',
  name: 'FSD 레이어 상향 import 금지',
  description: '하위 레이어는 상위 레이어를 import할 수 없습니다',
  severity: 'error',
  enabled: true,
  check: (files: FileInfo[]): ValidationIssue[] => {
    const issues: ValidationIssue[] = [];

    for (const file of files) {
      const fromLayer = getLayer(file.path);

      // Skip if file is not in a recognized layer
      if (fromLayer === 'unknown') continue;

      for (const imp of file.imports) {
        const toLayer = getLayer(imp.source);

        // Skip if import is not from a recognized layer
        if (toLayer === 'unknown') continue;

        // Check if importing from a higher layer (upward import)
        const fromIndex = layerOrder.indexOf(fromLayer);
        const toIndex = layerOrder.indexOf(toLayer);

        if (fromIndex > toIndex) {
          issues.push({
            file: file.path,
            line: imp.line,
            rule: 'fsd-layer-no-upward-import',
            severity: 'error',
            message: `${fromLayer} 레이어는 ${toLayer} 레이어를 import할 수 없습니다`,
            suggestion: `${toLayer}의 기능을 shared 레이어로 이동하거나 의존성 역전 패턴을 적용하세요`,
          });
        }
      }
    }

    return issues;
  },
};

/**
 * FSD Naming Convention Rule
 *
 * Validates file naming conventions:
 * - Hooks: use{Name}.ts (camelCase with 'use' prefix)
 * - Stores: {entity}Store.ts (camelCase with 'Store' suffix)
 */
export const fsdNamingRule: ArchitectureRule = {
  id: 'fsd-naming-convention',
  name: 'FSD 네이밍 규칙',
  description: 'Hook은 use{Name}.ts, Store는 {entity}Store.ts 형식',
  severity: 'error',
  enabled: true,
  check: (files: FileInfo[]): ValidationIssue[] => {
    const issues: ValidationIssue[] = [];

    for (const file of files) {
      const fileName = file.path.split('/').pop() || '';

      // Hook validation
      if (file.path.includes('/hooks/') || file.path.includes('/model/')) {
        // Check if it's a hook file (starts with 'use')
        if (fileName.startsWith('use')) {
          // Validate camelCase naming: use{Name}.ts
          if (!fileName.match(/^use[A-Z][a-zA-Z]*\.tsx?$/)) {
            issues.push({
              file: file.path,
              rule: 'fsd-naming-convention',
              severity: 'error',
              message: 'Hook 파일은 use{Name}.ts 형식이어야 합니다',
              suggestion: `파일명을 camelCase로 변경하세요 (예: useUserAuth.ts)`,
            });
          }
        } else if (file.path.includes('/hooks/')) {
          // File in hooks directory must start with 'use'
          issues.push({
            file: file.path,
            rule: 'fsd-naming-convention',
            severity: 'error',
            message: 'hooks 디렉토리의 파일은 use{Name}.ts 형식이어야 합니다',
            suggestion: `파일명을 use로 시작하도록 변경하세요 (예: use${fileName})`,
          });
        }
      }

      // Store validation
      if (fileName.includes('Store')) {
        // Validate camelCase naming: {entity}Store.ts
        if (!fileName.match(/^[a-z][a-zA-Z]*Store\.tsx?$/)) {
          issues.push({
            file: file.path,
            rule: 'fsd-naming-convention',
            severity: 'error',
            message: 'Store 파일은 {entity}Store.ts 형식이어야 합니다',
            suggestion: `파일명을 camelCase로 변경하세요 (예: userStore.ts)`,
          });
        }
      }
    }

    return issues;
  },
};
