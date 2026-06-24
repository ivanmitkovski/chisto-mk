/** @vitest-environment jsdom */
import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import type { ResolvedNewsPost } from "@/data/news-posts";
import { NewsArticle } from "./NewsArticle";

vi.mock("next/image", () => ({
  default: (props: { alt: string; src: string }) => (
    // eslint-disable-next-line @next/next/no-img-element
    <img alt={props.alt} src={props.src} />
  ),
}));

vi.mock("./NewsReadMoreLink", () => ({
  NewsBackLink: ({ children, href }: { children: React.ReactNode; href: string }) => (
    <a href={href}>{children}</a>
  ),
}));

vi.mock("./NewsShareBar", () => ({
  NewsShareBar: () => null,
}));

vi.mock("./NewsRelatedPosts", () => ({
  NewsRelatedPosts: () => null,
}));

const basePost: ResolvedNewsPost = {
  slug: "sample-post",
  publishedAt: "2026-06-23T06:00:00.000Z",
  category: "release",
  title: "Sample headline",
  excerpt: "Sample excerpt for the article.",
  body: [
    { type: "paragraph", text: "Opening paragraph." },
    {
      type: "image",
      mediaId: "img-1",
      url: "https://cdn.example.com/photo.jpg",
      caption: "A polluted site",
    },
    {
      type: "video",
      mediaId: "vid-1",
      url: "https://cdn.example.com/clip.mp4",
      caption: "Field report",
    },
  ],
};

describe("NewsArticle", () => {
  it("renders paragraph, image, and video blocks", () => {
    render(
      <NewsArticle
        locale="en"
        post={basePost}
        relatedPosts={[]}
        copy={{
          badge: "News",
          backToNews: "Back to news",
          readingTime: "1 min read",
          relatedTitle: "Related stories",
          share: {
            copyLink: "Copy link",
            copyLinkAria: "Copy article link",
            copied: "Link copied",
            share: "Share",
            shareAria: "Share this article",
          },
        }}
        categoryLabel="Release"
        relatedCategoryLabel={() => "Release"}
        jsonLd="{}"
      />,
    );

    expect(screen.getByRole("heading", { level: 1, name: "Sample headline" })).toBeInTheDocument();
    expect(screen.getByText("Opening paragraph.")).toBeInTheDocument();
    expect(screen.getByRole("img", { name: "A polluted site" })).toHaveAttribute(
      "src",
      "https://cdn.example.com/photo.jpg",
    );
    expect(screen.getByText("A polluted site")).toBeInTheDocument();
    const video = document.querySelector("video");
    expect(video).toHaveAttribute("src", "https://cdn.example.com/clip.mp4");
    expect(screen.getByText("Field report")).toBeInTheDocument();
  });
});
