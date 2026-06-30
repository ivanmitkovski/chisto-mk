import { ArrowRight, ChevronLeft } from "lucide-react";
import { Link } from "@/i18n/routing";
import { cn } from "@/lib/utils/cn";

const linkClass =
  "group inline-flex items-center gap-1.5 rounded-md text-sm font-semibold text-primary outline-none transition-colors hover:text-primary-600 focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2";

type NewsReadMoreLinkProps = {
  href: string;
  children: React.ReactNode;
  className?: string;
};

export function NewsReadMoreLink({ href, children, className }: NewsReadMoreLinkProps) {
  return (
    <Link href={href} className={cn(linkClass, className)}>
      <span>{children}</span>
      <ArrowRight
        className="size-[1.05rem] shrink-0 transition-transform duration-200 ease-out group-hover:translate-x-0.5 group-focus-visible:translate-x-0.5"
        aria-hidden
      />
    </Link>
  );
}

export function NewsBackLink({ href, children, className }: NewsReadMoreLinkProps) {
  return (
    <Link href={href} className={cn(linkClass, className)}>
      <ChevronLeft
        className="size-[1.05rem] shrink-0 transition-transform duration-200 ease-out group-hover:-translate-x-0.5 group-focus-visible:-translate-x-0.5"
        aria-hidden
      />
      <span>{children}</span>
    </Link>
  );
}
