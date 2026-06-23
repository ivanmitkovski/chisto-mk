import { getNamespacesForPathname } from './load-messages';

export function mergeRouteMessages(
  current: Record<string, unknown>,
  next: Record<string, unknown>,
): Record<string, unknown> {
  return { ...current, ...next };
}

export function messagesSatisfyPathname(
  pathname: string,
  messages: Record<string, unknown>,
): boolean {
  return getNamespacesForPathname(pathname).every((namespace) => namespace in messages);
}
