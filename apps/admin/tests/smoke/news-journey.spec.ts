import { authenticatedTest as test, expect } from '../fixtures/authenticated.fixture';

test.describe('News admin smoke', () => {
  test('news list loads for authenticated admin', async ({ authenticatedPage: page }) => {
    await page.goto('/dashboard/news');
    await page.waitForURL('**/dashboard/news**');
    await expect(page.getByRole('heading', { name: /news/i }).first()).toBeVisible();
  });

  test('create draft and open editor', async ({ authenticatedPage: page }) => {
    await page.goto('/dashboard/news/new');
    await page.waitForURL('**/dashboard/news/new**');
    await page.getByLabel(/title/i).first().fill('Smoke test draft');
    await page.getByRole('button', { name: /create draft/i }).click();
    await page.waitForURL('**/dashboard/news/**');
    await expect(page.getByRole('heading').first()).toBeVisible();
  });
});
