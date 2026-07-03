import { describe, expect, it } from "vitest";
import { NEWS_COVER_ASPECT_CLASS, newsCoverFrameClass } from "./news-cover-display";

describe("newsCoverFrameClass", () => {
  it("uses the 21:9 aspect ratio aligned with CMS cover guidance", () => {
    expect(NEWS_COVER_ASPECT_CLASS).toBe("aspect-[21/9]");
    expect(newsCoverFrameClass("shrink-0")).toContain("aspect-[21/9]");
    expect(newsCoverFrameClass("shrink-0")).toContain("shrink-0");
  });
});
