import { getTranslations } from 'next-intl/server';
import { DetailMultiSectionSkeleton } from '@/components/ui';
import { createDashboardLoadingPage } from '@/features/admin-shell/server';

export default async function ReportDetailLoading() {
  const t = await getTranslations('reports');
  return createDashboardLoadingPage({
    title: t('detailTitle'),
    activeItem: 'reports',
    children: <DetailMultiSectionSkeleton />,
  });
}
