import { getTranslations } from 'next-intl/server';
import { OverviewSkeleton } from '@/components/ui';
import { createDashboardLoadingPage } from '@/features/admin-shell/server';

export default async function DashboardLoading() {
  const t = await getTranslations('dashboard');
  return createDashboardLoadingPage({
    title: t('pageTitle'),
    activeItem: 'dashboard',
    children: <OverviewSkeleton />,
  });
}
