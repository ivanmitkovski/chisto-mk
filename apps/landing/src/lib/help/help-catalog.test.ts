import { describe, expect, it } from "vitest";
import en from "../../../messages/en.json";
import mk from "../../../messages/mk.json";
import sq from "../../../messages/sq.json";
import {
  HELP_ARTICLE_SLUGS,
  HELP_ARTICLES,
  HELP_CATEGORY_ORDER,
  HELP_RELATED_OVERRIDES,
  articlesInCategory,
  deriveHelpRelatedFromTags,
  helpArticleMeta,
  helpRelatedSlugs,
  isHelpArticleSlug,
} from "./help-catalog";
import { validateHelpArticlesForSlugs } from "./help-messages-schema";

describe("help-catalog", () => {
  it("covers every slug with meta and related entries", () => {
    for (const slug of HELP_ARTICLE_SLUGS) {
      expect(helpArticleMeta(slug)).toBeDefined();
      const related = helpRelatedSlugs(slug);
      expect(related.length).toBeGreaterThan(0);
      for (const rel of related) {
        expect(HELP_ARTICLE_SLUGS).toContain(rel);
        expect(rel).not.toBe(slug);
      }
    }
  });

  it("uses editorial overrides when present", () => {
    for (const slug of HELP_ARTICLE_SLUGS) {
      const override = HELP_RELATED_OVERRIDES[slug];
      if (override?.length) {
        expect(helpRelatedSlugs(slug)).toEqual(override);
      }
    }
  });

  it("deriveHelpRelatedFromTags returns two distinct slugs", () => {
    for (const slug of HELP_ARTICLE_SLUGS) {
      const d = deriveHelpRelatedFromTags(slug);
      expect(d).toHaveLength(2);
      expect(new Set(d).size).toBe(2);
    }
  });

  it("keeps category order in sync with article meta", () => {
    const used = new Set(HELP_ARTICLES.map((a) => a.categoryId));
    for (const id of HELP_CATEGORY_ORDER) {
      expect(used.has(id)).toBe(true);
    }
    for (const id of used) {
      expect(HELP_CATEGORY_ORDER).toContain(id);
    }
  });

  it("articlesInCategory returns only matching slugs", () => {
    const basics = articlesInCategory("basics");
    expect(basics.every((a) => a.categoryId === "basics")).toBe(true);
  });

  it("isHelpArticleSlug narrows known slugs", () => {
    expect(isHelpArticleSlug("getting-started")).toBe(true);
    expect(isHelpArticleSlug("partnerships-for-organisations")).toBe(true);
    expect(isHelpArticleSlug("unknown")).toBe(false);
  });
});

function assertHelpCentreMessages(locale: string, raw: typeof en) {
  const hub = raw.helpCentre.hub;
  expect(hub.title, `${locale} hub.title`).toBeTruthy();
  expect(hub.subtitle, `${locale} hub.subtitle`).toBeTruthy();
  expect(typeof hub.catalogMetrics, `${locale} hub.catalogMetrics`).toBe("string");
  expect(hub.catalogMetrics as string, `${locale} hub.catalogMetrics ICU count`).toContain("{count");
  expect(Array.isArray(hub.featuredSlugs), `${locale} hub.featuredSlugs`).toBe(true);
  for (const s of hub.featuredSlugs as string[]) {
    expect(HELP_ARTICLE_SLUGS as readonly string[], `${locale} featured slug ${s}`).toContain(s);
  }

  const validated = validateHelpArticlesForSlugs(raw.helpCentre.articles, HELP_ARTICLE_SLUGS);
  expect(validated.ok, `${locale} Zod: ${validated.ok ? "" : validated.errors.join("; ")}`).toBe(true);
}

function collectHelpCentreStrings(node: unknown, out: string[]): void {
  if (typeof node === "string") {
    out.push(node);
    return;
  }
  if (Array.isArray(node)) {
    for (const item of node) {
      collectHelpCentreStrings(item, out);
    }
    return;
  }
  if (node !== null && typeof node === "object") {
    for (const value of Object.values(node as Record<string, unknown>)) {
      collectHelpCentreStrings(value, out);
    }
  }
}

describe("helpCentre i18n parity", () => {
  it("en / mk / sq include hub and all article keys", () => {
    assertHelpCentreMessages("en", en);
    assertHelpCentreMessages("mk", mk);
    assertHelpCentreMessages("sq", sq);
  });

  it("helpCentre strings avoid forbidden punctuation (em dash, double hyphen)", () => {
    const forbidden = /—|--/;
    for (const [locale, raw] of [
      ["en", en],
      ["mk", mk],
      ["sq", sq],
    ] as const) {
      const strings: string[] = [];
      collectHelpCentreStrings(raw.helpCentre, strings);
      const hits = strings.filter((s) => forbidden.test(s));
      expect(hits, `${locale} helpCentre contains forbidden punctuation`).toEqual([]);
    }
  });
});
