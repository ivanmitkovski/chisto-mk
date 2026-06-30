import { describe, expect, it } from 'vitest';
import { feedTypeLabelKey } from '../lib/feed-type-label';

describe('feedTypeLabelKey', () => {
  it('maps known feed types to i18n keys', () => {
    expect(feedTypeLabelKey('LOGIN')).toBe('feed.types.login');
    expect(feedTypeLabelKey('REPORT_SUBMITTED')).toBe('feed.types.reportSubmitted');
  });

  it('falls back for unknown types', () => {
    expect(feedTypeLabelKey('CUSTOM_EVENT')).toBe('feed.types.unknown');
  });
});
