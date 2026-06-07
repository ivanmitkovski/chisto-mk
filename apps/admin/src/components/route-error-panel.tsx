'use client';

import { useEffect } from 'react';
import { useTranslations } from 'next-intl';
import { Button } from '@/components/ui';
import { clientLogger, getErrorReference } from '@/lib/observability';
import styles from '@/app/shared/route-state.module.css';

type RouteErrorPanelProps = {
  error: Error;
  reset: () => void;
  title: string;
  description: string;
  loginHref?: string;
};

export function RouteErrorPanel({
  error,
  reset,
  title,
  description,
  loginHref = '/login',
}: RouteErrorPanelProps) {
  const t = useTranslations('common');
  const reference = getErrorReference(error);

  useEffect(() => {
    clientLogger.error('route_error', {
      message: error.message,
      name: error.name,
      ...(reference !== undefined ? { requestId: reference } : {}),
    });
  }, [error, reference]);

  return (
    <main className={styles.wrapper}>
      <section className={styles.card} role="alert">
        <h1 className={styles.title}>{title}</h1>
        <p className={styles.text}>{description}</p>
        {reference ? (
          <p className={styles.text}>
            {t('reference', { id: reference })}
          </p>
        ) : null}
        <div className={styles.actions}>
          <Button type="button" onClick={reset}>
            {t('retry')}
          </Button>
          <Button type="button" variant="outline" onClick={() => window.location.assign(loginHref)}>
            {t('goToLogin')}
          </Button>
        </div>
      </section>
    </main>
  );
}
