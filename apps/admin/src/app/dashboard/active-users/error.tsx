'use client';

import { useTranslations } from 'next-intl';
import { DashboardSegmentError } from '@/features/admin-shell';

type ErrorProps = { error: Error; reset: () => void };

export default function ActiveUsersError({ error, reset }: ErrorProps) {
  const tErrors = useTranslations('errors');

  return (
    <DashboardSegmentError
      error={error}
      reset={reset}
      activeItem="active-users"
      message={tErrors('unableToLoadActiveUsers')}
    />
  );
}
