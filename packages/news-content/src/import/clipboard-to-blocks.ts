import type { NewsBodyBlock } from '../types';
import { htmlToNewsBlocks, looksLikeStructuredHtml } from './html-to-blocks';
import { looksLikeMarkdown, markdownToNewsBlocks } from './markdown-to-blocks';
import {
  paragraphBlocksFromPlainText,
  splitHtmlIntoParagraphBlocks,
} from './paragraph-from-html';
import { stripPasteMetadata } from './strip-paste-metadata';

export const DEFAULT_MAX_IMPORT_BLOCKS = 50;

export type ClipboardImportOptions = {
  maxBlocks?: number;
  stripEditorMetadata?: boolean;
};

export type ClipboardImportResult = {
  blocks: NewsBodyBlock[];
  truncated: boolean;
  source: 'markdown' | 'html' | 'plain';
};

export type ClipboardImportSummary = {
  quote: number;
  heading: number;
  paragraph: number;
  list: number;
  divider: number;
  other: number;
  total: number;
};

function truncateBlocks(blocks: NewsBodyBlock[], maxBlocks: number): { blocks: NewsBodyBlock[]; truncated: boolean } {
  if (blocks.length <= maxBlocks) return { blocks, truncated: false };
  return { blocks: blocks.slice(0, maxBlocks), truncated: true };
}

function isTrivialHtml(html: string): boolean {
  const trimmed = html.trim();
  if (!trimmed) return true;
  return !looksLikeStructuredHtml(trimmed) && !/<p\b/i.test(trimmed);
}

/**
 * Converts clipboard HTML/plain into structured news body blocks.
 * Falls back to legacy paragraph splitting when structure is not detected.
 */
export function clipboardToNewsBlocks(
  input: { html?: string; plain?: string },
  options?: ClipboardImportOptions,
): ClipboardImportResult | null {
  const maxBlocks = options?.maxBlocks ?? DEFAULT_MAX_IMPORT_BLOCKS;
  const stripMetadata = options?.stripEditorMetadata ?? true;

  const rawPlain = input.plain?.trim() ?? '';
  const rawHtml = input.html?.trim() ?? '';
  if (!rawPlain && !rawHtml) return null;

  let plain = rawPlain;
  if (stripMetadata && plain) {
    plain = stripPasteMetadata(plain);
  }

  let blocks: NewsBodyBlock[] = [];
  let source: ClipboardImportResult['source'] = 'plain';

  const preferMarkdown =
    plain &&
    looksLikeMarkdown(plain) &&
    (!rawHtml || isTrivialHtml(rawHtml));

  if (preferMarkdown) {
    blocks = markdownToNewsBlocks(plain);
    source = 'markdown';
  } else if (rawHtml && !isTrivialHtml(rawHtml)) {
    blocks = htmlToNewsBlocks(rawHtml);
    source = 'html';
  } else if (rawHtml) {
    blocks = splitHtmlIntoParagraphBlocks(rawHtml);
    source = 'html';
  }

  if (blocks.length <= 1 && plain.includes('\n')) {
    const markdownBlocks = looksLikeMarkdown(plain) ? markdownToNewsBlocks(plain) : [];
    if (markdownBlocks.length > blocks.length) {
      blocks = markdownBlocks;
      source = 'markdown';
    } else {
      const plainBlocks = paragraphBlocksFromPlainText(plain);
      if (plainBlocks.length > blocks.length) {
        blocks = plainBlocks;
        source = 'plain';
      }
    }
  }

  if (blocks.length === 0 && plain) {
    blocks = [{ type: 'paragraph', text: plain }];
    source = 'plain';
  }

  if (blocks.length === 0) return null;

  const { blocks: capped, truncated } = truncateBlocks(blocks, maxBlocks);
  return { blocks: capped, truncated, source };
}

export function summarizeImportedBlocks(blocks: NewsBodyBlock[]): ClipboardImportSummary {
  const summary: ClipboardImportSummary = {
    quote: 0,
    heading: 0,
    paragraph: 0,
    list: 0,
    divider: 0,
    other: 0,
    total: blocks.length,
  };

  for (const block of blocks) {
    if (block.type === 'quote') summary.quote += 1;
    else if (block.type === 'heading') summary.heading += 1;
    else if (block.type === 'paragraph') summary.paragraph += 1;
    else if (block.type === 'list') summary.list += 1;
    else if (block.type === 'divider') summary.divider += 1;
    else summary.other += 1;
  }

  return summary;
}

export function isParagraphBlockEmpty(block: NewsBodyBlock): boolean {
  if (block.type !== 'paragraph') return false;
  return !block.text?.trim() && !block.html?.trim();
}

/** True when the body is empty or a single blank paragraph block. */
export function isBodyEmptyOrSkeleton(blocks: NewsBodyBlock[]): boolean {
  if (blocks.length === 0) return true;
  if (blocks.length === 1) return isParagraphBlockEmpty(blocks[0]!);
  return false;
}
