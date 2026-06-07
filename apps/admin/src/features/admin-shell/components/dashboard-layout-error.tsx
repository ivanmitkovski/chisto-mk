'use client';

import { useTranslations } from 'next-intl';
import { RouteErrorPanel } from '@/components/route-error-panel';

type DashboardLayoutErrorProps = {
  description: string;
};

export function DashboardLayoutError({ description }: DashboardLayoutErrorProps) {
  const tCommon = useTranslations('common');

  return (
    <RouteErrorPanel
      error={new Error(description)}
      reset={() => window.location.reload()}
      title={tCommon('dashboardFailedToLoad')}
      description={description}
    />
  );
}
