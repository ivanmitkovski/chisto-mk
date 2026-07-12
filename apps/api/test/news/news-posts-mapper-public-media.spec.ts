/// <reference types="jest" />
import { toPublicDto, toPublicListItem } from '../../src/news/services/news-posts.mapper';

const basePost = {
  id: 'post-1',
  slug: 'kanal-5',
  category: 'MEDIA' as const,
  status: 'PUBLISHED' as const,
  publishedAt: new Date('2026-07-12T10:00:00.000Z'),
  scheduledAt: null,
  featured: true,
  translations: {
    en: { title: 'EN', excerpt: 'ex', body: [] },
    mk: { title: 'MK', excerpt: 'ex', body: [] },
    sq: { title: 'SQ', excerpt: 'ex', body: [] },
  },
  createdAt: new Date('2026-07-12T09:00:00.000Z'),
  updatedAt: new Date('2026-07-12T11:00:00.000Z'),
  coverMediaId: 'cover-1',
  createdById: null,
  updatedById: null,
};

const coverMedia = {
  id: 'cover-1',
  createdAt: new Date('2026-07-12T09:00:00.000Z'),
  postId: 'post-1',
  kind: 'COVER' as const,
  objectKey: 'news/post-1/cover.jpg',
  mimeType: 'image/jpeg',
  fileName: 'cover.jpg',
  sizeBytes: 1000,
  width: 2100,
  height: 900,
  durationSeconds: null,
  altText: { en: 'Cover', mk: 'Cover', sq: 'Cover' },
  sortOrder: 0,
};

describe('news public media mapper', () => {
  it('emits stable cover URLs for list items', () => {
    const item = toPublicListItem(
      { ...basePost, coverMedia },
      'en',
      'https://api.chisto.mk/v1',
    );
    expect(item.coverImageUrl).toBe('https://api.chisto.mk/v1/news/media/cover-1');
  });

  it('emits stable cover and media URLs for detail payloads', () => {
    const dto = toPublicDto(
      { ...basePost, coverMedia, media: [coverMedia] },
      'mk',
      'https://api.chisto.mk/v1',
    );
    expect(dto.coverImageUrl).toBe('https://api.chisto.mk/v1/news/media/cover-1');
    expect(dto.media[0]?.url).toBe('https://api.chisto.mk/v1/news/media/cover-1');
  });
});
