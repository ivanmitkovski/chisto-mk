import { getTranslations } from 'next-intl/server';
import { DetailMultiSectionSkeleton } from '@/components/ui';
import { createDashboardLoadingPage } from '@/features/admin-shell/server';

export default async function SiteDetailLoading() {
  const t = await getTranslations('sites');
  return createDashboardLoadingPage({
    title: t('detailTitle'),
    activeItem: 'sites',
    children: <DetailMultiSectionSkeleton />,
  });
}
