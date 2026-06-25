import path from 'node:path';
import { test as base, expect, type Page } from '@playwright/test';
import { hasAdminE2ECredentials } from './auth';

const authStatePath = path.join(__dirname, '.auth/admin.json');

export const authenticatedTest = base.extend<{ authenticatedPage: Page }>({
  authenticatedPage: async ({ browser }, use, testInfo) => {
    if (!hasAdminE2ECredentials()) {
      testInfo.skip(true, 'Set ADMIN_E2E_EMAIL and ADMIN_E2E_PASSWORD to run authenticated E2E tests.');
    }
    const context = await browser.newContext({ storageState: authStatePath });
    const page = await context.newPage();
    try {
      await use(page);
    } finally {
      await context.close();
    }
  },
});

export { expect };
