import { getTranslations } from 'next-intl/server';
import { ApiConnectionError } from '@/lib/api';
import { Card, PanelSkeleton, SkeletonCard } from '@/components/ui';
import {
  fetchEngagementAnalytics,
  fetchGeoClusters,
} from '../data/active-users-adapter.server';
import { EMPTY_ENGAGEMENT_ANALYTICS } from '../data/active-users.types';
import { EngagementChartsSection } from './engagement-charts';
import { ActiveUsersGeoMap } from './active-users-geo-map-client';

async function sectionErrorMessage(error: unknown): Promise<string> {
  const tErrors = await getTranslations('errors');
  return error instanceof ApiConnectionError
    ? tErrors('couldNotReachApi')
    : tErrors('somethingWentWrongTryAgain');
}

export function ActiveUsersEngagementFallback() {
  return (
    <Card padding="md">
      <SkeletonCard lines={4} />
    </Card>
  );
}

export function ActiveUsersGeoFallback() {
  return (
    <Card padding="md">
      <PanelSkeleton variant="card" lines={3} />
    </Card>
  );
}

export async function ActiveUsersEngagementSection() {
  try {
    const engagement = await fetchEngagementAnalytics();
    return <EngagementChartsSection engagement={engagement} />;
  } catch (error) {
    const message = await sectionErrorMessage(error);
    return (
      <EngagementChartsSection engagement={EMPTY_ENGAGEMENT_ANALYTICS} engagementError={message} />
    );
  }
}

export async function ActiveUsersGeoSection() {
  try {
    const clusters = await fetchGeoClusters();
    return <ActiveUsersGeoMap clusters={clusters} />;
  } catch (error) {
    const message = await sectionErrorMessage(error);
    return <ActiveUsersGeoMap clusters={[]} loadError={message} />;
  }
}
