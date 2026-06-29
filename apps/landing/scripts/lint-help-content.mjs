#!/usr/bin/env node
/**
 * Extra Help Centre content checks beyond Zod (forbidden placeholders, editorial markers).
 * Run: pnpm --filter @chisto/landing lint:help-content
 */
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const messagesDir = join(root, "messages");
const contentDir = join(root, "content", "help");
const locales = ["en", "mk", "sq"];

const PLACEHOLDER = /\[(?:TODO|PLACEHOLDER|SUPERVISORY)[^\]]*\]/i;
const TODO_ANGLE = /<todo\b/i;
const SKIP_KEYS = new Set(["href", "id", "type", "variant", "datePublished", "dateModified"]);

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

function walkCompare(enNode, locNode, path, hits) {
  if (typeof enNode === "string" && typeof locNode === "string") {
    if (
      enNode === locNode &&
      enNode.length > 12 &&
      /[A-Za-z]{4,}/.test(enNode) &&
      !/^(https?:|\/|\d{4}-\d{2})/.test(enNode)
    ) {
      hits.push(`${path}: ${enNode.slice(0, 100)}`);
    }
    return;
  }
  if (Array.isArray(enNode)) {
    enNode.forEach((item, i) => walkCompare(item, locNode?.[i], `${path}[${i}]`, hits));
    return;
  }
  if (enNode !== null && typeof enNode === "object") {
    for (const key of Object.keys(enNode)) {
      if (SKIP_KEYS.has(key)) continue;
      const next = path ? `${path}.${key}` : key;
      walkCompare(enNode[key], locNode?.[key], next, hits);
    }
  }
}

for (const locale of locales) {
  const path = join(messagesDir, `${locale}.json`);
  const raw = JSON.parse(readFileSync(path, "utf8"));
  const help = raw.helpCentre;
  if (!help) {
    console.error(`${locale}.json: missing helpCentre`);
    failed = true;
    continue;
  }
  const strings = [];
  walkStrings(help, strings);
  for (const s of strings) {
    if (PLACEHOLDER.test(s)) {
      console.error(`${locale}.json: placeholder token in helpCentre string: ${s.slice(0, 120)}…`);
      failed = true;
    }
    if (TODO_ANGLE.test(s)) {
      console.error(`${locale}.json: <todo marker in helpCentre string`);
      failed = true;
    }
    if (/\u2014|--/.test(s)) {
      console.error(`${locale}.json: forbidden punctuation in helpCentre: ${s.slice(0, 80)}…`);
      failed = true;
    }
  }
  const articles = help.articles ?? {};
  for (const article of Object.values(articles)) {
    const blob = JSON.stringify(article);
    if (blob.includes("apps.apple.com/app/id") && !blob.includes("/mk/app/")) {
      console.error(`${locale}.json: App Store links should use MK storefront (/mk/app/)`);
      failed = true;
      break;
    }
  }
}

const enArticles = JSON.parse(readFileSync(join(contentDir, "articles.en.json"), "utf8"));
for (const locale of ["mk", "sq"]) {
  const locArticles = JSON.parse(readFileSync(join(contentDir, `articles.${locale}.json`), "utf8"));
  const hits = [];
  for (const slug of Object.keys(enArticles)) {
    walkCompare(enArticles[slug], locArticles[slug], slug, hits);
  }
  if (hits.length > 0) {
    console.error(`${locale}: ${hits.length} help strings still identical to English:`);
    for (const h of hits.slice(0, 15)) console.error(`  ${h}`);
    if (hits.length > 15) console.error(`  … and ${hits.length - 15} more`);
    failed = true;
  }
}

if (failed) {
  process.exit(1);
}
console.log("help content lint: OK");
