/** @vitest-environment jsdom */
import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import { StoreDownloadButtons } from "./StoreDownloadButtons";

vi.mock("@/components/molecules/AppStoreButton", () => ({
  AppStoreButton: ({ store }: { store: string }) => (
    <a href={`#${store}`}>{store === "apple" ? "App Store" : "Google Play"}</a>
  ),
}));

const hasStoreDownloadLinks = vi.hoisted(() => vi.fn(() => true));

vi.mock("@/lib/store-links", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@/lib/store-links")>();
  return {
    ...actual,
    hasStoreDownloadLinks: () => hasStoreDownloadLinks(),
  };
});

describe("StoreDownloadButtons", () => {
  it("renders store links when configured", () => {
    hasStoreDownloadLinks.mockReturnValue(true);
    render(<StoreDownloadButtons />);
    expect(screen.getByRole("link", { name: "App Store" })).toBeInTheDocument();
  });

  it("returns null when no store URLs are configured", () => {
    hasStoreDownloadLinks.mockReturnValue(false);
    const { container } = render(<StoreDownloadButtons />);
    expect(container.firstChild).toBeNull();
  });
});
