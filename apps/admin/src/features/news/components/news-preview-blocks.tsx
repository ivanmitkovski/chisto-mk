'use client';

import { isSvgMediaUrl } from '@chisto/news-content';
import Image from 'next/image';
import { useTranslations } from 'next-intl';
import { RenderNewsBlocks, resolvePreviewBlocks as resolveSharedBlocks } from '@chisto/news-content/render';
import type { ResolvedNewsBodyBlock } from '@chisto/news-content';
import type { NewsBodyBlock, NewsMediaDto } from '../news-api-types';
import { NewsGalleryPreviewCarousel } from './news-gallery-preview-carousel';
import styles from './news-preview-blocks.module.css';

export function resolvePreviewBlocks(
  blocks: NewsBodyBlock[],
  media: NewsMediaDto[],
  locale: string,
): ResolvedNewsBodyBlock[] {
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
  body: ResolvedNewsBodyBlock[];
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
        galleryUnavailable: t('galleryUnavailable'),
        unknownBlock: t('unknownBlock'),
      }}
      showUnknownBlockWarning
      renderGallery={({ items, className }) => (
        <NewsGalleryPreviewCarousel items={items} className={className} />
      )}
      renderImage={({ src, alt, className, fill, loading, unoptimized }) => (
        <div className={[styles.fillImageWrap, className].filter(Boolean).join(' ')}>
          <Image
            src={src}
            alt={alt}
            {...(fill !== undefined ? { fill } : {})}
            className={isSvgMediaUrl(src) ? 'object-contain' : 'object-cover'}
            sizes="(min-width: 768px) 768px, 100vw"
            {...(loading ? { loading } : {})}
            {...(unoptimized !== undefined ? { unoptimized } : { unoptimized: true })}
          />
        </div>
      )}
    />
  );
}
