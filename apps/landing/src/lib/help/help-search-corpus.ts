import type { HelpContentBlock } from "./help-messages-schema";

/** Extract plain text from help blocks for hub search indexing. */
export function helpBlocksToSearchText(blocks: readonly HelpContentBlock[]): string {
  const parts: string[] = [];
  for (const block of blocks) {
    switch (block.type) {
      case "paragraph":
        parts.push(block.text);
        break;
      case "bullets":
        if (block.title) parts.push(block.title);
        parts.push(...block.items);
        break;
      case "callout":
        parts.push(block.text);
        break;
      case "internalLink":
        parts.push(block.label);
        break;
      case "steps":
        if (block.title) parts.push(block.title);
        for (const step of block.items) {
          parts.push(step.title, step.text);
        }
        break;
      default: {
        const _exhaustive: never = block;
        return _exhaustive;
      }
    }
  }
  return parts.join(" ");
}

export function helpSectionsToSearchText(
  sections: readonly { title: string; blocks: readonly HelpContentBlock[] }[],
): string {
  return sections.map((s) => `${s.title} ${helpBlocksToSearchText(s.blocks)}`).join(" ");
}
