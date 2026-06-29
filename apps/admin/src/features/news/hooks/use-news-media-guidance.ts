'use client';

import { useTranslations } from 'next-intl';
import { useCallback } from 'react';
import {
  getNewsMediaGuidanceParams,
  NEWS_MEDIA_GUIDANCE_MESSAGE_KEY,
  type NewsMediaGuidanceKind,
} from '../lib/news-media-guidance';

export function useNewsMediaGuidanceText() {
  const t = useTranslations('news');

  return useCallback(
    (kind: NewsMediaGuidanceKind) =>
      t(NEWS_MEDIA_GUIDANCE_MESSAGE_KEY[kind], getNewsMediaGuidanceParams(kind)),
    [t],
  );
}
