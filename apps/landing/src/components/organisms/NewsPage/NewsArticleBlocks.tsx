import Image from "next/image";
import type { ResolvedNewsBodyBlock } from "@/lib/news/fetch-news";

type NewsArticleBlocksProps = {
  body: ResolvedNewsBodyBlock[];
};

export function NewsArticleBlocks({ body }: NewsArticleBlocksProps) {
  return (
    <>
      {body.map((block, i) => {
        if (block.type === "paragraph") {
          return (
            <p key={i} className="mt-6 first:mt-0 leading-relaxed text-gray-700">
              {block.text}
            </p>
          );
        }
        if (block.type === "image") {
          if (!block.url) {
            return (
              <figure key={i} className="mt-8">
                <div className="flex aspect-[16/10] items-center justify-center rounded-xl border border-dashed border-gray-300 bg-gray-50 text-sm text-gray-500">
                  Image unavailable
                </div>
              </figure>
            );
          }
          return (
            <figure key={i} className="mt-8">
              <div className="relative aspect-[16/10] overflow-hidden rounded-xl border border-gray-200/90 bg-gray-100">
                <Image
                  src={block.url}
                  alt={block.caption ?? block.altText ?? ""}
                  fill
                  className="object-cover"
                  sizes="(min-width: 768px) 768px, 100vw"
                  unoptimized
                />
              </div>
              {block.caption ? (
                <figcaption className="mt-2 text-sm text-gray-500">{block.caption}</figcaption>
              ) : null}
            </figure>
          );
        }
        if (block.type === "video") {
          if (!block.url) {
            return (
              <figure key={i} className="mt-8">
                <div className="flex aspect-video items-center justify-center rounded-xl border border-dashed border-gray-300 bg-gray-50 text-sm text-gray-500">
                  Video unavailable
                </div>
              </figure>
            );
          }
          return (
            <figure key={i} className="mt-8">
              <video
                className="w-full rounded-xl border border-gray-200/90"
                controls
                preload="metadata"
                src={block.url}
              />
              {block.caption ? (
                <figcaption className="mt-2 text-sm text-gray-500">{block.caption}</figcaption>
              ) : null}
            </figure>
          );
        }
        return null;
      })}
    </>
  );
}
