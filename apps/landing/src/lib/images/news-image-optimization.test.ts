import { describe, expect, it } from "vitest";
import { newsImageObjectFitClass, shouldUseUnoptimizedNewsImage } from "./news-image-optimization";

describe("shouldUseUnoptimizedNewsImage", () => {
  it("always skips optimizer for SVG assets", () => {
    expect(shouldUseUnoptimizedNewsImage("/news/cover.svg")).toBe(true);
    expect(
      shouldUseUnoptimizedNewsImage(
        "https://bucket.s3.amazonaws.com/news/logo.svg?X-Amz-Signature=abc",
      ),
    ).toBe(true);
  });

  it("allows optimizer for local raster paths", () => {
    expect(shouldUseUnoptimizedNewsImage("/news/cover.png")).toBe(false);
  });

  it("allows optimizer for stable CloudFront URLs", () => {
    expect(shouldUseUnoptimizedNewsImage("https://d111.cloudfront.net/news/cover.jpg")).toBe(false);
  });

  it("skips optimizer for presigned S3 URLs", () => {
    expect(
      shouldUseUnoptimizedNewsImage(
        "https://bucket.s3.amazonaws.com/key.jpg?X-Amz-Signature=abc",
      ),
    ).toBe(true);
  });

  it("skips optimizer for stable API media redirect URLs", () => {
    expect(
      shouldUseUnoptimizedNewsImage("https://api.chisto.mk/v1/news/media/media-1"),
    ).toBe(true);
    expect(
      shouldUseUnoptimizedNewsImage("https://api.chisto.mk/v1/sites/site1/share-media/0"),
    ).toBe(true);
    expect(
      shouldUseUnoptimizedNewsImage("https://api.chisto.mk/v1/sites/site1/share-avatar"),
    ).toBe(true);
  });

  it("skips optimizer for unknown remote hosts", () => {
    expect(shouldUseUnoptimizedNewsImage("https://example.com/image.jpg")).toBe(true);
  });
});

describe("newsImageObjectFitClass", () => {
  it("uses object-contain for SVG", () => {
    expect(newsImageObjectFitClass("/news/logo.svg")).toBe("object-contain object-center");
  });

  it("uses object-cover for cover images", () => {
    expect(newsImageObjectFitClass("/news/cover.jpg", "cover")).toBe("object-cover object-center");
  });

  it("uses object-cover for inline raster images", () => {
    expect(newsImageObjectFitClass("/news/inline.jpg")).toBe("object-cover object-center");
  });
});
