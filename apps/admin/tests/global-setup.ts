import fs from 'node:fs';
import path from 'node:path';
import { chromium, type FullConfig } from '@playwright/test';
import { hasAdminE2ECredentials, loginAsAdmin } from './fixtures/auth';

const authFile = path.join(__dirname, '.auth/admin.json');

export default async function globalSetup(config: FullConfig): Promise<void> {
  if (!hasAdminE2ECredentials()) {
    return;
  }

  fs.mkdirSync(path.dirname(authFile), { recursive: true });

  const baseURL =
    config.projects[0]?.use?.baseURL ??
    process.env.ADMIN_E2E_BASE_URL ??
    'http://127.0.0.1:3001';

  const browser = await chromium.launch();
  const context = await browser.newContext({ baseURL });
  const page = await context.newPage();
  await loginAsAdmin(page);
  await context.storageState({ path: authFile });
  await browser.close();
}
