'use client';

import { useTranslations } from 'next-intl';
import { DashboardSegmentError } from '@/features/admin-shell';

type ReportsErrorProps = {
  error: Error;
  reset: () => void;
};

export default function ReportsError({ error, reset }: ReportsErrorProps) {
  const tErrors = useTranslations('errors');

  return (
    <DashboardSegmentError
      error={error}
      reset={reset}
      activeItem="reports"
      message={tErrors('unableToLoadReports')}
    />
  );
}
