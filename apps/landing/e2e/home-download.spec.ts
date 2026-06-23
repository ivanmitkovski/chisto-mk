import { expect, test } from "@playwright/test";

test.describe("home download scroll", () => {
  test("header download button scrolls to top with badges visible", async ({
    page,
  }) => {
    await page.goto("/en");
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));

    const downloadButton = page.getByRole("button", { name: "Download" });
    await expect(downloadButton).toBeVisible();
    await downloadButton.click();

    await expect(page).toHaveURL(/#download$/);
    await expect
      .poll(async () => page.evaluate(() => window.scrollY))
      .toBeLessThan(8);

    const appStoreLink = page.getByRole("link", {
      name: /download on the app store/i,
    });
    await expect(appStoreLink).toBeVisible();

    const headerBottom = await page.locator("header").evaluate((el) => {
      const rect = el.getBoundingClientRect();
      return rect.bottom;
    });
    const badgeTop = await appStoreLink.evaluate((el) => el.getBoundingClientRect().top);

    expect(badgeTop).toBeGreaterThanOrEqual(headerBottom + 4);
  });

  test("direct hash navigation scrolls to top with badges visible", async ({ page }) => {
    await page.goto("/en#download");

    await expect
      .poll(async () => page.evaluate(() => window.scrollY))
      .toBeLessThan(8);

    const appStoreLink = page.getByRole("link", {
      name: /download on the app store/i,
    });
    await expect(appStoreLink).toBeVisible();

    const headerBottom = await page.locator("header").evaluate((el) => {
      const rect = el.getBoundingClientRect();
      return rect.bottom;
    });
    const badgeTop = await appStoreLink.evaluate((el) => el.getBoundingClientRect().top);

    expect(badgeTop).toBeGreaterThanOrEqual(headerBottom + 4);
  });
});
