import { RenderNewsBlocks } from "@chisto/news-content/render";
import type { ResolvedNewsBodyBlock } from "@/lib/news/fetch-news";
import { NewsGalleryCarousel } from "./NewsGalleryCarousel";
import { NewsImage } from "./NewsImage";

type NewsArticleBlocksProps = {
  body: ResolvedNewsBodyBlock[];
  imageUnavailableLabel?: string;
  videoUnavailableLabel?: string;
  galleryUnavailableLabel?: string;
  galleryCloseLabel?: string;
  galleryPreviousLabel?: string;
  galleryNextLabel?: string;
  galleryAriaLabel?: string;
};

export function NewsArticleBlocks({
  body,
  imageUnavailableLabel = "Image unavailable",
  videoUnavailableLabel = "Video unavailable",
  galleryUnavailableLabel = "Gallery unavailable",
  galleryCloseLabel = "Close",
  galleryPreviousLabel = "Previous image",
  galleryNextLabel = "Next image",
  galleryAriaLabel = "Image gallery",
}: NewsArticleBlocksProps) {
  return (
    <RenderNewsBlocks
      blocks={body}
      className="prose-news mt-6 first:mt-0"
      labels={{
        imageUnavailable: imageUnavailableLabel,
        videoUnavailable: videoUnavailableLabel,
        galleryUnavailable: galleryUnavailableLabel,
      }}
      renderImage={({ src, alt, loading }) => (
        <NewsImage
          src={src}
          alt={alt}
          sizes="(min-width: 768px) 768px, 100vw"
          {...(loading ? { loading } : {})}
        />
      )}
      renderGallery={({ items, className }) => (
        <NewsGalleryCarousel
          items={items}
          {...(className !== undefined ? { className } : {})}
          imageUnavailableLabel={galleryUnavailableLabel}
          closeLabel={galleryCloseLabel}
          previousLabel={galleryPreviousLabel}
          nextLabel={galleryNextLabel}
          dialogLabel={galleryAriaLabel}
        />
      )}
    />
  );
}
