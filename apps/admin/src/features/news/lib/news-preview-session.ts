import type { NewsMediaDto, NewsPostAdminDto } from '../news-api-types';
import type { NewsFormLocale, NewsPostFormValues } from '../types';

export const NEWS_PREVIEW_SESSION_PREFIX = 'chisto:news-preview:';
export const NEWS_PREVIEW_CHANNEL = 'chisto:news-preview';

export type NewsPreviewSessionPayload = {
  postId: string;
  locale: NewsFormLocale;
  values: NewsPostFormValues;
  media: NewsMediaDto[];
  coverImageUrl: string | null;
  coverMediaId: string | null;
  status: NewsPostAdminDto['status'];
  category: NewsPostFormValues['category'];
  updatedAt: number;
};

function sessionKey(postId: string): string {
  return `${NEWS_PREVIEW_SESSION_PREFIX}${postId}`;
}

export function writeNewsPreviewSession(payload: NewsPreviewSessionPayload): void {
  if (typeof window === 'undefined') return;
  try {
    sessionStorage.setItem(sessionKey(payload.postId), JSON.stringify(payload));
    if (typeof BroadcastChannel !== 'undefined') {
      const channel = new BroadcastChannel(NEWS_PREVIEW_CHANNEL);
      channel.postMessage({ type: 'update', postId: payload.postId, updatedAt: payload.updatedAt });
      channel.close();
    }
  } catch {
    // sessionStorage may be unavailable in private mode
  }
}

export function readNewsPreviewSession(postId: string): NewsPreviewSessionPayload | null {
  if (typeof window === 'undefined') return null;
  try {
    const raw = sessionStorage.getItem(sessionKey(postId));
    if (!raw) return null;
    return JSON.parse(raw) as NewsPreviewSessionPayload;
  } catch {
    return null;
  }
}

export function newsPreviewPagePath(postId: string, locale?: NewsFormLocale): string {
  const base = `/dashboard/news/${encodeURIComponent(postId)}/preview`;
  return locale ? `${base}?locale=${locale}` : base;
}
