import { afterEach, describe, expect, it, vi } from "vitest";
import {
  VERCEL_INSIGHTS_SCRIPT,
  isVercelInsightsScriptReady,
} from "./vercel-insights-ready";

afterEach(() => {
  vi.restoreAllMocks();
});

describe("isVercelInsightsScriptReady", () => {
  it("returns true for a JS content-type on HEAD", async () => {
    const fetchImpl = vi.fn().mockResolvedValue({
      ok: true,
      headers: { get: () => "application/javascript; charset=utf-8" },
    });
    await expect(isVercelInsightsScriptReady(fetchImpl)).resolves.toBe(true);
    expect(fetchImpl).toHaveBeenCalledWith(
      VERCEL_INSIGHTS_SCRIPT,
      expect.objectContaining({ method: "HEAD", cache: "no-store" }),
    );
    expect(fetchImpl).toHaveBeenCalledTimes(1);
  });

  it("falls back to GET when HEAD has no content-type", async () => {
    const fetchImpl = vi
      .fn()
      .mockResolvedValueOnce({
        ok: true,
        headers: { get: () => null },
      })
      .mockResolvedValueOnce({
        ok: true,
        headers: { get: () => "application/javascript" },
      });
    await expect(isVercelInsightsScriptReady(fetchImpl)).resolves.toBe(true);
    expect(fetchImpl).toHaveBeenNthCalledWith(
      1,
      VERCEL_INSIGHTS_SCRIPT,
      expect.objectContaining({ method: "HEAD" }),
    );
    expect(fetchImpl).toHaveBeenNthCalledWith(
      2,
      VERCEL_INSIGHTS_SCRIPT,
      expect.objectContaining({ method: "GET" }),
    );
  });

  it("returns false when the path returns HTML (404 fallback)", async () => {
    const fetchImpl = vi.fn().mockResolvedValue({
      ok: true,
      headers: { get: () => "text/html; charset=utf-8" },
    });
    await expect(isVercelInsightsScriptReady(fetchImpl)).resolves.toBe(false);
  });

  it("returns false on HTTP error after GET fallback", async () => {
    const fetchImpl = vi
      .fn()
      .mockResolvedValueOnce({
        ok: false,
        headers: { get: () => "application/javascript" },
      })
      .mockResolvedValueOnce({
        ok: false,
        headers: { get: () => "text/html" },
      });
    await expect(isVercelInsightsScriptReady(fetchImpl)).resolves.toBe(false);
  });

  it("returns false when fetch throws", async () => {
    const fetchImpl = vi.fn().mockRejectedValue(new Error("network"));
    await expect(isVercelInsightsScriptReady(fetchImpl)).resolves.toBe(false);
  });
});
