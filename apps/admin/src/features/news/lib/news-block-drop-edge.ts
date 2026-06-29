/** Visual drop line: after when moving down, before when moving up. */
export function resolveBlockDropEdge(
  activeIndex: number,
  overIndex: number,
  rowIndex: number,
): 'before' | 'after' | null {
  if (activeIndex < 0 || overIndex < 0 || rowIndex !== overIndex || activeIndex === rowIndex) {
    return null;
  }
  return activeIndex < overIndex ? 'after' : 'before';
}
