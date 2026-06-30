import { NEWS_LIST_PAGE_SIZE } from '../config/news-list-filters';
import type { NewsListQuery } from '../config/news-list-filters';
import type { NewsListResponse, NewsPostAdminDto } from '../news-api-types';
import { countsByStatus } from './news-locale-utils';

/** Normalize legacy array responses and partial payloads from the admin list API. */
export function normalizeNewsListResponse(
  payload: NewsListResponse | NewsPostAdminDto[] | null | undefined,
  params?: NewsListQuery,
): NewsListResponse {
  const limit = NEWS_LIST_PAGE_SIZE;
  const page = params?.page ?? 1;
  const offset = (page - 1) * limit;

  if (Array.isArray(payload)) {
    const total = payload.length;
    return {
      items: payload.slice(offset, offset + limit),
      total,
      countsByStatus: countsByStatus(payload),
      limit,
      offset,
    };
  }

  const items = payload?.items ?? [];
  return {
    items,
    total: payload?.total ?? items.length,
    countsByStatus: payload?.countsByStatus ?? countsByStatus(items),
    limit: payload?.limit ?? limit,
    offset: payload?.offset ?? offset,
  };
}
