import { describe, expect, it } from 'vitest';

function moveSelectionIndex(current: number, step: 1 | -1, length: number): number {
  if (length === 0) return 0;
  const nextIndex = current + step;
  if (nextIndex < 0) return length - 1;
  if (nextIndex >= length) return 0;
  return nextIndex;
}

describe('command palette selection', () => {
  it('wraps selection at list boundaries', () => {
    expect(moveSelectionIndex(0, -1, 3)).toBe(2);
    expect(moveSelectionIndex(2, 1, 3)).toBe(0);
    expect(moveSelectionIndex(1, 1, 3)).toBe(2);
  });
});
