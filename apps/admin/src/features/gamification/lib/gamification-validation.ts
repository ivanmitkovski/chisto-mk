import type { GamificationConfig } from '../types';

export type GamificationValidationError =
  | 'thresholdRequired'
  | 'thresholdNonNegative'
  | 'thresholdIncreasing'
  | 'actionRequired'
  | 'actionKeyFormat'
  | 'pointsNonNegative';

export function parseLevelThresholds(text: string): number[] {
  return text
    .split(',')
    .map((value) => Number(value.trim()))
    .filter((value) => Number.isFinite(value));
}

export function validateGamificationConfig(
  config: GamificationConfig,
  thresholdsText: string,
): GamificationValidationError | null {
  const thresholds = parseLevelThresholds(thresholdsText);
  if (thresholds.length === 0) {
    return 'thresholdRequired';
  }
  if (thresholds.some((value) => !Number.isInteger(value) || value < 0)) {
    return 'thresholdNonNegative';
  }
  for (let i = 1; i < thresholds.length; i += 1) {
    if (thresholds[i] <= thresholds[i - 1]) {
      return 'thresholdIncreasing';
    }
  }

  const keys = Object.keys(config.pointValues);
  if (keys.length === 0) {
    return 'actionRequired';
  }
  if (keys.some((key) => !/^[A-Z][A-Z0-9_]*$/.test(key))) {
    return 'actionKeyFormat';
  }
  if (Object.values(config.pointValues).some((value) => !Number.isFinite(value) || value < 0)) {
    return 'pointsNonNegative';
  }

  return null;
}
