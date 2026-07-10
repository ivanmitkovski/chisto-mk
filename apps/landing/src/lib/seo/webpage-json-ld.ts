import { getSiteUrl } from "@/lib/site-url";

type WebPageJsonLdInput = {
  locale: string;
  path: string;
  name: string;
  description: string;
  siteName: string;
};

/** Simple WebPage + isPartOf WebSite graph for marketing/legal pages. */
export function buildWebPageJsonLd({
  locale,
  path,
  name,
  description,
  siteName,
}: WebPageJsonLdInput): Record<string, unknown> {
  const siteUrl = getSiteUrl().replace(/\/$/, "");
  const normalizedPath = path.startsWith("/") ? path : `/${path}`;
  const pageUrl = `${siteUrl}/${locale}${normalizedPath === "/" ? "" : normalizedPath}`;

  return {
    "@context": "https://schema.org",
    "@type": "WebPage",
    name,
    description,
    url: pageUrl,
    isPartOf: {
      "@type": "WebSite",
      name: siteName,
      url: siteUrl,
    },
  };
}

type CollectionPageJsonLdInput = {
  locale: string;
  path: string;
  name: string;
  description: string;
  siteName: string;
  items: Array<{ name: string; url: string }>;
};

/** CollectionPage with ItemList of child URLs (help hub, news hub). */
export function buildCollectionPageJsonLd({
  locale,
  path,
  name,
  description,
  siteName,
  items,
}: CollectionPageJsonLdInput): Record<string, unknown> {
  const siteUrl = getSiteUrl().replace(/\/$/, "");
  const normalizedPath = path.startsWith("/") ? path : `/${path}`;
  const pageUrl = `${siteUrl}/${locale}${normalizedPath === "/" ? "" : normalizedPath}`;

  return {
    "@context": "https://schema.org",
    "@type": "CollectionPage",
    name,
    description,
    url: pageUrl,
    isPartOf: {
      "@type": "WebSite",
      name: siteName,
      url: siteUrl,
    },
    mainEntity: {
      "@type": "ItemList",
      itemListElement: items.map((item, index) => ({
        "@type": "ListItem",
        position: index + 1,
        name: item.name,
        url: item.url,
      })),
    },
  };
}
