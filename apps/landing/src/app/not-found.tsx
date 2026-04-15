import Link from "next/link";

export default function NotFound() {
  return (
    <main
      style={{
        minHeight: "100dvh",
        display: "grid",
        placeItems: "center",
        padding: "2rem",
        fontFamily: "system-ui, sans-serif",
      }}
    >
      <div style={{ textAlign: "center" }}>
        <p style={{ marginBottom: "1rem" }}>Not found.</p>
        <Link href="/mk" style={{ color: "#25db86" }}>
          Chisto.mk
        </Link>
      </div>
    </main>
  );
}
