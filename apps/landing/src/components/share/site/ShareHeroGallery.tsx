"use client";

import { useCallback, useEffect, useId, useRef, useState } from "react";
import { cn } from "@/lib/utils/cn";

type ShareHeroGalleryProps = {
  urls: string[];
  alt: string;
  emptyLabel: string;
  openPhotoLabel: string;
  closeLabel: string;
  prevLabel: string;
  nextLabel: string;
  unavailableLabel?: string;
};

function GalleryImage({
  src,
  alt,
  className,
  priority = false,
  unavailableLabel,
  onFailedChange,
}: {
  src: string;
  alt: string;
  className?: string;
  priority?: boolean;
  unavailableLabel?: string;
  onFailedChange?: (failed: boolean) => void;
}) {
  const [failed, setFailed] = useState(false);

  useEffect(() => {
    setFailed(false);
    onFailedChange?.(false);
  }, [src, onFailedChange]);

  if (failed) {
    return (
      <div
        className={cn(
          "flex items-center justify-center bg-surface-muted px-4 text-center text-sm font-medium text-ink-muted",
          className,
        )}
        role="img"
        aria-label={alt}
      >
        {unavailableLabel ?? alt}
      </div>
    );
  }

  return (
    // Stable API redirects + signed hosts vary; next/image cannot follow share 302s reliably.
    // eslint-disable-next-line @next/next/no-img-element
    <img
      src={src}
      alt={alt}
      className={cn("h-full w-full object-cover", className)}
      onError={() => {
        setFailed(true);
        onFailedChange?.(true);
      }}
      loading={priority ? "eager" : "lazy"}
      fetchPriority={priority ? "high" : "auto"}
      decoding="async"
      referrerPolicy="no-referrer"
      draggable={false}
    />
  );
}

export function ShareHeroGallery({
  urls,
  alt,
  emptyLabel,
  openPhotoLabel,
  closeLabel,
  prevLabel,
  nextLabel,
  unavailableLabel,
}: ShareHeroGalleryProps) {
  const [index, setIndex] = useState(0);
  const [lightbox, setLightbox] = useState(false);
  const [currentFailed, setCurrentFailed] = useState(false);
  const scrollerRef = useRef<HTMLDivElement>(null);
  const dialogRef = useRef<HTMLDialogElement>(null);
  const touchStartX = useRef<number | null>(null);
  const titleId = useId();

  const count = urls.length;
  const safeIndex = count === 0 ? 0 : ((index % count) + count) % count;

  const go = useCallback(
    (delta: number) => {
      if (count === 0) return;
      setIndex((i) => (i + delta + count) % count);
    },
    [count],
  );

  const goTo = useCallback(
    (i: number) => {
      if (count === 0) return;
      setIndex(((i % count) + count) % count);
    },
    [count],
  );

  // Keep scroll-snap strip aligned with index (hero + dots + arrows).
  useEffect(() => {
    const el = scrollerRef.current;
    if (!el || count < 2) return;
    const child = el.children.item(safeIndex) as HTMLElement | null;
    if (!child) return;
    el.scrollTo({ left: child.offsetLeft, behavior: "smooth" });
  }, [safeIndex, count]);

  useEffect(() => {
    const dialog = dialogRef.current;
    if (!dialog) return;
    if (lightbox) {
      if (!dialog.open) dialog.showModal();
    } else if (dialog.open) {
      dialog.close();
    }
  }, [lightbox]);

  useEffect(() => {
    if (!lightbox) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "ArrowLeft") go(-1);
      if (e.key === "ArrowRight") go(1);
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [lightbox, go]);

  const onScrollerScroll = () => {
    const el = scrollerRef.current;
    if (!el || count < 2) return;
    const width = el.clientWidth || 1;
    const next = Math.round(el.scrollLeft / width);
    if (next !== safeIndex && next >= 0 && next < count) {
      setIndex(next);
    }
  };

  if (count === 0) {
    return (
      <div className="flex aspect-[4/3] w-full items-center justify-center rounded-[22px] bg-surface-muted text-sm font-medium text-ink-muted sm:aspect-video">
        {emptyLabel}
      </div>
    );
  }

  return (
    <div className="relative">
      <div className="relative overflow-hidden rounded-[22px] bg-surface-muted">
        <div
          ref={scrollerRef}
          className="flex aspect-[4/3] snap-x snap-mandatory overflow-x-auto scroll-smooth [-ms-overflow-style:none] [scrollbar-width:none] sm:aspect-video [&::-webkit-scrollbar]:hidden"
          onScroll={onScrollerScroll}
          role="region"
          aria-roledescription="carousel"
          aria-label={alt}
        >
          {urls.map((url, i) => (
            <button
              key={`${url}-${i}`}
              type="button"
              className="relative h-full w-full shrink-0 snap-center focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-primary"
              onClick={() => {
                if (i === safeIndex && !currentFailed) setLightbox(true);
                else goTo(i);
              }}
              aria-label={
                currentFailed && i === safeIndex
                  ? (unavailableLabel ?? openPhotoLabel)
                  : `${openPhotoLabel} (${i + 1}/${count})`
              }
            >
              <GalleryImage
                src={url}
                alt={`${alt} (${i + 1}/${count})`}
                className="absolute inset-0"
                priority={i === 0}
                {...(unavailableLabel != null ? { unavailableLabel } : {})}
                {...(i === safeIndex ? { onFailedChange: setCurrentFailed } : {})}
              />
            </button>
          ))}
        </div>

        {count > 1 ? (
          <>
            <button
              type="button"
              className="absolute left-2 top-1/2 z-10 hidden h-10 w-10 -translate-y-1/2 items-center justify-center rounded-full bg-black/35 text-lg font-semibold text-white backdrop-blur-md hover:bg-black/50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary sm:flex"
              onClick={() => go(-1)}
              aria-label={prevLabel}
            >
              ‹
            </button>
            <button
              type="button"
              className="absolute right-2 top-1/2 z-10 hidden h-10 w-10 -translate-y-1/2 items-center justify-center rounded-full bg-black/35 text-lg font-semibold text-white backdrop-blur-md hover:bg-black/50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary sm:flex"
              onClick={() => go(1)}
              aria-label={nextLabel}
            >
              ›
            </button>
          </>
        ) : null}

        <div className="pointer-events-none absolute inset-x-0 bottom-0 flex items-end justify-between gap-3 bg-gradient-to-t from-black/45 via-black/10 to-transparent px-3 pb-3 pt-10">
          <span className="rounded-full border border-white/15 bg-black/25 px-2.5 py-1 text-[11px] font-semibold tabular-nums text-white backdrop-blur-md">
            {safeIndex + 1}/{count}
          </span>
          {!currentFailed ? (
            <span className="rounded-full border border-white/15 bg-black/25 px-3 py-1 text-xs font-medium text-white backdrop-blur-md">
              {openPhotoLabel}
            </span>
          ) : null}
        </div>
      </div>

      {count > 1 ? (
        <div className="mt-3 flex items-center justify-center gap-2" role="tablist" aria-label={alt}>
          {urls.map((url, i) => (
            <button
              key={`dot-${url}-${i}`}
              type="button"
              role="tab"
              aria-selected={i === safeIndex}
              aria-label={`${i + 1} / ${count}`}
              className={cn(
                "h-2 rounded-full transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary",
                i === safeIndex ? "w-5 bg-primary" : "w-2 bg-gray-300 hover:bg-gray-400",
              )}
              onClick={() => goTo(i)}
            />
          ))}
        </div>
      ) : null}

      <dialog
        ref={dialogRef}
        className="fixed inset-0 z-50 m-0 h-dvh max-h-none w-screen max-w-none border-0 bg-black/92 p-0 text-white backdrop:bg-black/80"
        aria-labelledby={titleId}
        onClose={() => setLightbox(false)}
        onClick={(e) => {
          if (e.target === dialogRef.current) setLightbox(false);
        }}
      >
        <div className="flex h-full flex-col">
          <div className="flex items-center justify-between gap-3 px-4 py-3">
            <p id={titleId} className="text-sm font-medium text-white/90">
              {safeIndex + 1}/{count}
            </p>
            <button
              type="button"
              className="rounded-full bg-white/10 px-4 py-2 text-sm font-semibold hover:bg-white/20 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary"
              onClick={() => setLightbox(false)}
            >
              {closeLabel}
            </button>
          </div>
          <div
            className="relative flex min-h-0 flex-1 items-center justify-center px-4 pb-8"
            onTouchStart={(e) => {
              touchStartX.current = e.changedTouches[0]?.clientX ?? null;
            }}
            onTouchEnd={(e) => {
              const start = touchStartX.current;
              touchStartX.current = null;
              if (start == null || count < 2) return;
              const end = e.changedTouches[0]?.clientX;
              if (end == null) return;
              const delta = end - start;
              if (Math.abs(delta) < 40) return;
              go(delta < 0 ? 1 : -1);
            }}
          >
            {count > 1 ? (
              <button
                type="button"
                className="absolute left-3 z-10 rounded-full bg-white/10 px-3 py-2 text-sm font-semibold hover:bg-white/20 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary"
                onClick={() => go(-1)}
              >
                {prevLabel}
              </button>
            ) : null}
            <div className="max-h-full max-w-5xl">
              <GalleryImage
                src={urls[safeIndex]!}
                alt={`${alt} (${safeIndex + 1}/${count})`}
                className="max-h-[80dvh] w-auto rounded-lg object-contain"
                priority
                {...(unavailableLabel != null ? { unavailableLabel } : {})}
              />
            </div>
            {count > 1 ? (
              <button
                type="button"
                className="absolute right-3 z-10 rounded-full bg-white/10 px-3 py-2 text-sm font-semibold hover:bg-white/20 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary"
                onClick={() => go(1)}
              >
                {nextLabel}
              </button>
            ) : null}
          </div>
        </div>
      </dialog>
    </div>
  );
}
