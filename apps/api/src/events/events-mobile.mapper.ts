import {
  EcoCleanupScale,
  EcoEventCategory,
  EcoEventDifficulty,
  EcoEventLifecycleStatus,
} from '../prisma-client';

const LIFECYCLE_TO_MOBILE: Record<EcoEventLifecycleStatus, string> = {
  [EcoEventLifecycleStatus.UPCOMING]: 'upcoming',
  [EcoEventLifecycleStatus.IN_PROGRESS]: 'inProgress',
  [EcoEventLifecycleStatus.COMPLETED]: 'completed',
  [EcoEventLifecycleStatus.CANCELLED]: 'cancelled',
};

const MOBILE_TO_LIFECYCLE: Record<string, EcoEventLifecycleStatus> = {
  upcoming: EcoEventLifecycleStatus.UPCOMING,
  inProgress: EcoEventLifecycleStatus.IN_PROGRESS,
  completed: EcoEventLifecycleStatus.COMPLETED,
  cancelled: EcoEventLifecycleStatus.CANCELLED,
};

const CATEGORY_TO_MOBILE: Record<EcoEventCategory, string> = {
  [EcoEventCategory.GENERAL_CLEANUP]: 'generalCleanup',
  [EcoEventCategory.RIVER_AND_LAKE]: 'riverAndLake',
  [EcoEventCategory.TREE_AND_GREEN]: 'treeAndGreen',
  [EcoEventCategory.RECYCLING_DRIVE]: 'recyclingDrive',
  [EcoEventCategory.HAZARDOUS_REMOVAL]: 'hazardousRemoval',
  [EcoEventCategory.AWARENESS_AND_EDUCATION]: 'awarenessAndEducation',
  [EcoEventCategory.OTHER]: 'other',
};

const MOBILE_TO_CATEGORY: Record<string, EcoEventCategory> = {
  generalCleanup: EcoEventCategory.GENERAL_CLEANUP,
  riverAndLake: EcoEventCategory.RIVER_AND_LAKE,
  treeAndGreen: EcoEventCategory.TREE_AND_GREEN,
  recyclingDrive: EcoEventCategory.RECYCLING_DRIVE,
  hazardousRemoval: EcoEventCategory.HAZARDOUS_REMOVAL,
  awarenessAndEducation: EcoEventCategory.AWARENESS_AND_EDUCATION,
  other: EcoEventCategory.OTHER,
};

const SCALE_TO_MOBILE: Record<EcoCleanupScale, string> = {
  [EcoCleanupScale.SMALL]: 'small',
  [EcoCleanupScale.MEDIUM]: 'medium',
  [EcoCleanupScale.LARGE]: 'large',
  [EcoCleanupScale.MASSIVE]: 'massive',
};

const MOBILE_TO_SCALE: Record<string, EcoCleanupScale> = {
  small: EcoCleanupScale.SMALL,
  medium: EcoCleanupScale.MEDIUM,
  large: EcoCleanupScale.LARGE,
  massive: EcoCleanupScale.MASSIVE,
};

const DIFFICULTY_TO_MOBILE: Record<EcoEventDifficulty, string> = {
  [EcoEventDifficulty.EASY]: 'easy',
  [EcoEventDifficulty.MODERATE]: 'moderate',
  [EcoEventDifficulty.HARD]: 'hard',
};

const MOBILE_TO_DIFFICULTY: Record<string, EcoEventDifficulty> = {
  easy: EcoEventDifficulty.EASY,
  moderate: EcoEventDifficulty.MODERATE,
  hard: EcoEventDifficulty.HARD,
};

/** Allowed gear keys aligned with mobile [EventGear.name]. */
export const ALLOWED_GEAR_KEYS = new Set([
  'trashBags',
  'gloves',
  'rakes',
  'wheelbarrow',
  'waterBoots',
  'safetyVest',
  'firstAid',
  'sunscreen',
]);

export const MOBILE_CATEGORY_KEYS = Object.keys(MOBILE_TO_CATEGORY);

export function lifecycleToMobile(status: EcoEventLifecycleStatus): string {
  return LIFECYCLE_TO_MOBILE[status];
}

export function lifecycleFromMobile(raw: string): EcoEventLifecycleStatus | null {
  return MOBILE_TO_LIFECYCLE[raw] ?? null;
}

export function categoryToMobile(category: EcoEventCategory): string {
  return CATEGORY_TO_MOBILE[category];
}

export function categoryFromMobile(raw: string): EcoEventCategory | null {
  return MOBILE_TO_CATEGORY[raw] ?? null;
}

export function scaleToMobile(scale: EcoCleanupScale | null): string | null {
  if (scale == null) {
    return null;
  }
  return SCALE_TO_MOBILE[scale];
}

export function scaleFromMobile(raw: string | undefined): EcoCleanupScale | null {
  if (raw == null || raw === '') {
    return null;
  }
  return MOBILE_TO_SCALE[raw] ?? null;
}

export function difficultyToMobile(difficulty: EcoEventDifficulty | null): string | null {
  if (difficulty == null) {
    return null;
  }
  return DIFFICULTY_TO_MOBILE[difficulty];
}

export function difficultyFromMobile(raw: string | undefined): EcoEventDifficulty | null {
  if (raw == null || raw === '') {
    return null;
  }
  return MOBILE_TO_DIFFICULTY[raw] ?? null;
}

export function parseLifecycleFilterList(raw: string | undefined): EcoEventLifecycleStatus[] | null {
  if (raw == null || raw.trim() === '') {
    return null;
  }
  const parts = raw.split(',').map((p) => p.trim()).filter(Boolean);
  const out: EcoEventLifecycleStatus[] = [];
  for (const p of parts) {
    const v = lifecycleFromMobile(p);
    if (v == null) {
      return null;
    }
    out.push(v);
  }
  return out;
}

/** Comma-separated mobile category keys (e.g. `riverAndLake,treeAndGreen`). Deduped. */
export function parseCategoryFilterList(raw: string | undefined): EcoEventCategory[] | null {
  if (raw == null || raw.trim() === '') {
    return null;
  }
  const parts = raw
    .split(',')
    .map((p) => p.trim())
    .filter(Boolean);
  const seen = new Set<EcoEventCategory>();
  const out: EcoEventCategory[] = [];
  for (const p of parts) {
    const v = categoryFromMobile(p);
    if (v == null) {
      return null;
    }
    if (!seen.has(v)) {
      seen.add(v);
      out.push(v);
    }
  }
  return out;
}

export function normalizeGearKeys(raw: string[] | undefined): string[] {
  if (!raw?.length) {
    return [];
  }
  const seen = new Set<string>();
  const out: string[] = [];
  for (const g of raw) {
    const key = g.trim();
    if (!ALLOWED_GEAR_KEYS.has(key) || seen.has(key)) {
      continue;
    }
    seen.add(key);
    out.push(key);
  }
  return out;
}
