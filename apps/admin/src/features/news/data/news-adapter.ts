import { serverAuthenticatedFetch } from '@/lib/auth/server-api-with-refresh';
import type { NewsPostAdminDto } from '../news-api-types';

export async function listNewsPosts(): Promise<NewsPostAdminDto[]> {
  return serverAuthenticatedFetch<NewsPostAdminDto[]>('/admin/news/posts', { method: 'GET' });
}

export async function getNewsPost(id: string): Promise<NewsPostAdminDto> {
  return serverAuthenticatedFetch<NewsPostAdminDto>(
    `/admin/news/posts/${encodeURIComponent(id)}`,
    { method: 'GET' },
  );
}
