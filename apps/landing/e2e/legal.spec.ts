import AxeBuilder from "@axe-core/playwright";
import { expect, test } from "@playwright/test";

function criticalAndSerious(violations: { impact?: string }[]) {
  return violations.filter((v) => v.impact === "critical" || v.impact === "serious");
}

test.describe("legal pages", () => {
  for (const locale of ["mk", "en", "sq"] as const) {
    test(`privacy page loads (${locale})`, async ({ page }) => {
      await page.goto(`/${locale}/privacy`);
      await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
    });
  }

  test("privacy has no critical or serious axe violations (en)", async ({ page }) => {
    await page.goto("/en/privacy");
    const results = await new AxeBuilder({ page }).withTags(["wcag2a", "wcag2aa"]).analyze();
    const bad = criticalAndSerious(results.violations);
    expect(bad, JSON.stringify(bad, null, 2)).toHaveLength(0);
  });
});
