/**
 * @vitest-environment jsdom
 */
import { describe, expect, it, vi } from 'vitest';
import { renderHook, waitFor } from '@testing-library/react';
import { useBroadcastCampaignForm } from './use-broadcast-campaign-form';

vi.mock('../data/broadcast-audience-api', () => ({
  lookupBroadcastAudienceUsers: vi.fn(),
}));

import { lookupBroadcastAudienceUsers } from '../data/broadcast-audience-api';

describe('useBroadcastCampaignForm', () => {
  it('hydrates selected users when editing a users campaign', async () => {
    vi.mocked(lookupBroadcastAudienceUsers).mockResolvedValue({
      users: [
        {
          id: 'user-1',
          firstName: 'Ada',
          lastName: 'Lovelace',
          email: 'ada@example.com',
          phoneNumber: '',
          status: 'ACTIVE',
        },
      ],
    });

    const { result } = renderHook(() => useBroadcastCampaignForm());

    await result.current.startEdit({
      id: 'campaign-1',
      title: 'Hello',
      body: 'World',
      type: 'SYSTEM',
      audience: 'users',
      audienceUserIds: ['user-1'],
      status: 'draft',
      createdAt: '2026-01-01T00:00:00.000Z',
      updatedAt: '2026-01-01T00:00:00.000Z',
    });

    await waitFor(() => {
      expect(result.current.values.selectedAudienceUsers).toEqual([
        { id: 'user-1', label: 'Ada Lovelace · ada@example.com' },
      ]);
    });
    expect(result.current.mode).toBe('edit');
    expect(result.current.parsedUserIds).toEqual(['user-1']);
  });
});
