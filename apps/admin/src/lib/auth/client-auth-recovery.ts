'use client';

import { getAdminCsrfHeaders } from '@/lib/auth/csrf-headers';
import { ApiError } from '@/lib/api';

export type RefreshSessionOutcome = 'ok' | 'unauthorized' | 'transient';

let refreshInFlight: Promise<RefreshSessionOutcome> | null = null;

async function refreshAdminSessionOnce(): Promise<RefreshSessionOutcome> {
  const response = await fetch('/api/auth/refresh', {
    method: 'POST',
    headers: getAdminCsrfHeaders(),
    credentials: 'include',
  }).catch(() => null);

  if (response?.ok === true) return 'ok';
  if (response?.status === 401) return 'unauthorized';
  if (
    response?.status === 403 ||
    response?.status === 429 ||
    response?.status === 503 ||
    response == null
  ) {
    return 'transient';
  }
  return 'unauthorized';
}

async function signOutAndRedirectToLogin(): Promise<void> {
  try {
    await fetch('/api/auth/logout', {
      method: 'POST',
      headers: getAdminCsrfHeaders(),
      credentials: 'include',
    });
  } catch {
    // Still redirect — route may have partially cleared cookies.
  }
  window.location.assign('/login');
}

async function refreshOnce(): Promise<RefreshSessionOutcome> {
  if (refreshInFlight) return refreshInFlight;
  refreshInFlight = (async () => {
    const first = await refreshAdminSessionOnce();
    if (first !== 'transient') return first;
    // CSRF cookie may have been re-issued by middleware/BFF; retry once with fresh header.
    const retry = await refreshAdminSessionOnce();
    return retry;
  })().finally(() => {
    refreshInFlight = null;
  });
  return refreshInFlight;
}

/** Refresh session once; sign out only when refresh is definitively unauthorized (401). */
export async function recoverFromUnauthorized(): Promise<boolean> {
  const outcome = await refreshOnce();
  if (outcome === 'ok') return true;
  if (outcome === 'transient') return false;
  await signOutAndRedirectToLogin();
  return false;
}

export function isUnauthorizedApiError(error: unknown): error is ApiError {
  return error instanceof ApiError && error.status === 401;
}

export async function handleQueryUnauthorized(error: unknown): Promise<void> {
  if (!isUnauthorizedApiError(error)) return;
  await recoverFromUnauthorized();
}
