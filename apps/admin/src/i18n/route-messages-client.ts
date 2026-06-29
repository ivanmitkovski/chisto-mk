import { getNamespacesForPathname } from './load-messages';

function isPlainObject(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}

/** Deep-merge message trees so fresher leaf keys win without dropping sibling keys. */
function deepMergeMessages(
  base: Record<string, unknown>,
  override: Record<string, unknown>,
): Record<string, unknown> {
  const merged: Record<string, unknown> = { ...base };

  for (const [key, overrideValue] of Object.entries(override)) {
    const baseValue = base[key];
    if (isPlainObject(baseValue) && isPlainObject(overrideValue)) {
      merged[key] = deepMergeMessages(baseValue, overrideValue);
    } else {
      merged[key] = overrideValue;
    }
  }

  return merged;
}

export function mergeRouteMessages(
  current: Record<string, unknown>,
  next: Record<string, unknown>,
): Record<string, unknown> {
  return deepMergeMessages(current, next);
}

export function messagesSatisfyPathname(
  pathname: string,
  messages: Record<string, unknown>,
): boolean {
  return getNamespacesForPathname(pathname).every((namespace) => namespace in messages);
}
