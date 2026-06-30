import type { IconName } from '@/components/ui';
import type { NewsBodyBlock } from '../news-api-types';
import {
  createGalleryBlock,
  createHeadingBlock,
  createHtmlBlock,
  createImageBlock,
  createListBlock,
  createParagraphBlock,
  createVideoBlock,
} from './news-block-factory';

export type BlockInsertType =
  | 'paragraph'
  | 'heading'
  | 'list'
  | 'image'
  | 'gallery'
  | 'video'
  | 'html';

export type MediaInsertAction = 'cover' | 'inline_image' | 'inline_video';

export type InsertIconTone = 'text' | 'media' | 'advanced';

export type BlockInsertOption = {
  type: BlockInsertType;
  icon: IconName;
  tone: InsertIconTone;
  labelKey: `form.${string}`;
  descriptionKey: `insert.${string}`;
};

export type MediaInsertOption = {
  action: MediaInsertAction;
  icon: IconName;
  tone: InsertIconTone;
  labelKey: `form.${string}`;
  descriptionKey: `insert.${string}`;
  guidanceKind?: 'cover' | 'inlineImage' | 'video';
};

export const BLOCK_INSERT_OPTIONS: BlockInsertOption[] = [
  {
    type: 'paragraph',
    icon: 'document-text',
    tone: 'text',
    labelKey: 'form.addParagraph',
    descriptionKey: 'insert.paragraph',
  },
  {
    type: 'heading',
    icon: 'heading',
    tone: 'text',
    labelKey: 'form.addHeading',
    descriptionKey: 'insert.heading',
  },
  {
    type: 'list',
    icon: 'list',
    tone: 'text',
    labelKey: 'form.addList',
    descriptionKey: 'insert.list',
  },
  {
    type: 'gallery',
    icon: 'gallery',
    tone: 'media',
    labelKey: 'form.addGalleryBlock',
    descriptionKey: 'insert.gallery',
  },
  {
    type: 'image',
    icon: 'image',
    tone: 'media',
    labelKey: 'form.addImageBlock',
    descriptionKey: 'insert.imageBlock',
  },
  {
    type: 'video',
    icon: 'video',
    tone: 'media',
    labelKey: 'form.addVideoBlock',
    descriptionKey: 'insert.videoBlock',
  },
  {
    type: 'html',
    icon: 'code',
    tone: 'advanced',
    labelKey: 'form.addHtmlBlock',
    descriptionKey: 'insert.html',
  },
];

export const MEDIA_INSERT_OPTIONS: MediaInsertOption[] = [
  {
    action: 'cover',
    icon: 'image',
    tone: 'media',
    labelKey: 'form.uploadCover',
    descriptionKey: 'insert.cover',
    guidanceKind: 'cover',
  },
  {
    action: 'inline_image',
    icon: 'image',
    tone: 'media',
    labelKey: 'form.addImageBlock',
    descriptionKey: 'insert.image',
    guidanceKind: 'inlineImage',
  },
  {
    action: 'inline_video',
    icon: 'video',
    tone: 'media',
    labelKey: 'form.addVideoBlock',
    descriptionKey: 'insert.video',
    guidanceKind: 'video',
  },
];

/** Quick-start options shown when the document body is empty. */
export const EMPTY_BODY_QUICK_INSERT: BlockInsertType[] = [
  'paragraph',
  'heading',
  'image',
  'gallery',
];

export function createBlockFromType(type: BlockInsertType): NewsBodyBlock {
  switch (type) {
    case 'paragraph':
      return createParagraphBlock();
    case 'heading':
      return createHeadingBlock();
    case 'list':
      return createListBlock();
    case 'image':
      return createImageBlock();
    case 'gallery':
      return createGalleryBlock();
    case 'video':
      return createVideoBlock();
    case 'html':
      return createHtmlBlock();
  }
}

export function blockOptionByType(type: BlockInsertType): BlockInsertOption {
  const found = BLOCK_INSERT_OPTIONS.find((option) => option.type === type);
  if (!found) {
    return BLOCK_INSERT_OPTIONS[0];
  }
  return found;
}

/** Content blocks shown in the toolbar insert menu (media uploads are separate). */
export const TOOLBAR_BLOCK_INSERT_OPTIONS = BLOCK_INSERT_OPTIONS.filter(
  (option) => option.type !== 'image' && option.type !== 'video',
);
