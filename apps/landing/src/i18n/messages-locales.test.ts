import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";

const landingRoot = join(dirname(fileURLToPath(import.meta.url)), "../..");
const messagesDir = join(landingRoot, "messages");
const LOCALES = ["en", "mk", "sq"] as const;

const EXCLUDED_ROOTS = new Set([
  "termsPage",
  "privacyPage",
  "cookiesPage",
  "dataPage",
]);

const FORBIDDEN_PUNCTUATION = /—|--/;

type JsonValue = string | number | boolean | null | JsonValue[] | { [key: string]: JsonValue };

function loadMessages(locale: string): Record<string, JsonValue> {
  const raw = readFileSync(join(messagesDir, `${locale}.json`), "utf8");
  return JSON.parse(raw) as Record<string, JsonValue>;
}

function stripLegalRoots(node: JsonValue): JsonValue {
  if (Array.isArray(node)) {
    return node.map(stripLegalRoots);
  }
  if (node !== null && typeof node === "object") {
    const out: Record<string, JsonValue> = {};
    for (const [key, value] of Object.entries(node)) {
      if (EXCLUDED_ROOTS.has(key)) continue;
      if (key === "metadata" && value !== null && typeof value === "object" && !Array.isArray(value)) {
        const meta: Record<string, JsonValue> = {};
        for (const [mk, mv] of Object.entries(value as Record<string, JsonValue>)) {
          if (["terms", "privacy", "cookies", "data"].includes(mk)) continue;
          meta[mk] = stripLegalRoots(mv);
        }
        out[key] = meta;
        continue;
      }
      out[key] = stripLegalRoots(value);
    }
    return out;
  }
  return node;
}

function collectKeyPaths(
  node: JsonValue,
  prefix: string,
  out: Map<string, "string" | "number" | "boolean" | "null" | "array" | "object">,
): void {
  if (Array.isArray(node)) {
    out.set(prefix, "array");
    node.forEach((item, index) => {
      collectKeyPaths(item, `${prefix}[${index}]`, out);
    });
    return;
  }
  if (node !== null && typeof node === "object") {
    out.set(prefix, "object");
    for (const [key, value] of Object.entries(node)) {
      const next = prefix ? `${prefix}.${key}` : key;
      collectKeyPaths(value, next, out);
    }
    return;
  }
  const kind =
    node === null ? "null" : typeof node === "string" ? "string" : typeof node === "number" ? "number" : "boolean";
  out.set(prefix, kind);
}

function collectStrings(node: JsonValue, out: string[]): void {
  if (typeof node === "string") {
    out.push(node);
    return;
  }
  if (Array.isArray(node)) {
    for (const item of node) collectStrings(item, out);
    return;
  }
  if (node !== null && typeof node === "object") {
    for (const value of Object.values(node)) collectStrings(value, out);
  }
}

describe("landing messages locale parity", () => {
  const byLocale = Object.fromEntries(LOCALES.map((locale) => [locale, stripLegalRoots(loadMessages(locale))])) as Record<
    (typeof LOCALES)[number],
    JsonValue
  >;

  it("en / mk / sq share the same non-legal key paths", () => {
    const paths = Object.fromEntries(
      LOCALES.map((locale) => {
        const map = new Map<string, string>();
        collectKeyPaths(byLocale[locale], "", map);
        map.delete("");
        return [locale, map];
      }),
    ) as Record<(typeof LOCALES)[number], Map<string, string>>;

    const enKeys = [...paths.en.keys()].sort();
    for (const locale of LOCALES) {
      if (locale === "en") continue;
      const otherKeys = [...paths[locale].keys()].sort();
      expect(otherKeys, `${locale} key paths`).toEqual(enKeys);
      for (const key of enKeys) {
        expect(paths[locale].get(key), `${locale} type at ${key}`).toBe(paths.en.get(key));
      }
    }
  });

  it("non-legal copy avoids em dashes and double hyphens", () => {
    for (const locale of LOCALES) {
      const strings: string[] = [];
      collectStrings(byLocale[locale], strings);
      const hits = strings.filter((s) => FORBIDDEN_PUNCTUATION.test(s));
      expect(hits, `${locale} forbidden punctuation`).toEqual([]);
    }
  });
});
