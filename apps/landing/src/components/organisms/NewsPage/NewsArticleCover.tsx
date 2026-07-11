"use client";

import Image from "next/image";
import { useState } from "react";
import { NEWS_COVER_FRAME_SURFACE } from "@/lib/images/news-cover-display";
import { newsImageObjectFitClass, shouldUseUnoptimizedNewsImage } from "@/lib/images/news-image-optimization";
import { ImageViewer } from "@/components/molecules/ImageViewer";
import { cn } from "@/lib/utils/cn";

type NewsArticleCoverProps = {
  src: string;
  alt: string;
  caption?: string | null;
  viewImageLabel: string;
  closeLabel: string;
  dialogLabel: string;
};

export function NewsArticleCover({
  src,
  alt,
  caption,
  viewImageLabel,
  closeLabel,
  dialogLabel,
}: NewsArticleCoverProps) {
  const [open, setOpen] = useState(false);
  const showCaption = Boolean(caption?.trim());

  return (
    <>
      <figure className="mt-10 max-w-4xl">
        <button
          type="button"
          onClick={() => setOpen(true)}
          aria-label={viewImageLabel}
          className={cn(
            "group relative block aspect-[21/9] w-full cursor-zoom-in overflow-hidden rounded-2xl border border-gray-200/70",
            NEWS_COVER_FRAME_SURFACE,
            "shadow-sm transition-[box-shadow,border-color,transform]",
            "hover:border-primary/25 hover:shadow-md",
            "motion-safe:active:scale-[0.99]",
            "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2",
            "print:cursor-default print:border-gray-300 print:shadow-none",
          )}
        >
          <Image
            src={src}
            alt={alt}
            fill
            className={cn(
              newsImageObjectFitClass(src, "cover"),
              "transition-transform duration-300 motion-safe:group-hover:scale-[1.02] motion-safe:group-active:scale-100",
            )}
            sizes="(min-width: 896px) 896px, 100vw"
            priority
            unoptimized={shouldUseUnoptimizedNewsImage(src)}
          />
        </button>
        {showCaption ? (
          <figcaption className="mt-3 text-center text-sm leading-relaxed text-gray-500">
            {caption}
          </figcaption>
        ) : null}
      </figure>

      <div className="print:hidden">
        <ImageViewer
          open={open}
          onOpenChange={setOpen}
          items={[{ src, alt, ...(showCaption && caption ? { caption } : {}) }]}
          index={0}
          labels={{
            close: closeLabel,
            dialog: dialogLabel,
          }}
        />
      </div>
    </>
  );
}
