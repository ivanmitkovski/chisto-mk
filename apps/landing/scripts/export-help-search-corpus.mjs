#!/usr/bin/env node
/**
 * Export help search corpus stats for CI review.
 * Run: node scripts/export-help-search-corpus.mjs
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(__dirname, "..");

function walkStrings(node, out) {
  if (typeof node === "string") {
    out.push(node);
    return;
  }
  if (Array.isArray(node)) {
    for (const v of node) walkStrings(v, out);
  } else if (node && typeof node === "object") {
    for (const v of Object.values(node)) walkStrings(v, out);
  }
}

for (const locale of ["en", "mk", "sq"]) {
  const raw = JSON.parse(fs.readFileSync(path.join(root, "messages", `${locale}.json`), "utf8"));
  const articles = raw.helpCentre?.articles ?? {};
  let totalChars = 0;
  for (const [slug, article] of Object.entries(articles)) {
    const strings = [];
    walkStrings(article, strings);
    const len = strings.join(" ").length;
    totalChars += len;
    console.log(`${locale}/${slug}: ${len} chars`);
  }
  console.log(`${locale} total corpus: ${totalChars} chars\n`);
}
