'use client';

import { useTranslations } from 'next-intl';
import { RouteErrorPanel } from '@/components/route-error-panel';

type DashboardErrorProps = {
  error: Error;
  reset: () => void;
};

export default function DashboardError({ error, reset }: DashboardErrorProps) {
  const tCommon = useTranslations('common');

  return (
    <RouteErrorPanel
      error={error}
      reset={reset}
      title={tCommon('dashboardFailedToLoad')}
      description={tCommon('dashboardLoadErrorDescription')}
    />
  );
}
