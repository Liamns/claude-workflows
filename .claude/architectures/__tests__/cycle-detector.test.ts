import { describe, it, expect } from 'vitest';
import { detectCycles } from '../tools/cycle-detector';

describe('Cycle Detector', () => {
  it('should detect simple cycle', () => {
    const graph = new Map([
      ['A', ['B']],
      ['B', ['C']],
      ['C', ['A']],
    ]);

    const cycles = detectCycles(graph);

    expect(cycles.length).toBe(1);
    expect(cycles[0]).toContain('A');
    expect(cycles[0]).toContain('B');
    expect(cycles[0]).toContain('C');
  });

  it('should not detect cycle in acyclic graph', () => {
    const graph = new Map([
      ['A', ['B']],
      ['B', ['C']],
    ]);

    const cycles = detectCycles(graph);

    expect(cycles.length).toBe(0);
  });

  it('should detect self-loop', () => {
    const graph = new Map([
      ['A', ['A']],
    ]);

    const cycles = detectCycles(graph);

    expect(cycles.length).toBe(1);
    expect(cycles[0]).toContain('A');
  });

  it('should detect multiple separate cycles', () => {
    const graph = new Map([
      ['A', ['B']],
      ['B', ['A']],
      ['C', ['D']],
      ['D', ['E']],
      ['E', ['C']],
    ]);

    const cycles = detectCycles(graph);

    expect(cycles.length).toBe(2);
  });

  it('should handle complex graph with multiple paths', () => {
    const graph = new Map([
      ['A', ['B', 'C']],
      ['B', ['D']],
      ['C', ['D']],
      ['D', ['E']],
      ['E', ['A']],
    ]);

    const cycles = detectCycles(graph);

    expect(cycles.length).toBeGreaterThan(0);
    expect(cycles[0]).toContain('A');
    expect(cycles[0]).toContain('E');
  });

  it('should handle empty graph', () => {
    const graph = new Map();

    const cycles = detectCycles(graph);

    expect(cycles.length).toBe(0);
  });

  it('should handle disconnected graph', () => {
    const graph = new Map([
      ['A', ['B']],
      ['C', ['D']],
    ]);

    const cycles = detectCycles(graph);

    expect(cycles.length).toBe(0);
  });
});
