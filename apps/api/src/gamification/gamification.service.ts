import { Injectable } from '@nestjs/common';

import {
  levelDisplayName,
  levelTierKey,
  xpToAdvanceFromLevel as xpStepForLevel,
} from './gamification-tiers';

/**
 * Level curve and titles (server source of truth for mobile profile).
 * Co-reporting does not grant XP; only first approved report per site does.
 */
@Injectable()
export class GamificationService {
  /** XP required to move from `level` to `level + 1` (1-based level). */
  xpToAdvanceFromLevel(level: number): number {
    return xpStepForLevel(level);
  }

  getLevelProgress(totalPointsEarned: number): {
    level: number;
    pointsInLevel: number;
    pointsToNextLevel: number;
    levelProgress: number;
    levelTierKey: string;
    levelDisplayName: string;
  } {
    const total = Math.max(0, Math.floor(totalPointsEarned));
    let level = 1;
    let segmentStart = 0;
    const maxIterations = 50_000;

    for (let i = 0; i < maxIterations; i++) {
      const need = xpStepForLevel(level);
      if (total < segmentStart + need) {
        const pointsInLevel = total - segmentStart;
        const pointsToNextLevel = segmentStart + need - total;
        return {
          level,
          pointsInLevel,
          pointsToNextLevel,
          levelProgress: need > 0 ? pointsInLevel / need : 1,
          levelTierKey: levelTierKey(level),
          levelDisplayName: levelDisplayName(level),
        };
      }
      segmentStart += need;
      level++;
    }

    return {
      level,
      pointsInLevel: 0,
      pointsToNextLevel: xpStepForLevel(level),
      levelProgress: 0,
      levelTierKey: levelTierKey(level),
      levelDisplayName: levelDisplayName(level),
    };
  }
}
