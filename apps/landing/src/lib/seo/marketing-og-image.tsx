import { ImageResponse } from "next/og";
import { getTranslations } from "next-intl/server";

export const OG_IMAGE_SIZE = { width: 1200, height: 630 };

/** Shared 1200x630 OG card used by legal/utility pages (same style as privacy). */
export async function renderMarketingOgImage(locale: string, metaKey: string) {
  const t = await getTranslations({ locale, namespace: "metadata" });
  const title = t(`${metaKey}.title`);
  const description = t(`${metaKey}.description`);
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
          background: "linear-gradient(145deg, #0f172a 0%, #115e59 42%, #0f172a 100%)",
          color: "#f8fafc",
        }}
      >
        <div style={{ fontSize: 36, fontWeight: 700, color: "#5eead4" }}>{site}</div>
        <div style={{ display: "flex", flexDirection: "column" }}>
          <div style={{ fontSize: 48, fontWeight: 700, letterSpacing: "-0.03em", lineHeight: 1.1 }}>
            {title}
          </div>
          <div style={{ marginTop: 20, fontSize: 24, color: "#cbd5e1", maxWidth: 900 }}>
            {description}
          </div>
        </div>
        <div style={{ fontSize: 22, color: "#64748b" }}>chisto.mk</div>
      </div>
    ),
    { ...OG_IMAGE_SIZE },
  );
}
