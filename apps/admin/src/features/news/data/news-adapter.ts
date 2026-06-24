import { serverAuthenticatedFetch } from '@/lib/auth/server-api-with-refresh';
import type { NewsListResponse, NewsPostAdminDto } from '../news-api-types';
import type { NewsListQuery } from '../config/news-list-filters';
import { NEWS_LIST_PAGE_SIZE } from '../config/news-list-filters';
import { normalizeNewsListResponse } from '../lib/news-list-response';

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

export async function listNewsPosts(params?: NewsListQuery): Promise<NewsListResponse> {
  const payload = await serverAuthenticatedFetch<NewsListResponse | NewsPostAdminDto[]>(
    buildListQuery(params),
    { method: 'GET' },
  );
  return normalizeNewsListResponse(payload, params);
}

export async function getNewsPost(id: string): Promise<NewsPostAdminDto> {
  return serverAuthenticatedFetch<NewsPostAdminDto>(
    `/admin/news/posts/${encodeURIComponent(id)}`,
    { method: 'GET' },
  );
}
