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

  test("shows team members with LinkedIn profiles", async ({ page }) => {
    await page.goto("/en/about");

    await expect(page.getByText("The people building Chisto.mk.")).toBeVisible();

    const members = [
      "Ivan Mitkovski",
      "Vasil Angelov",
      "Leon Mitev",
      "Antonio Hristovski",
    ] as const;

    for (const name of members) {
      const article = page.getByRole("article", { name });
      await article.scrollIntoViewIfNeeded();
      await expect(article).toBeVisible();
      await expect(article.getByRole("heading", { name })).toBeVisible();
    }

    await expect(page.getByRole("article", { name: "Ivan Mitkovski" }).getByText("CTO", { exact: true })).toBeVisible();
    await expect(page.getByRole("article", { name: "Vasil Angelov" }).getByText("CMO", { exact: true })).toBeVisible();
    await expect(page.getByRole("article", { name: "Antonio Hristovski" }).getByText("CDO", { exact: true })).toBeVisible();
    await expect(
      page.getByRole("article", { name: "Vasil Angelov" }).getByText("Principal Marketer", { exact: true }),
    ).toBeVisible();
    await expect(
      page.getByRole("article", { name: "Leon Mitev" }).getByText("Senior Marketer", { exact: true }),
    ).toBeVisible();

    await expect(page.getByText("President of the Supervisory Board of EKOHAB Skopje")).toBeVisible();
    await expect(page.getByText("Member of the Executive Board of EKOHAB Skopje")).toHaveCount(2);

    await expect(page.getByRole("img", { name: /Portrait of Leon Mitev/i })).toBeVisible();
    await expect(page.getByRole("img", { name: /Portrait of Antonio Hristovski/i })).toBeVisible();

    const profiles = [
      {
        name: /Ivan Mitkovski on LinkedIn/i,
        href: "https://www.linkedin.com/in/ivanmitkovski/",
      },
      {
        name: /Vasil Angelov on LinkedIn/i,
        href: "https://www.linkedin.com/in/vasil-angelov-b0a25930b/",
      },
      {
        name: /Leon Mitev on LinkedIn/i,
        href: "https://www.linkedin.com/in/leon-mitev-68aa3816a/",
      },
      {
        name: /Antonio Hristovski on LinkedIn/i,
        href: "https://www.linkedin.com/in/antoniohristovski/",
      },
    ] as const;

    for (const profile of profiles) {
      const link = page.getByRole("link", { name: profile.name });
      await link.scrollIntoViewIfNeeded();
      await expect(link).toHaveAttribute("href", profile.href);
      await expect(link).toHaveAttribute("target", "_blank");
    }

    const ivanLinkedIn = page.getByRole("link", { name: /Ivan Mitkovski on LinkedIn/i });
    await ivanLinkedIn.focus();
    await expect(ivanLinkedIn).toBeFocused();
  });

  test("has no critical or serious axe violations", async ({ page }) => {
    await page.goto("/en/about");
    const results = await new AxeBuilder({ page }).withTags(["wcag2a", "wcag2aa"]).exclude(".brand-logotype").analyze();
    const bad = criticalAndSerious(results.violations);
    expect(bad, JSON.stringify(bad, null, 2)).toHaveLength(0);
  });
});
