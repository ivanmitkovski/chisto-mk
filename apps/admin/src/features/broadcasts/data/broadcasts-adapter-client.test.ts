import { describe, expect, it, vi } from 'vitest';

vi.mock('@/lib/api', () => ({
  adminBrowserFetch: vi.fn(),
}));

import { adminBrowserFetch } from '@/lib/api';
import { createBroadcastCampaign } from '@/features/broadcasts/data/broadcasts-adapter-client';

describe('broadcasts-adapter-client', () => {
  it('builds audienceUserIds from selected users', async () => {
    vi.mocked(adminBrowserFetch).mockResolvedValue({ id: '1' });

    await createBroadcastCampaign({
      title: 'Hello',
      body: 'World',
      audience: 'users',
      selectedAudienceUsers: [
        { id: 'user-1', label: 'Ada Lovelace · ada@example.com' },
        { id: 'user-2', label: 'Grace Hopper · grace@example.com' },
      ],
      deeplink: '',
      scheduledAt: '',
    });

    expect(adminBrowserFetch).toHaveBeenCalledWith('/admin/broadcasts', {
      method: 'POST',
      body: {
        title: 'Hello',
        body: 'World',
        audience: 'users',
        audienceUserIds: ['user-1', 'user-2'],
      },
    });
  });
});
