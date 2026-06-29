import { Link } from "@/i18n/routing";
import { cn } from "@/lib/utils/cn";

export function EmptyStatePanel({
  title,
  body,
  ctaHref,
  ctaLabel,
  className,
}: {
  title: string;
  body: string;
  ctaHref?: string;
  ctaLabel?: string;
  className?: string;
}) {
  return (
    <div
      className={cn(
        "rounded-2xl border border-gray-200/90 bg-white/80 p-6 text-center shadow-sm md:p-8",
        className,
      )}
    >
      <p className="text-base font-semibold text-gray-900">{title}</p>
      <p className="mt-2 text-sm leading-relaxed text-gray-600">{body}</p>
      {ctaHref && ctaLabel ? (
        <Link
          href={ctaHref}
          className="mt-5 inline-flex rounded-full bg-primary px-5 py-2.5 text-sm font-semibold text-white shadow-sm transition-colors hover:bg-primary-600 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2"
        >
          {ctaLabel}
        </Link>
      ) : null}
    </div>
  );
}
