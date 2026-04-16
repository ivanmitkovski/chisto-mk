/**
 * One-off style: convert helpCentre article sections from legacy `body` to `blocks`.
 * Run: node scripts/migrate-help-to-blocks.mjs
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const messagesDir = path.join(__dirname, "..", "messages");

for (const locale of ["en", "mk", "sq"]) {
  const fp = path.join(messagesDir, `${locale}.json`);
  const raw = fs.readFileSync(fp, "utf8");
  const j = JSON.parse(raw);
  const articles = j.helpCentre?.articles;
  if (!articles) continue;

  for (const slug of Object.keys(articles)) {
    const article = articles[slug];
    if (!article?.sections) continue;
    for (const sec of article.sections) {
      if (Array.isArray(sec.blocks)) continue;
      const body = typeof sec.body === "string" ? sec.body : "";
      delete sec.body;
      const text = body
        .replace(/\u2014/g, ", ")
        .replace(/\u2013/g, "-")
        .replace(/--+/g, " ")
        .replace(/\bNorth Macedonia\b/g, "Macedonia")
        .trim();
      sec.blocks = [{ type: "paragraph", text: text.length > 0 ? text : " " }];
    }
  }

  fs.writeFileSync(fp, `${JSON.stringify(j, null, 2)}\n`);
  console.log("updated", fp);
}
