import { serverAuthenticatedFetch } from '@/lib/auth/server-api-with-refresh';
import type { GamificationConfig, UserPointLedgerEntry, WeeklyRankingsResponse } from '../types';

export async function getGamificationConfig(): Promise<GamificationConfig> {
  return serverAuthenticatedFetch<GamificationConfig>('/admin/gamification/config', {
    method: 'GET',
  });
}

export async function getWeeklyRankings(
  limit = 50,
  weekStartsAt?: string,
): Promise<WeeklyRankingsResponse> {
  const search = new URLSearchParams({ limit: String(limit) });
  if (weekStartsAt) search.set('weekStartsAt', weekStartsAt);
  return serverAuthenticatedFetch<WeeklyRankingsResponse>(
    `/admin/gamification/rankings/weekly?${search.toString()}`,
    { method: 'GET' },
  );
}

export async function getUserPointLedger(userId: string, limit = 20, page = 1) {
  const search = new URLSearchParams({ limit: String(limit), page: String(page) });
  return serverAuthenticatedFetch<{ data: UserPointLedgerEntry[]; meta: { total: number; page: number; limit: number } }>(
    `/admin/gamification/users/${encodeURIComponent(userId)}/points?${search.toString()}`,
    { method: 'GET' },
  );
}
