import { describe, expect, it } from "vitest";
import {
  httpsAppUrlToAndroidIntent,
  httpsAppUrlToCustomScheme,
  isAppDeepLinkPath,
  resolveAppHttpsUrl,
  stripLocalePrefixedAppPath,
} from "./app-deep-link";

describe("isAppDeepLinkPath", () => {
  it("matches /app and nested paths", () => {
    expect(isAppDeepLinkPath("/app")).toBe(true);
    expect(isAppDeepLinkPath("/app/home/map-focus")).toBe(true);
    expect(isAppDeepLinkPath("/app/events/detail/abc")).toBe(true);
  });

  it("rejects share and marketing paths", () => {
    expect(isAppDeepLinkPath("/sites/cuid")).toBe(false);
    expect(isAppDeepLinkPath("/mk/app/home")).toBe(false);
    expect(isAppDeepLinkPath("/apple")).toBe(false);
  });
});

describe("stripLocalePrefixedAppPath", () => {
  it("strips mk/en/sq prefixes from /app paths", () => {
    expect(stripLocalePrefixedAppPath("/mk/app/home/map-focus")).toBe("/app/home/map-focus");
    expect(stripLocalePrefixedAppPath("/en/app")).toBe("/app");
    expect(stripLocalePrefixedAppPath("/sq/app/events/detail/x")).toBe("/app/events/detail/x");
  });

  it("returns null for non-prefixed paths", () => {
    expect(stripLocalePrefixedAppPath("/app/home")).toBeNull();
    expect(stripLocalePrefixedAppPath("/mk/sites/x")).toBeNull();
  });
});

describe("httpsAppUrlToCustomScheme", () => {
  it("mirrors path and query onto chisto://", () => {
    expect(
      httpsAppUrlToCustomScheme(
        "https://www.chisto.mk/app/home/map-focus?siteId=c123&st=tok",
      ),
    ).toBe("chisto://app/home/map-focus?siteId=c123&st=tok");
  });

  it("rejects non-app URLs", () => {
    expect(httpsAppUrlToCustomScheme("https://www.chisto.mk/sites/c123")).toBeNull();
    expect(httpsAppUrlToCustomScheme("not-a-url")).toBeNull();
  });
});

describe("httpsAppUrlToAndroidIntent", () => {
  it("builds an intent URL with package and fallback", () => {
    const intent = httpsAppUrlToAndroidIntent(
      "https://www.chisto.mk/app/home/map-focus?siteId=c1",
      "https://play.google.com/store/apps/details?id=mk.chisto.app",
    );
    expect(intent).toContain("intent://app/home/map-focus?siteId=c1#Intent;");
    expect(intent).toContain("scheme=chisto;");
    expect(intent).toContain("package=mk.chisto.app;");
    expect(intent).toContain("S.browser_fallback_url=");
  });
});

describe("resolveAppHttpsUrl", () => {
  it("resolves relative app paths against origin", () => {
    expect(resolveAppHttpsUrl("/app/home/map-focus?siteId=1", "https://www.chisto.mk")).toBe(
      "https://www.chisto.mk/app/home/map-focus?siteId=1",
    );
  });
});
