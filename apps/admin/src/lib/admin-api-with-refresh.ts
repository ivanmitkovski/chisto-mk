import { NextRequest, NextResponse } from 'next/server';
import { ADMIN_AUTH_COOKIE_KEY, ADMIN_REFRESH_COOKIE_KEY } from '@/features/auth/lib/auth-constants';
import { getApiBaseUrl } from '@/lib/api-base-url';

type RequestInitWithBody = RequestInit & { body?: unknown };

async function doRefresh(refreshToken: string): Promise<{ accessToken: string; refreshToken?: string } | null> {
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

function applyTokenCookies(
  response: NextResponse,
  tokens: { accessToken: string; refreshToken?: string },
  request: NextRequest,
) {
  const secure = request.nextUrl.protocol === 'https:';
  response.cookies.set(ADMIN_AUTH_COOKIE_KEY, tokens.accessToken, {
    path: '/',
    maxAge: 15 * 60, // 15 min, aligned with JWT access expiry
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
}

export async function fetchBackendWithRefresh(
  path: string,
  request: NextRequest,
  init: RequestInitWithBody = {},
): Promise<{ response: Response; nextResponse: NextResponse }> {
  const accessToken = request.cookies.get(ADMIN_AUTH_COOKIE_KEY)?.value ?? null;
  const refreshToken = request.cookies.get(ADMIN_REFRESH_COOKIE_KEY)?.value ?? null;

  const url = `${getApiBaseUrl()}${path}`;
  const headers: Record<string, string> = {
    Accept: 'application/json',
    ...((init.headers as Record<string, string>) ?? {}),
  };
  if (accessToken) {
    headers.Authorization = `Bearer ${accessToken}`;
  }
  if (init.body !== undefined) {
    headers['Content-Type'] = 'application/json';
  }

  const { body: bodyVal, ...restInit } = init;
  const fetchInit: RequestInit = {
    ...restInit,
    headers,
    cache: 'no-store',
  };
  if (bodyVal !== undefined) {
    (fetchInit as RequestInit & { body: string }).body =
      typeof bodyVal === 'string' ? bodyVal : JSON.stringify(bodyVal);
  }

  let res = await fetch(url, fetchInit);

  if (res.status === 401 && refreshToken) {
    const tokens = await doRefresh(refreshToken);
    if (tokens) {
      headers.Authorization = `Bearer ${tokens.accessToken}`;
      res = await fetch(url, fetchInit);
      const payload = await res.json().catch(() => ({}));
      const nextRes = NextResponse.json(payload, { status: res.status });
      applyTokenCookies(nextRes, tokens, request);
      return { response: res, nextResponse: nextRes };
    }
  }

  const payload = await res.json().catch(() => ({}));
  return { response: res, nextResponse: NextResponse.json(payload, { status: res.status }) };
}
