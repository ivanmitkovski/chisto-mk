"use client";

import type { MouseEvent } from "react";
import { Link, usePathname } from "@/i18n/routing";
import { cn } from "@/lib/utils/cn";
import { handleHomeNavigationClick } from "@/lib/utils/smooth-scroll";

interface NavItemProps {
  href: string;
  label: string;
  onClick?: () => void;
}

export function NavItem({ href, label, onClick }: NavItemProps) {
  const pathname = usePathname();
  const isActive = pathname === href;

  function onLinkClick(e: MouseEvent<HTMLAnchorElement>) {
    handleHomeNavigationClick(e, pathname, href);
    onClick?.();
  }

  return (
    <Link
      href={href}
      onClick={onLinkClick}
      className={cn(
        "relative rounded-md px-1 py-2 text-[0.9375rem] font-medium tracking-tight transition-colors duration-300 ease-[cubic-bezier(0.22,1,0.36,1)]",
        "outline-none ring-offset-2 focus-visible:ring-2 focus-visible:ring-primary",
        isActive ? "text-primary" : "text-gray-800 hover:text-primary",
      )}
    >
      {label}
    </Link>
  );
}
