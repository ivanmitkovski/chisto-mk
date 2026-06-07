import type { Page } from '@playwright/test';

export const ADMIN_E2E_EMAIL = process.env.ADMIN_E2E_EMAIL?.trim() ?? '';
export const ADMIN_E2E_PASSWORD = process.env.ADMIN_E2E_PASSWORD?.trim() ?? '';

export function hasAdminE2ECredentials(): boolean {
  return ADMIN_E2E_EMAIL.length > 0 && ADMIN_E2E_PASSWORD.length > 0;
}

export async function loginAsAdmin(page: Page): Promise<void> {
  if (!hasAdminE2ECredentials()) {
    throw new Error('ADMIN_E2E_EMAIL and ADMIN_E2E_PASSWORD are required for authenticated E2E tests.');
  }

  await page.goto('/login');
  await page.locator('#login-email').fill(ADMIN_E2E_EMAIL);
  await page.locator('#login-password').fill(ADMIN_E2E_PASSWORD);
  await page.getByRole('button', { name: /sign in/i }).click();
  await page.waitForURL('**/dashboard**', { timeout: 30_000 });
}
