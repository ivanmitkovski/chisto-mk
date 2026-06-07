import type { BroadcastAudience } from '../types';

export const BROADCAST_AUDIENCE_VALUES: readonly BroadcastAudience[] = ['all', 'active', 'users'];

export const BROADCAST_STATUS_VALUES = ['draft', 'scheduled', 'sent', 'cancelled'] as const;

export function audienceTranslationKey(audience: BroadcastAudience): 'all' | 'active' | 'specific' {
  if (audience === 'users') return 'specific';
  return audience;
}
