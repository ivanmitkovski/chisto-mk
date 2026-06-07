import { describe, expect, it } from 'vitest';
import {
  isBroadcastDeletable,
  isBroadcastEditable,
  parseAudienceUserIds,
  validateBroadcastForm,
} from '@/features/broadcasts/lib/broadcast-campaign-policy';

describe('broadcast-campaign-policy', () => {
  it('parses audience user ids', () => {
    expect(parseAudienceUserIds('a, b  c')).toEqual(['a', 'b', 'c']);
  });

  it('validates specific audience requires user ids', () => {
    expect(
      validateBroadcastForm({ title: 'T', body: 'B', audience: 'users', audienceUserIds: [] }),
    ).toBe('userIdsRequired');
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
