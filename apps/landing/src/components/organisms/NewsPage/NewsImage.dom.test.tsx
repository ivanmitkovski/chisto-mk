/** @vitest-environment jsdom */
import { describe, expect, it, vi } from "vitest";
import { render, screen, fireEvent } from "@testing-library/react";
import { NewsImage } from "./NewsImage";

vi.mock("next/image", () => ({
  default: ({
    alt,
    onError,
    src,
  }: {
    alt: string;
    onError?: () => void;
    src: string;
  }) => (
    // eslint-disable-next-line @next/next/no-img-element
    <img alt={alt} data-testid="news-img" onError={onError} src={src} />
  ),
}));

describe("NewsImage", () => {
  it("retries once then shows a soft fallback instead of a broken icon", () => {
    render(
      <div className="relative h-24 w-24">
        <NewsImage src="https://api.chisto.mk/v1/news/media/m1" alt="Cover" sizes="96px" />
      </div>,
    );

    fireEvent.error(screen.getByTestId("news-img"));
    // First error triggers an internal remount (retry).
    fireEvent.error(screen.getByTestId("news-img"));
    expect(screen.queryByTestId("news-img")).toBeNull();
  });
});
