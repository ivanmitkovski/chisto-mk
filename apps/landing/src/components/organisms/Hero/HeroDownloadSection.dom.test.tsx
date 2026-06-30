/** @vitest-environment jsdom */
import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import { DOWNLOAD_SECTION_ID } from "@/lib/utils/smooth-scroll";
import { HeroDownloadSection } from "./HeroDownloadSection";

vi.mock("next-intl", () => ({
  useTranslations: () => (key: string) =>
    key === "downloadRegionLabel" ? "Download the app" : key,
}));

vi.mock("@/components/molecules/StoreDownloadButtons", () => ({
  StoreDownloadButtons: () => <div data-testid="store-buttons">Store buttons</div>,
}));

describe("HeroDownloadSection", () => {
  it("exposes the download landmark with accessible label", () => {
    render(<HeroDownloadSection />);
    const region = screen.getByRole("region", { name: "Download the app" });
    expect(region).toHaveAttribute("id", DOWNLOAD_SECTION_ID);
    expect(screen.getByTestId("store-buttons")).toBeInTheDocument();
  });
});
