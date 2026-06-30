import { describe, expect, it } from 'vitest';
import {
  filterCampaignsByStatus,
  isBroadcastDeletable,
  isBroadcastEditable,
  parseAudienceUserIds,
  validateBroadcastForm,
} from '@/features/broadcasts/lib/broadcast-campaign-policy';

describe('broadcast-campaign-policy', () => {
  it('parses audience user ids', () => {
    expect(parseAudienceUserIds('a, b  c')).toEqual(['a', 'b', 'c']);
  });

  it('validates specific audience requires selected users', () => {
    expect(
      validateBroadcastForm({ title: 'T', body: 'B', audience: 'users', audienceUserIds: [] }),
    ).toBe('usersRequired');
  });

  it('rejects schedule in the past', () => {
    expect(
      validateBroadcastForm({
        title: 'T',
        body: 'B',
        audience: 'all',
        audienceUserIds: [],
        scheduledAt: '2020-01-01T10:00',
      }),
    ).toBe('scheduleInPast');
  });

  it('filters campaigns by status', () => {
    const campaigns = [
      { id: '1', status: 'draft' },
      { id: '2', status: 'sent' },
    ];
    expect(filterCampaignsByStatus(campaigns, 'sent')).toEqual([{ id: '2', status: 'sent' }]);
    expect(filterCampaignsByStatus(campaigns, 'all')).toHaveLength(2);
  });

  it('allows edit for draft and scheduled only', () => {
    expect(isBroadcastEditable('draft')).toBe(true);
    expect(isBroadcastEditable('scheduled')).toBe(true);
    expect(isBroadcastEditable('sent')).toBe(false);
  });

  it('blocks delete for sent campaigns', () => {
    expect(isBroadcastDeletable('sent')).toBe(false);
    expect(isBroadcastDeletable('draft')).toBe(true);
  });
});
