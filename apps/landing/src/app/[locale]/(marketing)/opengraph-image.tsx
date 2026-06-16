import { ImageResponse } from "next/og";
import { getTranslations } from "next-intl/server";

export const runtime = "nodejs";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

type Props = { params: Promise<{ locale: string }> };

export default async function Image({ params }: Props) {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "metadata" });
  const title = t("home.title");
  const description = t("home.description");
  const site = t("siteName");

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
          background: "linear-gradient(145deg, #0f172a 0%, #065f46 42%, #0f172a 100%)",
          color: "#f8fafc",
        }}
      >
        <div style={{ fontSize: 36, fontWeight: 700, color: "#6ee7b7" }}>{site}</div>
        <div>
          <div style={{ fontSize: 56, fontWeight: 700, letterSpacing: "-0.03em", lineHeight: 1.1 }}>
            {title}
          </div>
          <div style={{ marginTop: 20, fontSize: 26, color: "#cbd5e1", maxWidth: 900 }}>{description}</div>
        </div>
        <div style={{ fontSize: 22, color: "#64748b" }}>chisto.mk</div>
      </div>
    ),
    { ...size },
  );
}
