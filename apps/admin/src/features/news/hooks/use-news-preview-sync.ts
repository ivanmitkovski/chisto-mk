'use client';

import { useEffect, useRef } from 'react';
import type { NewsMediaDto, NewsPostAdminDto } from '../news-api-types';
import { writeNewsPreviewSession, type NewsPreviewSessionPayload } from '../lib/news-preview-session';
import type { NewsFormLocale, NewsPostFormValues } from '../types';

type UseNewsPreviewSyncOptions = {
  postId: string;
  locale: NewsFormLocale;
  values: NewsPostFormValues;
  media: NewsMediaDto[];
  coverImageUrl: string | null;
  coverMediaId: string | null;
  status: NewsPostAdminDto['status'];
};

export function useNewsPreviewSync({
  postId,
  locale,
  values,
  media,
  coverImageUrl,
  coverMediaId,
  status,
}: UseNewsPreviewSyncOptions): void {
  const timerRef = useRef<number | null>(null);

  useEffect(() => {
    const payload: NewsPreviewSessionPayload = {
      postId,
      locale,
      values,
      media,
      coverImageUrl,
      coverMediaId,
      status,
      category: values.category,
      updatedAt: Date.now(),
    };

    if (timerRef.current !== null) {
      window.clearTimeout(timerRef.current);
    }

    timerRef.current = window.setTimeout(() => {
      writeNewsPreviewSession(payload);
    }, 200);

    return () => {
      if (timerRef.current !== null) {
        window.clearTimeout(timerRef.current);
      }
    };
  }, [coverImageUrl, coverMediaId, locale, media, postId, status, values]);
}
