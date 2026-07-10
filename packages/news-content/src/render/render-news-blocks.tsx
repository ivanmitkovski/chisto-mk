import type { ReactNode } from 'react';
import type { EnrichedGalleryBlock, EnrichedGalleryItem, ResolvedNewsBodyBlock } from '../types';
import { buildEmbedIframeHtml } from '../sanitize/embed-allowlist';
import { sanitizeHtmlBlock, sanitizeInlineHtml } from '../sanitize/html-sanitize';
import { collectHeadingAnchors } from './heading-toc';
import './external-link-indicator.css';
import styles from './render-news-blocks.module.css';

export type RenderNewsBlocksLabels = {
  imageUnavailable: string;
  videoUnavailable: string;
  unknownBlock?: string;
  galleryUnavailable?: string;
};

export type GalleryRenderItem = {
  id: string;
  src: string;
  alt: string;
  caption?: string;
};

export type RenderNewsBlocksOptions = {
  blocks: ResolvedNewsBodyBlock[];
  labels: RenderNewsBlocksLabels;
  className?: string;
  showUnknownBlockWarning?: boolean;
  warnUnknownBlocks?: boolean;
  renderImage?: (props: {
    src: string;
    alt: string;
    className?: string;
    fill?: boolean;
    loading?: 'lazy' | 'eager';
    unoptimized?: boolean;
  }) => ReactNode;
  renderGallery?: (props: {
    block: EnrichedGalleryBlock;
    items: GalleryRenderItem[];
    labels: RenderNewsBlocksLabels;
    className?: string;
  }) => ReactNode;
};

function defaultRenderImage(props: {
  src: string;
  alt: string;
  className?: string;
}): ReactNode {
  return (
    // eslint-disable-next-line @next/next/no-img-element
    <img src={props.src} alt={props.alt} className={props.className} loading="lazy" />
  );
}

function defaultRenderGallery({
  items,
  labels,
  className,
  renderImage,
}: {
  items: GalleryRenderItem[];
  labels: RenderNewsBlocksLabels;
  className?: string;
  renderImage: NonNullable<RenderNewsBlocksOptions['renderImage']>;
}): ReactNode {
  if (items.length === 0) {
    return (
      <div className={styles.mediaPlaceholder} role="img" aria-label={labels.galleryUnavailable ?? labels.imageUnavailable}>
        {labels.galleryUnavailable ?? labels.imageUnavailable}
      </div>
    );
  }

  return (
    <figure className={[styles.gallery, className].filter(Boolean).join(' ')}>
      <div className={styles.galleryTrack} role="list">
        {items.map((item, index) => (
          <div key={`${item.id}-${index}`} className={styles.gallerySlide} role="listitem">
            <div className={styles.galleryFrame}>
              {renderImage({
                src: item.src,
                alt: item.alt,
                fill: true,
                loading: 'lazy',
                unoptimized: true,
              })}
            </div>
            {item.caption ? <figcaption className={styles.caption}>{item.caption}</figcaption> : null}
          </div>
        ))}
      </div>
    </figure>
  );
}

export function RenderNewsBlocks({
  blocks,
  labels,
  className,
  showUnknownBlockWarning = false,
  warnUnknownBlocks = process.env.NODE_ENV === 'development',
  renderImage = defaultRenderImage,
  renderGallery,
}: RenderNewsBlocksOptions) {
  const headingIdByIndex = new Map(
    collectHeadingAnchors(blocks).map((anchor) => [anchor.blockIndex, anchor.id] as const),
  );

  return (
    <div className={[styles.proseNews, 'news-prose', className].filter(Boolean).join(' ')}>
      {blocks.map((block, i) => {
        const key = block.id ?? `${block.type}-${i}`;

        if (block.type === 'paragraph') {
          const html = block.html?.trim();
          if (html) {
            const safe = sanitizeInlineHtml(html);
            return (
              <div
                key={key}
                className={`${styles.paragraph} ${styles.paragraphRich}`}
                dangerouslySetInnerHTML={{ __html: safe }}
              />
            );
          }
          return (
            <p key={key} className={styles.paragraph}>
              {block.text}
            </p>
          );
        }

        if (block.type === 'html') {
          const safe = sanitizeHtmlBlock(block.html);
          if (!safe) return null;
          return (
            <div
              key={key}
              className={`${styles.htmlBlock} prose-news-html`}
              dangerouslySetInnerHTML={{ __html: safe }}
            />
          );
        }

        if (block.type === 'heading') {
          const text = block.text.trim();
          if (!text) return null;
          const headingId = headingIdByIndex.get(i);
          if (block.level === 3) {
            return (
              <h3 key={key} id={headingId} className={styles.heading3}>
                {text}
              </h3>
            );
          }
          return (
            <h2 key={key} id={headingId} className={styles.heading2}>
              {text}
            </h2>
          );
        }

        if (block.type === 'list') {
          const items = block.items.filter((item) => item.trim());
          if (items.length === 0) return null;
          const Tag = block.ordered ? 'ol' : 'ul';
          return (
            <Tag key={key} className={styles.list}>
              {items.map((item, itemIndex) => (
                <li key={`${key}-item-${itemIndex}`}>{item}</li>
              ))}
            </Tag>
          );
        }

        if (block.type === 'image') {
          if (!block.url) {
            return (
              <figure key={key} className={styles.mediaFigure}>
                <div className={styles.mediaPlaceholder} role="img" aria-label={labels.imageUnavailable}>
                  {labels.imageUnavailable}
                </div>
              </figure>
            );
          }
          const alt = block.altText ?? block.caption ?? '';
          return (
            <figure key={key} className={styles.mediaFigure}>
              <div className={styles.mediaFrame}>
                {renderImage({
                  src: block.url,
                  alt,
                  fill: true,
                  loading: 'lazy',
                  unoptimized: true,
                })}
              </div>
              {block.caption ? <figcaption className={styles.caption}>{block.caption}</figcaption> : null}
            </figure>
          );
        }

        if (block.type === 'video') {
          if (!block.url) {
            return (
              <div key={key} className={styles.mediaPlaceholder} role="img" aria-label={labels.videoUnavailable}>
                {labels.videoUnavailable}
              </div>
            );
          }
          const videoLabel = block.caption?.trim() || labels.videoUnavailable;
          return (
            <figure key={key} className={styles.mediaFigure}>
              <video
                src={block.url}
                controls
                preload="metadata"
                className={styles.video}
                aria-label={videoLabel}
              />
              {block.caption ? <figcaption className={styles.caption}>{block.caption}</figcaption> : null}
            </figure>
          );
        }

        if (block.type === 'gallery') {
          const enriched = block as EnrichedGalleryBlock;
          const galleryItems: GalleryRenderItem[] = enriched.items
            .map((item, index) => {
              const resolved = item as EnrichedGalleryItem;
              if (!resolved.url) return null;
              return {
                id: `${key}-item-${index}`,
                src: resolved.url,
                alt: resolved.altText ?? resolved.caption ?? '',
                ...(resolved.caption ? { caption: resolved.caption } : {}),
              };
            })
            .filter((item): item is GalleryRenderItem => item !== null);

          if (renderGallery) {
            return (
              <div key={key}>
                {renderGallery({ block, items: galleryItems, labels, className: styles.gallery })}
              </div>
            );
          }

          return (
            <div key={key}>
              {defaultRenderGallery({ items: galleryItems, labels, className: styles.gallery, renderImage })}
            </div>
          );
        }

        if (block.type === 'quote') {
          const text = block.text.trim();
          if (!text) return null;
          return (
            <blockquote key={key} className={styles.quote}>
              <p>{text}</p>
              {block.attribution?.trim() ? (
                <cite className={styles.quoteAttribution}>{block.attribution.trim()}</cite>
              ) : null}
            </blockquote>
          );
        }

        if (block.type === 'divider') {
          return <hr key={key} className={styles.divider} aria-hidden />;
        }

        if (block.type === 'embed') {
          const embedUrl = block.url?.trim();
          if (!embedUrl) return null;
          const html = buildEmbedIframeHtml(embedUrl);
          return (
            <div
              key={key}
              className={styles.embedBlock}
              dangerouslySetInnerHTML={{ __html: html }}
            />
          );
        }

        if (warnUnknownBlocks) {
          console.warn('[RenderNewsBlocks] Unknown block type dropped:', (block as { type?: string }).type);
        }

        if (showUnknownBlockWarning && labels.unknownBlock) {
          return (
            <div key={key} className={styles.unknownBlock} role="note">
              {labels.unknownBlock}
            </div>
          );
        }

        return null;
      })}
    </div>
  );
}

export function resolvePreviewBlocks(
  blocks: ResolvedNewsBodyBlock[],
  mediaById: Map<string, { url: string | null; altText?: string | null }>,
): ResolvedNewsBodyBlock[] {
  return blocks.map((block) => {
    if (block.type === 'gallery') {
      return {
        ...block,
        items: block.items.map((item) => {
          const media = mediaById.get(item.mediaId);
          return {
            ...item,
            url: media?.url ?? null,
            altText: media?.altText ?? null,
          };
        }),
      };
    }
    if (block.type !== 'image' && block.type !== 'video') return block;
    const item = mediaById.get(block.mediaId);
    return {
      ...block,
      url: item?.url ?? block.url ?? null,
      altText: item?.altText ?? block.altText ?? null,
    };
  });
}
