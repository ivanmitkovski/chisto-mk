'use client';

import dynamic from 'next/dynamic';
import { Card, PanelSkeleton } from '@/components/ui';
import type { EngagementAnalytics } from '../data/active-users.types';

const EngagementChartsInner = dynamic(
  () => import('./engagement-charts-inner').then((m) => ({ default: m.EngagementChartsInner })),
  {
    ssr: false,
    loading: () => (
      <Card padding="md">
        <PanelSkeleton lines={4} />
      </Card>
    ),
  },
);

type EngagementChartsSectionProps = {
  engagement: EngagementAnalytics;
  engagementError?: string;
};

export function EngagementChartsSection({ engagement, engagementError }: EngagementChartsSectionProps) {
  return (
    <EngagementChartsInner engagement={engagement} {...(engagementError ? { engagementError } : {})} />
  );
}
