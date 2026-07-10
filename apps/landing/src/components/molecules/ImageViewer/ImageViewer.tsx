"use client";

import * as Dialog from "@radix-ui/react-dialog";
import { ChevronLeft, ChevronRight, X } from "lucide-react";
import Image from "next/image";
import { useCallback, useEffect, useId, useRef, useState } from "react";
import { useReducedMotion } from "framer-motion";
import { shouldUseUnoptimizedNewsImage } from "@/lib/images/news-image-optimization";
import { cn } from "@/lib/utils/cn";
import styles from "./image-viewer.module.css";
import { useImageViewerGestures } from "./use-image-viewer-gestures";

export type ImageViewerItem = {
  src: string;
  alt: string;
  caption?: string;
};

export type ImageViewerLabels = {
  close: string;
  dialog: string;
  previous?: string;
  next?: string;
  slide?: (index: number, total: number) => string;
};

export type ImageViewerProps = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  items: readonly ImageViewerItem[];
  index: number;
  onIndexChange?: (index: number) => void;
  labels: ImageViewerLabels;
};

export function ImageViewer({
  open,
  onOpenChange,
  items,
  index,
  onIndexChange,
  labels,
}: ImageViewerProps) {
  const titleId = useId();
  const liveId = useId();
  const thumbsRef = useRef<HTMLDivElement>(null);
  const reduceMotion = useReducedMotion() === true;
  const [chromeVisible, setChromeVisible] = useState(true);

  const multi = items.length > 1;
  const canNavigate = multi && typeof onIndexChange === "function";
  const safeIndex = items.length === 0 ? 0 : Math.min(Math.max(index, 0), items.length - 1);
  const active = items[safeIndex];

  const showPrevious = useCallback(() => {
    if (!canNavigate || !onIndexChange) return;
    onIndexChange(safeIndex <= 0 ? items.length - 1 : safeIndex - 1);
  }, [canNavigate, onIndexChange, safeIndex, items.length]);

  const showNext = useCallback(() => {
    if (!canNavigate || !onIndexChange) return;
    onIndexChange(safeIndex >= items.length - 1 ? 0 : safeIndex + 1);
  }, [canNavigate, onIndexChange, safeIndex, items.length]);

  const toggleChrome = useCallback(() => {
    setChromeVisible((v) => !v);
  }, []);

  const { handlers, dragY, dragOpacity, isDragging } = useImageViewerGestures({
    enabled: open,
    canNavigate,
    reduceMotion,
    onNext: showNext,
    onPrevious: showPrevious,
    onDismiss: () => onOpenChange(false),
    onTap: toggleChrome,
  });

  useEffect(() => {
    if (!open) return;
    setChromeVisible(true);
  }, [open]);

  useEffect(() => {
    if (!open) return;
    const main = document.getElementById("main-content");
    const root = document.documentElement;
    const prevOverscroll = root.style.overscrollBehavior;
    main?.setAttribute("inert", "");
    root.style.overscrollBehavior = "none";
    return () => {
      main?.removeAttribute("inert");
      root.style.overscrollBehavior = prevOverscroll;
    };
  }, [open]);

  useEffect(() => {
    if (!open || !canNavigate) return;
    function onKeyDown(e: KeyboardEvent) {
      if (e.key === "ArrowLeft") {
        e.preventDefault();
        showPrevious();
      }
      if (e.key === "ArrowRight") {
        e.preventDefault();
        showNext();
      }
    }
    document.addEventListener("keydown", onKeyDown);
    return () => document.removeEventListener("keydown", onKeyDown);
  }, [open, canNavigate, showPrevious, showNext]);

  // Preload adjacent images for smoother swipe nav.
  useEffect(() => {
    if (!open || !canNavigate) return;
    const prev = items[safeIndex <= 0 ? items.length - 1 : safeIndex - 1];
    const next = items[safeIndex >= items.length - 1 ? 0 : safeIndex + 1];
    for (const item of [prev, next]) {
      if (!item?.src) continue;
      const img = new window.Image();
      img.src = item.src;
    }
  }, [open, canNavigate, items, safeIndex]);

  // Keep active thumbnail in view.
  useEffect(() => {
    if (!open || !multi || !chromeVisible) return;
    const activeThumb = thumbsRef.current?.querySelector<HTMLElement>("[data-active-thumb='true']");
    activeThumb?.scrollIntoView({
      behavior: reduceMotion ? "auto" : "smooth",
      inline: "center",
      block: "nearest",
    });
  }, [open, multi, chromeVisible, safeIndex, reduceMotion]);

  if (items.length === 0 || !active) {
    return null;
  }

  const titleText = active.caption?.trim() || active.alt.trim() || labels.dialog;
  const slideLabelFn = labels.slide;
  const liveAnnouncement =
    slideLabelFn?.(safeIndex + 1, items.length) ??
    (multi ? `${safeIndex + 1} / ${items.length}` : titleText);

  return (
    <Dialog.Root open={open} onOpenChange={onOpenChange}>
      <Dialog.Portal>
        <Dialog.Overlay
          className={cn("fixed inset-0 z-[1400] bg-black/92 backdrop-blur-sm", styles.overlay)}
          style={{ opacity: dragOpacity }}
        />
        <Dialog.Content
          className={cn(
            "fixed inset-0 z-[1401] flex flex-col outline-none",
            styles.content,
          )}
          aria-describedby={undefined}
          aria-labelledby={titleId}
          onPointerDownOutside={(e) => {
            e.preventDefault();
          }}
        >
          <Dialog.Title id={titleId} className="sr-only">
            {titleText}
          </Dialog.Title>
          <p id={liveId} className="sr-only" aria-live="polite">
            {open ? liveAnnouncement : ""}
          </p>

          {!chromeVisible ? <div className={styles.chromeHiddenGradient} aria-hidden /> : null}

          <div
            className={cn(
              "flex shrink-0 items-center justify-between gap-3 text-white transition-opacity",
              "px-[max(1rem,env(safe-area-inset-left))] sm:px-[max(1.5rem,env(safe-area-inset-left))]",
              "pr-[max(1rem,env(safe-area-inset-right))] sm:pr-[max(1.5rem,env(safe-area-inset-right))]",
              "pt-[max(0.75rem,env(safe-area-inset-top))] pb-3",
              chromeVisible ? "opacity-100" : "pointer-events-none opacity-0",
            )}
            data-testid="image-viewer-chrome"
          >
            <div className="min-w-0 flex-1">
              <p className="truncate text-sm font-medium text-white/90" aria-hidden>
                {titleText}
              </p>
              {multi ? (
                <p className="mt-0.5 tabular-nums text-xs text-white/60" aria-hidden>
                  {safeIndex + 1} / {items.length}
                </p>
              ) : null}
            </div>
            <Dialog.Close asChild>
              <button
                type="button"
                className={cn(
                  "inline-flex h-11 w-11 shrink-0 items-center justify-center rounded-full",
                  "bg-white/10 text-white transition-colors hover:bg-white/20 active:bg-white/25",
                  "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white focus-visible:ring-offset-2 focus-visible:ring-offset-black",
                )}
                aria-label={labels.close}
                tabIndex={chromeVisible ? 0 : -1}
              >
                <X className="h-5 w-5" strokeWidth={2} aria-hidden />
              </button>
            </Dialog.Close>
          </div>

          <div
            className={cn(
              "relative flex min-h-0 flex-1 touch-none items-center justify-center",
              "px-[max(1rem,env(safe-area-inset-left))] sm:px-[max(1.5rem,env(safe-area-inset-left))]",
              "pr-[max(1rem,env(safe-area-inset-right))] sm:pr-[max(1.5rem,env(safe-area-inset-right))]",
              "pb-4",
              isDragging && dragY > 0 ? styles.stageDragging : styles.stageIdle,
            )}
            style={{
              transform: dragY > 0 ? `translateY(${dragY}px)` : undefined,
              opacity: dragY > 0 ? dragOpacity : undefined,
            }}
            {...handlers}
            role="presentation"
            data-testid="image-viewer-stage"
          >
            {canNavigate && labels.previous ? (
              <button
                type="button"
                className={cn(
                  "absolute left-2 z-10 hidden h-11 w-11 items-center justify-center rounded-full md:inline-flex",
                  "bg-white/10 text-white transition-colors hover:bg-white/20 active:bg-white/25 sm:left-4",
                  "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white",
                  !chromeVisible && "pointer-events-none opacity-0",
                )}
                onClick={(e) => {
                  e.stopPropagation();
                  showPrevious();
                }}
                onPointerDown={(e) => e.stopPropagation()}
                aria-label={labels.previous}
                tabIndex={chromeVisible ? 0 : -1}
              >
                <ChevronLeft className="h-6 w-6" strokeWidth={2} aria-hidden />
              </button>
            ) : null}

            <div className="relative h-[min(72dvh,720px)] w-full max-w-5xl" role="presentation">
              <Image
                src={active.src}
                alt={active.alt}
                fill
                className="object-contain pointer-events-none select-none"
                sizes="100vw"
                unoptimized={shouldUseUnoptimizedNewsImage(active.src)}
                priority
                draggable={false}
              />
            </div>

            {canNavigate && labels.next ? (
              <button
                type="button"
                className={cn(
                  "absolute right-2 z-10 hidden h-11 w-11 items-center justify-center rounded-full md:inline-flex",
                  "bg-white/10 text-white transition-colors hover:bg-white/20 active:bg-white/25 sm:right-4",
                  "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white",
                  !chromeVisible && "pointer-events-none opacity-0",
                )}
                onClick={(e) => {
                  e.stopPropagation();
                  showNext();
                }}
                onPointerDown={(e) => e.stopPropagation()}
                aria-label={labels.next}
                tabIndex={chromeVisible ? 0 : -1}
              >
                <ChevronRight className="h-6 w-6" strokeWidth={2} aria-hidden />
              </button>
            ) : null}
          </div>

          {multi && slideLabelFn ? (
            <div
              ref={thumbsRef}
              className={cn(
                "flex shrink-0 gap-2 overflow-x-auto scroll-smooth snap-x snap-mandatory transition-opacity",
                "px-[max(1rem,env(safe-area-inset-left))] sm:px-[max(1.5rem,env(safe-area-inset-left))]",
                "pr-[max(1rem,env(safe-area-inset-right))] sm:pr-[max(1.5rem,env(safe-area-inset-right))]",
                "pb-[max(1.25rem,env(safe-area-inset-bottom))]",
                chromeVisible ? "opacity-100" : "pointer-events-none opacity-0",
              )}
              onPointerDown={(e) => e.stopPropagation()}
              role="presentation"
              aria-hidden={!chromeVisible}
            >
              {items.map((item, i) => (
                <button
                  key={`${item.src}-${i}`}
                  type="button"
                  data-active-thumb={i === safeIndex ? "true" : undefined}
                  className={cn(
                    "relative h-14 w-20 shrink-0 snap-center overflow-hidden rounded-md border-2 transition-opacity",
                    i === safeIndex ? "border-white opacity-100" : "border-transparent opacity-70 hover:opacity-90",
                    "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white",
                  )}
                  onClick={() => onIndexChange?.(i)}
                  aria-label={slideLabelFn(i + 1, items.length)}
                  aria-current={i === safeIndex ? "true" : undefined}
                  tabIndex={chromeVisible ? 0 : -1}
                >
                  <Image
                    src={item.src}
                    alt=""
                    fill
                    className="object-cover"
                    sizes="80px"
                    unoptimized={shouldUseUnoptimizedNewsImage(item.src)}
                  />
                </button>
              ))}
            </div>
          ) : null}
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  );
}
