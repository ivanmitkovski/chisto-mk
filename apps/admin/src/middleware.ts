import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { ADMIN_AUTH_COOKIE_KEY, ADMIN_REFRESH_COOKIE_KEY } from '@/features/auth/lib/auth-constants';
const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:3000';
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
    const res = await fetch(`${API_BASE_URL}/auth/refresh`, {
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

export async function middleware(request: NextRequest) {
  const token = request.cookies.get(ADMIN_AUTH_COOKIE_KEY)?.value;
  const refreshToken = request.cookies.get(ADMIN_REFRESH_COOKIE_KEY)?.value;
  const { pathname } = request.nextUrl;

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
          return response;
        }
      }
      return NextResponse.redirect(new URL('/login', request.url));
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
        return response;
      }
    }
  }

  if (pathname === '/login' && token) {
    return NextResponse.redirect(new URL('/dashboard', request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/dashboard/:path*', '/login'],
};
