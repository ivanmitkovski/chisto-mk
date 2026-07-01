#!/usr/bin/env node
/**
 * Validates relative markdown links resolve to files in the repo.
 * Skips http(s), mailto, anchors-only, and code spans.
 *
 *   node scripts/check-doc-links.mjs
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const LINK_RE = /(?<!!)\[([^\]]*)\]\(([^)]+)\)/g;
const SKIP_SCHEMES = /^(https?:|mailto:|#)/i;

function listMarkdownFiles(dir, acc = []) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    if (entry.name.startsWith(".") && entry.name !== ".github") continue;
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (
        [
          "node_modules",
          ".next",
          "dist",
          "build",
          ".git",
          "coverage",
          "Pods",
          "ios",
          "android",
        ].includes(entry.name)
      ) {
        continue;
      }
      listMarkdownFiles(full, acc);
    } else if (entry.name.endsWith(".md")) {
      acc.push(full);
    }
  }
  return acc;
}

function resolveLink(fromFile, target) {
  const cleaned = target.split("#")[0].split("?")[0].trim();
  if (!cleaned || SKIP_SCHEMES.test(cleaned)) return null;
  if (cleaned.startsWith("<") && cleaned.endsWith(">")) return null;
  const abs = path.resolve(path.dirname(fromFile), cleaned);
  const normalizedRoot = `${root}${path.sep}`;
  if (!abs.startsWith(normalizedRoot) && abs !== root) {
    return { abs, reason: "outside repo" };
  }
  if (fs.existsSync(abs)) return null;
  if (fs.existsSync(`${abs}.md`)) return null;
  return { abs, reason: "missing" };
}

const files = listMarkdownFiles(root);
const errors = [];

for (const file of files) {
  const content = fs.readFileSync(file, "utf8");
  let match;
  while ((match = LINK_RE.exec(content)) !== null) {
    const [, , rawTarget] = match;
    const result = resolveLink(file, rawTarget);
    if (result) {
      errors.push({
        file: path.relative(root, file),
        target: rawTarget,
        resolved: path.relative(root, result.abs),
        reason: result.reason,
      });
    }
  }
}

if (errors.length > 0) {
  console.error("Broken markdown links:\n");
  for (const e of errors) {
    console.error(`  ${e.file}`);
    console.error(`    -> ${e.target} (${e.reason}: ${e.resolved})\n`);
  }
  process.exit(1);
}

console.log(`OK: ${files.length} markdown files, no broken relative links.`);
