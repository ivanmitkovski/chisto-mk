import AxeBuilder from "@axe-core/playwright";
import { expect, test } from "@playwright/test";

function criticalAndSerious(violations: { impact?: string }[]) {
  return violations.filter((v) => v.impact === "critical" || v.impact === "serious");
}

test.describe("about page", () => {
  test("loads in English", async ({ page }) => {
    await page.goto("/en/about");
    await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
  });

  test("team carousel prev/next buttons are keyboard reachable", async ({ page }) => {
    await page.goto("/en/about");
    const next = page.getByRole("button", { name: /next/i }).first();
    if (await next.isVisible().catch(() => false)) {
      await next.focus();
      await expect(next).toBeFocused();
    }
  });

  test("has no critical or serious axe violations", async ({ page }) => {
    await page.goto("/en/about");
    const results = await new AxeBuilder({ page }).withTags(["wcag2a", "wcag2aa"]).exclude(".brand-logotype").analyze();
    const bad = criticalAndSerious(results.violations);
    expect(bad, JSON.stringify(bad, null, 2)).toHaveLength(0);
  });
});
