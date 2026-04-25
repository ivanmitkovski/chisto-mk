/**
 * Level design (aligned with mobile `profile_level_tier_icons.dart`).
 *
 * Levels 1–10: numeric tiers, unique XP steps per step.
 * Levels 11–50: named prestige tiers (40 names).
 * Level 51+: capped title "Chisto Legend" with continued XP scaling (soft cap).
 */

import {
  PRESTIGE_TIER_NAME_COUNT,
  resolveLevelDisplayTitle,
} from '../common/i18n/gamification-tier.copy';

export const NUMERIC_LEVEL_MAX = 10;

/** XP to advance from `level` → `level + 1` (1-based). */
export const NUMERIC_XP_STEPS: readonly number[] = [
  36, 42, 48, 56, 64, 74, 86, 100, 116, 134,
];

/** Stable keys: numeric_1 … numeric_10, prestige_01 … prestige_40, prestige_cap */
export function levelTierKey(level: number): string {
  if (level <= 0) return 'numeric_1';
  if (level <= NUMERIC_LEVEL_MAX) return `numeric_${level}`;
  const idx = level - NUMERIC_LEVEL_MAX - 1;
  if (idx < PRESTIGE_TIER_NAME_COUNT) {
    return `prestige_${String(idx + 1).padStart(2, '0')}`;
  }
  return 'prestige_cap';
}

/** Display title for API / clients; pass BCP-47 locale (`mk`, `mk-MK`, `en`, …). */
export function levelDisplayName(level: number, locale = 'en'): string {
  return resolveLevelDisplayTitle(level, locale);
}

export function xpToAdvanceFromLevel(level: number): number {
  if (level < 1) return NUMERIC_XP_STEPS[0]!;
  if (level <= NUMERIC_LEVEL_MAX) {
    const i = level - 1;
    return NUMERIC_XP_STEPS[i] ?? NUMERIC_XP_STEPS[NUMERIC_XP_STEPS.length - 1]!;
  }
  const prestigeIndex = level - NUMERIC_LEVEL_MAX;
  return Math.max(72, Math.floor(58 * Math.pow(prestigeIndex, 1.14)));
}
