import styles from '../shared/route-state.module.css';

export default function LoginLoading() {
  return (
    <main className={styles.wrapper}>
      <section className={styles.loginShell} aria-busy="true" aria-live="polite">
        <div className={styles.loginPanel}>
          <span className={styles.loginLogo} />
          <span className={styles.loginTitle} />
          <span className={styles.loginField} />
          <span className={styles.loginField} />
          <span className={styles.loginButton} />
          <span className={styles.loginFooter} />
        </div>
        <div className={styles.loginVisual} />
      </section>
    </main>
  );
}
