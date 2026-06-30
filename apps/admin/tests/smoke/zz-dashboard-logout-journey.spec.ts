import { authenticatedTest as test, expect } from '../fixtures/authenticated.fixture';

test.describe('Admin dashboard smoke journey', () => {
  test('overview to reports and back through logout', async ({ authenticatedPage: page }) => {
    await page.goto('/dashboard');
    await expect(page).toHaveURL(/\/dashboard/);

    await page.getByRole('link', { name: /reports/i }).first().click();
    await page.waitForURL('**/dashboard/reports**');
    await expect(
      page.getByRole('searchbox', { name: /search reports by name, location, or number/i }),
    ).toBeVisible();

    await page.getByRole('button', { name: /^profile$/i }).click();
    await page.getByRole('menuitem', { name: /^sign out$/i }).click();
    await page.waitForURL('**/login**');
    await expect(page.locator('#login-email')).toBeVisible();
  });
});
