import { Facebook, Instagram } from "lucide-react";
import { cn } from "@/lib/utils/cn";

interface SocialIconProps {
  platform: "facebook" | "instagram";
  href?: string;
  className?: string;
}

const icons = {
  facebook: Facebook,
  instagram: Instagram,
} as const;

export function SocialIcon({ platform, href = "#", className }: SocialIconProps) {
  const Icon = icons[platform];

  return (
    <a
      href={href}
      target="_blank"
      rel="noopener noreferrer"
      aria-label={platform}
      className={cn(
        "flex h-10 w-10 items-center justify-center rounded-full border border-gray-300 text-gray-600 transition-colors hover:border-primary hover:text-primary",
        className,
      )}
    >
      <Icon className="h-4 w-4" />
    </a>
  );
}
