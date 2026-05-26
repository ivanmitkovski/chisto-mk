import { expect, test } from '@playwright/test';

test.describe('Admin BFF auth smoke', () => {
  test('renders the secure login form', async ({ page }) => {
    await page.goto('/login');
    await page.waitForLoadState('networkidle');

    await expect(page.locator('#login-email')).toBeVisible();
    await expect(page.locator('#login-password')).toBeVisible();
    await expect(page.getByLabel(/remember this trusted device/i)).toBeVisible();
  });

  test('exposes a healthy admin BFF endpoint', async ({ request }) => {
    const response = await request.get('/api/health');
    expect(response.ok()).toBeTruthy();
    const body = (await response.json()) as { status?: string; service?: string };

    expect(body.status).toBe('ok');
    expect(body.service).toBe('chisto-admin-bff');
  });
});
