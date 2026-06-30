import { Link } from "@/i18n/routing";
import { newsHubPageHref } from "@/lib/news/news-hub-page";
import { cn } from "@/lib/utils/cn";

type NewsHubPaginationProps = {
  page: number;
  totalPages: number;
  prevLabel: string;
  nextLabel: string;
  pageLabel: (current: number, total: number) => string;
  category?: string;
};

export function NewsHubPagination({
  page,
  totalPages,
  prevLabel,
  nextLabel,
  pageLabel,
  category,
}: NewsHubPaginationProps) {
  if (totalPages <= 1) return null;

  const prevDisabled = page <= 1;
  const nextDisabled = page >= totalPages;
  const showNumberedLinks = totalPages <= 7;

  return (
    <nav
      className="mt-12 flex flex-wrap items-center justify-center gap-4"
      aria-label={pageLabel(page, totalPages)}
    >
      {prevDisabled ? (
        <span className="text-sm font-medium text-gray-400" aria-disabled="true">
          {prevLabel}
        </span>
      ) : (
        <Link
          href={newsHubPageHref(page - 1, category)}
          className="text-sm font-semibold text-primary transition-colors hover:text-primary-600"
        >
          {prevLabel}
        </Link>
      )}

      {showNumberedLinks ? (
        <div className="flex items-center gap-1">
          {Array.from({ length: totalPages }, (_, i) => i + 1).map((pageNum) => (
            <Link
              key={pageNum}
              href={newsHubPageHref(pageNum, category)}
              aria-current={pageNum === page ? "page" : undefined}
              className={cn(
                "inline-flex h-8 min-w-8 items-center justify-center rounded-full px-2 text-sm font-semibold transition-colors",
                pageNum === page
                  ? "bg-primary text-white"
                  : "text-gray-600 hover:bg-primary/10 hover:text-primary-700",
              )}
            >
              {pageNum}
            </Link>
          ))}
        </div>
      ) : (
        <span className="text-sm text-gray-500">{pageLabel(page, totalPages)}</span>
      )}

      {nextDisabled ? (
        <span className={cn("text-sm font-medium text-gray-400")} aria-disabled="true">
          {nextLabel}
        </span>
      ) : (
        <Link
          href={newsHubPageHref(page + 1, category)}
          className="text-sm font-semibold text-primary transition-colors hover:text-primary-600"
        >
          {nextLabel}
        </Link>
      )}
    </nav>
  );
}
