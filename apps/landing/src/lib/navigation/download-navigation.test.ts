import { describe, expect, it } from "vitest";
import { DOWNLOAD_HASH_HREF, isOnHomePage } from "./download-navigation.shared";
import { DOWNLOAD_SECTION_ID } from "@/lib/utils/smooth-scroll";

describe("download-navigation", () => {
  it("builds locale-agnostic home download hash href", () => {
    expect(DOWNLOAD_HASH_HREF).toBe(`/#${DOWNLOAD_SECTION_ID}`);
  });

  it("detects home pathname", () => {
    expect(isOnHomePage("/")).toBe(true);
    expect(isOnHomePage("/news")).toBe(false);
    expect(isOnHomePage("/help/getting-started")).toBe(false);
  });
});
