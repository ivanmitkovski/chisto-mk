"use client";

import Image from "next/image";
import { Link, usePathname } from "@/i18n/routing";
import { cn } from "@/lib/utils/cn";
import { handleHomeNavigationClick } from "@/lib/utils/smooth-scroll";

/** Figma mark (leaf + arrow). Wordmark is HTML so Inter matches the design file. */
const MARK_SRC = "/brand/chisto-mark.svg";

interface LogoProps {
  className?: string;
}

export function Logo({ className }: LogoProps) {
  const pathname = usePathname();

  return (
    <Link
      href="/"
      onClick={(e) => handleHomeNavigationClick(e, pathname, "/")}
      className={cn(
        "rounded-lg outline-none ring-offset-2 focus-visible:ring-2 focus-visible:ring-primary",
        className,
      )}
    >
      <span className="flex items-center gap-[0.4em] font-sans text-[1.125rem] leading-none tracking-tight md:text-xl">
        <Image
          src={MARK_SRC}
          alt=""
          width={271}
          height={313}
          className="h-[1.05em] w-auto shrink-0"
          priority
          unoptimized
        />
        <span>
          <span className="font-bold text-black">Chisto</span>
          <span className="font-medium text-[#25DB86]">.mk</span>
        </span>
      </span>
    </Link>
  );
}
