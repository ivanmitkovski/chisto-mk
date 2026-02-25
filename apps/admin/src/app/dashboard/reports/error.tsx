'use client';

import { useEffect } from 'react';
import { Button } from '@/components/ui';
import { AdminShell } from '@/features/admin-shell';
import styles from '../../shared/route-state.module.css';

type ReportsErrorProps = {
  error: Error;
  reset: () => void;
};

export default function ReportsError({ error, reset }: ReportsErrorProps) {
  useEffect(() => {
    console.error(error);
  }, [error]);

  return (
    <AdminShell title="Reports" activeItem="reports">
      <section className={styles.card} role="alert">
        <h1 className={styles.title}>Report workspace unavailable</h1>
        <p className={styles.text}>
          We could not load the selected report right now. Retry this request, or return to the reports queue.
        </p>
        <div className={styles.actions}>
          <Button type="button" onClick={reset}>
            Retry
          </Button>
          <Button type="button" variant="outline" onClick={() => window.location.assign('/dashboard')}>
            Go to Overview
          </Button>
        </div>
      </section>
    </AdminShell>
  );
}
