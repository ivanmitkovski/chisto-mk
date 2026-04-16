import { defineConfig, devices } from "@playwright/test";

/** Dedicated port so `pnpm dev` on 3002 does not collide with E2E. */
const port = process.env.PLAYWRIGHT_PORT ?? "3333";
const baseURL = process.env.PLAYWRIGHT_BASE_URL ?? `http://127.0.0.1:${port}`;

export default defineConfig({
  testDir: "./e2e",
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  use: {
    ...devices["Desktop Chrome"],
    baseURL,
    trace: "on-first-retry",
  },
  webServer: {
    command: `pnpm run build && pnpm exec next start -p ${port}`,
    url: `${baseURL}/en/help`,
    reuseExistingServer: !process.env.CI,
    timeout: 240_000,
  },
});
