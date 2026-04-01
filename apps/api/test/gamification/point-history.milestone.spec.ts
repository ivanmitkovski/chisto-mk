import { GamificationService } from '../../src/gamification/gamification.service';
import { computeLevelMilestonesFromAscRows } from '../../src/gamification/point-history.service';

describe('computeLevelMilestonesFromAscRows', () => {
  const gamification = new GamificationService();

  it('returns empty when no positive deltas', () => {
    const t0 = new Date('2024-01-01T00:00:00.000Z');
    expect(
      computeLevelMilestonesFromAscRows(
        [
          { createdAt: t0, delta: 0 },
          { createdAt: t0, delta: -5 },
        ],
        gamification,
      ),
    ).toEqual([]);
  });

  it('records a milestone when XP crosses into the next level', () => {
    const need1 = gamification.xpToAdvanceFromLevel(1);
    const t0 = new Date('2024-01-01T12:00:00.000Z');
    const t1 = new Date('2024-01-02T12:00:00.000Z');
    const rows = [
      { createdAt: t0, delta: need1 - 1 },
      { createdAt: t1, delta: 2 },
    ];
    const m = computeLevelMilestonesFromAscRows(rows, gamification);
    expect(m).toHaveLength(1);
    expect(m[0].level).toBe(2);
    expect(m[0].reachedAt).toBe(t1.toISOString());
  });

  it('skips non-XP rows but still accumulates positive deltas', () => {
    const need1 = gamification.xpToAdvanceFromLevel(1);
    const t0 = new Date('2024-01-01T12:00:00.000Z');
    const rows = [{ createdAt: t0, delta: need1 }];
    const m = computeLevelMilestonesFromAscRows(rows, gamification);
    expect(m).toHaveLength(1);
    expect(m[0].level).toBe(2);
  });
});
