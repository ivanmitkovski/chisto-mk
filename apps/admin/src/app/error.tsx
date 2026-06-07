'use client';

import { useTranslations } from 'next-intl';
import { RouteErrorPanel } from '@/components/route-error-panel';

type ErrorProps = {
  error: Error & { digest?: string };
  reset: () => void;
};

export default function Error({ error, reset }: ErrorProps) {
  const t = useTranslations('common');

  return (
    <RouteErrorPanel
      error={error}
      reset={reset}
      title={t('somethingWentWrong')}
      description={t('unexpectedError')}
    />
  );
}
