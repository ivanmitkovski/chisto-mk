import { afterEach, describe, expect, it, vi } from "vitest";
import React from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { LatestNewsSection } from "./LatestNewsSection";
import { NewsFetchError } from "@/lib/news/news-fetch-error";

vi.mock("next-intl/server", () => ({
  getTranslations: vi.fn(async () => {
    const t = (key: string) => key;
    return Object.assign(t, { raw: (key: string) => key });
  }),
}));

vi.mock("@/config/launch", () => ({
  isLaunchPageVisible: () => true,
}));

vi.mock("@/data/news-posts", () => ({
  getLatestNewsPosts: vi.fn(),
}));

vi.mock("next/image", () => ({
  default: (props: { alt?: string }) => <img alt={props.alt ?? ""} />,
}));

vi.mock("@/i18n/routing", () => ({
  Link: ({ children, href }: { children: React.ReactNode; href: string }) => (
    <a href={href}>{children}</a>
  ),
}));

import { getLatestNewsPosts } from "@/data/news-posts";

describe("LatestNewsSection", () => {
  afterEach(() => {
    vi.clearAllMocks();
  });

  it("renders error panel when news fetch fails", async () => {
    vi.mocked(getLatestNewsPosts).mockRejectedValue(new NewsFetchError("News request failed (503)"));

    const tree = await LatestNewsSection({ locale: "en" });
    const html = renderToStaticMarkup(tree as React.ReactElement);

    expect(html).toContain("errorTitle");
    expect(html).not.toBe("");
  });

  it("renders empty panel when there are no posts", async () => {
    vi.mocked(getLatestNewsPosts).mockResolvedValue([]);

    const tree = await LatestNewsSection({ locale: "en" });
    const html = renderToStaticMarkup(tree as React.ReactElement);

    expect(html).toContain("emptyTitle");
  });
});
