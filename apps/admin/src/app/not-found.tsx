import Image from 'next/image';
import Link from 'next/link';
import styles from './not-found.module.css';

export default function NotFound() {
  return (
    <main className={styles.wrapper}>
      <div className={styles.content}>
        {/* Default loading is lazy; no priority — 404 is not a primary LCP path. */}
        <Image
          src="/images/404.svg"
          alt=""
          width={232}
          height={109}
          className={styles.illustration}
          sizes="(max-width: 480px) 100vw, 232px"
        />
        <h1 className={styles.title}>Page not found</h1>
        <p className={styles.subtitle}>
          The link may be broken or the page has been moved. Try returning to
          the dashboard or login.
        </p>
        <div className={styles.actions}>
          <Link href="/login" className={styles.primary}>
            Back to Login
          </Link>
          <Link href="/dashboard" className={styles.secondary}>
            Go to Dashboard
          </Link>
        </div>
      </div>
    </main>
  );
}
