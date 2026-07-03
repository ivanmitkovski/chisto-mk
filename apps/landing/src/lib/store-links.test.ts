import { afterEach, describe, expect, it, vi } from "vitest";
import {
  APP_STORE_APP_ID,
  APP_STORE_LISTING_SLUG,
  APP_STORE_URL_DEFAULT,
  GOOGLE_PLAY_PACKAGE_ID,
  GOOGLE_PLAY_URL_DEFAULT,
  getAppStoreUrl,
  getGooglePlayUrl,
  hasStoreDownloadLinks,
  homeDownloadSectionUrl,
} from "./store-links";

describe("store-links", () => {
  afterEach(() => {
    vi.unstubAllEnvs();
  });

  it("returns the live App Store URL by default", () => {
    expect(getAppStoreUrl()).toBe(APP_STORE_URL_DEFAULT);
    expect(APP_STORE_URL_DEFAULT).toBe(
      `https://apps.apple.com/mk/app/${APP_STORE_LISTING_SLUG}/id${APP_STORE_APP_ID}`,
    );
    expect(hasStoreDownloadLinks()).toBe(true);
  });

  it("allows env override for App Store URL", () => {
    vi.stubEnv("NEXT_PUBLIC_APP_STORE_URL", "https://apps.apple.com/app/example/id1");
    expect(getAppStoreUrl()).toBe("https://apps.apple.com/app/example/id1");
  });

  it("rejects non-https store URLs", () => {
    vi.stubEnv("NEXT_PUBLIC_APP_STORE_URL", "http://example.com");
    expect(getAppStoreUrl()).toBe(APP_STORE_URL_DEFAULT);
  });

  it("returns the live Google Play URL by default", () => {
    expect(getGooglePlayUrl()).toBe(GOOGLE_PLAY_URL_DEFAULT);
    expect(GOOGLE_PLAY_URL_DEFAULT).toBe(
      `https://play.google.com/store/apps/details?id=${GOOGLE_PLAY_PACKAGE_ID}`,
    );
    expect(hasStoreDownloadLinks()).toBe(true);
  });

  it("allows env override for Google Play URL", () => {
    vi.stubEnv("NEXT_PUBLIC_GOOGLE_PLAY_URL", "https://play.google.com/store/apps/details?id=example");
    expect(getGooglePlayUrl()).toBe("https://play.google.com/store/apps/details?id=example");
  });

  it("builds locale-aware home download anchors", () => {
    expect(homeDownloadSectionUrl("https://chisto.mk", "mk")).toBe("https://chisto.mk/mk#download");
  });
});
