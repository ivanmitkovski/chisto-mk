import { defaultLocale } from "@/i18n/config";

/**
 * Root 404 for paths that bypass the locale middleware matcher
 * (`/_vercel/*`, dotted static probes, etc.).
 *
 * Do NOT redirect here. Redirecting turns script probes like
 * `/_vercel/insights/script.js` into HTML (`text/html`), which browsers refuse
 * to execute under `X-Content-Type-Options: nosniff` and floods the console.
 * Locale UX 404s live in `app/[locale]/not-found.tsx`.
 */
export default function RootNotFound() {
  return (
    <html lang={defaultLocale}>
      <body
        style={{
          margin: 0,
          minHeight: "100vh",
          display: "grid",
          placeItems: "center",
          fontFamily:
            "ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial, sans-serif",
          color: "#111827",
          background: "#ffffff",
        }}
      >
        <main style={{ textAlign: "center", padding: "1.5rem" }}>
          <p style={{ fontSize: "2.5rem", fontWeight: 700, margin: 0 }}>404</p>
          <p style={{ margin: "0.75rem 0 1.5rem", color: "#4b5563" }}>Page not found</p>
          <a
            href={`/${defaultLocale}`}
            style={{
              display: "inline-flex",
              alignItems: "center",
              justifyContent: "center",
              borderRadius: "9999px",
              background: "#2FD788",
              color: "#121212",
              textDecoration: "none",
              fontWeight: 600,
              padding: "0.75rem 1.5rem",
            }}
          >
            Home
          </a>
        </main>
      </body>
    </html>
  );
}
