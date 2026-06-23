import type { Prisma } from '../../prisma-client';
import { NewsMediaSignedUrlService } from './news-media-signed-url.service';

export const NEWS_POST_ADMIN_INCLUDE = {
  media: { orderBy: { sortOrder: 'asc' as const } },
  coverMedia: true,
} as const;

export type NewsPostWithMedia = Prisma.NewsPostGetPayload<{
  include: typeof NEWS_POST_ADMIN_INCLUDE;
}>;

export async function signNewsPostMedia(
  signedUrls: NewsMediaSignedUrlService,
  post: NewsPostWithMedia,
) {
  const keys: string[] = [];
  for (const m of post.media) keys.push(m.objectKey);
  if (post.coverMedia) keys.push(post.coverMedia.objectKey);
  return signedUrls.signMany(keys);
}
