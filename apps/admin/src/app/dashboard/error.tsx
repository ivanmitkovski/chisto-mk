'use client';

import { useEffect } from 'react';
import { Button } from '@/components/ui';
import styles from '../shared/route-state.module.css';

type DashboardErrorProps = {
  error: Error;
  reset: () => void;
};

export default function DashboardError({ error, reset }: DashboardErrorProps) {
  useEffect(() => {
    console.error(error);
  }, [error]);

  return (
    <main className={styles.wrapper}>
      <section className={styles.card} role="alert">
        <h1 className={styles.title}>Dashboard failed to load</h1>
        <p className={styles.text}>
          Something went wrong while loading this page. Please retry, or return to the login screen.
        </p>
        <div className={styles.actions}>
          <Button type="button" onClick={reset}>
            Retry
          </Button>
          <Button type="button" variant="outline" onClick={() => window.location.assign('/login')}>
            Go to Login
          </Button>
        </div>
      </section>
    </main>
  );
}
