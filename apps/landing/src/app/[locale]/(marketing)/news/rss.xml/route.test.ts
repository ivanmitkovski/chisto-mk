import { beforeEach, describe, expect, it, vi } from "vitest";
import { GET } from "./route";
import { fetchNewsPostBySlug, fetchNewsPosts } from "@/lib/news/fetch-news";
import { NewsFetchError } from "@/lib/news/news-fetch-error";

vi.mock("@/config/launch", () => ({
  isLaunchPageVisible: vi.fn(() => true),
}));

vi.mock("@/lib/news/fetch-news", () => ({
  fetchNewsPosts: vi.fn(),
  fetchNewsPostBySlug: vi.fn(),
}));

vi.mock("@/lib/site-url", () => ({
  getSiteUrl: () => "https://chisto.mk",
}));

vi.mock("next-intl/server", () => ({
  getTranslations: vi.fn(async () => (key: string) => {
    if (key === "title") return "News";
    if (key === "siteName") return "Chisto";
    if (key === "lead") return "Latest updates";
    return key;
  }),
}));

vi.mock("next/navigation", () => ({
  notFound: vi.fn(() => {
    throw new Error("notFound");
  }),
}));

describe("news RSS route", () => {
  beforeEach(() => {
    vi.mocked(fetchNewsPosts).mockReset();
    vi.mocked(fetchNewsPostBySlug).mockReset();
  });

  it("returns valid empty RSS when fetchNewsPosts fails", async () => {
    vi.mocked(fetchNewsPosts).mockRejectedValue(new NewsFetchError("News list request failed (503)"));
    const consoleSpy = vi.spyOn(console, "error").mockImplementation(() => {});

    const response = await GET(new Request("http://localhost/en/news/rss.xml"), {
      params: Promise.resolve({ locale: "en" }),
    });
    const xml = await response.text();

    expect(response.status).toBe(200);
    expect(response.headers.get("Content-Type")).toContain("application/rss+xml");
    expect(xml).toContain('<?xml version="1.0" encoding="UTF-8"?>');
    expect(xml).toContain('<rss version="2.0"');
    expect(xml).toContain("<channel>");
    expect(xml).not.toContain("<item>");
    expect(consoleSpy).toHaveBeenCalledWith("RSS fetchNewsPosts failed", expect.any(NewsFetchError));

    consoleSpy.mockRestore();
  });

  it("returns RSS items when fetchNewsPosts succeeds", async () => {
    vi.mocked(fetchNewsPosts).mockResolvedValue({
      total: 1,
      items: [
        {
          slug: "launch-2026",
          publishedAt: "2026-06-23T06:00:00.000Z",
          category: "release",
          title: "Chisto.mk launches on the App Store",
          excerpt: "The civic environmental platform went live on Apple's App Store.",
          body: [],
          featured: true,
        },
      ],
    });
    vi.mocked(fetchNewsPostBySlug).mockResolvedValue({
      slug: "launch-2026",
      publishedAt: "2026-06-23T06:00:00.000Z",
      category: "release",
      title: "Chisto.mk launches on the App Store",
      excerpt: "The civic environmental platform went live on Apple's App Store.",
      body: [{ type: "paragraph", text: "Full article body." }],
    });

    const response = await GET(new Request("http://localhost/en/news/rss.xml"), {
      params: Promise.resolve({ locale: "en" }),
    });
    const xml = await response.text();

    expect(fetchNewsPostBySlug).toHaveBeenCalledWith("en", "launch-2026");
    expect(response.status).toBe(200);
    expect(response.headers.get("Content-Type")).toContain("application/rss+xml");
    expect(xml).toContain("<item>");
    expect(xml).toContain("<title>Chisto.mk launches on the App Store</title>");
    expect(xml).toContain("https://chisto.mk/en/news/launch-2026");
    expect(xml).toContain("Apple&apos;s App Store");
    expect(xml).toContain("<content:encoded>");
    expect(xml).toContain("Full article body.");
  });

  it("includes enriched image URLs in content:encoded", async () => {
    vi.mocked(fetchNewsPosts).mockResolvedValue({
      total: 1,
      items: [
        {
          slug: "photo-post",
          publishedAt: "2026-06-23T06:00:00.000Z",
          category: "community",
          title: "Photo story",
          excerpt: "Excerpt.",
          body: [],
        },
      ],
    });
    vi.mocked(fetchNewsPostBySlug).mockResolvedValue({
      slug: "photo-post",
      publishedAt: "2026-06-23T06:00:00.000Z",
      category: "community",
      title: "Photo story",
      excerpt: "Excerpt.",
      body: [
        {
          type: "image",
          mediaId: "img-1",
          url: "https://cdn.example.com/photo.jpg",
          altText: "Field photo",
        },
      ],
    });

    const response = await GET(new Request("http://localhost/mk/news/rss.xml"), {
      params: Promise.resolve({ locale: "mk" }),
    });
    const xml = await response.text();

    expect(fetchNewsPostBySlug).toHaveBeenCalledWith("mk", "photo-post");
    expect(xml).toContain("<content:encoded>");
    expect(xml).toContain("https://cdn.example.com/photo.jpg");
  });
});
