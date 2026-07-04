import { getAdminCsrfHeaders } from '@/lib/auth/csrf-headers';
import { recoverFromUnauthorized } from '@/lib/auth/client-auth-recovery';
import { ApiConnectionError, ApiError } from '@/lib/api/api';
import type { NewsPostAdminDto } from '../news-api-types';
import type {
  NewsCategoryApi,
  NewsLocale,
  NewsMediaDto,
  NewsTranslations,
  NewsListResponse,
} from '../news-api-types';
import type { NewsPostFormValues } from '../types';
import type { NewsListQuery } from '../config/news-list-filters';
import { NEWS_LIST_PAGE_SIZE } from '../config/news-list-filters';
import { normalizeNewsListResponse } from '../lib/news-list-response';
import { buildCreateNewsInput } from '../lib/build-create-news-input';

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
    details?: unknown;
  };
  if (!response.ok) {
    throw new ApiError(
      response.status,
      payload.code ?? 'HTTP_ERROR',
      payload.message ?? `Request failed (${response.status})`,
      payload.details,
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

export async function createNewsPost(
  input: Pick<NewsPostFormValues, 'slug' | 'category' | 'translations'>,
): Promise<NewsPostAdminDto> {
  const payload = buildCreateNewsInput(input);
  return apiFetch('/admin/news/posts', {
    method: 'POST',
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
      ...getAdminCsrfHeaders(),
      'X-Idempotency-Key': crypto.randomUUID(),
    },
    body: JSON.stringify(payload),
  });
}

export async function updateNewsPost(
  id: string,
  input: {
    slug?: string;
    category?: NewsCategoryApi;
    translations?: NewsTranslations;
    scheduledAt?: string | null;
    featured?: boolean;
    expectedUpdatedAt?: string;
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
): Promise<NewsMediaDto> {
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

function buildListQuery(params?: NewsListQuery): string {
  const sp = new URLSearchParams();
  const limit = NEWS_LIST_PAGE_SIZE;
  const page = params?.page ?? 1;
  sp.set('limit', String(limit));
  sp.set('offset', String((page - 1) * limit));
  if (params?.status) sp.set('status', params.status);
  if (params?.category) sp.set('category', params.category);
  if (params?.q) sp.set('q', params.q);
  if (params?.sort && params.sort !== 'publishedAt') sp.set('sort', params.sort);
  const qs = sp.toString();
  return `/admin/news/posts${qs ? `?${qs}` : ''}`;
}

export async function listNewsPostsClient(params?: NewsListQuery): Promise<NewsListResponse> {
  const payload = await apiFetch<NewsListResponse | NewsPostAdminDto[]>(buildListQuery(params), {
    method: 'GET',
    headers: { Accept: 'application/json' },
  });
  return normalizeNewsListResponse(payload, params);
}

export type NewsRevisionDto = {
  id: string;
  createdAt: string;
  createdById: string | null;
  snapshot: {
    slug: string;
    category: NewsCategoryApi;
    featured: boolean;
    scheduledAt: string | null;
    translations: NewsTranslations;
  };
};

export async function duplicateNewsPost(id: string): Promise<NewsPostAdminDto> {
  return apiFetch(`/admin/news/posts/${encodeURIComponent(id)}/duplicate`, {
    method: 'POST',
    headers: { Accept: 'application/json', ...getAdminCsrfHeaders() },
  });
}

export async function listNewsRevisions(postId: string): Promise<NewsRevisionDto[]> {
  return apiFetch(`/admin/news/posts/${encodeURIComponent(postId)}/revisions`, {
    method: 'GET',
    headers: { Accept: 'application/json' },
  });
}

export async function restoreNewsRevision(
  postId: string,
  revisionId: string,
): Promise<NewsPostAdminDto> {
  return apiFetch(
    `/admin/news/posts/${encodeURIComponent(postId)}/revisions/${encodeURIComponent(revisionId)}/restore`,
    {
      method: 'POST',
      headers: { Accept: 'application/json', ...getAdminCsrfHeaders() },
    },
  );
}

export async function clearNewsRevisions(postId: string): Promise<{ deleted: number }> {
  return apiFetch(`/admin/news/posts/${encodeURIComponent(postId)}/revisions`, {
    method: 'DELETE',
    headers: { Accept: 'application/json', ...getAdminCsrfHeaders() },
  });
}

export async function updateNewsMediaAlt(
  mediaId: string,
  altText: Partial<Record<NewsLocale, string>>,
): Promise<NewsMediaDto> {
  return apiFetch(`/admin/news/media/${encodeURIComponent(mediaId)}`, {
    method: 'PATCH',
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
      ...getAdminCsrfHeaders(),
    },
    body: JSON.stringify({ altText }),
  });
}
