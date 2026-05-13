import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { ADMIN_AUTH_COOKIE_KEY, ADMIN_REFRESH_COOKIE_KEY } from '@/features/auth/lib/auth-constants';
import { buildAdminContentSecurityPolicy } from '@/lib/content-security-policy';
import { getApiBaseUrl } from '@/lib/api-base-url';

const REFRESH_THRESHOLD_MS = 60 * 1000; // Refresh if token expires in < 1 min
const ACCESS_COOKIE_MAX_AGE = 15 * 60; // 15 min, aligned with JWT access expiry

function getTokenExpiryMs(token: string): number | null {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) return null;
    const payload = parts[1].replace(/-/g, '+').replace(/_/g, '/');
    const decoded = JSON.parse(atob(payload)) as { exp?: number };
    return decoded.exp ? decoded.exp * 1000 : null;
  } catch {
    return null;
  }
}

async function refreshTokens(refreshToken: string): Promise<{ accessToken: string; refreshToken?: string } | null> {
  try {
    const res = await fetch(`${getApiBaseUrl()}/auth/refresh`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refreshToken }),
      cache: 'no-store',
    });
    if (!res.ok) return null;
    return res.json();
  } catch {
    return null;
  }
}

function applyCspHeaders(response: NextResponse, csp: string): NextResponse {
  response.headers.set('Content-Security-Policy', csp);
  return response;
}

export async function middleware(request: NextRequest) {
  const nonce = Buffer.from(crypto.randomUUID()).toString('base64');
  const isDev = process.env.NODE_ENV === 'development';
  const csp = buildAdminContentSecurityPolicy(nonce, isDev);

  const requestHeaders = new Headers(request.headers);
  requestHeaders.set('x-nonce', nonce);
  requestHeaders.set('Content-Security-Policy', csp);

  const { pathname } = request.nextUrl;
  const token = request.cookies.get(ADMIN_AUTH_COOKIE_KEY)?.value;
  const refreshToken = request.cookies.get(ADMIN_REFRESH_COOKIE_KEY)?.value;

  const next = () => applyCspHeaders(NextResponse.next({ request: { headers: requestHeaders } }), csp);

  if (pathname.startsWith('/dashboard')) {
    if (!token) {
      if (refreshToken) {
        const tokens = await refreshTokens(refreshToken);
        if (tokens) {
          const response = NextResponse.redirect(request.url);
          const secure = request.nextUrl.protocol === 'https:';
          response.cookies.set(ADMIN_AUTH_COOKIE_KEY, tokens.accessToken, {
            path: '/',
            maxAge: ACCESS_COOKIE_MAX_AGE,
            sameSite: 'lax',
            secure,
          });
          if (tokens.refreshToken) {
            response.cookies.set(ADMIN_REFRESH_COOKIE_KEY, tokens.refreshToken, {
              path: '/',
              maxAge: 7 * 24 * 60 * 60,
              sameSite: 'lax',
              secure,
            });
          }
          return applyCspHeaders(response, csp);
        }
      }
      return applyCspHeaders(NextResponse.redirect(new URL('/login', request.url)), csp);
    }

    const expMs = getTokenExpiryMs(token);
    if (expMs && refreshToken && Date.now() > expMs - REFRESH_THRESHOLD_MS) {
      const tokens = await refreshTokens(refreshToken);
      if (tokens) {
        const response = NextResponse.redirect(request.url);
        const secure = request.nextUrl.protocol === 'https:';
        response.cookies.set(ADMIN_AUTH_COOKIE_KEY, tokens.accessToken, {
          path: '/',
          maxAge: ACCESS_COOKIE_MAX_AGE,
          sameSite: 'lax',
          secure,
        });
        if (tokens.refreshToken) {
          response.cookies.set(ADMIN_REFRESH_COOKIE_KEY, tokens.refreshToken, {
            path: '/',
            maxAge: 7 * 24 * 60 * 60,
            sameSite: 'lax',
            secure,
          });
        }
        return applyCspHeaders(response, csp);
      }
    }
  }

  if (pathname === '/login' && token) {
    return applyCspHeaders(NextResponse.redirect(new URL('/dashboard', request.url)), csp);
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
