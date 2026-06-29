import AxeBuilder from "@axe-core/playwright";
import { expect, test } from "@playwright/test";

function criticalAndSerious(violations: { impact?: string }[]) {
  return violations.filter((v) => v.impact === "critical" || v.impact === "serious");
}

test.describe("home page", () => {
  test("renders primary marketing sections", async ({ page }) => {
    await page.goto("/en");

    await expect(
      page.getByRole("heading", { level: 1, name: /Snap it\. Report it\. Clean it\./i }),
    ).toBeVisible();
    await expect(page.getByRole("heading", { level: 2, name: /How it works/i })).toBeVisible();
    await expect(page.getByRole("heading", { level: 2, name: /Frequently asked questions/i })).toBeVisible();
    await expect(page.getByRole("heading", { level: 2, name: /Download Chisto\.mk/i })).toBeVisible();
    await expect(page.locator("#download")).toBeVisible();
  });

  test("main navigation links are reachable", async ({ page }) => {
    await page.goto("/en");
    const nav = page.getByRole("navigation", { name: /Main navigation/i });
    await expect(nav.getByRole("link", { name: "Home" })).toBeVisible();
    await expect(nav.getByRole("link", { name: "About us" })).toBeVisible();
    await expect(nav.getByRole("link", { name: "News" })).toBeVisible();
    await expect(nav.getByRole("link", { name: "Help" })).toBeVisible();
    await expect(nav.getByRole("link", { name: "Contact" })).toBeVisible();
    await expect(nav.getByRole("link", { name: "Press" })).toHaveCount(0);
  });

  test("language selector switches locale", async ({ page }) => {
    await page.goto("/en");
    await page.getByRole("button", { name: /Language/i }).click();
    await page.getByRole("option", { name: "MK" }).click();
    await expect(page).toHaveURL(/\/mk$/);
    await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
  });

  test("has no critical or serious axe violations", async ({ page }) => {
    await page.goto("/en");
    const results = await new AxeBuilder({ page }).withTags(["wcag2a", "wcag2aa"]).analyze();
    const bad = criticalAndSerious(results.violations);
    expect(bad, JSON.stringify(bad, null, 2)).toHaveLength(0);
  });

  test("mk home has no critical or serious axe violations", async ({ page }) => {
    await page.goto("/mk");
    const results = await new AxeBuilder({ page }).withTags(["wcag2a", "wcag2aa"]).analyze();
    const bad = criticalAndSerious(results.violations);
    expect(bad, JSON.stringify(bad, null, 2)).toHaveLength(0);
  });

  test("sq home has no critical or serious axe violations", async ({ page }) => {
    await page.goto("/sq");
    const results = await new AxeBuilder({ page }).withTags(["wcag2a", "wcag2aa"]).analyze();
    const bad = criticalAndSerious(results.violations);
    expect(bad, JSON.stringify(bad, null, 2)).toHaveLength(0);
  });

  test("about page loads when launched", async ({ page }) => {
    await page.goto("/en/about");
    await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
  });

  test("news page loads when launched", async ({ page }) => {
    await page.goto("/en/news");
    await expect(
      page.getByRole("heading", { level: 1, name: /News from Chisto\.mk/i }),
    ).toBeVisible();
    await expect(
      page.getByRole("link", { name: /Chisto\.mk launches on the App Store/i }).first(),
    ).toBeVisible();

    await page.goto("/en/news/chisto-mk-ios-app-store-launch-2026");
    await expect(
      page.getByRole("heading", {
        level: 1,
        name: /Chisto\.mk launches on the App Store, bringing pollution reporting to iPhone users in North Macedonia/i,
      }),
    ).toBeVisible();
  });
});
