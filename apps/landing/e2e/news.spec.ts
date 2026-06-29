import AxeBuilder from "@axe-core/playwright";
import { expect, test } from "@playwright/test";

function criticalAndSerious(violations: { impact?: string }[]) {
  return violations.filter((v) => v.impact === "critical" || v.impact === "serious");
}

async function dismissCookieBanner(page: import("@playwright/test").Page) {
  const accept = page.getByRole("button", { name: /accept all/i });
  if (await accept.isVisible().catch(() => false)) {
    await accept.click();
  }
}

test.describe("news pages", () => {
  test("hub loads in English", async ({ page }) => {
    await page.goto("/en/news");
    await expect(
      page.getByRole("heading", { level: 1, name: /News from Chisto\.mk/i }),
    ).toBeVisible();
  });

  test("has no critical or serious axe violations on hub", async ({ page }) => {
    await page.goto("/en/news");
    await dismissCookieBanner(page);
    const results = await new AxeBuilder({ page }).withTags(["wcag2a", "wcag2aa"]).analyze();
    const bad = criticalAndSerious(results.violations);
    expect(bad, JSON.stringify(bad, null, 2)).toHaveLength(0);
  });
});
