import { describe, expect, it } from 'vitest';
import { normalizeNewsListResponse } from './news-list-response';
import type { NewsListResponse, NewsPostAdminDto } from '../news-api-types';

function mockPost(id: string, status: string): NewsPostAdminDto {
  return {
    id,
    slug: `post-${id}`,
    category: 'release',
    status: status as NewsPostAdminDto['status'],
    publishedAt: null,
    scheduledAt: null,
    featured: false,
    translations: {
      en: { title: 'T', excerpt: 'E', body: [] },
      mk: { title: '', excerpt: '', body: [] },
      sq: { title: '', excerpt: '', body: [] },
    },
    coverMediaId: null,
    coverImageUrl: null,
    media: [],
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
  };
}

describe('normalizeNewsListResponse', () => {
  it('normalizes legacy array responses with pagination', () => {
    const posts = [mockPost('1', 'draft'), mockPost('2', 'published')];
    const result = normalizeNewsListResponse(posts, { page: 1 });
    expect(result.items).toHaveLength(2);
    expect(result.total).toBe(2);
    expect(result.countsByStatus.draft).toBe(1);
    expect(result.countsByStatus.published).toBe(1);
  });

  it('fills missing fields on partial payloads', () => {
    const result = normalizeNewsListResponse({
      items: [mockPost('1', 'draft')],
      total: 1,
    } as NewsListResponse);
    expect(result.countsByStatus.draft).toBe(1);
    expect(result.limit).toBe(20);
  });

  it('handles null payload', () => {
    const result = normalizeNewsListResponse(null);
    expect(result.items).toEqual([]);
    expect(result.total).toBe(0);
  });
});
