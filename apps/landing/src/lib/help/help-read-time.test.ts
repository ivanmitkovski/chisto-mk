import { describe, expect, it } from "vitest";
import type { HelpContentBlock } from "@/lib/help/help-messages-schema";
import { estimateReadMinutesFromSections } from "./help-read-time";

function section(title: string, blocks: readonly HelpContentBlock[]) {
  return { title, blocks };
}

describe("estimateReadMinutesFromSections", () => {
  it("returns at least 1 minute for empty body", () => {
    expect(estimateReadMinutesFromSections([section("A", [{ type: "paragraph", text: "x" }])])).toBe(1);
  });

  it("rounds up from word count at 200 wpm", () => {
    const words = Array.from({ length: 200 }, () => "word").join(" ");
    expect(estimateReadMinutesFromSections([section("extra", [{ type: "paragraph", text: words }])])).toBe(2);
  });

  it("includes bullets and section titles", () => {
    const blocks: HelpContentBlock[] = [
      {
        type: "bullets",
        title: "One two",
        items: ["three four five", "six"],
      },
    ];
    const minutes = estimateReadMinutesFromSections([section("Seven eight", blocks)]);
    expect(minutes).toBe(1);
  });
});
