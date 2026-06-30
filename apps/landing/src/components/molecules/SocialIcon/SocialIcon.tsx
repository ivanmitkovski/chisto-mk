import { Facebook, Instagram, Linkedin } from "lucide-react";
import { cn } from "@/lib/utils/cn";
import type { SocialPlatform } from "@/lib/social-links";

interface SocialIconProps {
  platform: SocialPlatform;
  href: string;
  ariaLabel: string;
  className?: string;
}

const icons = {
  facebook: Facebook,
  instagram: Instagram,
  linkedin: Linkedin,
} as const;

export function SocialIcon({ platform, href, ariaLabel, className }: SocialIconProps) {
  const Icon = icons[platform];

  return (
    <a
      href={href}
      target="_blank"
      rel="noopener noreferrer me"
      aria-label={ariaLabel}
      className={cn(
        "flex h-9 w-9 items-center justify-center rounded-full border border-gray-200/90 bg-white/50 text-gray-500 transition-[color,border-color,background-color,box-shadow] duration-200 hover:border-primary/40 hover:bg-white hover:text-primary hover:shadow-sm",
        className,
      )}
    >
      <Icon className="h-4 w-4" strokeWidth={1.75} aria-hidden />
    </a>
  );
}
