import { ImageResponse } from "next/og";
import { chistoApiBase } from "@/lib/share-api";

export const runtime = "edge";
export const alt = "Chisto.mk";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

type Props = { params: Promise<{ id: string }> };

async function loadTitle(id: string): Promise<{ title: string; status: string } | null> {
  try {
    const res = await fetch(`${chistoApiBase()}/sites/${encodeURIComponent(id)}/share-card`, {
      next: { revalidate: 60 },
    });
    if (!res.ok) return null;
    const data = (await res.json()) as { title?: string; status?: string };
    if (!data.title) return null;
    return { title: data.title, status: data.status ?? "" };
  } catch {
    return null;
  }
}

export default async function Image({ params }: Props) {
  const { id } = await params;
  const card = await loadTitle(id);
  const title = card?.title ?? "Chisto.mk";
  const status = card?.status?.replace(/_/g, " ") ?? "";

  return new ImageResponse(
    (
      <div
        style={{
          height: "100%",
          width: "100%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "space-between",
          background: "linear-gradient(160deg, #F4F5F7 0%, #EDFFF6 55%, #D4F9E8 100%)",
          padding: 64,
          fontFamily: "system-ui, sans-serif",
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
          <div
            style={{
              width: 48,
              height: 48,
              borderRadius: 16,
              background: "#2FD788",
            }}
          />
          <div style={{ fontSize: 36, fontWeight: 700, color: "#121212" }}>
            Chisto<span style={{ color: "#14B96A" }}>.mk</span>
          </div>
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
          {status ? (
            <div
              style={{
                display: "flex",
                alignSelf: "flex-start",
                background: "#EDFFF6",
                color: "#14B96A",
                fontSize: 22,
                fontWeight: 600,
                padding: "8px 18px",
                borderRadius: 999,
              }}
            >
              {status}
            </div>
          ) : null}
          <div
            style={{
              fontSize: title.length > 60 ? 42 : 52,
              fontWeight: 700,
              color: "#121212",
              lineHeight: 1.15,
              maxWidth: 1000,
            }}
          >
            {title}
          </div>
        </div>
      </div>
    ),
    { ...size },
  );
}
