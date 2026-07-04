import { authenticatedTest as test, expect } from '../fixtures/authenticated.fixture';

test.describe('News admin smoke', () => {
  test.describe.configure({ mode: 'serial' });

  test('news list loads for authenticated admin', async ({ authenticatedPage: page }) => {
    await page.goto('/dashboard/news');
    await page.waitForURL('**/dashboard/news**');
    await expect(page.getByRole('heading', { name: /news/i }).first()).toBeVisible();
  });

  test('create draft and open editor', async ({ authenticatedPage: page }) => {
    await page.goto('/dashboard/news/new');
    const titleField = page.getByRole('textbox', { name: /^title$/i });
    await expect(titleField).toBeVisible({ timeout: 15_000 });
    await titleField.fill('Smoke test draft');
    await page.getByRole('button', { name: /create draft/i }).click();
    await page.waitForURL(/\/dashboard\/news\/(?!new)/);
    await expect(page.getByRole('heading').first()).toBeVisible();
    await expect(page.getByRole('button', { name: /publish/i })).toBeVisible();
    await expect(page.getByRole('button', { name: /^update$/i })).toHaveCount(0);
  });
});

