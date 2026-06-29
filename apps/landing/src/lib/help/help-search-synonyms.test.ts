import { describe, expect, it } from "vitest";
import { expandHelpSearchQuery } from "./help-search-synonyms";

describe("expandHelpSearchQuery", () => {
  it("expands OTP to verification terms", () => {
    expect(expandHelpSearchQuery("otp")).toContain("verification");
  });

  it("expands QR to check-in terms", () => {
    expect(expandHelpSearchQuery("qr check-in")).toContain("scan");
  });

  it("returns original query when no synonyms", () => {
    expect(expandHelpSearchQuery("hello")).toBe("hello");
  });
});
