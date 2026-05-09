import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { defineConfig, devices } from '@playwright/test';

const rootDir = path.dirname(fileURLToPath(import.meta.url));

export default defineConfig({
  testDir: path.join(rootDir, 'tests'),
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  use: {
    ...devices['Desktop Chrome'],
    baseURL: process.env.ADMIN_E2E_BASE_URL ?? 'http://127.0.0.1:3001',
    trace: 'on-first-retry',
  },
  webServer: process.env.CI
    ? undefined
    : {
        command: 'pnpm build && pnpm exec next start -p 3001',
        cwd: rootDir,
        url: 'http://127.0.0.1:3001',
        reuseExistingServer: true,
        timeout: 180_000,
      },
});
