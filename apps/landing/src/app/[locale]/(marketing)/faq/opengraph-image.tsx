import { renderMarketingOgImage, OG_IMAGE_SIZE } from "@/lib/seo/marketing-og-image";

export const runtime = "nodejs";
export const size = OG_IMAGE_SIZE;
export const contentType = "image/png";

type Props = { params: Promise<{ locale: string }> };

export default async function Image({ params }: Props) {
  const { locale } = await params;
  return renderMarketingOgImage(locale, "faq");
}
