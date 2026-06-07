import { describe, expect, it } from 'vitest';
import { ListWorkspaceSkeleton } from './list-workspace-skeleton';

describe('ListWorkspaceSkeleton', () => {
  it('is exported as a render function', () => {
    expect(typeof ListWorkspaceSkeleton).toBe('function');
    expect(ListWorkspaceSkeleton.name).toBe('ListWorkspaceSkeleton');
  });
});
