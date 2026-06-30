'use client';

import { useTranslations } from 'next-intl';
import { RouteErrorPanel } from '@/components/route-error-panel';

type ErrorProps = { error: Error; reset: () => void };

export default function AcceptInviteError({ error, reset }: ErrorProps) {
  const t = useTranslations('common');

  return (
    <RouteErrorPanel
      error={error}
      reset={reset}
      title={t('somethingWentWrong')}
      description={t('unexpectedError')}
      loginHref="/login"
    />
  );
}
