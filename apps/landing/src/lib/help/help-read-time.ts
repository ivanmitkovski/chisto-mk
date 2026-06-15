import type { HelpContentBlock } from "@/lib/help/help-messages-schema";

/** Typical silent reading speed for short civic help copy (English baseline). */
const WORDS_PER_MINUTE = 200;

function countWordsInText(text: string): number {
  const trimmed = text.trim();
  if (trimmed.length === 0) return 0;
  return trimmed.split(/\s+/).filter(Boolean).length;
}

function countWordsInBlock(block: HelpContentBlock): number {
  switch (block.type) {
    case "paragraph":
      return countWordsInText(block.text);
    case "callout":
      return countWordsInText(block.text);
    case "internalLink":
      return countWordsInText(block.label);
    case "bullets": {
      const titleWords = block.title != null ? countWordsInText(block.title) : 0;
      const itemWords = block.items.reduce((sum, item) => sum + countWordsInText(item), 0);
      return titleWords + itemWords;
    }
  }
}

export type SectionForReadTime = {
  title: string;
  blocks: readonly HelpContentBlock[];
};

/**
 * Estimated reading time from section titles and body blocks (paragraphs,
 * bullets, callouts, internal link labels). At least 1 minute.
 */
export function estimateReadMinutesFromSections(sections: readonly SectionForReadTime[]): number {
  let words = 0;
  for (const section of sections) {
    words += countWordsInText(section.title);
    for (const block of section.blocks) {
      words += countWordsInBlock(block);
    }
  }
  return Math.max(1, Math.ceil(words / WORDS_PER_MINUTE));
}
