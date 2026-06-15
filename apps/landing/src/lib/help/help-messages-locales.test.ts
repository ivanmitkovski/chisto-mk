import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";
import { HELP_ARTICLE_SLUGS } from "./help-catalog";
import { validateHelpArticlesForSlugs } from "./help-messages-schema";
import type { HelpArticleMessage } from "./help-messages-schema";

const landingRoot = join(dirname(fileURLToPath(import.meta.url)), "../../..");
const messagesDir = join(landingRoot, "messages");
const LOCALES = ["en", "mk", "sq"] as const;

function loadMessages(locale: string): unknown {
  const raw = readFileSync(join(messagesDir, `${locale}.json`), "utf8");
  return JSON.parse(raw) as { helpCentre?: { articles?: unknown } };
}

function assertUniqueSectionIds(articleSlug: string, locale: string, article: HelpArticleMessage): void {
  const seen = new Set<string>();
  for (const section of article.sections) {
    expect(seen.has(section.id), `duplicate section id "${section.id}" (${locale}/${articleSlug})`).toBe(false);
    seen.add(section.id);
  }
}

describe("helpCentre messages (all locales)", () => {
  for (const locale of LOCALES) {
    it(`parses helpCentre.articles for ${locale}.json`, () => {
      const root = loadMessages(locale);
      const articles = root.helpCentre?.articles;
      expect(articles, `${locale}: missing helpCentre.articles`).toBeDefined();
      const result = validateHelpArticlesForSlugs(articles, HELP_ARTICLE_SLUGS);
      expect(result.ok, result.ok ? "" : result.errors.join("\n")).toBe(true);
      if (!result.ok) return;
      for (const slug of HELP_ARTICLE_SLUGS) {
        const article = result.data[slug];
        expect(article, `${locale}: missing parsed article ${slug}`).toBeDefined();
        if (article) assertUniqueSectionIds(slug, locale, article);
      }
    });
  }

  it("article key sets match across en, mk, sq", () => {
    const keys = LOCALES.map((locale) => {
      const root = loadMessages(locale);
      const articles = root.helpCentre?.articles as Record<string, unknown> | undefined;
      expect(articles).toBeDefined();
      return new Set(Object.keys(articles ?? {}));
    });
    const [enKeys, mkKeys, sqKeys] = keys;
    expect(mkKeys).toEqual(enKeys);
    expect(sqKeys).toEqual(enKeys);
  });
});
