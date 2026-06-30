import { serverAuthenticatedFetch } from '@/lib/auth/server-api-with-refresh';
import type { AppConfigSnapshot, FeedRankingConfig, ReportCreditsConfig } from '../types';

export async function getAppConfigSnapshot(): Promise<AppConfigSnapshot> {
  const [reportCredits, feedRanking, terms, organizerQuiz] = await Promise.all([
    serverAuthenticatedFetch<ReportCreditsConfig>('/admin/app-config/report-credits', {
      method: 'GET',
    }),
    serverAuthenticatedFetch<FeedRankingConfig>('/admin/app-config/feed-ranking', {
      method: 'GET',
    }),
    serverAuthenticatedFetch<{ version: string }>('/admin/app-config/terms-version', {
      method: 'GET',
    }),
    serverAuthenticatedFetch<Record<string, unknown>>('/admin/app-config/organizer-quiz?locale=en', {
      method: 'GET',
    }),
  ]);

  return {
    reportCredits,
    feedRanking,
    termsVersion: terms.version,
    organizerQuiz,
  };
}
