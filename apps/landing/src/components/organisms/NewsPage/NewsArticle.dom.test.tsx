/** @vitest-environment jsdom */
import { describe, expect, it, vi } from "vitest";
import { fireEvent, render, screen } from "@testing-library/react";
import type { ResolvedNewsPost } from "@/data/news-posts";
import { NewsArticle } from "./NewsArticle";

vi.mock("next/image", () => ({
  default: (props: { alt: string; src: string }) => (
    // eslint-disable-next-line @next/next/no-img-element
    <img alt={props.alt} src={props.src} />
  ),
}));

vi.mock("@/i18n/routing", () => ({
  Link: ({ children, href }: { children: React.ReactNode; href: string }) => (
    <a href={href}>{children}</a>
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

vi.mock("next-intl", () => ({
  useTranslations: () => (key: string, values?: { index?: number; total?: number }) => {
    if (key === "gallerySlideLabel" && values) {
      return `Image ${values.index} of ${values.total}`;
    }
    return key;
  },
}));

const articleCopy = {
  badge: "News",
  backToNews: "Back to news",
  readingTime: "1 min read",
  relatedTitle: "Related stories",
  share: {
    copyLink: "Copy link",
    copyLinkAria: "Copy article link",
    copied: "Link copied",
    copyLinkFailed: "Could not copy link",
    share: "Share",
    shareAria: "Share this article",
  },
  imageUnavailable: "Image unavailable",
  videoUnavailable: "Video unavailable",
  galleryClose: "Close gallery",
  galleryPrevious: "Previous image",
  galleryNext: "Next image",
  galleryUnavailable: "Gallery unavailable",
  galleryAriaLabel: "Image gallery",
  breadcrumbHome: "Home",
  breadcrumbNews: "News",
  breadcrumbAriaLabel: "Breadcrumb",
  updatedLabel: (date: string) => `Updated ${date}`,
};

const fullBlockPost: ResolvedNewsPost = {
  slug: "all-blocks",
  publishedAt: "2026-06-23T06:00:00.000Z",
  updatedAt: "2026-06-24T06:00:00.000Z",
  category: "release",
  title: "All block types",
  excerpt: "Sample excerpt for the article.",
  body: [
    { type: "paragraph", text: "Opening paragraph." },
    { type: "heading", level: 2, text: "Section title" },
    { type: "list", ordered: false, items: ["First item", "Second item"] },
    {
      type: "html",
      html: '<div class="news-embed"><iframe src="https://www.youtube-nocookie.com/embed/demo" title="Demo"></iframe></div>',
    },
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
    {
      type: "gallery",
      items: [
        {
          mediaId: "g-1",
          url: "https://cdn.example.com/g1.jpg",
          altText: "Gallery one",
        },
        {
          mediaId: "g-2",
          url: "https://cdn.example.com/g2.jpg",
          altText: "Gallery two",
        },
      ],
    },
  ],
};

describe("NewsArticle", () => {
  it("renders all seven block types and breadcrumb trail", () => {
    render(
      <NewsArticle
        locale="en"
        post={fullBlockPost}
        relatedPosts={[]}
        copy={articleCopy}
        categoryLabel="Release"
        relatedCategoryLabel={() => "Release"}
        jsonLd="{}"
      />,
    );

    expect(screen.getByRole("navigation", { name: "Breadcrumb" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Home" })).toHaveAttribute("href", "/");
    expect(screen.getByRole("link", { name: "News" })).toHaveAttribute("href", "/news");
    expect(screen.getByRole("heading", { level: 1, name: "All block types" })).toBeInTheDocument();
    expect(screen.getByText("Opening paragraph.")).toBeInTheDocument();
    expect(screen.getByRole("heading", { level: 2, name: "Section title" })).toBeInTheDocument();
    expect(screen.getByText("First item")).toBeInTheDocument();
    expect(document.querySelector("iframe")).toHaveAttribute(
      "src",
      "https://www.youtube-nocookie.com/embed/demo",
    );
    expect(screen.getByRole("img", { name: "A polluted site" })).toHaveAttribute(
      "src",
      "https://cdn.example.com/photo.jpg",
    );
    const video = document.querySelector("video");
    expect(video).toHaveAttribute("src", "https://cdn.example.com/clip.mp4");
    expect(screen.getByLabelText("Gallery one")).toBeInTheDocument();
    expect(screen.getByText(/Updated/)).toBeInTheDocument();
  });

  it("passes localized gallery labels to carousel controls", () => {
    render(
      <NewsArticle
        locale="en"
        post={{
          ...fullBlockPost,
          body: [
            {
              type: "gallery",
              items: [
                { mediaId: "g-1", url: "https://cdn.example.com/g1.jpg", altText: "One" },
                { mediaId: "g-2", url: "https://cdn.example.com/g2.jpg", altText: "Two" },
              ],
            },
          ],
        }}
        relatedPosts={[]}
        copy={articleCopy}
        categoryLabel="Release"
        relatedCategoryLabel={() => "Release"}
        jsonLd="{}"
      />,
    );

    expect(screen.getByLabelText("One")).toBeInTheDocument();
    fireEvent.click(screen.getByLabelText("One"));
    expect(screen.getByRole("button", { name: "Close gallery" })).toBeInTheDocument();
    expect(screen.getByLabelText("Image 1 of 2")).toBeInTheDocument();
  });
});
