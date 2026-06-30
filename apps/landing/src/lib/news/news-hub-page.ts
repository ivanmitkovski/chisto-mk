export function newsHubPageHref(page: number, category?: string): string {
  const params = new URLSearchParams();
  if (page > 1) params.set("page", String(page));
  if (category) params.set("category", category);
  const qs = params.toString();
  return qs ? `/news?${qs}` : "/news";
}

/**
 * Returns a locale-relative hub path when the requested page is out of range, or null if valid.
 */
export function newsHubRedirectPath(
  page: number,
  total: number,
  pageSize: number,
  category?: string,
): string | null {
  const totalPages = Math.max(1, Math.ceil(total / pageSize));
  if (total > 0 && page > totalPages) {
    return newsHubPageHref(totalPages, category);
  }
  if (total === 0 && page > 1) {
    return newsHubPageHref(1, category);
  }
  return null;
}
