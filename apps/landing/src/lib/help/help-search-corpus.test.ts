import { describe, expect, it } from "vitest";
import { helpBlocksToSearchText, helpSectionsToSearchText } from "./help-search-corpus";
import type { HelpContentBlock } from "./help-messages-schema";

describe("help-search-corpus", () => {
  it("extracts text from all block types", () => {
    const blocks: HelpContentBlock[] = [
      { type: "paragraph", text: "Hello world" },
      { type: "bullets", title: "Tips", items: ["One", "Two"] },
      { type: "callout", variant: "tip", text: "Quick tip" },
      { type: "internalLink", href: "/help/report-a-site", label: "Report guide" },
      {
        type: "steps",
        title: "Steps",
        items: [{ title: "Open app", text: "Tap Home" }],
      },
    ];
    const text = helpBlocksToSearchText(blocks);
    expect(text).toContain("Hello world");
    expect(text).toContain("Quick tip");
    expect(text).toContain("Open app");
    expect(text).toContain("Report guide");
  });

  it("includes section titles in corpus", () => {
    const text = helpSectionsToSearchText([
      {
        title: "QR check-in",
        blocks: [{ type: "paragraph", text: "Scan at the event." }],
      },
    ]);
    expect(text).toContain("QR check-in");
    expect(text).toContain("Scan at the event.");
  });
});
