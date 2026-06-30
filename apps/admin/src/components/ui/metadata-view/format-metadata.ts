export function formatMetadataValue(value: unknown, pretty = true): string {
  if (value == null) return '—';
  if (typeof value === 'string') return value;
  try {
    return JSON.stringify(value, null, pretty ? 2 : undefined);
  } catch {
    return String(value);
  }
}
