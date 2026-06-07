import { describe, expect, it, vi } from 'vitest';

vi.mock('@/lib/auth/server-api-with-refresh', () => ({
  serverAuthenticatedFetch: vi.fn(),
}));

import { serverAuthenticatedFetch } from '@/lib/auth/server-api-with-refresh';
import { listBroadcastCampaigns } from '@/features/broadcasts/data/broadcasts-adapter';
import { getGamificationConfig } from '@/features/gamification/data/gamification-adapter';
import { getAppConfigSnapshot } from '@/features/app-config/data/app-config-adapter';

describe('broadcasts-adapter', () => {
  it('lists campaigns from admin API', async () => {
    vi.mocked(serverAuthenticatedFetch).mockResolvedValue([
      { id: '1', title: 'Test', body: 'Hi', audience: 'all', status: 'draft' },
    ]);
    const rows = await listBroadcastCampaigns();
    expect(serverAuthenticatedFetch).toHaveBeenCalledWith(
      '/admin/broadcasts',
      expect.objectContaining({ method: 'GET' }),
    );
    expect(rows).toHaveLength(1);
  });
});

describe('gamification-adapter', () => {
  it('loads gamification config', async () => {
    vi.mocked(serverAuthenticatedFetch).mockResolvedValue({
      levelThresholds: [100],
      pointValues: { report: 10 },
    });
    const config = await getGamificationConfig();
    expect(serverAuthenticatedFetch).toHaveBeenCalledWith(
      '/admin/gamification/config',
      expect.objectContaining({ method: 'GET' }),
    );
    expect(config.pointValues.report).toBe(10);
  });
});

describe('app-config-adapter', () => {
  it('loads combined app config snapshot', async () => {
    vi.mocked(serverAuthenticatedFetch)
      .mockResolvedValueOnce({ dailyCredits: 5, emergencyWindowHours: 24, refillIntervalHours: 12 })
      .mockResolvedValueOnce({ defaultVariant: 'control', experimentEnabled: false })
      .mockResolvedValueOnce({ version: '2026-01' })
      .mockResolvedValueOnce({ questions: [] });
    const snapshot = await getAppConfigSnapshot();
    expect(snapshot.termsVersion).toBe('2026-01');
    expect(snapshot.feedRanking.defaultVariant).toBe('control');
    expect(snapshot.organizerQuiz).toEqual({ questions: [] });
  });
});
