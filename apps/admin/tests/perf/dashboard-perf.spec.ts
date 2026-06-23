import { authenticatedTest as test, expect } from '../fixtures/authenticated.fixture';

const ROUTE_BUDGET_MS = 15_000;

test.describe('Admin dashboard perf smoke', () => {
  test('dashboard home responds within budget', async ({ authenticatedPage: page }) => {
    const start = Date.now();
    await page.goto('/dashboard');
    await expect(page).toHaveURL(/\/dashboard/);
    await expect(page.getByRole('main')).toBeVisible();
    const elapsed = Date.now() - start;
    expect(elapsed).toBeLessThan(ROUTE_BUDGET_MS);
  });

  test('active-users responds within budget', async ({ authenticatedPage: page }) => {
    const start = Date.now();
    await page.goto('/dashboard/active-users');
    await expect(page).toHaveURL(/\/dashboard\/active-users/);
    await expect(page.getByRole('main')).toBeVisible();
    const elapsed = Date.now() - start;
    expect(elapsed).toBeLessThan(ROUTE_BUDGET_MS);
  });
});
