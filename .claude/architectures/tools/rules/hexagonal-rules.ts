/**
 * Hexagonal Architecture Rules (Ports and Adapters)
 *
 * Validates separation between Core (domain + ports) and Adapters.
 *
 * Structure:
 * - Core: domain logic + port interfaces
 * - Adapters: implementations that connect to external systems
 */

import type { ArchitectureRule, FileInfo, ValidationIssue } from '../../types/validation-types';

/**
 * Check if a file path is in the core layer
 *
 * @param filePath - File path to check
 * @returns True if in core/domain layer
 */
function isCore(filePath: string): boolean {
  return filePath.includes('/core/') ||
         filePath.includes('/domain/') ||
         filePath.includes('/ports/') ||
         filePath.includes('\\core\\') ||
         filePath.includes('\\domain\\') ||
         filePath.includes('\\ports\\');
}

/**
 * Check if a file path is in the adapters layer
 *
 * @param filePath - File path to check
 * @returns True if in adapters layer
 */
function isAdapter(filePath: string): boolean {
  return filePath.includes('/adapters/') ||
         filePath.includes('/adapter/') ||
         filePath.includes('\\adapters\\') ||
         filePath.includes('\\adapter\\');
}

/**
 * Hexagonal Ports Separation Rule
 *
 * Core principle: Core cannot depend on Adapters
 * - Core defines port interfaces
 * - Adapters implement those ports
 * - Dependencies point inward (Adapters → Core, never Core → Adapters)
 */
export const hexagonalPortsRule: ArchitectureRule = {
  id: 'hexagonal-ports-separation',
  name: 'Hexagonal Ports 분리',
  description: 'Core는 Adapters를 import할 수 없습니다',
  severity: 'error',
  enabled: true,
  check: (files: FileInfo[]): ValidationIssue[] => {
    const issues: ValidationIssue[] = [];

    for (const file of files) {
      // Only check files in core layer
      if (!isCore(file.path)) continue;

      for (const imp of file.imports) {
        // Check if importing from adapters layer
        if (isAdapter(imp.source)) {
          issues.push({
            file: file.path,
            line: imp.line,
            rule: 'hexagonal-ports-separation',
            severity: 'error',
            message: `Core는 Adapters를 import할 수 없습니다`,
            suggestion: `Adapter에서 구현할 Port 인터페이스를 Core에 정의하고, 의존성 주입을 사용하세요`,
          });
        }
      }
    }

    return issues;
  },
};

/**
 * Hexagonal Port Interface Rule
 *
 * Validates that port interfaces are properly defined in the ports directory
 */
export const hexagonalPortInterfaceRule: ArchitectureRule = {
  id: 'hexagonal-port-interface',
  name: 'Hexagonal Port 인터페이스 정의',
  description: 'Port 인터페이스는 ports 디렉토리에 정의되어야 합니다',
  severity: 'warning',
  enabled: true,
  check: (files: FileInfo[]): ValidationIssue[] => {
    const issues: ValidationIssue[] = [];

    for (const file of files) {
      const fileName = file.path.split('/').pop() || '';

      // Check if file appears to be a port interface
      if (fileName.includes('Port') && fileName.endsWith('.ts')) {
        const inPortsDir = file.path.includes('/ports/') || file.path.includes('\\ports\\');

        if (!inPortsDir) {
          issues.push({
            file: file.path,
            rule: 'hexagonal-port-interface',
            severity: 'warning',
            message: `Port 인터페이스는 ports 디렉토리에 정의되어야 합니다`,
            suggestion: `파일을 ports 디렉토리로 이동하세요`,
          });
        }
      }
    }

    return issues;
  },
};
