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
  refreshAdminTokens,
  setAdminAuthCookies,
  clearAdminAuthCookies,
} from '@/lib/auth/admin-session';

const REFRESH_THRESHOLD_MS = 60 * 1000; // Refresh if token expires in < 1 min

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

export async function middleware(request: NextRequest) {
  const nonce = Buffer.from(crypto.randomUUID()).toString('base64');
  const isDev = process.env.NODE_ENV === 'development';
  const csp = buildAdminContentSecurityPolicy(nonce, isDev);
  const reportOnlyCsp = shouldEmitStrictReportOnlyCsp()
    ? buildAdminReportOnlyContentSecurityPolicy(nonce, isDev)
    : null;

  const requestHeaders = new Headers(request.headers);
  requestHeaders.set('x-nonce', nonce);
  requestHeaders.set('Content-Security-Policy', csp);
  if (reportOnlyCsp) {
    requestHeaders.set('Content-Security-Policy-Report-Only', reportOnlyCsp);
  }

  const { pathname } = request.nextUrl;
  const token = getAdminAccessToken(request);
  const refreshToken = getAdminRefreshToken(request);
  const deviceId = getOrCreateAdminDeviceId(request);

  const next = () =>
    applyCspHeaders(NextResponse.next({ request: { headers: requestHeaders } }), csp, reportOnlyCsp);

  if (pathname.startsWith('/dashboard')) {
    if (!token) {
      if (refreshToken) {
        const tokens = await refreshAdminTokens(refreshToken, deviceId);
        if (tokens) {
          const response = NextResponse.redirect(request.url);
          setAdminAuthCookies(response, tokens, request, { deviceId });
          return applyCspHeaders(response, csp, reportOnlyCsp);
        }
      }
      const response = NextResponse.redirect(new URL('/login', request.url));
      clearAdminAuthCookies(response, request);
      return applyCspHeaders(response, csp, reportOnlyCsp);
    }

    const expMs = getTokenExpiryMs(token);
    if (expMs && refreshToken && Date.now() > expMs - REFRESH_THRESHOLD_MS) {
      const tokens = await refreshAdminTokens(refreshToken, deviceId);
      if (tokens) {
        const response = NextResponse.redirect(request.url);
        setAdminAuthCookies(response, tokens, request, { deviceId });
        return applyCspHeaders(response, csp, reportOnlyCsp);
      }
      const response = NextResponse.redirect(new URL('/login', request.url));
      clearAdminAuthCookies(response, request);
      return applyCspHeaders(response, csp, reportOnlyCsp);
    }
  }

  if (pathname === '/login' && token) {
    return applyCspHeaders(NextResponse.redirect(new URL('/dashboard', request.url)), csp, reportOnlyCsp);
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
