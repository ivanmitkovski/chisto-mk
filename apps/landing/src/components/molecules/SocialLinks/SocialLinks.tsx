"use client";

import { useTranslations } from "next-intl";
import { SocialIcon } from "@/components/molecules/SocialIcon";
import { getSocialLinks, type SocialPlatform } from "@/lib/social-links";
import { cn } from "@/lib/utils/cn";

const labelKeys: Record<SocialPlatform, "socialFacebook" | "socialInstagram" | "socialLinkedin"> = {
  facebook: "socialFacebook",
  instagram: "socialInstagram",
  linkedin: "socialLinkedin",
};

interface SocialLinksProps {
  className?: string;
  iconClassName?: string;
}

export function SocialLinks({ className, iconClassName }: SocialLinksProps) {
  const t = useTranslations("footer");
  const links = getSocialLinks();

  if (links.length === 0) return null;

  return (
    <nav aria-label={t("socialNavLabel")} className={cn("flex gap-2", className)}>
      {links.map(({ platform, href }) => (
        <SocialIcon
          key={platform}
          platform={platform}
          href={href}
          ariaLabel={t(labelKeys[platform])}
          {...(iconClassName !== undefined ? { className: iconClassName } : {})}
        />
      ))}
    </nav>
  );
}
