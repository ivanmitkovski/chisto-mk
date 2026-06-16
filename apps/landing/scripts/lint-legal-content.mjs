#!/usr/bin/env node
/**
 * Legal page content checks: structural parity across locales and forbidden editorial markers.
 * Run: pnpm --filter @chisto/landing lint:legal-content
 */
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const messagesDir = join(root, "messages");
const locales = ["en", "mk", "sq"];
const LEGAL_KEYS = ["termsPage", "privacyPage", "cookiesPage", "dataPage"];

const EDITORIAL_MARKER = /\[(?:TODO|PLACEHOLDER)(?:[^\]]*)\]/i;
const TODO_ANGLE = /<todo\b/i;

let failed = false;

function fail(message) {
  console.error(message);
  failed = true;
}

function walkStrings(node, out) {
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

const byLocale = {};

for (const locale of locales) {
  const path = join(messagesDir, `${locale}.json`);
  const raw = JSON.parse(readFileSync(path, "utf8"));
  byLocale[locale] = raw;

  for (const key of LEGAL_KEYS) {
    if (!raw[key]) {
      fail(`${locale}.json: missing ${key}`);
      continue;
    }

    const strings = [];
    walkStrings(raw[key], strings);

    for (const s of strings) {
      if (EDITORIAL_MARKER.test(s)) {
        fail(`${locale}.json: editorial marker in ${key}: ${s.slice(0, 120)}…`);
      }
      if (TODO_ANGLE.test(s)) {
        fail(`${locale}.json: <todo marker in ${key}`);
      }
      if (s.includes("info@ekohab.mk") && !s.includes("[PRIVACY_EMAIL]")) {
        fail(`${locale}.json: hardcoded info@ekohab.mk in ${key} (use [PRIVACY_EMAIL])`);
      }
    }
  }
}

const en = byLocale.en;
if (en) {
  for (const key of LEGAL_KEYS) {
    const enPage = en[key];
    if (!enPage) continue;

    const enSections = enPage.sections?.length ?? 0;
    const enCookieRows = enPage.cookieRows?.length ?? null;

    for (const locale of locales) {
      if (locale === "en") continue;
      const page = byLocale[locale]?.[key];
      if (!page) continue;

      const sections = page.sections?.length ?? 0;
      if (sections !== enSections) {
        fail(
          `${locale}.json: ${key}.sections length ${sections} != en ${enSections}`,
        );
      }

      if (enCookieRows !== null) {
        const rows = page.cookieRows?.length ?? 0;
        if (rows !== enCookieRows) {
          fail(
            `${locale}.json: ${key}.cookieRows length ${rows} != en ${enCookieRows}`,
          );
        }
      }
    }
  }
}

if (failed) {
  process.exit(1);
}

console.log("legal content lint (structure): OK");
