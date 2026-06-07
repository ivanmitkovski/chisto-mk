'use client';

import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import type { ReportEvidence } from '../types';

type UseReportPhotoGalleryOptions = {
  evidence: ReportEvidence[];
};

export function useReportPhotoGallery({ evidence }: UseReportPhotoGalleryOptions) {
  const [activePhotoId, setActivePhotoId] = useState<string | null>(null);
  const [isLightboxOpen, setIsLightboxOpen] = useState(false);
  const filmstripRef = useRef<HTMLDivElement | null>(null);
  const thumbRefs = useRef<Map<number, HTMLButtonElement | null>>(new Map());

  const photoEvidence = useMemo(
    () => evidence.filter((item) => item.kind === 'image' && item.previewUrl),
    [evidence],
  );

  useEffect(() => {
    if (photoEvidence.length === 0) {
      setActivePhotoId(null);
      return;
    }

    const hasActive = photoEvidence.some((item) => item.id === activePhotoId);
    if (!hasActive) {
      setActivePhotoId(photoEvidence[0].id);
    }
  }, [activePhotoId, photoEvidence]);

  const activePhoto = photoEvidence.find((item) => item.id === activePhotoId) ?? photoEvidence[0] ?? null;
  const activePhotoIndex = photoEvidence.findIndex((item) => item.id === activePhoto?.id);

  const showPreviousPhoto = useCallback(() => {
    if (photoEvidence.length < 2 || activePhotoIndex === -1) {
      return;
    }

    const nextIndex = (activePhotoIndex - 1 + photoEvidence.length) % photoEvidence.length;
    setActivePhotoId(photoEvidence[nextIndex].id);
  }, [activePhotoIndex, photoEvidence]);

  const showNextPhoto = useCallback(() => {
    if (photoEvidence.length < 2 || activePhotoIndex === -1) {
      return;
    }

    const nextIndex = (activePhotoIndex + 1) % photoEvidence.length;
    setActivePhotoId(photoEvidence[nextIndex].id);
  }, [activePhotoIndex, photoEvidence]);

  const openLightbox = useCallback(
    (photoId?: string) => {
      if (photoId) {
        setActivePhotoId(photoId);
      }
      setIsLightboxOpen(true);
    },
    [],
  );

  useEffect(() => {
    const el = thumbRefs.current.get(activePhotoIndex);
    if (el && filmstripRef.current) {
      el.scrollIntoView({ block: 'nearest', inline: 'center', behavior: 'smooth' });
    }
  }, [activePhotoIndex, isLightboxOpen]);

  useEffect(() => {
    if (!isLightboxOpen) {
      return;
    }

    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';

    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        event.preventDefault();
        setIsLightboxOpen(false);
        return;
      }

      if (event.key === 'ArrowLeft') {
        event.preventDefault();
        showPreviousPhoto();
        return;
      }

      if (event.key === 'ArrowRight') {
        event.preventDefault();
        showNextPhoto();
      }
    };

    window.addEventListener('keydown', onKeyDown);
    return () => {
      document.body.style.overflow = previousOverflow;
      window.removeEventListener('keydown', onKeyDown);
    };
  }, [isLightboxOpen, showNextPhoto, showPreviousPhoto]);

  return {
    photoEvidence,
    activePhoto,
    activePhotoIndex,
    activePhotoId,
    setActivePhotoId,
    isLightboxOpen,
    setIsLightboxOpen,
    openLightbox,
    showPreviousPhoto,
    showNextPhoto,
    filmstripRef,
    thumbRefs,
  };
}
