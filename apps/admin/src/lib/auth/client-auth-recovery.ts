'use client';

import { getAdminCsrfHeaders } from '@/lib/auth/csrf-headers';
import { ApiError } from '@/lib/api';

let refreshInFlight: Promise<'ok' | 'unauthorized' | 'network'> | null = null;

async function refreshAdminSessionOnce(): Promise<'ok' | 'unauthorized' | 'network'> {
  const response = await fetch('/api/auth/refresh', {
    method: 'POST',
    headers: getAdminCsrfHeaders(),
    credentials: 'include',
  }).catch(() => null);

  if (response?.ok === true) return 'ok';
  if (response?.status === 503) return 'network';
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

async function refreshOnce(): Promise<'ok' | 'unauthorized' | 'network'> {
  if (refreshInFlight) return refreshInFlight;
  refreshInFlight = refreshAdminSessionOnce().finally(() => {
    refreshInFlight = null;
  });
  return refreshInFlight;
}

/** Refresh session once; sign out only when refresh is definitively unauthorized. */
export async function recoverFromUnauthorized(): Promise<boolean> {
  const outcome = await refreshOnce();
  if (outcome === 'ok') return true;
  if (outcome === 'network') return false;
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
