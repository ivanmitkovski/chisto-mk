import { OpenInAppLink } from "@/components/app-handoff/OpenInAppLink";
import { SharePageLayout } from "@/components/layout/SharePageLayout";
import { ShareActionLink } from "@/components/layout/SharePageLayout/ShareActionLink";
import { buttonVariants } from "@/components/atoms/Button";
import { cn } from "@/lib/utils/cn";

type ShareAction = {
  href: string;
  label: string;
};

type SharePageShellProps = {
  homeHref: string;
  homeLabel: string;
  eyebrow?: string;
  title: string;
  lines: string[];
  primary: ShareAction;
  secondary?: ShareAction;
  footerLink?: ShareAction;
  children?: React.ReactNode;
};

export function SharePageShell({
  homeHref,
  homeLabel,
  eyebrow = "Chisto.mk",
  title,
  lines,
  primary,
  secondary,
  footerLink,
  children,
}: SharePageShellProps) {
  return (
    <SharePageLayout homeHref={homeHref} homeLabel={homeLabel}>
      {children}
      <p className="text-xs font-semibold uppercase tracking-wider text-[#7A7A7A]">{eyebrow}</p>
      <h1 className="mt-2 text-2xl font-bold tracking-tight text-[#121212]">{title}</h1>
      <div className="mt-3 space-y-2 text-sm leading-relaxed text-[#4C4C4C]">
        {lines.map((line) => (
          <p key={line}>{line}</p>
        ))}
      </div>
      <div className="mt-8 flex flex-wrap gap-3">
        <OpenInAppLink
          href={primary.href}
          className={cn(buttonVariants({ variant: "primary", size: "md" }), "min-h-14 text-[17px] font-semibold")}
        >
          {primary.label}
        </OpenInAppLink>
        {secondary ? (
          <ShareActionLink
            href={secondary.href}
            label={secondary.label}
            variant="outline"
            analyticsSource="share_get_app"
          />
        ) : null}
      </div>
      {footerLink ? (
        <p className="mt-8 text-sm">
          <a
            href={footerLink.href}
            className={cn(
              "font-medium text-primary-text underline-offset-2 hover:underline",
              "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2",
            )}
          >
            {footerLink.label}
          </a>
        </p>
      ) : null}
    </SharePageLayout>
  );
}
