#!/usr/bin/env node
/**
 * Marketing and help copy checks across locale message files (legal pages excluded).
 * Run: pnpm --filter @chisto/landing lint:marketing-copy
 */
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const messagesDir = join(root, "messages");
const locales = ["en", "mk", "sq"];

/** Legal roots left untouched by the copy rewrite pass. */
const EXCLUDED_ROOTS = new Set([
  "termsPage",
  "privacyPage",
  "cookiesPage",
  "dataPage",
  "appStore",
]);

const FORBIDDEN_PUNCTUATION = /—|--/;
const PLACEHOLDER_COPY = /\b(?:TBC|Bio later)\b/i;
const GOOGLE_PLAY_MENTION = /\bGoogle Play\b/i;

const googlePlayUrl = process.env.NEXT_PUBLIC_GOOGLE_PLAY_URL?.trim();

let failed = false;

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

function marketingPayload(raw) {
  const copy = { ...raw };
  for (const key of EXCLUDED_ROOTS) {
    delete copy[key];
  }
  if (copy.metadata && typeof copy.metadata === "object") {
    copy.metadata = { ...copy.metadata };
    for (const key of ["terms", "privacy", "cookies", "data"]) {
      delete copy.metadata[key];
    }
  }
  return copy;
}

for (const locale of locales) {
  const path = join(messagesDir, `${locale}.json`);
  const raw = JSON.parse(readFileSync(path, "utf8"));
  const payload = marketingPayload(raw);
  const strings = [];
  walkStrings(payload, strings);

  for (const s of strings) {
    if (FORBIDDEN_PUNCTUATION.test(s)) {
      console.error(`${locale}.json: forbidden punctuation in copy: ${s.slice(0, 120)}…`);
      failed = true;
    }
    if (PLACEHOLDER_COPY.test(s)) {
      console.error(`${locale}.json: placeholder editorial copy: ${s.slice(0, 120)}…`);
      failed = true;
    }
    if (!googlePlayUrl && GOOGLE_PLAY_MENTION.test(s)) {
      console.error(`${locale}.json: Google Play mention without NEXT_PUBLIC_GOOGLE_PLAY_URL: ${s.slice(0, 120)}…`);
      failed = true;
    }
  }
}

if (failed) {
  process.exit(1);
}
console.log("marketing copy lint: OK");
