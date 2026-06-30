import AxeBuilder from '@axe-core/playwright';
import { authenticatedTest as test, expect } from '../fixtures/authenticated.fixture';

test.describe('Admin map accessibility', () => {
  test('dashboard map route has no serious or critical axe violations', async ({ authenticatedPage: page }) => {
    await page.goto('/dashboard/map');
    await page.waitForLoadState('domcontentloaded');
    await page.waitForTimeout(700);

    const results = await new AxeBuilder({ page })
      // Leaflet raster tiles use decorative imagery without alt text.
      .disableRules(['image-alt'])
      .withTags(['wcag2a', 'wcag2aa'])
      .analyze();

    const seriousOrCritical = results.violations.filter(
      (v) => v.impact === 'serious' || v.impact === 'critical',
    );
    expect(seriousOrCritical, JSON.stringify(seriousOrCritical, null, 2)).toEqual([]);
  });
});
