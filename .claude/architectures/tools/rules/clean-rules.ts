/**
 * Clean Architecture Rules
 *
 * Validates Clean Architecture dependency direction:
 * Domain ← Application ← Infrastructure/Presentation
 *
 * Core principle: Dependencies point inward. Inner layers don't depend on outer layers.
 */

import type { ArchitectureRule, FileInfo, ValidationIssue } from '../../types/validation-types';

/**
 * Clean Architecture layers from inner to outer
 * Inner layers cannot import from outer layers
 */
const layerOrder = ['domain', 'application', 'infrastructure', 'presentation'];

/**
 * Get the Clean Architecture layer from a file path
 *
 * @param filePath - Absolute or relative file path
 * @returns Layer name or 'unknown'
 */
function getLayer(filePath: string): string {
  for (const layer of layerOrder) {
    if (filePath.includes(`/${layer}/`) || filePath.includes(`\\${layer}\\`)) {
      return layer;
    }
  }
  return 'unknown';
}

/**
 * Clean Architecture Dependency Direction Rule
 *
 * Validates that dependencies only point inward:
 * - Domain cannot import from any other layer
 * - Application can only import from Domain
 * - Infrastructure/Presentation can import from Application and Domain
 */
export const cleanDependencyRule: ArchitectureRule = {
  id: 'clean-dependency-direction',
  name: 'Clean Architecture 의존성 방향',
  description: 'Domain은 다른 레이어를 import할 수 없습니다',
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

        // Check if importing from an outer layer (outward dependency)
        const fromIndex = layerOrder.indexOf(fromLayer);
        const toIndex = layerOrder.indexOf(toLayer);

        if (fromIndex < toIndex) {
          issues.push({
            file: file.path,
            line: imp.line,
            rule: 'clean-dependency-direction',
            severity: 'error',
            message: `${fromLayer} 레이어는 ${toLayer} 레이어를 import할 수 없습니다`,
            suggestion: `의존성 역전 원칙(DIP)을 적용하여 인터페이스를 ${fromLayer}에 정의하고 ${toLayer}에서 구현하세요`,
          });
        }
      }
    }

    return issues;
  },
};

/**
 * Clean Architecture Use Case Rule
 *
 * Validates that use cases are properly isolated in the application layer
 */
export const cleanUseCaseRule: ArchitectureRule = {
  id: 'clean-usecase-isolation',
  name: 'Clean Architecture UseCase 격리',
  description: 'UseCase는 application 레이어에만 존재해야 합니다',
  severity: 'warning',
  enabled: true,
  check: (files: FileInfo[]): ValidationIssue[] => {
    const issues: ValidationIssue[] = [];

    for (const file of files) {
      const fileName = file.path.split('/').pop() || '';

      // Check if file appears to be a use case
      if (fileName.includes('UseCase') || fileName.includes('use-case')) {
        const layer = getLayer(file.path);

        if (layer !== 'application' && layer !== 'unknown') {
          issues.push({
            file: file.path,
            rule: 'clean-usecase-isolation',
            severity: 'warning',
            message: `UseCase는 application 레이어에 위치해야 합니다`,
            suggestion: `파일을 application 레이어로 이동하세요`,
          });
        }
      }
    }

    return issues;
  },
};
