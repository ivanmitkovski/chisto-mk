/** @vitest-environment jsdom */
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import {
  DOWNLOAD_SECTION_ID,
  getScrollPaddingTopPx,
  scrollToDownloadSection,
} from "./smooth-scroll";

describe("smooth-scroll download target", () => {
  beforeEach(() => {
    vi.useFakeTimers();
    Object.defineProperty(window, "matchMedia", {
      writable: true,
      configurable: true,
      value: vi.fn().mockImplementation((query: string) => ({
        matches: query === "(prefers-reduced-motion: reduce)" ? false : false,
        media: query,
        onchange: null,
        addListener: vi.fn(),
        removeListener: vi.fn(),
        addEventListener: vi.fn(),
        removeEventListener: vi.fn(),
        dispatchEvent: vi.fn(),
      })),
    });
    document.documentElement.style.scrollPaddingTop = "110px";
    document.body.innerHTML = `
      <header style="position:sticky;height:80px"></header>
      <main>
        <section id="${DOWNLOAD_SECTION_ID}" tabindex="-1" style="margin-top:400px;height:80px">
          <a href="#">App Store</a>
        </section>
      </main>
    `;
    Object.defineProperty(window, "scrollY", { value: 480, writable: true, configurable: true });
    vi.spyOn(window, "scrollTo").mockImplementation(() => {});
    history.replaceState(null, "", "/en");
  });

  afterEach(() => {
    vi.useRealTimers();
    vi.restoreAllMocks();
    document.body.innerHTML = "";
    document.documentElement.style.scrollPaddingTop = "";
  });

  it("reads scroll-padding-top from html", () => {
    expect(getScrollPaddingTopPx()).toBe(110);
  });

  it("scrolls to page top and updates hash", () => {
    const ok = scrollToDownloadSection();
    expect(ok).toBe(true);
    expect(window.scrollTo).toHaveBeenCalledWith({
      top: 0,
      behavior: "smooth",
    });
    expect(window.location.hash).toBe("#download");
  });

  it("returns false when download landmark is missing", () => {
    document.getElementById(DOWNLOAD_SECTION_ID)?.remove();
    expect(scrollToDownloadSection()).toBe(false);
  });
});
