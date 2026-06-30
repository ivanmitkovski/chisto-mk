import { describe, expect, it } from 'vitest';
import { validateGamificationConfig } from './gamification-validation';

describe('validateGamificationConfig', () => {
  it('requires strictly increasing thresholds', () => {
    const error = validateGamificationConfig(
      { levelThresholds: [], pointValues: { FIRST_REPORT: 10 } },
      '0, 100, 50',
    );
    expect(error).toBe('thresholdIncreasing');
  });

  it('accepts valid config', () => {
    const error = validateGamificationConfig(
      { levelThresholds: [], pointValues: { FIRST_REPORT: 10 } },
      '0, 100, 250',
    );
    expect(error).toBeNull();
  });
});
