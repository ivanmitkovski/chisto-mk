import type { NewsBodyBlock } from './types';
import { stripHtmlToPlainText } from './sanitize/html-sanitize';

export function paragraphPlainText(block: { text: string; html?: string }): string {
  if (block.html?.trim()) {
    return stripHtmlToPlainText(block.html);
  }
  return block.text.trim();
}

export function plainTextFromBlocks(blocks: NewsBodyBlock[]): string {
  const parts: string[] = [];
  for (const block of blocks) {
    switch (block.type) {
      case 'paragraph':
        parts.push(paragraphPlainText(block));
        break;
      case 'html':
        parts.push(stripHtmlToPlainText(block.html));
        break;
      case 'heading':
        parts.push(block.text.trim());
        break;
      case 'list':
        parts.push(...block.items.map((item) => item.trim()).filter(Boolean));
        break;
      case 'image':
      case 'video':
        if (block.caption?.trim()) parts.push(block.caption.trim());
        break;
      case 'gallery':
        for (const item of block.items) {
          if (item.caption?.trim()) parts.push(item.caption.trim());
        }
        break;
      case 'quote':
        parts.push(block.text.trim());
        if (block.attribution?.trim()) parts.push(block.attribution.trim());
        break;
      case 'embed':
        break;
      case 'divider':
        break;
      default:
        break;
    }
  }
  return parts.filter(Boolean).join(' ');
}

export function wordCountFromBlocks(blocks: NewsBodyBlock[]): number {
  const text = plainTextFromBlocks(blocks);
  if (!text) return 0;
  return text.split(/\s+/).filter(Boolean).length;
}
