/** Same-origin path Vercel injects after Web Analytics is enabled + redeployed. */
export const VERCEL_INSIGHTS_SCRIPT = "/_vercel/insights/script.js";

function isExecutableScriptType(contentType: string | null): boolean | null {
  const type = (contentType ?? "").toLowerCase();
  if (!type) return null;
  if (type.includes("javascript") || type.includes("ecmascript")) return true;
  if (type.includes("text/html") || type.includes("application/json")) return false;
  return null;
}

/**
 * Returns true when the deployment exposes the Web Analytics script as JS.
 * When Analytics was never enabled (or was enabled after the last deploy),
 * this path falls through to Next.js and returns HTML — which browsers refuse to execute.
 */
export async function isVercelInsightsScriptReady(
  fetchImpl: typeof fetch = fetch,
): Promise<boolean> {
  for (const method of ["HEAD", "GET"] as const) {
    try {
      const res = await fetchImpl(VERCEL_INSIGHTS_SCRIPT, {
        method,
        cache: "no-store",
        credentials: "same-origin",
      });
      if (!res.ok) {
        if (method === "HEAD") continue;
        return false;
      }
      const verdict = isExecutableScriptType(res.headers.get("content-type"));
      if (verdict === true) return true;
      if (verdict === false) return false;
      // Ambiguous content-type on HEAD — try GET before giving up.
    } catch {
      if (method === "GET") return false;
    }
  }
  return false;
}
