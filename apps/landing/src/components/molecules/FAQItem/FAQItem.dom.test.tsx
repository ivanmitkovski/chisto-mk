/** @vitest-environment jsdom */
import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import { FAQItem } from "./FAQItem";

describe("FAQItem", () => {
  it("renders title and content", () => {
    render(
      <FAQItem
        title="Is Chisto.mk free?"
        content="Yes. The app is free to download and use."
        variant="white"
      />,
    );
    expect(screen.getByRole("heading", { level: 3, name: "Is Chisto.mk free?" })).toBeInTheDocument();
    expect(screen.getByText("Yes. The app is free to download and use.")).toBeInTheDocument();
  });

  it("uses article semantics for accessibility", () => {
    const { container } = render(
      <FAQItem title="Q" content="A" variant="green" />,
    );
    expect(container.querySelector("article")).toBeTruthy();
  });
});
