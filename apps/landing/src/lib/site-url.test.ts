import { afterEach, describe, expect, it } from "vitest";
import { PRODUCTION_SITE_URL, getSiteUrl } from "./site-url";

const ENV_KEYS = [
  "NEXT_PUBLIC_SITE_URL",
  "VERCEL_URL",
  "VERCEL_ENV",
  "NODE_ENV",
] as const;

const originalEnv: Record<string, string | undefined> = {};

function snapshotEnv() {
  for (const key of ENV_KEYS) {
    originalEnv[key] = process.env[key];
  }
}

function restoreEnv() {
  for (const key of ENV_KEYS) {
    const value = originalEnv[key];
    if (value === undefined) delete process.env[key];
    else process.env[key] = value;
  }
}

function clearSeoEnv() {
  delete process.env.NEXT_PUBLIC_SITE_URL;
  delete process.env.VERCEL_URL;
  delete process.env.VERCEL_ENV;
}

describe("getSiteUrl", () => {
  snapshotEnv();
  afterEach(restoreEnv);

  it("uses NEXT_PUBLIC_SITE_URL when set (strips trailing slash)", () => {
    clearSeoEnv();
    process.env.NEXT_PUBLIC_SITE_URL = "https://www.chisto.mk/";
    process.env.VERCEL_ENV = "production";
    process.env.NODE_ENV = "production";
    process.env.VERCEL_URL = "chisto-mk-landing-preview.vercel.app";
    expect(getSiteUrl()).toBe("https://www.chisto.mk");
  });

  it("returns production www when production and env unset (ignores VERCEL_URL)", () => {
    clearSeoEnv();
    process.env.VERCEL_ENV = "production";
    process.env.NODE_ENV = "production";
    process.env.VERCEL_URL = "chisto-mk-landing-1yqpxpfsm.vercel.app";
    expect(getSiteUrl()).toBe(PRODUCTION_SITE_URL);
    expect(getSiteUrl()).not.toContain("vercel.app");
    expect(getSiteUrl()).not.toBe("https://chisto.mk");
  });

  it("uses VERCEL_URL on preview when explicit site URL is unset", () => {
    clearSeoEnv();
    process.env.VERCEL_ENV = "preview";
    process.env.NODE_ENV = "production";
    process.env.VERCEL_URL = "my-preview.vercel.app";
    expect(getSiteUrl()).toBe("https://my-preview.vercel.app");
  });

  it("uses VERCEL_URL in non-production NODE_ENV when explicit site URL is unset", () => {
    clearSeoEnv();
    process.env.NODE_ENV = "development";
    process.env.VERCEL_URL = "local-dev.vercel.app";
    expect(getSiteUrl()).toBe("https://local-dev.vercel.app");
  });

  it("defaults to production www when nothing is set", () => {
    clearSeoEnv();
    process.env.NODE_ENV = "production";
    expect(getSiteUrl()).toBe(PRODUCTION_SITE_URL);
  });
});
