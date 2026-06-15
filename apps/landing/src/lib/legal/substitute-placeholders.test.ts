import { describe, expect, it } from "vitest";
import {
  substituteCookieRows,
  substituteLegalSections,
  substituteLegalText,
} from "./substitute-placeholders";

describe("substituteLegalText", () => {
  it("replaces longest keys first via map order in implementation", () => {
    const map: Record<string, string> = {
      "[LONG_TOKEN_SUFFIX]": "X",
      "[LONG_TOKEN]": "Y",
    };
    expect(substituteLegalText("A [LONG_TOKEN_SUFFIX] B [LONG_TOKEN] C", map)).toBe("A X B Y C");
  });

  it("replaces all occurrences", () => {
    const map = { "[X]": "1" };
    expect(substituteLegalText("[X] and [X]", map)).toBe("1 and 1");
  });
});

describe("substituteLegalSections", () => {
  it("maps title and body", () => {
    const map = { "[A]": "Z" };
    const out = substituteLegalSections([{ title: "T [A]", body: "B [A]" }], map);
    expect(out).toEqual([{ title: "T Z", body: "B Z" }]);
  });
});

describe("substituteCookieRows", () => {
  it("substitutes all string fields", () => {
    const map = { "[N]": "Name" };
    const rows = [
      {
        name: "[N]",
        provider: "[N]",
        purpose: "[N]",
        duration: "[N]",
        type: "[N]",
      },
    ];
    expect(substituteCookieRows(rows, map)).toEqual([
      {
        name: "Name",
        provider: "Name",
        purpose: "Name",
        duration: "Name",
        type: "Name",
      },
    ]);
  });
});
