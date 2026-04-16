import { ImageResponse } from "next/og";
import { getTranslations } from "next-intl/server";
import { helpArticleMeta, isHelpArticleSlug } from "@/lib/help/help-catalog";
import { getSiteUrl } from "@/lib/site-url";

export const runtime = "nodejs";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

type Props = { params: Promise<{ locale: string; slug: string }> };

export default async function Image({ params }: Props) {
  const { locale, slug } = await params;
  if (!isHelpArticleSlug(slug)) {
    return new ImageResponse(
      (
        <div
          style={{
            width: "100%",
            height: "100%",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            background: "#0f172a",
            color: "#f8fafc",
            fontSize: 48,
            fontWeight: 700,
          }}
        >
          Chisto.mk
        </div>
      ),
      { ...size },
    );
  }

  const meta = helpArticleMeta(slug);
  if (meta?.publicOgImagePath) {
    const src = `${getSiteUrl()}${meta.publicOgImagePath}`;
    return new ImageResponse(
      (
        <div style={{ width: "100%", height: "100%", display: "flex", background: "#0f172a" }}>
          <img src={src} alt="" width={1200} height={630} style={{ objectFit: "cover", width: "100%", height: "100%" }} />
        </div>
      ),
      { ...size },
    );
  }

  const tMeta = await getTranslations({ locale, namespace: "metadata" });
  const t = await getTranslations({ locale, namespace: "helpCentre" });
  const articleTitle = t(`articles.${slug}.title`);
  const summary = t(`articles.${slug}.cardSummary`);
  const site = tMeta("siteName");

  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "space-between",
          padding: 64,
          background: "linear-gradient(145deg, #0f172a 0%, #14532d 38%, #0f172a 100%)",
          color: "#f8fafc",
        }}
      >
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", gap: 24 }}>
          <div style={{ fontSize: 28, fontWeight: 600, color: "#4ade80" }}>{site}</div>
          <div style={{ fontSize: 22, color: "#94a3b8" }}>Help</div>
        </div>
        <div>
          <div style={{ fontSize: 52, fontWeight: 700, letterSpacing: "-0.03em", lineHeight: 1.12 }}>{articleTitle}</div>
          <div style={{ marginTop: 24, fontSize: 24, color: "#cbd5e1", lineHeight: 1.45, maxWidth: 1000 }}>{summary}</div>
        </div>
        <div style={{ fontSize: 20, color: "#64748b" }}>chisto.mk · {slug.replace(/-/g, " ")}</div>
      </div>
    ),
    { ...size },
  );
}
