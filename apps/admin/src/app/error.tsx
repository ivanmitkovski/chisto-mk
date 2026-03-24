'use client';

import { useEffect } from 'react';
import { Button } from '@/components/ui';

type ErrorProps = {
  error: Error & { digest?: string };
  reset: () => void;
};

export default function Error({ error, reset }: ErrorProps) {
  useEffect(() => {
    console.error(error);
  }, [error]);

  return (
    <main
      style={{
        minHeight: '100vh',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        padding: 'var(--space-7)',
        background: 'var(--bg-app)',
      }}
    >
      <section
        style={{
          maxWidth: '28rem',
          padding: 'var(--space-8)',
          background: 'var(--bg-surface)',
          borderRadius: 'var(--radius-card)',
          boxShadow: 'var(--shadow-md)',
          textAlign: 'center',
        }}
        role="alert"
      >
        <div
          style={{
            width: '3rem',
            height: '3rem',
            margin: '0 auto var(--space-5)',
            borderRadius: 'var(--radius-full)',
            background: 'var(--color-red-100)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontSize: 'var(--font-size-xl)',
          }}
          aria-hidden
        >
          !
        </div>
        <h1
          style={{
            margin: '0 0 var(--space-2)',
            fontSize: 'var(--font-size-xl)',
            fontWeight: 'var(--font-weight-bold)',
          }}
        >
          Something went wrong
        </h1>
        <p
          style={{
            margin: '0 0 var(--space-6)',
            color: 'var(--text-secondary)',
            fontSize: 'var(--font-size-base)',
          }}
        >
          An unexpected error occurred. Please try again.
        </p>
        <div
          style={{
            display: 'flex',
            gap: 'var(--space-3)',
            justifyContent: 'center',
            flexWrap: 'wrap',
          }}
        >
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
