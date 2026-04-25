export default function EventShareLoading() {
  return (
    <main
      style={{
        fontFamily: "var(--font-sans), system-ui, sans-serif",
        padding: 24,
        maxWidth: 560,
        margin: "0 auto",
        lineHeight: 1.5,
      }}
    >
      <div
        style={{
          height: 14,
          width: 120,
          borderRadius: 4,
          background: "#e2e8f0",
          marginBottom: 16,
        }}
      />
      <div
        style={{
          height: 28,
          width: "85%",
          borderRadius: 6,
          background: "#e2e8f0",
          marginBottom: 12,
        }}
      />
      <div
        style={{
          height: 16,
          width: "70%",
          borderRadius: 4,
          background: "#e2e8f0",
          marginBottom: 8,
        }}
      />
      <div
        style={{
          height: 16,
          width: "55%",
          borderRadius: 4,
          background: "#e2e8f0",
          marginBottom: 24,
        }}
      />
      <div style={{ display: "flex", flexWrap: "wrap", gap: 12 }}>
        <div style={{ height: 44, width: 160, borderRadius: 8, background: "#e2e8f0" }} />
        <div style={{ height: 44, width: 140, borderRadius: 8, background: "#e2e8f0" }} />
      </div>
    </main>
  );
}
