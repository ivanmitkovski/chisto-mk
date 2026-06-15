/** @vitest-environment jsdom */
import { describe, expect, it, vi, beforeEach, afterEach } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import { HelpToc } from "./HelpToc";

describe("HelpToc", () => {
  beforeEach(() => {
    vi.spyOn(window, "requestAnimationFrame").mockImplementation((cb: FrameRequestCallback) => {
      cb(0);
      return 0;
    });
    vi.spyOn(window, "cancelAnimationFrame").mockImplementation(() => {});
    Object.defineProperty(window, "matchMedia", {
      writable: true,
      configurable: true,
      value: vi.fn().mockImplementation(() => ({
        matches: false,
        media: "",
        addEventListener: vi.fn(),
        removeEventListener: vi.fn(),
        addListener: vi.fn(),
        removeListener: vi.fn(),
      })),
    });
  });

  afterEach(() => {
    vi.restoreAllMocks();
    document.body.replaceChildren();
  });

  it("renders anchor links for each toc item", () => {
    render(
      <HelpToc
        items={[
          { id: "alpha", title: "Alpha" },
          { id: "beta", title: "Beta" },
        ]}
        ariaLabel="On this page"
        mobileTriggerLabel="Contents"
      />,
    );
    const alphaLinks = screen.getAllByRole("link", { name: "Alpha" });
    expect(alphaLinks[0]).toHaveAttribute("href", "#alpha");
    expect(screen.getAllByRole("link", { name: "Beta" })[0]).toHaveAttribute("href", "#beta");
  });

  it("updates active link from scroll positions", async () => {
    const el1 = document.createElement("div");
    el1.id = "s1";
    const el2 = document.createElement("div");
    el2.id = "s2";
    document.body.appendChild(el1);
    document.body.appendChild(el2);
    vi.spyOn(el1, "getBoundingClientRect").mockReturnValue({ top: 120 } as DOMRect);
    vi.spyOn(el2, "getBoundingClientRect").mockReturnValue({ top: 40 } as DOMRect);

    render(
      <HelpToc
        items={[
          { id: "s1", title: "First" },
          { id: "s2", title: "Second" },
        ]}
        ariaLabel="TOC"
        mobileTriggerLabel="Open"
      />,
    );

    await waitFor(() => {
      const second = screen.getAllByRole("link", { name: "Second" })[0];
      expect(second.className).toMatch(/border-primary/);
    });
  });
});
