import { getAdminCsrfHeaders } from '@/lib/auth/csrf-headers';
import { recoverFromUnauthorized } from '@/lib/auth/client-auth-recovery';
import { ApiConnectionError, ApiError } from '@/lib/api/api';
import type { NewsPostAdminDto } from '../news-api-types';
import type { NewsCategoryApi, NewsTranslations } from '../news-api-types';

async function fetchOnce<T>(
  path: string,
  init: RequestInit,
): Promise<T> {
  let response: Response;
  try {
    response = await fetch(`/api/proxy${path}`, {
      ...init,
      credentials: 'include',
      signal: AbortSignal.timeout(60_000),
    });
  } catch (cause) {
    throw new ApiConnectionError(`Network request failed (${path})`, { cause });
  }
  const payload = (await response.json().catch(() => ({}))) as {
    code?: string;
    message?: string;
  };
  if (!response.ok) {
    throw new ApiError(
      response.status,
      payload.code ?? 'HTTP_ERROR',
      payload.message ?? `Request failed (${response.status})`,
    );
  }
  return payload as T;
}

async function apiFetch<T>(path: string, init: RequestInit): Promise<T> {
  try {
    return await fetchOnce<T>(path, init);
  } catch (error) {
    if (error instanceof ApiError && error.status === 401) {
      const retry = await recoverFromUnauthorized();
      if (retry) return fetchOnce<T>(path, init);
    }
    throw error;
  }
}

export async function createNewsPost(input: {
  slug?: string;
  category: NewsCategoryApi;
  translations: NewsTranslations;
}): Promise<NewsPostAdminDto> {
  return apiFetch('/admin/news/posts', {
    method: 'POST',
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
      ...getAdminCsrfHeaders(),
      'X-Idempotency-Key': crypto.randomUUID(),
    },
    body: JSON.stringify(input),
  });
}

export async function updateNewsPost(
  id: string,
  input: {
    slug?: string;
    category?: NewsCategoryApi;
    translations?: NewsTranslations;
    scheduledAt?: string | null;
  },
): Promise<NewsPostAdminDto> {
  return apiFetch(`/admin/news/posts/${encodeURIComponent(id)}`, {
    method: 'PATCH',
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
      ...getAdminCsrfHeaders(),
    },
    body: JSON.stringify(input),
  });
}

export async function publishNewsPost(id: string): Promise<NewsPostAdminDto> {
  return apiFetch(`/admin/news/posts/${encodeURIComponent(id)}/publish`, {
    method: 'POST',
    headers: { Accept: 'application/json', ...getAdminCsrfHeaders() },
  });
}

export async function unpublishNewsPost(id: string): Promise<NewsPostAdminDto> {
  return apiFetch(`/admin/news/posts/${encodeURIComponent(id)}/unpublish`, {
    method: 'POST',
    headers: { Accept: 'application/json', ...getAdminCsrfHeaders() },
  });
}

export async function archiveNewsPost(id: string): Promise<NewsPostAdminDto> {
  return apiFetch(`/admin/news/posts/${encodeURIComponent(id)}/archive`, {
    method: 'POST',
    headers: { Accept: 'application/json', ...getAdminCsrfHeaders() },
  });
}

export async function deleteNewsPost(id: string): Promise<void> {
  await apiFetch(`/admin/news/posts/${encodeURIComponent(id)}`, {
    method: 'DELETE',
    headers: { Accept: 'application/json', ...getAdminCsrfHeaders() },
  });
}

export async function uploadNewsMedia(
  postId: string,
  kind: 'cover' | 'inline_image' | 'inline_video',
  file: File,
): Promise<unknown> {
  const form = new FormData();
  form.append('file', file);
  return apiFetch(
    `/admin/news/posts/${encodeURIComponent(postId)}/media?kind=${encodeURIComponent(kind)}`,
    {
      method: 'POST',
      headers: { Accept: 'application/json', ...getAdminCsrfHeaders() },
      body: form,
    },
  );
}

export async function deleteNewsMedia(mediaId: string): Promise<void> {
  await apiFetch(`/admin/news/media/${encodeURIComponent(mediaId)}`, {
    method: 'DELETE',
    headers: { Accept: 'application/json', ...getAdminCsrfHeaders() },
  });
}

export async function fetchNewsPost(id: string): Promise<NewsPostAdminDto> {
  return apiFetch(`/admin/news/posts/${encodeURIComponent(id)}`, {
    method: 'GET',
    headers: { Accept: 'application/json' },
  });
}
