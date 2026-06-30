/** @vitest-environment jsdom */
import { describe, expect, it, vi, beforeEach } from "vitest";
import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { HelpArticleSectionHeading } from "./HelpArticleSectionHeading";

describe("HelpArticleSectionHeading", () => {
  const writeText = vi.fn().mockResolvedValue(undefined);

  beforeEach(() => {
    writeText.mockClear();
    vi.stubGlobal("navigator", {
      ...navigator,
      clipboard: { writeText },
    });
  });

  it("copies section URL and briefly sets copied aria-label", async () => {
    window.history.pushState({}, "", "/en/help/demo");

    render(
      <HelpArticleSectionHeading
        sectionId="my-section"
        title="Section title"
        copyLabel="Copy link"
        copiedLabel="Copied"
      />,
    );

    fireEvent.click(screen.getByRole("button", { name: "Copy link" }));

    await waitFor(() => {
      expect(writeText).toHaveBeenCalledTimes(1);
    });
    const arg = writeText.mock.calls[0]?.[0] as string;
    expect(arg).toContain("#my-section");
    expect(screen.getByRole("button", { name: "Copied" })).toBeInTheDocument();
  });
});
