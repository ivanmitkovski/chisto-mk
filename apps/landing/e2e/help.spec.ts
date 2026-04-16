import AxeBuilder from "@axe-core/playwright";
import { expect, test } from "@playwright/test";
import { HELP_ARTICLE_SLUGS } from "../src/lib/help/help-catalog";

function criticalAndSerious(violations: { impact?: string }[]) {
  return violations.filter((v) => v.impact === "critical" || v.impact === "serious");
}

test.describe("Help centre", () => {
  test("hub loads in English", async ({ page }) => {
    await page.goto("/en/help");
    await expect(page.getByRole("heading", { level: 1, name: /Help centre/i })).toBeVisible();
    await expect(page.getByText(/^Start here$/i)).toBeVisible();
  });

  for (const slug of HELP_ARTICLE_SLUGS) {
    test(`article shell loads for ${slug}`, async ({ page }) => {
      await page.goto(`/en/help/${slug}`);
      await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
      await expect(page.getByRole("navigation", { name: /On this page/i })).toBeVisible();
    });
  }

  test("article in-page anchor focuses target section", async ({ page }) => {
    await page.goto("/en/help/getting-started#download-the-app");
    await expect(page.locator("#download-the-app")).toBeVisible();
  });

  test("hub loads in Macedonian locale path", async ({ page }) => {
    await page.goto("/mk/help");
    await expect(page.getByRole("heading", { level: 1, name: /Центар за помош/i })).toBeVisible();
  });

  test("help article has no critical or serious axe violations", async ({ page }) => {
    await page.goto("/en/help/report-a-site");
    const results = await new AxeBuilder({ page }).withTags(["wcag2a", "wcag2aa"]).analyze();
    const bad = criticalAndSerious(results.violations);
    expect(bad, JSON.stringify(bad, null, 2)).toHaveLength(0);
  });

  test("search filters topics", async ({ page }) => {
    await page.goto("/en/help");
    const input = page.getByRole("searchbox");
    await input.fill("zzzznotfound");
    await expect(page.getByText(/No guides match that search/i)).toBeVisible();
    await input.fill("reporting");
    await expect(page.getByRole("heading", { name: /Reporting/i })).toBeVisible();
  });

  test("help search hydrates query from URL and supports keyboard", async ({ page }) => {
    await page.goto("/en/help?q=troubleshooting");
    const input = page.getByRole("searchbox");
    await expect(input).toHaveValue("troubleshooting");
    await input.press("ArrowDown");
    await input.press("Enter");
    await expect(page).toHaveURL(/\/en\/help\/troubleshooting$/);
  });

  test("help hub has no critical or serious axe violations", async ({ page }) => {
    await page.goto("/en/help");
    const results = await new AxeBuilder({ page }).withTags(["wcag2a", "wcag2aa"]).analyze();
    const bad = criticalAndSerious(results.violations);
    expect(bad, JSON.stringify(bad, null, 2)).toHaveLength(0);
  });

  test("keyboard: TOC link navigates to in-page hash (desktop)", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 800 });
    await page.goto("/en/help/getting-started");
    const toc = page.getByRole("navigation", { name: /On this page/i });
    const link = toc.getByRole("link", { name: /^Download the app$/i });
    await link.focus();
    await link.press("Enter");
    await expect(page).toHaveURL(/#download-the-app$/);
    await expect(page.locator("#download-the-app")).toBeVisible();
  });

  test("keyboard: mobile TOC opens then link navigates to hash", async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 820 });
    await page.goto("/en/help/getting-started");
    await page.getByRole("button", { name: /Table of contents/i }).click();
    const toc = page.getByRole("navigation", { name: /On this page/i });
    await toc.getByRole("link", { name: /^Download the app$/i }).click();
    await expect(page).toHaveURL(/#download-the-app$/);
  });

  test("keyboard: copy section link writes URL to clipboard", async ({ page, context }) => {
    await context.grantPermissions(["clipboard-read", "clipboard-write"]);
    await page.goto("/en/help/report-a-site#before-you-start");
    const section = page.locator("#before-you-start");
    const copyBtn = section.getByRole("button", { name: /copy link to section/i });
    await copyBtn.focus();
    await copyBtn.press("Enter");
    const text = await page.evaluate(() => navigator.clipboard.readText());
    expect(text).toMatch(/\/en\/help\/report-a-site#before-you-start$/);
  });
});
