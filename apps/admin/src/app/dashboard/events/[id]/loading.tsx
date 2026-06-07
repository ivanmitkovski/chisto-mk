import { getTranslations } from 'next-intl/server';
import { DetailMultiSectionSkeleton } from '@/components/ui';
import { createDashboardLoadingPage } from '@/features/admin-shell/server';

export default async function EventDetailLoading() {
  const t = await getTranslations('events');
  return createDashboardLoadingPage({
    title: t('detailTitle'),
    activeItem: 'events',
    children: <DetailMultiSectionSkeleton />,
  });
}
