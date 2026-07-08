import { sanitizeInlineHtml } from '../sanitize/html-sanitize';
import { createBlockId, type NewsBodyBlock } from '../types';
import {
  hasMarkdownLink,
  inlineMarkdownToHtml,
  listItemHasInlineMarkup,
  stripInlineMarkdown,
} from './inline-markdown';
import { paragraphFromHtml } from './paragraph-from-html';

type BlockDraft = NewsBodyBlock;

const HEADING2 = /^##\s+(.+)$/;
const HEADING3 = /^###\s+(.+)$/;
const QUOTE = /^>\s?(.*)$/;
const DIVIDER = /^---+$/;
const ORDERED_ITEM = /^\d+\.\s+(.+)$/;
const BULLET_ITEM = /^[-*]\s+(.+)$/;

function flushParagraph(lines: string[], blocks: BlockDraft[]) {
  const joined = lines.join(' ').trim();
  if (!joined) return;
  const html = inlineMarkdownToHtml(joined);
  const safe = sanitizeInlineHtml(`<p>${html}</p>`);
  blocks.push(paragraphFromHtml(safe));
  lines.length = 0;
}

function flushOrderedList(items: string[], blocks: BlockDraft[]) {
  if (items.length === 0) return;
  const hasMarkup = items.some((item) => listItemHasInlineMarkup(item));
  if (hasMarkup) {
    const lis = items
      .map((item) => `<li>${inlineMarkdownToHtml(item)}</li>`)
      .join('');
    blocks.push(paragraphFromHtml(sanitizeInlineHtml(`<ol>${lis}</ol>`)));
  } else {
    blocks.push({
      id: createBlockId(),
      type: 'list',
      ordered: true,
      items: items.map((item) => stripInlineMarkdown(item)),
    });
  }
  items.length = 0;
}

function flushBulletList(items: string[], blocks: BlockDraft[]) {
  if (items.length === 0) return;
  const hasMarkup = items.some((item) => listItemHasInlineMarkup(item));
  if (hasMarkup) {
    const lis = items
      .map((item) => `<li>${inlineMarkdownToHtml(item)}</li>`)
      .join('');
    blocks.push(paragraphFromHtml(sanitizeInlineHtml(`<ul>${lis}</ul>`)));
  } else {
    blocks.push({
      id: createBlockId(),
      type: 'list',
      ordered: false,
      items: items.map((item) => stripInlineMarkdown(item)),
    });
  }
  items.length = 0;
}

/** Parses a markdown subset into native news body blocks. */
export function markdownToNewsBlocks(markdown: string): NewsBodyBlock[] {
  const lines = markdown.replace(/\r\n/g, '\n').split('\n');
  const blocks: BlockDraft[] = [];
  const paragraphLines: string[] = [];
  const orderedItems: string[] = [];
  const bulletItems: string[] = [];
  let quoteLines: string[] = [];

  const flushQuote = () => {
    if (quoteLines.length === 0) return;
    const text = stripInlineMarkdown(quoteLines.join(' ').trim());
    if (text) {
      blocks.push({ id: createBlockId(), type: 'quote', text });
    }
    quoteLines = [];
  };

  const flushListsAndParagraph = () => {
    flushParagraph(paragraphLines, blocks);
    flushOrderedList(orderedItems, blocks);
    flushBulletList(bulletItems, blocks);
  };

  for (const line of lines) {
    const trimmed = line.trim();

    if (!trimmed) {
      flushQuote();
      flushListsAndParagraph();
      continue;
    }

    if (DIVIDER.test(trimmed)) {
      flushQuote();
      flushListsAndParagraph();
      const last = blocks[blocks.length - 1];
      if (last?.type !== 'divider') {
        blocks.push({ id: createBlockId(), type: 'divider' });
      }
      continue;
    }

    const h3 = trimmed.match(HEADING3);
    if (h3) {
      flushQuote();
      flushListsAndParagraph();
      blocks.push({
        id: createBlockId(),
        type: 'heading',
        level: 3,
        text: stripInlineMarkdown(h3[1] ?? ''),
      });
      continue;
    }

    const h2 = trimmed.match(HEADING2);
    if (h2) {
      flushQuote();
      flushListsAndParagraph();
      blocks.push({
        id: createBlockId(),
        type: 'heading',
        level: 2,
        text: stripInlineMarkdown(h2[1] ?? ''),
      });
      continue;
    }

    const quote = trimmed.match(QUOTE);
    if (quote) {
      flushListsAndParagraph();
      quoteLines.push(quote[1] ?? '');
      continue;
    }

    if (quoteLines.length > 0) {
      flushQuote();
    }

    const ordered = trimmed.match(ORDERED_ITEM);
    if (ordered) {
      flushParagraph(paragraphLines, blocks);
      flushBulletList(bulletItems, blocks);
      orderedItems.push(ordered[1] ?? '');
      continue;
    }

    const bullet = trimmed.match(BULLET_ITEM);
    if (bullet) {
      flushParagraph(paragraphLines, blocks);
      flushOrderedList(orderedItems, blocks);
      bulletItems.push(bullet[1] ?? '');
      continue;
    }

    flushOrderedList(orderedItems, blocks);
    flushBulletList(bulletItems, blocks);
    paragraphLines.push(trimmed);
  }

  flushQuote();
  flushListsAndParagraph();

  return blocks.filter((block) => {
    if (block.type === 'paragraph') return block.text.trim() || block.html?.trim();
    if (block.type === 'heading') return block.text.trim();
    if (block.type === 'quote') return block.text.trim();
    if (block.type === 'list') return block.items.some((item) => item.trim());
    return true;
  });
}

export function looksLikeMarkdown(text: string): boolean {
  return (
    /^#{2,3}\s+/m.test(text) ||
    /^>\s/m.test(text) ||
    /^---+$/m.test(text) ||
    /^\d+\.\s+/m.test(text) ||
    /^[-*]\s+/m.test(text) ||
    hasMarkdownLink(text)
  );
}
