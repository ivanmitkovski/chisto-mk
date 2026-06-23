import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import {
  buildAdminContentSecurityPolicy,
  buildAdminReportOnlyContentSecurityPolicy,
} from '@/lib/security/content-security-policy';
import {
  getAdminAccessToken,
  getAdminRefreshToken,
  getOrCreateAdminDeviceId,
  getTokenExpiryMs,
  isRememberDeviceEnabled,
  refreshAdminTokens,
  setAdminAuthCookies,
  clearAdminAuthCookies,
  ensureAdminCsrfCookie,
} from '@/lib/auth/admin-session';

const REFRESH_THRESHOLD_MS = 60 * 1000;

function shouldEmitStrictReportOnlyCsp(): boolean {
  return process.env.ADMIN_STRICT_CSP_REPORT_ONLY === '1';
}

function applyCspHeaders(response: NextResponse, csp: string, reportOnlyCsp: string | null): NextResponse {
  response.headers.set('Content-Security-Policy', csp);
  if (reportOnlyCsp) {
    response.headers.set('Content-Security-Policy-Report-Only', reportOnlyCsp);
  }
  return response;
}

function authCookieOptions(request: NextRequest, deviceId: string) {
  return {
    rememberDevice: isRememberDeviceEnabled(request),
    deviceId,
  };
}

export async function middleware(request: NextRequest) {
  const nonce = Buffer.from(crypto.randomUUID()).toString('base64');
  const isDev = process.env.NODE_ENV === 'development';
  const csp = buildAdminContentSecurityPolicy(nonce, isDev);
  const reportOnlyCsp = shouldEmitStrictReportOnlyCsp()
    ? buildAdminReportOnlyContentSecurityPolicy(nonce, isDev)
    : null;

  const { pathname } = request.nextUrl;
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set('x-nonce', nonce);
  requestHeaders.set('x-pathname', pathname);
  requestHeaders.set('Content-Security-Policy', csp);
  if (reportOnlyCsp) {
    requestHeaders.set('Content-Security-Policy-Report-Only', reportOnlyCsp);
  }
  const token = getAdminAccessToken(request);
  const refreshToken = getAdminRefreshToken(request);
  const deviceId = getOrCreateAdminDeviceId(request);

  const next = () => {
    const response = NextResponse.next({ request: { headers: requestHeaders } });
    ensureAdminCsrfCookie(request, response, authCookieOptions(request, deviceId));
    return applyCspHeaders(response, csp, reportOnlyCsp);
  };

  const redirectWithCsrf = (url: URL | string) => {
    const response = NextResponse.redirect(url);
    ensureAdminCsrfCookie(request, response, authCookieOptions(request, deviceId));
    return applyCspHeaders(response, csp, reportOnlyCsp);
  };

  const redirectWithAuth = (url: URL | string, tokens: Parameters<typeof setAdminAuthCookies>[1]) => {
    const response = NextResponse.redirect(url);
    setAdminAuthCookies(response, tokens, request, authCookieOptions(request, deviceId));
    ensureAdminCsrfCookie(request, response, authCookieOptions(request, deviceId));
    return applyCspHeaders(response, csp, reportOnlyCsp);
  };

  if (pathname.startsWith('/dashboard')) {
    if (!token) {
      if (refreshToken) {
        const result = await refreshAdminTokens(refreshToken, deviceId);
        if (result.ok) {
          return redirectWithAuth(request.url, result.tokens);
        }
        if (result.reason === 'unauthorized') {
          const response = NextResponse.redirect(new URL('/login', request.url));
          clearAdminAuthCookies(response, request);
          ensureAdminCsrfCookie(request, response, authCookieOptions(request, deviceId));
          return applyCspHeaders(response, csp, reportOnlyCsp);
        }
        // Network failure: fall through with existing cookies (avoid redirect loop).
        return next();
      }
      return redirectWithCsrf(new URL('/login', request.url));
    }

    const expMs = getTokenExpiryMs(token);
    if (expMs && refreshToken && Date.now() > expMs - REFRESH_THRESHOLD_MS) {
      const result = await refreshAdminTokens(refreshToken, deviceId);
      if (result.ok) {
        return redirectWithAuth(request.url, result.tokens);
      }
      if (result.reason === 'unauthorized') {
        const response = NextResponse.redirect(new URL('/login', request.url));
        clearAdminAuthCookies(response, request);
        ensureAdminCsrfCookie(request, response, authCookieOptions(request, deviceId));
        return applyCspHeaders(response, csp, reportOnlyCsp);
      }
      if (Date.now() < expMs) {
        return next();
      }
      return redirectWithCsrf(new URL('/login', request.url));
    }
  }

  if (pathname === '/login' && token) {
    const expMs = getTokenExpiryMs(token);
    if (expMs && Date.now() < expMs) {
      return redirectWithCsrf(new URL('/dashboard', request.url));
    }
  }

  return next();
}

export const config = {
  matcher: [
    {
      source: '/((?!api|_next/static|_next/image|favicon.ico).*)',
      missing: [
        { type: 'header', key: 'next-router-prefetch' },
        { type: 'header', key: 'purpose', value: 'prefetch' },
      ],
    },
  ],
};
