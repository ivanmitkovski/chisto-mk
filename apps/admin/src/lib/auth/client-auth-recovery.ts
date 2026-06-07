'use client';

import { ApiError } from '@/lib/api';
import { getAdminCsrfHeaders } from '@/lib/auth/csrf-headers';

let refreshInFlight: Promise<boolean> | null = null;

async function refreshAdminSession(): Promise<boolean> {
  const response = await fetch('/api/auth/refresh', {
    method: 'POST',
    headers: getAdminCsrfHeaders(),
    credentials: 'include',
  }).catch(() => null);
  return response?.ok === true;
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

async function refreshOnce(): Promise<boolean> {
  if (refreshInFlight) return refreshInFlight;
  refreshInFlight = refreshAdminSession().finally(() => {
    refreshInFlight = null;
  });
  return refreshInFlight;
}

/** Refresh session once; sign out when refresh fails. Returns whether the caller should retry. */
export async function recoverFromUnauthorized(): Promise<boolean> {
  const refreshed = await refreshOnce();
  if (refreshed) return true;
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
