import { describe, expect, it } from "vitest";
import { resolvePreviewBlocks } from "@chisto/news-content/render";
import { sanitizeInlineHtml } from "@chisto/news-content";
import type { NewsBodyBlock } from "@/lib/news/fetch-news";

const releaseParagraphHtml =
  '<p>СКОПЈЕ, 3 јули 2026. <a target="_blank" rel="noopener noreferrer" href="http://Chisto.mk">Chisto.mk</a>, граѓанската еколошка платформа развиена од здружението ЕКОХАБ Скопје, од денес е достапна на App Store и Google Play.</p>';

describe("public news post rendering", () => {
  it("sanitizes release announcement paragraph links", () => {
    const safe = sanitizeInlineHtml(releaseParagraphHtml);
    expect(safe).toContain('href="http://Chisto.mk"');
    expect(safe).toContain("Chisto.mk");
    expect(safe).not.toContain("<script");
  });

  it("resolves preview blocks without throwing", () => {
    const blocks: NewsBodyBlock[] = [
      {
        id: "p1",
        type: "paragraph",
        text: "Plain fallback",
        html: releaseParagraphHtml,
      },
      {
        id: "p2",
        type: "paragraph",
        text: "Second paragraph without html.",
      },
    ];

    const resolved = resolvePreviewBlocks(blocks, new Map());
    expect(resolved).toHaveLength(2);
    expect(resolved[0]?.type).toBe("paragraph");
  });
});
