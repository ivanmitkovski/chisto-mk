import AxeBuilder from "@axe-core/playwright";
import { expect, test } from "@playwright/test";

function criticalAndSerious(violations: { impact?: string }[]) {
  return violations.filter((v) => v.impact === "critical" || v.impact === "serious");
}

test.describe("Contact page", () => {
  test("loads in English", async ({ page }) => {
    await page.goto("/en/contact");
    await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
  });

  test("has no critical or serious axe violations", async ({ page }) => {
    await page.goto("/en/contact");
    const accept = page.getByRole("button", { name: /accept all/i });
    if (await accept.isVisible().catch(() => false)) {
      await accept.click();
    }
    const results = await new AxeBuilder({ page }).withTags(["wcag2a", "wcag2aa"]).exclude(".brand-logotype").analyze();
    const bad = criticalAndSerious(results.violations);
    expect(bad, JSON.stringify(bad, null, 2)).toHaveLength(0);
  });
});
