"use client";

import Image, { type ImageProps } from "next/image";
import { useCallback, useEffect, useRef, useState } from "react";
import { NEWS_COVER_FRAME_SURFACE } from "@/lib/images/news-cover-display";
import {
  newsImageObjectFitClass,
  shouldUseUnoptimizedNewsImage,
  type NewsImageRole,
} from "@/lib/images/news-image-optimization";
import { cn } from "@/lib/utils/cn";

type NewsImageProps = {
  src: string;
  alt: string;
  sizes: string;
  role?: NewsImageRole;
  className?: string;
  priority?: boolean;
  loading?: ImageProps["loading"];
  /** Extra classes for the soft fallback surface when the image fails. */
  fallbackClassName?: string;
};

/**
 * Resilient news media image: one automatic retry (covers transient CDN/redirect
 * blips), then a soft gradient surface — never a broken-image icon.
 */
export function NewsImage({
  src,
  alt,
  sizes,
  role = "inline",
  className,
  priority,
  loading,
  fallbackClassName,
}: NewsImageProps) {
  const [failed, setFailed] = useState(false);
  const [retryNonce, setRetryNonce] = useState(0);
  const didRetry = useRef(false);
  const prevSrc = useRef(src);

  useEffect(() => {
    if (prevSrc.current === src) return;
    prevSrc.current = src;
    didRetry.current = false;
    setFailed(false);
    setRetryNonce(0);
  }, [src]);

  const onError = useCallback(() => {
    if (!didRetry.current) {
      didRetry.current = true;
      setRetryNonce((n) => n + 1);
      return;
    }
    setFailed(true);
  }, []);

  if (failed || !src) {
    return (
      <div
        className={cn("absolute inset-0", NEWS_COVER_FRAME_SURFACE, fallbackClassName)}
        role="img"
        aria-label={alt || undefined}
      />
    );
  }

  return (
    <Image
      key={`${src}:${retryNonce}`}
      src={src}
      alt={alt}
      fill
      className={cn(newsImageObjectFitClass(src, role), className)}
      sizes={sizes}
      {...(priority ? { priority: true } : {})}
      {...(loading && !priority ? { loading } : {})}
      unoptimized={shouldUseUnoptimizedNewsImage(src)}
      onError={onError}
    />
  );
}
