/** @vitest-environment jsdom */
import { describe, expect, it, vi, beforeEach } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { HelpArticleSectionHeading } from "./HelpArticleSectionHeading";

describe("HelpArticleSectionHeading", () => {
  const writeText = vi.fn().mockResolvedValue(undefined);

  beforeEach(() => {
    writeText.mockClear();
    Object.assign(navigator, {
      clipboard: { writeText },
    });
  });

  it("copies section URL and briefly sets copied aria-label", async () => {
    const user = userEvent.setup();
    window.history.pushState({}, "", "/en/help/demo");

    render(
      <HelpArticleSectionHeading
        sectionId="my-section"
        title="Section title"
        copyLabel="Copy link"
        copiedLabel="Copied"
      />,
    );

    await user.click(screen.getByRole("button", { name: "Copy link" }));
    expect(writeText).toHaveBeenCalledTimes(1);
    const arg = writeText.mock.calls[0]?.[0] as string;
    expect(arg).toContain("#my-section");
    expect(screen.getByRole("button", { name: "Copied" })).toBeInTheDocument();
  });
});
