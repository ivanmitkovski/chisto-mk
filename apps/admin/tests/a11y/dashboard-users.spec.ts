import AxeBuilder from '@axe-core/playwright';
import { authenticatedTest as test, expect } from '../fixtures/authenticated.fixture';

test.describe('Admin users list accessibility', () => {
  test('users route has no serious or critical axe violations', async ({ authenticatedPage: page }) => {
    await page.goto('/dashboard/users');
    await page.waitForLoadState('domcontentloaded');
    await page.waitForTimeout(700);

    const results = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa'])
      .analyze();

    const seriousOrCritical = results.violations.filter(
      (v) => v.impact === 'serious' || v.impact === 'critical',
    );
    expect(seriousOrCritical, JSON.stringify(seriousOrCritical, null, 2)).toEqual([]);
  });
});
