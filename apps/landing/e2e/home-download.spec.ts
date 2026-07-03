import { expect, test } from "@playwright/test";

async function dismissCookieBanner(page: import("@playwright/test").Page) {
  const accept = page.getByRole("button", { name: /accept all/i });
  if (await accept.isVisible().catch(() => false)) {
    await accept.click();
  }
}

async function expectDownloadBadgesVisible(page: import("@playwright/test").Page) {
  await expect
    .poll(async () => page.evaluate(() => window.scrollY), { timeout: 10_000 })
    .toBeLessThan(8);

  const downloadRegion = page.getByRole("region", { name: /Download the app/i });
  const appStoreLink = downloadRegion.getByRole("link", {
    name: /download on the app store/i,
  });
  const googlePlayLink = downloadRegion.getByRole("link", {
    name: /get it on google play/i,
  });
  await expect(appStoreLink).toBeVisible();
  await expect(googlePlayLink).toBeVisible();

  const headerBottom = await page.locator("header").evaluate((el) => {
    const rect = el.getBoundingClientRect();
    return rect.bottom;
  });
  const badgeTop = await appStoreLink.evaluate((el) => el.getBoundingClientRect().top);

  expect(badgeTop).toBeGreaterThanOrEqual(headerBottom + 4);
}

test.describe("home download scroll", () => {
  test("header download link scrolls to top with badges visible", async ({ page }) => {
    await page.goto("/en");
    await dismissCookieBanner(page);
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));

    const downloadLink = page.locator("header").getByRole("link", { name: "Download" });
    await expect(downloadLink).toBeVisible();
    await downloadLink.click();

    await expect(page).toHaveURL(/#download$/);
    await expectDownloadBadgesVisible(page);
  });

  test("direct hash navigation scrolls to top with badges visible", async ({ page }) => {
    await page.goto("/en#download");
    await dismissCookieBanner(page);
    await expectDownloadBadgesVisible(page);
  });

  test("mobile hamburger download scrolls to badges", async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 820 });
    await page.goto("/en");
    await dismissCookieBanner(page);
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));

    await page.getByRole("button", { name: /menu/i }).click();
    const downloadLink = page.getByRole("dialog").getByRole("link", { name: "Download" });
    await expect(downloadLink).toBeVisible();
    await downloadLink.click();

    await expect(page).toHaveURL(/#download$/);
    await expectDownloadBadgesVisible(page);
  });

  test("download from news page navigates home to badges", async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 820 });
    await page.goto("/en/news");
    await dismissCookieBanner(page);

    await page.getByRole("button", { name: /menu/i }).click();
    await page.getByRole("dialog").getByRole("link", { name: "Download" }).click();

    await expect(page).toHaveURL(/\/en#download$/);
    await expectDownloadBadgesVisible(page);
  });
});
