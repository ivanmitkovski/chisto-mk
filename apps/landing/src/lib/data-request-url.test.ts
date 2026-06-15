import { describe, expect, it } from "vitest";
import { getDataRequestChannelHref } from "./data-request-url";

describe("getDataRequestChannelHref", () => {
  it("returns null for missing or blank", () => {
    expect(getDataRequestChannelHref(undefined)).toBeNull();
    expect(getDataRequestChannelHref("")).toBeNull();
    expect(getDataRequestChannelHref("  ")).toBeNull();
  });

  it("normalises https and mailto", () => {
    expect(getDataRequestChannelHref("https://example.com/r")).toBe("https://example.com/r");
    expect(getDataRequestChannelHref("mailto:a@b.co")).toBe("mailto:a@b.co");
  });

  it("wraps bare email", () => {
    expect(getDataRequestChannelHref("privacy@chisto.mk")).toBe("mailto:privacy@chisto.mk");
  });

  it("returns null for ambiguous strings", () => {
    expect(getDataRequestChannelHref("not-a-url")).toBeNull();
  });
});
