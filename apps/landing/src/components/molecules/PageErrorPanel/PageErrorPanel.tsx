import { Link } from "@/i18n/routing";
import { cn } from "@/lib/utils/cn";

export function PageErrorPanel({
  title,
  body,
  retryLabel,
  onRetry,
  contactHref = "/contact",
  contactLabel,
  className,
}: {
  title: string;
  body: string;
  retryLabel?: string;
  onRetry?: () => void;
  contactHref?: string;
  contactLabel?: string;
  className?: string;
}) {
  return (
    <div
      className={cn(
        "rounded-2xl border border-red-200/80 bg-red-50/60 p-6 text-center shadow-sm md:p-8",
        className,
      )}
      role="alert"
    >
      <p className="text-base font-semibold text-gray-900">{title}</p>
      <p className="mt-2 text-sm leading-relaxed text-gray-600">{body}</p>
      <div className="mt-5 flex flex-wrap items-center justify-center gap-3">
        {onRetry && retryLabel ? (
          <button
            type="button"
            onClick={onRetry}
            className="rounded-full bg-primary px-5 py-2.5 text-sm font-semibold text-white shadow-sm transition-colors hover:bg-primary-600 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2"
          >
            {retryLabel}
          </button>
        ) : null}
        {contactLabel ? (
          <Link
            href={contactHref}
            className="rounded-full border border-gray-200 bg-white px-5 py-2.5 text-sm font-semibold text-gray-800 shadow-sm transition-colors hover:border-primary/30 hover:text-primary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2"
          >
            {contactLabel}
          </Link>
        ) : null}
      </div>
    </div>
  );
}
