export {
  ADMIN_AUTH_COOKIE_KEY,
  ADMIN_REFRESH_COOKIE_KEY,
  ADMIN_CSRF_COOKIE_KEY,
  ADMIN_DEVICE_COOKIE_KEY,
  ADMIN_REMEMBER_DEVICE_COOKIE_KEY,
  ADMIN_LEGACY_AUTH_COOKIE_KEY,
  ADMIN_LEGACY_REFRESH_COOKIE_KEY,
  ADMIN_CSRF_HEADER,
} from './auth-constants';

export { getAdminCsrfHeaders } from './csrf-headers';

export {
  ACCESS_COOKIE_MAX_AGE,
  clearAdminAuthCookies,
  ensureAdminCsrfCookie,
  getAdminAccessToken,
  getAdminRefreshToken,
  getOrCreateAdminDeviceId,
  getTokenExpiryMs,
  isRememberDeviceEnabled,
  isRememberDeviceEnabledServer,
  refreshAdminTokens,
  resolveRefreshCookieMaxAge,
  setAdminAuthCookies,
  verifyAdminCsrf,
  type AdminRefreshResult,
  type AdminTokenPair,
} from './admin-session';

export {
  createBackendProxyHeaders,
  fetchBackendWithRefresh,
  proxyBackendWithRefresh,
} from './admin-api-with-refresh';
