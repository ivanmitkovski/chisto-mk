"use client";

import { useEffect, useRef } from "react";
import { chistoApiBase } from "@/lib/share-api";

type Props = {
  token: string | null;
};

/** Best-effort share click attribution; failures are ignored. */
export function SiteShareAttribution({ token }: Props) {
  const sentRef = useRef(false);

  useEffect(() => {
    if (sentRef.current) return;
    const trimmed = token?.trim();
    if (!trimmed || trimmed.length < 16) return;
    sentRef.current = true;

    void fetch(`${chistoApiBase()}/sites/share-events/click`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ token: trimmed }),
      keepalive: true,
    }).catch(() => {
      /* non-blocking */
    });
  }, [token]);

  return null;
}
