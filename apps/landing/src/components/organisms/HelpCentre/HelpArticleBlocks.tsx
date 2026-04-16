import { Link } from "@/i18n/routing";
import { cn } from "@/lib/utils/cn";
import type { HelpContentBlock } from "@/lib/help/help-messages-schema";
import { Lightbulb, Info } from "lucide-react";

export function HelpArticleBlocks({
  blocks,
  calloutTipLabel,
  calloutNoteLabel,
}: {
  blocks: readonly HelpContentBlock[];
  calloutTipLabel: string;
  calloutNoteLabel: string;
}) {
  return (
    <div className="mt-5 space-y-6 text-[0.9375rem] leading-relaxed text-gray-700 md:mt-6 md:text-base md:leading-[1.65]">
      {blocks.map((block, i) => {
        const key = `${block.type}-${i}`;
        switch (block.type) {
          case "paragraph":
            return (
              <div key={key} className="space-y-3.5">
                {block.text
                  .split(/\n\n+/)
                  .map((chunk) => chunk.trim())
                  .filter(Boolean)
                  .map((chunk, j) => (
                    <p key={j} className="text-pretty text-gray-700">
                      {chunk}
                    </p>
                  ))}
              </div>
            );
          case "bullets":
            return (
              <div key={key} className="rounded-2xl border border-gray-200/80 bg-gray-50/60 px-4 py-4 md:px-5 md:py-5">
                {block.title ? (
                  <p className="mb-3 text-xs font-semibold uppercase tracking-[0.12em] text-gray-500">{block.title}</p>
                ) : null}
                <ul className="list-none space-y-2.5 pl-0">
                  {block.items.map((item, j) => (
                    <li key={j} className="flex gap-3 text-pretty text-gray-800">
                      <span
                        className="mt-2 h-1.5 w-1.5 shrink-0 rounded-full bg-primary/80"
                        aria-hidden
                      />
                      <span>{item}</span>
                    </li>
                  ))}
                </ul>
              </div>
            );
          case "callout": {
            const isTip = block.variant === "tip";
            return (
              <aside
                key={key}
                role="note"
                aria-label={isTip ? calloutTipLabel : calloutNoteLabel}
                className={cn(
                  "rounded-2xl border p-4 shadow-sm md:p-5",
                  isTip
                    ? "border-primary/25 bg-gradient-to-br from-primary/[0.06] to-emerald-500/[0.04]"
                    : "border-sky-200/80 bg-sky-50/80",
                )}
              >
                <div className="flex gap-3">
                  <div
                    className={cn(
                      "flex h-9 w-9 shrink-0 items-center justify-center rounded-xl",
                      isTip ? "bg-primary/15 text-primary" : "bg-sky-100 text-sky-800",
                    )}
                    aria-hidden
                  >
                    {isTip ? <Lightbulb className="h-4 w-4" strokeWidth={2} /> : <Info className="h-4 w-4" strokeWidth={2} />}
                  </div>
                  <p className="min-w-0 text-pretty text-[0.9375rem] leading-relaxed text-gray-800 md:text-base">
                    {block.text}
                  </p>
                </div>
              </aside>
            );
          }
          case "internalLink":
            return (
              <p key={key}>
                <Link
                  href={block.href}
                  className="font-semibold text-primary underline decoration-primary/35 underline-offset-2 transition-colors hover:decoration-primary/70 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2"
                >
                  {block.label}
                </Link>
              </p>
            );
          default: {
            const _exhaustive: never = block;
            return _exhaustive;
          }
        }
      })}
    </div>
  );
}
