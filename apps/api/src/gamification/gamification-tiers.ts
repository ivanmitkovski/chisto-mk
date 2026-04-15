/**
 * Level design (aligned with mobile `profile_level_tier_icons.dart`).
 *
 * Levels 1–10: numeric tiers, unique XP steps per step.
 * Levels 11–50: named prestige tiers (40 names).
 * Level 51+: capped title "Chisto Legend" with continued XP scaling (soft cap).
 */

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
  if (idx < PRESTIGE_TIER_NAMES.length) {
    return `prestige_${String(idx + 1).padStart(2, '0')}`;
  }
  return 'prestige_cap';
}

/** English display title (mobile may localize via tierKey). */
export function levelDisplayName(level: number): string {
  if (level <= 0) return 'Level 1';
  if (level <= NUMERIC_LEVEL_MAX) return `Level ${level}`;
  const idx = level - NUMERIC_LEVEL_MAX - 1;
  if (idx < PRESTIGE_TIER_NAMES.length) {
    return PRESTIGE_TIER_NAMES[idx]!;
  }
  return 'Chisto Legend';
}

const PRESTIGE_TIER_NAMES: readonly string[] = [
  'River Watcher',
  'Valley Keeper',
  'Field Guardian',
  'Grove Sentinel',
  'Sky Steward',
  'Trail Blazer',
  'Spring Voice',
  'Stone Warden',
  'Meadow Herald',
  'Ridge Runner',
  'Creek Protector',
  'Hill Watcher',
  'Canopy Ally',
  'Soil Advocate',
  'Wind Listener',
  'Dawn Patroller',
  'Dusk Ranger',
  'Wild Path Guide',
  'Clear Water Knight',
  'Green Belt Champion',
  'Urban Roots Ally',
  'Park Keeper',
  'Riverbank Defender',
  'Summit Scout',
  'Valley Voice',
  'Eco Cartographer',
  'Cleanup Captain',
  'Circle Steward',
  'Harbor Helper',
  'Plains Protector',
  'Forest Friend',
  'Lake Lookout',
  'Mountain Mate',
  'City Green Lead',
  'Neighborhood Naturalist',
  'Citizen Scientist',
  'Climate Courier',
  'Zero-Waste Warrior',
  'Circular Economy Sage',
  'Planet Partner',
];

export function xpToAdvanceFromLevel(level: number): number {
  if (level < 1) return NUMERIC_XP_STEPS[0]!;
  if (level <= NUMERIC_LEVEL_MAX) {
    const i = level - 1;
    return NUMERIC_XP_STEPS[i] ?? NUMERIC_XP_STEPS[NUMERIC_XP_STEPS.length - 1]!;
  }
  const prestigeIndex = level - NUMERIC_LEVEL_MAX;
  return Math.max(72, Math.floor(58 * Math.pow(prestigeIndex, 1.14)));
}
