import { describe, expect, it } from "vitest";
import { HELP_ARTICLE_SLUGS } from "./help-catalog";
import { helpArticleLastModified, helpHubLastModified } from "./help-sitemap-dates";

describe("help-sitemap-dates", () => {
  const fallback = new Date("2020-01-01T00:00:00.000Z");

  it("uses dateModified from messages for known article", () => {
    const d = helpArticleLastModified("en", "getting-started", fallback);
    expect(d.toISOString()).toBe("2026-04-16T00:00:00.000Z");
  });

  it("falls back when locale unknown", () => {
    expect(helpArticleLastModified("xx", "getting-started", fallback)).toEqual(fallback);
  });

  it("helpHubLastModified is at least the newest article date", () => {
    const hub = helpHubLastModified("en", fallback);
    for (const slug of HELP_ARTICLE_SLUGS) {
      const article = helpArticleLastModified("en", slug, fallback);
      expect(hub.getTime()).toBeGreaterThanOrEqual(article.getTime());
    }
  });
});
