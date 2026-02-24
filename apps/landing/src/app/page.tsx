export default function LandingPage() {
  return (
    <main style={styles.main}>
      <h1 style={styles.title}>Chisto.mk</h1>
    </main>
  );
}

const styles: Record<string, React.CSSProperties> = {
  main: {
    minHeight: '100vh',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    fontFamily: 'system-ui, sans-serif',
    backgroundColor: '#fff',
    color: '#000',
  },
  title: {
    margin: 0,
    fontSize: '2rem',
    fontWeight: 400,
  },
};
