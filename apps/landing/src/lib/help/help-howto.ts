import type { HelpContentBlock } from "@/lib/help/help-messages-schema";

const MAX_HOWTO_STEPS = 12;

/**
 * Flattens bullet list items from article sections into ordered HowTo steps (Schema.org).
 */
export function helpHowToStepsFromBlocks(sections: readonly { blocks: readonly HelpContentBlock[] }[]): string[] {
  const out: string[] = [];
  for (const section of sections) {
    for (const block of section.blocks) {
      if (block.type === "bullets") {
        for (const item of block.items) {
          if (out.length >= MAX_HOWTO_STEPS) return out;
          out.push(item);
        }
      }
    }
  }
  return out;
}
