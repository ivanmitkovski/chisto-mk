import type { BroadcastAudience } from '../types';

export const BROADCAST_AUDIENCE_VALUES: readonly BroadcastAudience[] = ['all', 'active', 'users'];

export const BROADCAST_STATUS_VALUES = ['draft', 'scheduled', 'sent', 'cancelled'] as const;

export function audienceTranslationKey(audience: BroadcastAudience): 'all' | 'active' | 'specific' {
  if (audience === 'users') return 'specific';
  return audience;
}

export function isBroadcastAudience(value: string): value is BroadcastAudience {
  return (BROADCAST_AUDIENCE_VALUES as readonly string[]).includes(value);
}

/** Coerce API/legacy campaign audience strings to a known broadcast audience. */
export function normalizeBroadcastAudience(value: string): BroadcastAudience {
  return isBroadcastAudience(value) ? value : 'all';
}
