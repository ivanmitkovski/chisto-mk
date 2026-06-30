import { describe, expect, it } from 'vitest';
import { resolveBlockDropEdge } from './news-block-drop-edge';

describe('resolveBlockDropEdge', () => {
  it('shows after when dragging down', () => {
    expect(resolveBlockDropEdge(0, 2, 2)).toBe('after');
  });

  it('shows before when dragging up', () => {
    expect(resolveBlockDropEdge(3, 1, 1)).toBe('before');
  });

  it('hides on the active row', () => {
    expect(resolveBlockDropEdge(2, 2, 2)).toBeNull();
  });
});
