/**
 * Cycle Detector
 *
 * Detects circular dependencies in a dependency graph using DFS.
 */

/**
 * Detect cycles in a directed graph using Depth-First Search
 *
 * @param graph - Adjacency list representation of the graph
 * @returns Array of cycles, where each cycle is an array of node names
 */
export function detectCycles(graph: Map<string, string[]>): string[][] {
  const visited = new Set<string>();
  const recursionStack = new Set<string>();
  const cycles: string[][] = [];

  /**
   * Depth-First Search to detect cycles
   *
   * @param node - Current node being visited
   * @param path - Path from root to current node
   */
  function dfs(node: string, path: string[]): void {
    visited.add(node);
    recursionStack.add(node);

    const neighbors = graph.get(node) || [];

    for (const neighbor of neighbors) {
      if (!visited.has(neighbor)) {
        // Visit unvisited neighbor
        dfs(neighbor, [...path, neighbor]);
      } else if (recursionStack.has(neighbor)) {
        // Cycle detected: neighbor is in current recursion stack
        const cycleStart = path.indexOf(neighbor);

        if (cycleStart !== -1) {
          // Extract the cycle from the path
          const cycle = [...path.slice(cycleStart), neighbor];

          // Check if this cycle is not already recorded (avoid duplicates)
          const cycleKey = cycle.sort().join('->');
          const isDuplicate = cycles.some(existingCycle =>
            existingCycle.sort().join('->') === cycleKey
          );

          if (!isDuplicate) {
            cycles.push(cycle);
          }
        } else {
          // Neighbor is in path but not found (self-loop case)
          cycles.push([node, neighbor]);
        }
      }
    }

    // Remove node from recursion stack when backtracking
    recursionStack.delete(node);
  }

  // Visit all nodes in the graph
  for (const node of graph.keys()) {
    if (!visited.has(node)) {
      dfs(node, [node]);
    }
  }

  return cycles;
}

/**
 * Build a human-readable cycle report
 *
 * @param cycles - Array of detected cycles
 * @returns Formatted cycle report
 */
export function formatCycleReport(cycles: string[][]): string {
  if (cycles.length === 0) {
    return 'No circular dependencies detected.';
  }

  const lines: string[] = [
    `Found ${cycles.length} circular ${cycles.length === 1 ? 'dependency' : 'dependencies'}:`,
    '',
  ];

  cycles.forEach((cycle, index) => {
    lines.push(`${index + 1}. ${cycle.join(' → ')}`);
  });

  return lines.join('\n');
}
