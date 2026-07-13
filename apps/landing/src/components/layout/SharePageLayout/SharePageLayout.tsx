import Link from "next/link";
import Image from "next/image";
import { cn } from "@/lib/utils/cn";

type SharePageLayoutProps = {
  children: React.ReactNode;
  homeHref: string;
  homeLabel: string;
};

export function SharePageLayout({ children, homeHref, homeLabel }: SharePageLayoutProps) {
  return (
    <main className="min-h-dvh bg-[#F4F5F7] px-4 py-10 font-sans text-[#121212]">
      <div className="mx-auto max-w-lg">
        <div className="mb-8 flex items-center gap-2">
          <Image
            src="/brand/chisto-mark.svg"
            alt=""
            width={28}
            height={32}
            className="h-7 w-auto"
            unoptimized
          />
          <span className="text-lg font-bold tracking-tight text-[#121212]">
            Chisto<span className="brand-logotype font-medium text-primary">.mk</span>
          </span>
        </div>
        <div className="rounded-[24px] border border-[#E5E7ED]/90 bg-white p-6 shadow-[var(--shadow-card)] ring-1 ring-black/[0.04] md:p-8">
          {children}
        </div>
        <p className="mt-8 text-center text-sm text-[#7A7A7A]">
          <Link
            href={homeHref}
            className={cn(
              "font-medium text-primary-text underline-offset-2 transition-colors hover:underline",
              "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2",
            )}
          >
            {homeLabel}
          </Link>
        </p>
      </div>
    </main>
  );
}
