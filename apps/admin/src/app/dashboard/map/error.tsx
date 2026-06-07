'use client';

import { DashboardSegmentError } from '@/features/admin-shell';

type ErrorProps = { error: Error; reset: () => void };

export default function SegmentError({ error, reset }: ErrorProps) {
  return <DashboardSegmentError error={error} reset={reset} activeItem="map" />;
}
