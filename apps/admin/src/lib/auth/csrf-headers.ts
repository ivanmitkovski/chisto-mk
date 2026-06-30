import { ADMIN_CSRF_COOKIE_KEY, ADMIN_CSRF_HEADER } from './auth-constants';

function readCookie(name: string): string | null {
  if (typeof document === 'undefined') return null;
  const match = document.cookie.match(
    new RegExp(`(?:^|;\\s*)${encodeURIComponent(name)}=([^;]*)`),
  );
  return match ? decodeURIComponent(match[1]) : null;
}

export function getAdminCsrfHeaders(): Record<string, string> {
  const token = readCookie(ADMIN_CSRF_COOKIE_KEY);
  return token ? { [ADMIN_CSRF_HEADER]: token } : {};
}
