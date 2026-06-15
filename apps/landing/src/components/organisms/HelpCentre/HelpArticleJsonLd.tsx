type BreadcrumbItem = { name: string; item: string };

type Props = {
  pageUrl: string;
  locale: string;
  headline: string;
  description: string;
  publisherName: string;
  publisherUrl: string;
  /** ISO-8601 strings when provided in messages (editorial). */
  datePublished?: string;
  dateModified?: string;
  /** Optional HowTo derived from structured bullet blocks (same order as on page). */
  howToSteps?: readonly string[];
  /** BreadcrumbList (same trail as visible breadcrumb). */
  breadcrumb?: readonly BreadcrumbItem[];
};

/**
 * Conservative structured data for help articles (no medical/legal claims).
 */
export function HelpArticleJsonLd({
  pageUrl,
  locale,
  headline,
  description,
  publisherName,
  publisherUrl,
  datePublished,
  dateModified,
  howToSteps,
  breadcrumb,
}: Props) {
  const inLanguage = locale === "mk" ? "mk-MK" : locale === "sq" ? "sq-AL" : "en";
  const article: Record<string, unknown> = {
    "@type": "Article",
    headline,
    description,
    inLanguage,
    mainEntityOfPage: {
      "@type": "WebPage",
      "@id": pageUrl,
    },
    url: pageUrl,
    isAccessibleForFree: true,
    publisher: {
      "@type": "Organization",
      name: publisherName,
      url: publisherUrl,
    },
  };
  if (datePublished != null && datePublished.length > 0) {
    article.datePublished = datePublished;
  }
  if (dateModified != null && dateModified.length > 0) {
    article.dateModified = dateModified;
  }

  const howTo =
    howToSteps != null && howToSteps.length >= 2
      ? {
          "@type": "HowTo",
          name: headline,
          description,
          inLanguage,
          step: howToSteps.map((text, i) => ({
            "@type": "HowToStep",
            position: i + 1,
            name: text.length > 110 ? `${text.slice(0, 107)}…` : text,
            text,
          })),
        }
      : null;

  const breadcrumbLd =
    breadcrumb != null && breadcrumb.length > 0
      ? {
          "@type": "BreadcrumbList",
          itemListElement: breadcrumb.map((b, i) => ({
            "@type": "ListItem",
            position: i + 1,
            name: b.name,
            item: b.item,
          })),
        }
      : null;

  const graph: unknown[] = [article];
  if (howTo != null) {
    graph.push(howTo);
  }
  if (breadcrumbLd != null) {
    graph.push(breadcrumbLd);
  }

  const payload = {
    "@context": "https://schema.org",
    "@graph": graph,
  };

  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(payload) }}
    />
  );
}
