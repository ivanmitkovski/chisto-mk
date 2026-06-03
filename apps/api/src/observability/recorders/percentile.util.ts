export function percentileFromSorted(sorted: number[], percentile: number): number {
  if (sorted.length === 0) return 0;
  const idx = Math.min(sorted.length - 1, Math.floor((percentile / 100) * sorted.length));
  return Number(sorted[idx].toFixed(2));
}

export function p95Ms(values: number[]): number {
  const sorted = [...values].sort((a, b) => a - b);
  return percentileFromSorted(sorted, 95);
}

export function trimRollingBuffer<T>(buffer: T[], max = 2000, keep = 1200): T[] {
  return buffer.length > max ? buffer.slice(-keep) : buffer;
}
