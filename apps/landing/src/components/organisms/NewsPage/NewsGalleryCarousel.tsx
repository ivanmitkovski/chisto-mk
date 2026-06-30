"use client";

import Image from "next/image";
import { shouldUseUnoptimizedNewsImage } from "@/lib/images/news-image-optimization";
import { useCallback, useEffect, useRef, useState } from "react";
import { useTranslations } from "next-intl";
import type { GalleryRenderItem } from "@chisto/news-content/render";
import { cn } from "@/lib/utils/cn";

type NewsGalleryCarouselProps = {
  items: GalleryRenderItem[];
  className?: string;
  imageUnavailableLabel: string;
  closeLabel: string;
  previousLabel: string;
  nextLabel: string;
  dialogLabel: string;
};

export function NewsGalleryCarousel({
  items,
  className,
  imageUnavailableLabel,
  closeLabel,
  previousLabel,
  nextLabel,
  dialogLabel,
}: NewsGalleryCarouselProps) {
  const t = useTranslations("newsPage");
  const slideLabel = useCallback(
    (index: number, total: number) => t("gallerySlideLabel", { index, total }),
    [t],
  );
  const [activeIndex, setActiveIndex] = useState(0);
  const [lightboxOpen, setLightboxOpen] = useState(false);
  const closeButtonRef = useRef<HTMLButtonElement>(null);
  const triggerRef = useRef<HTMLButtonElement | null>(null);

  const openLightbox = useCallback((index: number, trigger: HTMLButtonElement) => {
    triggerRef.current = trigger;
    setActiveIndex(index);
    setLightboxOpen(true);
  }, []);

  const closeLightbox = useCallback(() => {
    setLightboxOpen(false);
    triggerRef.current?.focus();
  }, []);

  const showPrevious = useCallback(() => {
    setActiveIndex((i) => (i <= 0 ? items.length - 1 : i - 1));
  }, [items.length]);

  const showNext = useCallback(() => {
    setActiveIndex((i) => (i >= items.length - 1 ? 0 : i + 1));
  }, [items.length]);

  useEffect(() => {
    if (!lightboxOpen) return;
    const main = document.getElementById("main-content");
    main?.setAttribute("inert", "");
    closeButtonRef.current?.focus();
    function onKeyDown(e: KeyboardEvent) {
      if (e.key === "Escape") closeLightbox();
      if (e.key === "ArrowLeft") showPrevious();
      if (e.key === "ArrowRight") showNext();
    }
    document.addEventListener("keydown", onKeyDown);
    document.body.style.overflow = "hidden";
    return () => {
      document.removeEventListener("keydown", onKeyDown);
      document.body.style.overflow = "";
      main?.removeAttribute("inert");
    };
  }, [lightboxOpen, closeLightbox, showNext, showPrevious]);

  if (items.length === 0) {
    return (
      <div className="flex min-h-48 items-center justify-center rounded-xl border border-dashed border-gray-300 text-sm text-gray-500">
        {imageUnavailableLabel}
      </div>
    );
  }

  const active = items[activeIndex];

  return (
    <>
      <figure className={cn("mt-6", className)} aria-roledescription="carousel">
        <div className="flex snap-x snap-mandatory gap-3 overflow-x-auto pb-2" role="list">
          {items.map((item, index) => (
            <div key={`${item.id}-${index}`} className="w-[min(85%,28rem)] shrink-0 snap-start" role="listitem">
              <button
                type="button"
                className="relative block aspect-[4/3] w-full overflow-hidden rounded-xl bg-gray-100 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary"
                onClick={(e) => openLightbox(index, e.currentTarget)}
                aria-label={item.alt || item.caption || slideLabel(index + 1, items.length)}
              >
                <Image src={item.src} alt={item.alt} fill className="object-cover" sizes="(min-width: 768px) 448px, 85vw" unoptimized={shouldUseUnoptimizedNewsImage(item.src)} />
              </button>
              {item.caption ? (
                <figcaption className="mt-2 text-center text-sm text-gray-500">{item.caption}</figcaption>
              ) : null}
            </div>
          ))}
        </div>
        <div className="mt-3 flex justify-center gap-1.5" aria-hidden>
          {items.map((item, index) => (
            <span
              key={`dot-${item.id}-${index}`}
              className={cn(
                "h-1.5 w-1.5 rounded-full",
                index === activeIndex ? "bg-gray-600" : "bg-gray-300",
              )}
            />
          ))}
        </div>
      </figure>

      {lightboxOpen && active ? (
        <div
          className="fixed inset-0 z-[1400] flex flex-col bg-black/90"
          role="dialog"
          aria-modal="true"
          aria-label={active.caption ?? active.alt ?? dialogLabel}
        >
          <div className="flex items-center justify-between px-4 py-3 text-white">
            <p className="truncate text-sm">{active.caption ?? active.alt}</p>
            <button
              ref={closeButtonRef}
              type="button"
              className="rounded-md px-3 py-1 text-sm hover:bg-white/10"
              onClick={closeLightbox}
            >
              {closeLabel}
            </button>
          </div>
          <div className="relative flex flex-1 items-center justify-center px-4">
            <button type="button" className="absolute left-2 rounded-full bg-white/10 px-3 py-2 text-white hover:bg-white/20" onClick={showPrevious} aria-label={previousLabel}>
              ‹
            </button>
            <div className="relative h-[min(70vh,720px)] w-full max-w-5xl">
              <Image src={active.src} alt={active.alt} fill className="object-contain" sizes="100vw" unoptimized={shouldUseUnoptimizedNewsImage(active.src)} priority />
            </div>
            <button type="button" className="absolute right-2 rounded-full bg-white/10 px-3 py-2 text-white hover:bg-white/20" onClick={showNext} aria-label={nextLabel}>
              ›
            </button>
          </div>
          <div className="flex gap-2 overflow-x-auto px-4 pb-4">
            {items.map((item, index) => (
              <button
                key={`thumb-${item.id}-${index}`}
                type="button"
                className={cn(
                  "relative h-14 w-20 shrink-0 overflow-hidden rounded-md border-2",
                  index === activeIndex ? "border-white" : "border-transparent opacity-70",
                )}
                onClick={() => setActiveIndex(index)}
                aria-label={slideLabel(index + 1, items.length)}
                aria-current={index === activeIndex ? "true" : undefined}
              >
                <Image src={item.src} alt="" fill className="object-cover" sizes="80px" unoptimized={shouldUseUnoptimizedNewsImage(item.src)} />
              </button>
            ))}
          </div>
        </div>
      ) : null}
    </>
  );
}
