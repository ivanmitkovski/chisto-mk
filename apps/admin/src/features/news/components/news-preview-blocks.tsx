'use client';

import Image from 'next/image';
import { useTranslations } from 'next-intl';
import { RenderNewsBlocks, resolvePreviewBlocks as resolveSharedBlocks } from '@chisto/news-content/render';
import type { NewsBodyBlock, NewsMediaDto } from '../news-api-types';

export function resolvePreviewBlocks(
  blocks: NewsBodyBlock[],
  media: NewsMediaDto[],
  locale: string,
) {
  const mediaById = new Map(
    media.map((m) => [
      m.id,
      {
        url: m.url,
        altText: m.altText?.[locale as keyof NonNullable<NewsMediaDto['altText']>] ?? null,
      },
    ]),
  );
  return resolveSharedBlocks(blocks, mediaById);
}

type NewsPreviewBlocksProps = {
  body: ReturnType<typeof resolvePreviewBlocks>;
};

export function NewsPreviewBlocks({ body }: NewsPreviewBlocksProps) {
  const t = useTranslations('news.previewBlocks');

  return (
    <RenderNewsBlocks
      blocks={body}
      className="prose-news"
      labels={{
        imageUnavailable: t('imageUnavailable'),
        videoUnavailable: t('videoUnavailable'),
        unknownBlock: t('unknownBlock'),
      }}
      showUnknownBlockWarning
      renderImage={({ src, alt, className, fill, loading, unoptimized }) => (
        <div className={className} style={{ position: 'relative', width: '100%', height: '100%' }}>
          <Image
            src={src}
            alt={alt}
            {...(fill !== undefined ? { fill } : {})}
            className="object-cover"
            sizes="(min-width: 768px) 768px, 100vw"
            {...(loading ? { loading } : {})}
            {...(unoptimized !== undefined ? { unoptimized } : { unoptimized: true })}
          />
        </div>
      )}
    />
  );
}
