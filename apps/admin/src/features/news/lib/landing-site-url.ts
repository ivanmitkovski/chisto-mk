function landingSiteOrigin(): string {
  const explicit = process.env.NEXT_PUBLIC_SITE_URL?.trim();
  if (explicit) return explicit.replace(/\/$/, '');
  return 'https://chisto.mk';
}

export function landingSiteHost(): string {
  try {
    return new URL(landingSiteOrigin()).host;
  } catch {
    return 'chisto.mk';
  }
}

export function landingNewsArticleUrl(locale: string, slug: string): string {
  return `${landingSiteOrigin()}/${locale}/news/${slug}`;
}
