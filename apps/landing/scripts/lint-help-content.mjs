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
const locales = ["en", "mk", "sq"];

const PLACEHOLDER = /\[(?:TODO|PLACEHOLDER|SUPERVISORY)[^\]]*\]/i;
const TODO_ANGLE = /<todo\b/i;

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
  }
}

if (failed) {
  process.exit(1);
}
console.log("help content lint: OK");
