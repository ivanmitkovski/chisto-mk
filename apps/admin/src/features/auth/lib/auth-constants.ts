/**
 * Shared auth cookie keys for middleware (Edge) and client/server code.
 * Kept separate to avoid pulling browser-specific code into middleware.
 */
export const ADMIN_AUTH_COOKIE_KEY = 'chisto_admin_token';
export const ADMIN_REFRESH_COOKIE_KEY = 'chisto_admin_refresh';
