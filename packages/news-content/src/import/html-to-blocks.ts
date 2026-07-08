import { parse, type HTMLElement, type Node as HtmlNode } from 'node-html-parser';
import { normalizeInlineLinksInHtml, sanitizeImportHtml, stripHtmlToPlainText } from '../sanitize/html-sanitize';
import { createBlockId, type NewsBodyBlock } from '../types';
import { paragraphFromHtml } from './paragraph-from-html';

function nodeText(node: HtmlNode): string {
  return stripHtmlToPlainText(node.toString()).trim();
}

function listItemsHaveMarkup(listEl: HTMLElement): boolean {
  return listEl.querySelectorAll('a, strong, em, u').length > 0;
}

function listFromElement(listEl: HTMLElement, ordered: boolean): NewsBodyBlock {
  const items = listEl.querySelectorAll(':scope > li').map((li) => nodeText(li)).filter(Boolean);
  if (items.length === 0) {
    return { id: createBlockId(), type: 'paragraph', text: '' };
  }
  if (listItemsHaveMarkup(listEl)) {
    const tag = ordered ? 'ol' : 'ul';
    const inner = listEl.querySelectorAll(':scope > li')
      .map((li) => `<li>${normalizeInlineLinksInHtml(li.innerHTML)}</li>`)
      .join('');
    return paragraphFromHtml(normalizeInlineLinksInHtml(`<${tag}>${inner}</${tag}>`));
  }
  return { id: createBlockId(), type: 'list', ordered, items };
}

function paragraphFromNode(node: HtmlNode): NewsBodyBlock | null {
  const html = normalizeInlineLinksInHtml(node.toString());
  const block = paragraphFromHtml(html);
  return block.text.trim() || block.html?.trim() ? block : null;
}

function mapElement(el: HTMLElement): NewsBodyBlock[] {
  const tag = el.tagName?.toLowerCase();
  if (!tag) return [];

  if (tag === 'h2') {
    const text = nodeText(el);
    return text ? [{ id: createBlockId(), type: 'heading', level: 2, text }] : [];
  }
  if (tag === 'h3') {
    const text = nodeText(el);
    return text ? [{ id: createBlockId(), type: 'heading', level: 3, text }] : [];
  }
  if (tag === 'blockquote') {
    const text = nodeText(el);
    return text ? [{ id: createBlockId(), type: 'quote', text }] : [];
  }
  if (tag === 'hr') {
    return [{ id: createBlockId(), type: 'divider' }];
  }
  if (tag === 'ul') {
    const block = listFromElement(el, false);
    return block.type === 'paragraph' && !block.text && !block.html ? [] : [block];
  }
  if (tag === 'ol') {
    const block = listFromElement(el, true);
    return block.type === 'paragraph' && !block.text && !block.html ? [] : [block];
  }
  if (tag === 'p') {
    const block = paragraphFromNode(el);
    return block ? [block] : [];
  }
  if (tag === 'div') {
    const children = el.childNodes.filter((n) => n.nodeType === 1) as HTMLElement[];
    if (children.length === 1 && children[0]) {
      return mapElement(children[0]);
    }
    return children.flatMap((child) => mapElement(child));
  }

  const block = paragraphFromNode(el);
  return block ? [block] : [];
}

/** Maps sanitized import HTML into native news body blocks. */
export function htmlToNewsBlocks(html: string): NewsBodyBlock[] {
  const safe = sanitizeImportHtml(html);
  if (!safe) return [];

  const root = parse(`<div>${safe}</div>`);
  const container = root.querySelector('div');
  if (!container) return [];

  const blocks: NewsBodyBlock[] = [];
  for (const child of container.childNodes) {
    if (child.nodeType !== 1) {
      const text = child.text?.trim();
      if (text) {
        blocks.push(paragraphFromHtml(`<p>${normalizeInlineLinksInHtml(text)}</p>`));
      }
      continue;
    }
    blocks.push(...mapElement(child as HTMLElement));
  }

  const collapsed: NewsBodyBlock[] = [];
  for (const block of blocks) {
    const prev = collapsed[collapsed.length - 1];
    if (block.type === 'divider' && prev?.type === 'divider') continue;
    collapsed.push(block);
  }

  return collapsed.filter((block) => {
    if (block.type === 'paragraph') return block.text.trim() || block.html?.trim();
    if (block.type === 'heading') return block.text.trim();
    if (block.type === 'quote') return block.text.trim();
    if (block.type === 'list') return block.items.some((item) => item.trim());
    return true;
  });
}

export function looksLikeStructuredHtml(html: string): boolean {
  return /<(h2|h3|blockquote|hr|ul|ol)\b/i.test(html);
}
