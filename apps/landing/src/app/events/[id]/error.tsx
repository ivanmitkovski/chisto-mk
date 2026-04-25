"use client";

export default function EventShareError({
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <main
      style={{
        fontFamily: "var(--font-sans), system-ui, sans-serif",
        padding: 24,
        maxWidth: 480,
        margin: "0 auto",
        lineHeight: 1.5,
        textAlign: "center",
      }}
    >
      <h1 style={{ fontSize: "1.25rem", color: "#0f172a" }}>Temporarily unavailable</h1>
      <p style={{ color: "#64748b" }}>
        We couldn&apos;t load this event preview. Please try again in a moment.
      </p>
      <button
        type="button"
        onClick={() => reset()}
        style={{
          marginTop: 16,
          padding: "10px 20px",
          borderRadius: 8,
          border: "none",
          background: "#0d9488",
          color: "#fff",
          fontWeight: 600,
          cursor: "pointer",
        }}
      >
        Retry
      </button>
    </main>
  );
}
