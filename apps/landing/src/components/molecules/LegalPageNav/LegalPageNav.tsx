"use client";

import { useTranslations } from "next-intl";
import { Link, usePathname } from "@/i18n/routing";
import { cn } from "@/lib/utils/cn";

const LEGAL_PATHS = [
  { href: "/terms", key: "terms" as const },
  { href: "/privacy", key: "privacy" as const },
  { href: "/cookies", key: "cookies" as const },
  { href: "/data", key: "data" as const },
] as const;

export function LegalPageNav({ className }: { className?: string }) {
  const t = useTranslations("legalNav");
  const pathname = usePathname();

  return (
    <nav
      className={cn(
        "flex flex-wrap gap-x-6 gap-y-3 border-t border-gray-200/80 pt-10 text-sm",
        className,
      )}
      aria-label={t("ariaLabel")}
    >
      {LEGAL_PATHS.map(({ href, key }) => {
        const active = pathname === href || pathname.startsWith(`${href}/`);
        return (
          <Link
            key={href}
            href={href}
            aria-current={active ? "page" : undefined}
            className={cn(
              "font-medium underline-offset-4 hover:underline",
              active ? "text-gray-900" : "text-primary",
            )}
          >
            {t(key)}
          </Link>
        );
      })}
    </nav>
  );
}
