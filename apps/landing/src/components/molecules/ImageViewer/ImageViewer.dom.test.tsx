/** @vitest-environment jsdom */
import { describe, expect, it, vi } from "vitest";
import { fireEvent, render, screen } from "@testing-library/react";
import { ImageViewer } from "./ImageViewer";

vi.mock("next/image", () => ({
  default: (props: { alt: string; src: string }) => (
    // eslint-disable-next-line @next/next/no-img-element
    <img alt={props.alt} src={props.src} />
  ),
}));

vi.mock("framer-motion", () => ({
  useReducedMotion: () => false,
}));

const single = [{ src: "https://cdn.example.com/cover.jpg", alt: "Cover photo" }];
const multi = [
  { src: "https://cdn.example.com/a.jpg", alt: "Photo A" },
  { src: "https://cdn.example.com/b.jpg", alt: "Photo B", caption: "Caption B" },
];

function pointerSequence(
  el: Element,
  from: { x: number; y: number },
  to: { x: number; y: number },
  options?: { startTime?: number; endTime?: number },
) {
  const startTime = options?.startTime ?? 1000;
  const endTime = options?.endTime ?? startTime + 200;
  fireEvent.pointerDown(el, {
    button: 0,
    pointerId: 1,
    clientX: from.x,
    clientY: from.y,
    timeStamp: startTime,
  });
  fireEvent.pointerMove(el, {
    button: 0,
    pointerId: 1,
    clientX: to.x,
    clientY: to.y,
    timeStamp: startTime + 50,
  });
  fireEvent.pointerUp(el, {
    button: 0,
    pointerId: 1,
    clientX: to.x,
    clientY: to.y,
    timeStamp: endTime,
  });
}

describe("ImageViewer", () => {
  it("renders dialog when open with a single image and hides nav controls", () => {
    render(
      <ImageViewer
        open
        onOpenChange={() => {}}
        items={single}
        index={0}
        labels={{ close: "Close", dialog: "Image viewer" }}
      />,
    );

    expect(screen.getByRole("dialog")).toBeInTheDocument();
    expect(screen.getByRole("img", { name: "Cover photo" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Close" })).toBeInTheDocument();
    expect(screen.queryByRole("button", { name: "Previous" })).not.toBeInTheDocument();
    expect(screen.queryByRole("button", { name: "Next" })).not.toBeInTheDocument();
  });

  it("calls onOpenChange(false) when close is clicked", () => {
    const onOpenChange = vi.fn();
    render(
      <ImageViewer
        open
        onOpenChange={onOpenChange}
        items={single}
        index={0}
        labels={{ close: "Close", dialog: "Image viewer" }}
      />,
    );

    fireEvent.click(screen.getByRole("button", { name: "Close" }));
    expect(onOpenChange).toHaveBeenCalledWith(false);
  });

  it("toggles chrome on stage tap instead of closing", () => {
    const onOpenChange = vi.fn();
    render(
      <ImageViewer
        open
        onOpenChange={onOpenChange}
        items={single}
        index={0}
        labels={{ close: "Close", dialog: "Image viewer" }}
      />,
    );

    const stage = screen.getByTestId("image-viewer-stage");
    const chrome = screen.getByTestId("image-viewer-chrome");
    expect(chrome.className).toContain("opacity-100");

    pointerSequence(stage, { x: 100, y: 100 }, { x: 102, y: 101 }, { startTime: 1000, endTime: 1100 });

    expect(onOpenChange).not.toHaveBeenCalled();
    expect(chrome.className).toContain("opacity-0");

    pointerSequence(stage, { x: 100, y: 100 }, { x: 100, y: 100 }, { startTime: 2000, endTime: 2100 });
    expect(chrome.className).toContain("opacity-100");
  });

  it("navigates with next/previous and thumbnails when multi", () => {
    const onIndexChange = vi.fn();
    render(
      <ImageViewer
        open
        onOpenChange={() => {}}
        items={multi}
        index={0}
        onIndexChange={onIndexChange}
        labels={{
          close: "Close",
          dialog: "Gallery",
          previous: "Previous",
          next: "Next",
          slide: (i, total) => `Slide ${i} of ${total}`,
        }}
      />,
    );

    fireEvent.click(screen.getByRole("button", { name: "Next" }));
    expect(onIndexChange).toHaveBeenCalledWith(1);

    fireEvent.click(screen.getByRole("button", { name: "Previous" }));
    expect(onIndexChange).toHaveBeenCalledWith(1);

    fireEvent.click(screen.getByRole("button", { name: "Slide 2 of 2" }));
    expect(onIndexChange).toHaveBeenCalledWith(1);
  });

  it("swipes horizontally to change slide when multi", () => {
    const onIndexChange = vi.fn();
    render(
      <ImageViewer
        open
        onOpenChange={() => {}}
        items={multi}
        index={0}
        onIndexChange={onIndexChange}
        labels={{
          close: "Close",
          dialog: "Gallery",
          previous: "Previous",
          next: "Next",
          slide: (i, total) => `Slide ${i} of ${total}`,
        }}
      />,
    );

    const stage = screen.getByTestId("image-viewer-stage");
    // Swipe left → next
    pointerSequence(stage, { x: 200, y: 150 }, { x: 100, y: 150 }, { startTime: 1000, endTime: 1200 });
    expect(onIndexChange).toHaveBeenCalledWith(1);
  });

  it("swipes down to dismiss", () => {
    const onOpenChange = vi.fn();
    render(
      <ImageViewer
        open
        onOpenChange={onOpenChange}
        items={single}
        index={0}
        labels={{ close: "Close", dialog: "Image viewer" }}
      />,
    );

    const stage = screen.getByTestId("image-viewer-stage");
    pointerSequence(stage, { x: 150, y: 80 }, { x: 150, y: 200 }, { startTime: 1000, endTime: 1300 });
    expect(onOpenChange).toHaveBeenCalledWith(false);
  });

  it("does not navigate on horizontal swipe for a single image", () => {
    const onIndexChange = vi.fn();
    render(
      <ImageViewer
        open
        onOpenChange={() => {}}
        items={single}
        index={0}
        onIndexChange={onIndexChange}
        labels={{ close: "Close", dialog: "Image viewer" }}
      />,
    );

    const stage = screen.getByTestId("image-viewer-stage");
    pointerSequence(stage, { x: 200, y: 150 }, { x: 100, y: 150 }, { startTime: 1000, endTime: 1200 });
    expect(onIndexChange).not.toHaveBeenCalled();
  });

  it("renders nothing when items are empty", () => {
    const { container } = render(
      <ImageViewer
        open
        onOpenChange={() => {}}
        items={[]}
        index={0}
        labels={{ close: "Close", dialog: "Image viewer" }}
      />,
    );
    expect(container).toBeEmptyDOMElement();
  });
});
