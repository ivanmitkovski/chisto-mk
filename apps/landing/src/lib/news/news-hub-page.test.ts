import { describe, expect, it } from "vitest";
import { newsHubPageHref, newsHubRedirectPath } from "./news-hub-page";

describe("newsHubPageHref", () => {
  it("returns /news for first page without category", () => {
    expect(newsHubPageHref(1)).toBe("/news");
  });

  it("includes page and category query params", () => {
    expect(newsHubPageHref(3, "release")).toBe("/news?page=3&category=release");
  });
});

describe("newsHubRedirectPath", () => {
  const pageSize = 9;

  it("returns null for valid page", () => {
    expect(newsHubRedirectPath(2, 18, pageSize)).toBeNull();
  });

  it("redirects to last page when page exceeds total", () => {
    expect(newsHubRedirectPath(5, 18, pageSize)).toBe("/news?page=2");
  });

  it("preserves category when clamping page", () => {
    expect(newsHubRedirectPath(5, 18, pageSize, "community")).toBe(
      "/news?page=2&category=community",
    );
  });

  it("redirects to page 1 when total is zero and page > 1", () => {
    expect(newsHubRedirectPath(3, 0, pageSize, "product")).toBe("/news?category=product");
  });
});
