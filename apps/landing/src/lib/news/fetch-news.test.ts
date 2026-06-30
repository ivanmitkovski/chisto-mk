import { afterEach, describe, expect, it, vi } from "vitest";
import { fetchNewsPostBySlug } from "./fetch-news";
import { NewsFetchError } from "./news-fetch-error";

vi.mock("./e2e-fixture", () => ({
  isE2eNewsFixtureEnabled: () => false,
  e2eNewsPosts: vi.fn(),
  e2eNewsPostBySlug: vi.fn(),
  e2eNewsSlugs: vi.fn(),
}));

describe("fetchNewsPostBySlug", () => {
  afterEach(() => {
    vi.unstubAllGlobals();
    vi.unstubAllEnvs();
  });

  it("throws NewsFetchError on article 5xx", async () => {
    vi.stubEnv("NEXT_PUBLIC_CHISTO_API_URL", "https://api.example.test/v1");
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({
        status: 503,
        ok: false,
      }),
    );

    await expect(fetchNewsPostBySlug("en", "server-error-slug")).rejects.toBeInstanceOf(
      NewsFetchError,
    );
    await expect(fetchNewsPostBySlug("en", "server-error-slug")).rejects.toThrow(
      "News post request failed (503)",
    );
  });

  it("returns null on article 404", async () => {
    vi.stubEnv("NEXT_PUBLIC_CHISTO_API_URL", "https://api.example.test/v1");
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({
        status: 404,
        ok: false,
      }),
    );

    await expect(fetchNewsPostBySlug("en", "missing-slug")).resolves.toBeNull();
  });

  it("enriches image and gallery blocks with locale alt text fallback", async () => {
    vi.stubEnv("NEXT_PUBLIC_CHISTO_API_URL", "https://api.example.test/v1");
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({
        status: 200,
        ok: true,
        json: async () => ({
          slug: "photo-story",
          category: "community",
          publishedAt: "2026-06-23T06:00:00.000Z",
          title: "Photo story",
          excerpt: "Excerpt",
          coverImageUrl: null,
          body: [
            {
              type: "image",
              mediaId: "img-1",
            },
            {
              type: "gallery",
              items: [{ mediaId: "img-2" }, { mediaId: "img-3" }],
            },
          ],
          media: [
            {
              id: "img-1",
              url: "https://cdn.example.com/a.jpg",
              kind: "inline",
              altText: { en: "English alt" },
            },
            {
              id: "img-2",
              url: "https://cdn.example.com/b.jpg",
              kind: "inline",
              altText: { mk: "MK alt" },
            },
            {
              id: "img-3",
              url: "https://cdn.example.com/c.jpg",
              kind: "inline",
              altText: { en: "Slide three" },
            },
          ],
        }),
      }),
    );

    const post = await fetchNewsPostBySlug("mk", "photo-story");
    expect(post?.body[0]).toMatchObject({
      type: "image",
      url: "https://cdn.example.com/a.jpg",
      altText: "English alt",
    });
    expect(post?.body[1]).toMatchObject({
      type: "gallery",
      items: [
        { url: "https://cdn.example.com/b.jpg", altText: "MK alt" },
        { url: "https://cdn.example.com/c.jpg", altText: "Slide three" },
      ],
    });
  });
});
