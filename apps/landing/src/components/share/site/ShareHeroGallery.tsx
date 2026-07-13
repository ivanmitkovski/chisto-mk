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
  const dialogRef = useRef<HTMLDialogElement>(null);
  const touchStartX = useRef<number | null>(null);
  const titleId = useId();

  const count = urls.length;
  const safeIndex = count === 0 ? 0 : ((index % count) + count) % count;
  const current = count > 0 ? urls[safeIndex] : null;

  const go = useCallback(
    (delta: number) => {
      if (count === 0) return;
      setIndex((i) => (i + delta + count) % count);
    },
    [count],
  );

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

  if (count === 0) {
    return (
      <div className="flex aspect-video w-full items-center justify-center rounded-[22px] bg-surface-muted text-sm font-medium text-ink-muted">
        {emptyLabel}
      </div>
    );
  }

  return (
    <div className="relative">
      <button
        type="button"
        className="group relative block w-full overflow-hidden rounded-[22px] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2 disabled:cursor-default"
        onClick={() => {
          if (!currentFailed) setLightbox(true);
        }}
        disabled={currentFailed}
        aria-label={currentFailed ? (unavailableLabel ?? openPhotoLabel) : openPhotoLabel}
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
          e.preventDefault();
          go(delta < 0 ? 1 : -1);
        }}
      >
        <div className="aspect-video w-full bg-surface-muted">
          <GalleryImage
            src={current!}
            alt={`${alt} (${safeIndex + 1}/${count})`}
            priority={safeIndex === 0}
            {...(unavailableLabel != null ? { unavailableLabel } : {})}
            onFailedChange={setCurrentFailed}
          />
        </div>
        {!currentFailed ? (
          <span className="pointer-events-none absolute bottom-3 left-1/2 -translate-x-1/2 rounded-full border border-white/10 bg-black/22 px-3 py-1 text-xs font-medium text-white backdrop-blur-md motion-safe:transition-opacity group-hover:opacity-100">
            {openPhotoLabel}
            {count > 1 ? ` · ${safeIndex + 1}/${count}` : ""}
          </span>
        ) : null}
      </button>

      {count > 1 ? (
        <div className="mt-3 flex items-center justify-center gap-2" role="group" aria-label={alt}>
          {urls.map((url, i) => (
            <button
              key={`${url}-${i}`}
              type="button"
              aria-current={i === safeIndex ? "true" : undefined}
              aria-label={`${i + 1} / ${count}`}
              className={cn(
                "h-2 w-2 rounded-full transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary",
                i === safeIndex ? "bg-primary" : "bg-gray-300 hover:bg-gray-400",
              )}
              onClick={() => setIndex(i)}
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
          <div className="relative flex min-h-0 flex-1 items-center justify-center px-4 pb-8">
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
                src={current!}
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
