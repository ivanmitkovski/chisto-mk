'use client';

import Image from 'next/image';
import { useCallback, useEffect, useRef, useState } from 'react';
import { useTranslations } from 'next-intl';
import type { GalleryRenderItem } from '@chisto/news-content/render';
import styles from './news-gallery-preview-carousel.module.css';

type NewsGalleryPreviewCarouselProps = {
  items: GalleryRenderItem[];
  className?: string | undefined;
};

/**
 * Admin preview twin of the landing NewsGalleryCarousel: snap track with dots
 * plus a lightbox with keyboard navigation, so editors see the production
 * gallery UX while drafting.
 */
export function NewsGalleryPreviewCarousel({ items, className }: NewsGalleryPreviewCarouselProps) {
  const t = useTranslations('news.previewBlocks');
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
    closeButtonRef.current?.focus();
    function onKeyDown(e: KeyboardEvent) {
      if (e.key === 'Escape') closeLightbox();
      if (e.key === 'ArrowLeft') showPrevious();
      if (e.key === 'ArrowRight') showNext();
    }
    document.addEventListener('keydown', onKeyDown);
    document.body.style.overflow = 'hidden';
    return () => {
      document.removeEventListener('keydown', onKeyDown);
      document.body.style.overflow = '';
    };
  }, [lightboxOpen, closeLightbox, showNext, showPrevious]);

  if (items.length === 0) {
    return (
      <div className={styles.empty} role="img" aria-label={t('galleryUnavailable')}>
        {t('galleryUnavailable')}
      </div>
    );
  }

  const active = items[activeIndex];

  return (
    <>
      <figure
        className={[styles.gallery, className].filter(Boolean).join(' ')}
        aria-roledescription="carousel"
      >
        <div className={styles.track} role="list">
          {items.map((item, index) => (
            <div key={`${item.id}-${index}`} className={styles.slide} role="listitem">
              <button
                type="button"
                className={styles.slideButton}
                onClick={(e) => openLightbox(index, e.currentTarget)}
                aria-label={
                  item.alt || item.caption || t('gallerySlideLabel', { index: index + 1, total: items.length })
                }
              >
                <Image
                  src={item.src}
                  alt={item.alt}
                  fill
                  className={styles.slideImage}
                  sizes="(min-width: 48rem) 28rem, 85vw"
                  unoptimized
                />
              </button>
              {item.caption ? (
                <figcaption className={styles.slideCaption}>{item.caption}</figcaption>
              ) : null}
            </div>
          ))}
        </div>
        <div className={styles.dots} aria-hidden>
          {items.map((item, index) => (
            <span
              key={`dot-${item.id}-${index}`}
              className={index === activeIndex ? `${styles.dot} ${styles.dotActive}` : styles.dot}
            />
          ))}
        </div>
      </figure>

      {lightboxOpen && active ? (
        <div
          className={styles.lightbox}
          role="dialog"
          aria-modal="true"
          aria-label={active.caption ?? active.alt ?? t('galleryDialogLabel')}
        >
          <div className={styles.lightboxHeader}>
            <p className={styles.lightboxCaption}>{active.caption ?? active.alt}</p>
            <button
              ref={closeButtonRef}
              type="button"
              className={styles.lightboxClose}
              onClick={closeLightbox}
            >
              {t('galleryClose')}
            </button>
          </div>
          <div className={styles.lightboxStage}>
            <button
              type="button"
              className={`${styles.lightboxNav} ${styles.lightboxNavPrev}`}
              onClick={showPrevious}
              aria-label={t('galleryPrevious')}
            >
              ‹
            </button>
            <div className={styles.lightboxFrame}>
              <Image
                src={active.src}
                alt={active.alt}
                fill
                className={styles.lightboxImage}
                sizes="100vw"
                unoptimized
                priority
              />
            </div>
            <button
              type="button"
              className={`${styles.lightboxNav} ${styles.lightboxNavNext}`}
              onClick={showNext}
              aria-label={t('galleryNext')}
            >
              ›
            </button>
          </div>
          <div className={styles.thumbs}>
            {items.map((item, index) => (
              <button
                key={`thumb-${item.id}-${index}`}
                type="button"
                className={
                  index === activeIndex ? `${styles.thumb} ${styles.thumbActive}` : styles.thumb
                }
                onClick={() => setActiveIndex(index)}
                aria-label={t('gallerySlideLabel', { index: index + 1, total: items.length })}
                aria-current={index === activeIndex ? 'true' : undefined}
              >
                <Image src={item.src} alt="" fill className={styles.thumbImage} sizes="5rem" unoptimized />
              </button>
            ))}
          </div>
        </div>
      ) : null}
    </>
  );
}
