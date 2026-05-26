'use client';

import { useEffect } from 'react';
import { Button } from '@/components/ui';
import styles from './error.module.css';

type ErrorProps = {
  error: Error & { digest?: string };
  reset: () => void;
};

export default function Error({ error, reset }: ErrorProps) {
  useEffect(() => {
    console.error(error);
  }, [error]);

  return (
    <main className={styles.main}>
      <section className={styles.card} role="alert">
        <div className={styles.icon} aria-hidden>
          !
        </div>
        <h1 className={styles.title}>
          Something went wrong
        </h1>
        <p className={styles.message}>
          An unexpected error occurred. Please try again.
        </p>
        <div className={styles.actions}>
          <Button type="button" onClick={reset}>
            Retry
          </Button>
          <Button
            type="button"
            variant="outline"
            onClick={() => (window.location.href = '/login')}
          >
            Go to Login
          </Button>
        </div>
      </section>
    </main>
  );
}
