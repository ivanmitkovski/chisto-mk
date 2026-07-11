"use client";

import Image from "next/image";
import { shouldUseUnoptimizedNewsImage } from "@/lib/images/news-image-optimization";
import { useCallback, useState } from "react";
import { useTranslations } from "next-intl";
import type { GalleryRenderItem } from "@chisto/news-content/render";
import { ImageViewer } from "@/components/molecules/ImageViewer";
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

  const openLightbox = useCallback((index: number) => {
    setActiveIndex(index);
    setLightboxOpen(true);
  }, []);

  if (items.length === 0) {
    return (
      <div className="flex min-h-48 items-center justify-center rounded-xl border border-dashed border-gray-300 text-sm text-gray-500">
        {imageUnavailableLabel}
      </div>
    );
  }

  return (
    <>
      <figure className={cn("mt-6", className)} aria-roledescription="carousel">
        <div className="flex snap-x snap-mandatory gap-3 overflow-x-auto pb-2" role="list">
          {items.map((item, index) => (
            <div key={`${item.id}-${index}`} className="w-[min(85%,28rem)] shrink-0 snap-start" role="listitem">
              <button
                type="button"
                className="relative block aspect-[4/3] w-full cursor-zoom-in overflow-hidden rounded-xl bg-gray-100 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary"
                onClick={() => openLightbox(index)}
                aria-label={item.alt || item.caption || slideLabel(index + 1, items.length)}
              >
                <Image
                  src={item.src}
                  alt={item.alt}
                  fill
                  className="object-cover"
                  sizes="(min-width: 768px) 448px, 85vw"
                  unoptimized={shouldUseUnoptimizedNewsImage(item.src)}
                />
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

      <ImageViewer
        open={lightboxOpen}
        onOpenChange={setLightboxOpen}
        items={items.map((item) => ({
          src: item.src,
          alt: item.alt,
          ...(item.caption ? { caption: item.caption } : {}),
        }))}
        index={activeIndex}
        onIndexChange={setActiveIndex}
        labels={{
          close: closeLabel,
          dialog: dialogLabel,
          previous: previousLabel,
          next: nextLabel,
          slide: slideLabel,
        }}
      />
    </>
  );
}
