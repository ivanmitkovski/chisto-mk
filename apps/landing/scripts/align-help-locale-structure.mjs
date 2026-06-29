#!/usr/bin/env node
/**
 * Align MK/SQ help article JSON to EN block structure (canonical shape for i18n parity).
 * Preserves translated strings where section id + block type + field path match.
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const contentDir = path.join(__dirname, "..", "content", "help");

function mergeBlock(enBlock, locBlock) {
  if (!locBlock || locBlock.type !== enBlock.type) {
    return structuredClone(enBlock);
  }
  const out = structuredClone(enBlock);
  for (const [key, value] of Object.entries(locBlock)) {
    if (key === "type" || key === "items") continue;
    if (typeof value === "string") {
      out[key] = value;
    }
  }
  if (enBlock.type === "bullets" && Array.isArray(enBlock.items)) {
    out.items = enBlock.items.map((enItem, i) => locBlock.items?.[i] ?? enItem);
  }
  if (enBlock.type === "steps" && Array.isArray(enBlock.items)) {
    out.items = enBlock.items.map((enStep, i) => {
      const locStep = locBlock.items?.[i];
      if (!locStep) return structuredClone(enStep);
      return {
        title: locStep.title ?? enStep.title,
        text: locStep.text ?? enStep.text,
      };
    });
  }
  return out;
}

function alignArticle(enArticle, locArticle) {
  const loc = locArticle ?? {};
  const out = structuredClone(enArticle);
  for (const [key, value] of Object.entries(enArticle)) {
    if (key === "sections") continue;
    if (typeof value === "string" && typeof loc[key] === "string") {
      out[key] = loc[key];
    }
  }
  out.sections = enArticle.sections.map((enSection) => {
    const locSection =
      loc.sections?.find((s) => s.id === enSection.id) ??
      loc.sections?.[enArticle.sections.indexOf(enSection)];
    return {
      id: enSection.id,
      title: locSection?.title ?? enSection.title,
      blocks: enSection.blocks.map((enBlock, blockIndex) => {
        const locBlock =
          locSection?.blocks?.[blockIndex]?.type === enBlock.type
            ? locSection.blocks[blockIndex]
            : locSection?.blocks?.find((b) => b.type === enBlock.type);
        return mergeBlock(enBlock, locBlock);
      }),
    };
  });
  return out;
}

const enArticles = JSON.parse(
  fs.readFileSync(path.join(contentDir, "articles.en.json"), "utf8"),
);

for (const locale of ["mk", "sq"]) {
  const localePath = path.join(contentDir, `articles.${locale}.json`);
  const locArticles = JSON.parse(fs.readFileSync(localePath, "utf8"));
  const aligned = {};
  for (const slug of Object.keys(enArticles)) {
    aligned[slug] = alignArticle(enArticles[slug], locArticles[slug]);
  }
  fs.writeFileSync(localePath, `${JSON.stringify(aligned, null, 2)}\n`, "utf8");
  console.log(`aligned articles.${locale}.json → ${Object.keys(aligned).length} articles`);
}

console.log("align-help-locale-structure: OK");
