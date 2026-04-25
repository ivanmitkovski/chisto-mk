import { GamificationService } from '../../src/gamification/gamification.service';

describe('GamificationService', () => {
  const service = new GamificationService();

  describe('getLevelProgress', () => {
    it('starts at level 1 with zero XP', () => {
      const p = service.getLevelProgress(0);
      expect(p.level).toBe(1);
      expect(p.pointsInLevel).toBe(0);
      expect(p.pointsToNextLevel).toBe(service.xpToAdvanceFromLevel(1));
      expect(p.levelProgress).toBe(0);
      expect(p.levelTierKey).toBe('numeric_1');
      expect(p.levelDisplayName).toBe('Level 1');
    });

    it('moves to level 2 after completing level 1 segment', () => {
      const need1 = service.xpToAdvanceFromLevel(1);
      const atStartL2 = service.getLevelProgress(need1);
      expect(atStartL2.level).toBe(2);
      expect(atStartL2.pointsInLevel).toBe(0);
      expect(atStartL2.levelProgress).toBe(0);
    });

    it('clamps negative totals to zero', () => {
      const p = service.getLevelProgress(-5);
      expect(p.level).toBe(1);
      expect(p.pointsInLevel).toBe(0);
    });

    it('uses named prestige title from level 11', () => {
      let total = 0;
      for (let L = 1; L <= 10; L++) {
        total += service.xpToAdvanceFromLevel(L);
      }
      const p = service.getLevelProgress(total);
      expect(p.level).toBe(11);
      expect(p.levelTierKey).toBe('prestige_01');
      expect(p.levelDisplayName).toBe('River Watcher');
    });

    it('localizes prestige title for Macedonian locale', () => {
      let total = 0;
      for (let L = 1; L <= 10; L++) {
        total += service.xpToAdvanceFromLevel(L);
      }
      const p = service.getLevelProgress(total, 'mk-MK');
      expect(p.level).toBe(11);
      expect(p.levelDisplayName).toBe('Чувар на реката');
    });
  });
});
