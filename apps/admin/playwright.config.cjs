/* eslint-disable @typescript-eslint/no-require-imports */
const path = require('node:path');
const { defineConfig, devices } = require('@playwright/test');

const rootDir = __dirname;

module.exports = defineConfig({
  testDir: path.join(rootDir, 'tests'),
  globalSetup: path.join(rootDir, 'tests/global-setup.ts'),
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  use: {
    ...devices['Desktop Chrome'],
    baseURL: process.env.ADMIN_E2E_BASE_URL ?? 'http://127.0.0.1:3001',
    trace: 'on-first-retry',
  },
  ...(process.env.CI
    ? {}
    : {
        webServer: {
          command: 'pnpm build && pnpm exec next start -p 3001',
          cwd: rootDir,
          url: 'http://127.0.0.1:3001',
          reuseExistingServer: true,
          timeout: 180_000,
        },
      }),
});
