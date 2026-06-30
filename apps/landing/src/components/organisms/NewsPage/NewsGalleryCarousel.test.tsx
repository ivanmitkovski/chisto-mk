/** @vitest-environment jsdom */
import { describe, expect, it, vi } from "vitest";
import { fireEvent, render, screen } from "@testing-library/react";
import { NewsGalleryCarousel } from "./NewsGalleryCarousel";

vi.mock("next/image", () => ({
  default: (props: { alt: string; src: string }) => (
    // eslint-disable-next-line @next/next/no-img-element
    <img alt={props.alt} src={props.src} />
  ),
}));

vi.mock("next-intl", () => ({
  useTranslations: () => (key: string, values?: { index?: number; total?: number }) => {
    if (key === "gallerySlideLabel" && values) {
      return `Slide ${values.index} of ${values.total}`;
    }
    return key;
  },
}));

const items = [
  { id: "a", src: "https://cdn.example.com/a.jpg", alt: "Photo A" },
  { id: "b", src: "https://cdn.example.com/b.jpg", alt: "Photo B", caption: "Caption B" },
];

describe("NewsGalleryCarousel", () => {
  it("opens lightbox with localized close label and focuses close button", () => {
    render(
      <NewsGalleryCarousel
        items={items}
        imageUnavailableLabel="No images"
        closeLabel="Close gallery"
        previousLabel="Previous image"
        nextLabel="Next image"
        dialogLabel="Image gallery"
      />,
    );

    fireEvent.click(screen.getByLabelText("Photo A"));
    expect(screen.getByRole("dialog")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Close gallery" })).toHaveFocus();
    expect(screen.getByLabelText("Slide 1 of 2")).toBeInTheDocument();
  });
});
