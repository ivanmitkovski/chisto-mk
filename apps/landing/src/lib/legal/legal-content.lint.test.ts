import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";
import {
  getLegalPlaceholderMap,
  substituteCookieRows,
  substituteLegalSections,
  substituteLegalText,
} from "./substitute-placeholders";
import { buildLocaleLegalUrls } from "./legal-public-config";

const root = join(dirname(fileURLToPath(import.meta.url)), "../../..");
const locales = ["en", "mk", "sq"] as const;
const LEGAL_KEYS = ["termsPage", "privacyPage", "cookiesPage", "dataPage"] as const;
const UNREPLACED_TOKEN = /\[[A-Z0-9_/ -]+\]/;

function walkStrings(node: unknown, out: string[]) {
  if (typeof node === "string") {
    out.push(node);
    return;
  }
  if (Array.isArray(node)) {
    for (const v of node) walkStrings(v, out);
    return;
  }
  if (node !== null && typeof node === "object") {
    for (const v of Object.values(node)) walkStrings(v, out);
  }
}

describe("buildLocaleLegalUrls", () => {
  it("builds locale-prefixed legal URLs", () => {
    const urls = buildLocaleLegalUrls("en");
    expect(urls.privacyPolicyUrl).toBe("https://www.chisto.mk/en/privacy");
    expect(urls.termsUrl).toBe("https://www.chisto.mk/en/terms");
    expect(urls.cookiePolicyUrl).toBe("https://www.chisto.mk/en/cookies");
    expect(urls.cookiePreferencesUrl).toBe(
      "https://www.chisto.mk/en/cookies#cookie-settings",
    );
    expect(urls.websiteUrl).toBe("https://www.chisto.mk/en");
  });
});

describe("legal content substitution", () => {
  for (const locale of locales) {
    it(`leaves no unreplaced tokens in ${locale} legal pages`, () => {
      const raw = JSON.parse(
        readFileSync(join(root, "messages", `${locale}.json`), "utf8"),
      );
      const map = getLegalPlaceholderMap(locale);

      for (const key of LEGAL_KEYS) {
        const page = raw[key];
        expect(page, `${key} missing`).toBeTruthy();

        const strings: string[] = [];
        walkStrings(page, strings);

        for (const s of strings) {
          const out = substituteLegalText(s, map);
          expect(out, `${key} string still has tokens`).not.toMatch(UNREPLACED_TOKEN);
        }

        if (page.sections) {
          const sections = substituteLegalSections(page.sections, map);
          for (const section of sections) {
            expect(section.title).not.toMatch(UNREPLACED_TOKEN);
            expect(section.body).not.toMatch(UNREPLACED_TOKEN);
          }
        }

        if (page.cookieRows) {
          const rows = substituteCookieRows(page.cookieRows, map);
          for (const row of rows) {
            expect(Object.values(row).join(" ")).not.toMatch(UNREPLACED_TOKEN);
          }
        }
      }
    });
  }
});
