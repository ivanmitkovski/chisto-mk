import { describe, expect, it } from "vitest";
import { splitParagraphs } from "./split-paragraphs";

describe("splitParagraphs", () => {
  it("splits on blank lines", () => {
    expect(splitParagraphs("a\n\nb")).toEqual(["a", "b"]);
  });

  it("trims and drops empties", () => {
    expect(splitParagraphs("  x  \n\n y ")).toEqual(["x", "y"]);
  });

  it("returns single paragraph when no breaks", () => {
    expect(splitParagraphs("only")).toEqual(["only"]);
  });
});
