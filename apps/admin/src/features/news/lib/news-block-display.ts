import type { NewsBodyBlock } from '../news-api-types';

export function blockTypeLabel(
  block: NewsBodyBlock,
  t: (key: string) => string,
): string {
  switch (block.type) {
    case 'paragraph':
      return t('form.blockParagraph');
    case 'html':
      return t('form.blockHtml');
    case 'heading':
      return block.level === 3 ? t('form.blockHeading3') : t('form.blockHeading2');
    case 'list':
      return block.ordered ? t('form.blockOrderedList') : t('form.blockBulletList');
    case 'image':
      return t('form.blockImage');
    case 'video':
      return t('form.blockVideo');
    case 'gallery':
      return t('form.blockGallery');
    default:
      return t('form.blockParagraph');
  }
}

function stripHtml(value: string): string {
  return value.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();
}

export function blockPreviewText(block: NewsBodyBlock): string {
  switch (block.type) {
    case 'paragraph': {
      const raw = block.html?.trim() ? stripHtml(block.html) : block.text.trim();
      return raw.slice(0, 140);
    }
    case 'heading':
      return block.text.trim().slice(0, 140);
    case 'list':
      return block.items
        .map((item) => item.trim())
        .filter(Boolean)
        .join(' · ')
        .slice(0, 140);
    case 'image':
    case 'video':
      return (block.caption ?? '').trim();
    case 'gallery':
      return '';
    case 'html':
      return stripHtml(block.html).slice(0, 140);
    default:
      return '';
  }
}

export function blockGalleryItemCount(block: NewsBodyBlock): number {
  return block.type === 'gallery' ? block.items.length : 0;
}

export function blockAttachedMedia(
  block: NewsBodyBlock,
  media: { id: string; url: string | null; fileName: string | null }[],
): { id: string; url: string | null; fileName: string | null } | undefined {
  if (block.type === 'image' || block.type === 'video') {
    return media.find((item) => item.id === block.mediaId);
  }
  return undefined;
}

export function blockGalleryMedia(
  block: NewsBodyBlock,
  media: { id: string; url: string | null }[],
): { id: string; url: string | null }[] {
  if (block.type !== 'gallery') return [];
  return block.items
    .map((item) => media.find((m) => m.id === item.mediaId))
    .filter((item): item is { id: string; url: string | null } => Boolean(item));
}
