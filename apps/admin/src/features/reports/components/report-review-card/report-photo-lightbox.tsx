'use client';

import { RefObject, useEffect, useRef } from 'react';
import { useTranslations } from 'next-intl';
import Image from 'next/image';
import { createPortal } from 'react-dom';
import { AnimatePresence, motion } from 'framer-motion';
import { Icon } from '@/components/ui';
import { useFocusTrap } from '@/lib/utils';
import type { ReportEvidence } from '../../types';
import styles from './report-photo-lightbox.module.css';

type ReportPhotoLightboxProps = {
  isOpen: boolean;
  photoEvidence: ReportEvidence[];
  activePhoto: ReportEvidence | null;
  activePhotoIndex: number;
  filmstripRef: RefObject<HTMLDivElement | null>;
  thumbRefs: RefObject<Map<number, HTMLButtonElement | null>>;
  onClose: () => void;
  onSelectPhoto: (photoId: string) => void;
  onShowPrevious: () => void;
  onShowNext: () => void;
};

export function ReportPhotoLightbox({
  isOpen,
  photoEvidence,
  activePhoto,
  activePhotoIndex,
  filmstripRef,
  thumbRefs,
  onClose,
  onSelectPhoto,
  onShowPrevious,
  onShowNext,
}: ReportPhotoLightboxProps) {
  const t = useTranslations('reports.evidence');
  const backdropRef = useRef<HTMLDivElement>(null);
  const closeRef = useRef<HTMLButtonElement>(null);
  useFocusTrap(isOpen, backdropRef);

  useEffect(() => {
    if (!isOpen) return;
    const previousFocus = document.activeElement as HTMLElement | null;
    closeRef.current?.focus();
    return () => {
      previousFocus?.focus();
    };
  }, [isOpen]);

  if (typeof document === 'undefined' || !document.body) {
    return null;
  }

  return createPortal(
    <AnimatePresence mode="wait">
      {isOpen && activePhoto?.previewUrl ? (
        <motion.div
          ref={backdropRef}
          className={styles.lightboxBackdrop}
          role="dialog"
          aria-modal="true"
          aria-label={t('photoPreviewAria')}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.24 }}
          onMouseDown={(event) => {
            if (event.target !== event.currentTarget) return;
            onClose();
          }}
        >
          <motion.div
            className={styles.lightbox}
            initial={{ opacity: 0, scale: 0.94, y: 12 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.94, y: 12 }}
            transition={{ duration: 0.28, ease: [0.25, 0.46, 0.45, 0.94] }}
          >
            <div className={styles.lightboxHeader}>
              <p className={styles.lightboxLabel}>{activePhoto.label}</p>
              <button ref={closeRef} type="button" className={styles.lightboxClose} aria-label={t('closePhotoAria')} onClick={onClose}>
                <Icon name="x" size={18} />
              </button>
            </div>
            <div className={styles.lightboxBody}>
              {photoEvidence.length > 1 ? (
                <button type="button" className={styles.lightboxNav} aria-label={t('previousPhotoAria')} onClick={onShowPrevious}>
                  <Icon name="chevron-left" size={22} />
                </button>
              ) : null}
              <div className={styles.lightboxImageWrap}>
                <motion.div
                  key={activePhoto.id}
                  className={styles.lightboxImageInner}
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  transition={{ duration: 0.2 }}
                >
                  <Image
                    src={activePhoto.previewUrl}
                    alt={activePhoto.previewAlt ?? activePhoto.label}
                    className={styles.lightboxImage}
                    loading="lazy"
                    width={1600}
                    height={1000}
                  />
                </motion.div>
              </div>
              {photoEvidence.length > 1 ? (
                <button type="button" className={styles.lightboxNav} aria-label={t('nextPhotoAria')} onClick={onShowNext}>
                  <Icon name="chevron-right" size={22} />
                </button>
              ) : null}
            </div>
            <div className={styles.lightboxFooter}>
              {photoEvidence.length > 1 ? (
                <>
                  <div className={styles.lightboxPager}>
                    {photoEvidence.map((_, i) => (
                      <span
                        key={i}
                        className={`${styles.lightboxDot} ${i === activePhotoIndex ? styles.lightboxDotActive : ''}`}
                        aria-hidden
                      />
                    ))}
                  </div>
                  <div className={styles.lightboxFilmstripWrap}>
                    <div ref={filmstripRef} className={styles.lightboxFilmstrip} role="tablist" aria-label={t('thumbnailsAria')}>
                      {photoEvidence.map((item, i) => (
                        <button
                          key={item.id}
                          ref={(el) => {
                            thumbRefs.current?.set(i, el);
                          }}
                          type="button"
                          role="tab"
                          aria-selected={item.id === activePhoto?.id}
                          className={`${styles.lightboxThumb} ${item.id === activePhoto?.id ? styles.lightboxThumbActive : ''}`}
                          onClick={() => onSelectPhoto(item.id)}
                        >
                          {item.previewUrl ? <Image src={item.previewUrl} alt="" width={80} height={60} /> : null}
                        </button>
                      ))}
                    </div>
                  </div>
                </>
              ) : null}
              <p className={styles.lightboxMeta}>
                {activePhotoIndex + 1} of {photoEvidence.length}
                {activePhoto.sizeLabel ? ` · ${activePhoto.sizeLabel}` : ''}
              </p>
            </div>
          </motion.div>
        </motion.div>
      ) : null}
    </AnimatePresence>,
    document.body,
  );
}
