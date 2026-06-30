import { describe, expect, it } from "vitest";
import { shouldUseUnoptimizedNewsImage } from "./news-image-optimization";

describe("shouldUseUnoptimizedNewsImage", () => {
  it("allows optimizer for local paths", () => {
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

  it("skips optimizer for unknown remote hosts", () => {
    expect(shouldUseUnoptimizedNewsImage("https://example.com/image.jpg")).toBe(true);
  });
});
