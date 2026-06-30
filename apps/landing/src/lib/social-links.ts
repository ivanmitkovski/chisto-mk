import { getPublicOptionalUrl, LEGAL_PUBLIC_DEFAULTS } from "@/lib/legal/legal-public-config";

export type SocialPlatform = "facebook" | "instagram" | "linkedin";

export type SocialLink = {
  platform: SocialPlatform;
  href: string;
};

function resolveSocialUrl(envValue: string | undefined, fallback: string): string | null {
  return getPublicOptionalUrl(envValue) ?? getPublicOptionalUrl(fallback);
}

export function getFacebookUrl(): string | null {
  return resolveSocialUrl(process.env.NEXT_PUBLIC_FACEBOOK_URL, LEGAL_PUBLIC_DEFAULTS.facebookUrl);
}

export function getInstagramUrl(): string | null {
  return resolveSocialUrl(process.env.NEXT_PUBLIC_INSTAGRAM_URL, LEGAL_PUBLIC_DEFAULTS.instagramUrl);
}

export function getLinkedInUrl(): string | null {
  return resolveSocialUrl(process.env.NEXT_PUBLIC_LINKEDIN_URL, LEGAL_PUBLIC_DEFAULTS.linkedinUrl);
}

export function getSocialLinks(): SocialLink[] {
  return (
    [
      { platform: "facebook", href: getFacebookUrl() },
      { platform: "instagram", href: getInstagramUrl() },
      { platform: "linkedin", href: getLinkedInUrl() },
    ] as const
  ).filter((link): link is SocialLink => Boolean(link.href));
}

export function getSocialProfileUrls(): string[] {
  return getSocialLinks().map((link) => link.href);
}

export function hasSocialLinks(): boolean {
  return getSocialLinks().length > 0;
}
