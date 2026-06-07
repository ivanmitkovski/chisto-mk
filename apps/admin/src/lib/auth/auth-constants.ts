/**
 * Shared auth cookie keys for middleware (Edge) and client/server code.
 * Kept separate to avoid pulling browser-specific code into middleware.
 */
const useHostPrefixedCookies = process.env.NODE_ENV === 'production';

export const ADMIN_AUTH_COOKIE_KEY = useHostPrefixedCookies
  ? '__Host-chisto_admin_at'
  : 'chisto_admin_at';
export const ADMIN_REFRESH_COOKIE_KEY = useHostPrefixedCookies
  ? '__Host-chisto_admin_rt'
  : 'chisto_admin_rt';
export const ADMIN_CSRF_COOKIE_KEY = useHostPrefixedCookies
  ? '__Host-chisto_admin_csrf'
  : 'chisto_admin_csrf';
export const ADMIN_DEVICE_COOKIE_KEY = useHostPrefixedCookies
  ? '__Host-admin-device-id'
  : 'chisto_admin_device_id';

export const ADMIN_LEGACY_AUTH_COOKIE_KEY = 'chisto_admin_token';
export const ADMIN_LEGACY_REFRESH_COOKIE_KEY = 'chisto_admin_refresh';
export const ADMIN_CSRF_HEADER = 'x-chisto-csrf';
