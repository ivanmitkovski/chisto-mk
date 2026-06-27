import { test as base, expect, type Page } from '@playwright/test';
import { hasAdminE2ECredentials } from './auth';

export const authenticatedTest = base.extend<{ authenticatedPage: Page }>({
  authenticatedPage: async ({ page }, use, testInfo) => {
    if (!hasAdminE2ECredentials()) {
      testInfo.skip(true, 'Set ADMIN_E2E_EMAIL and ADMIN_E2E_PASSWORD to run authenticated E2E tests.');
    }
    await use(page);
  },
});

export { expect };
