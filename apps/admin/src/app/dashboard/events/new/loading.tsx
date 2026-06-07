import { getTranslations } from 'next-intl/server';
import { DetailFormSkeleton } from '@/components/ui';
import { createDashboardLoadingPage } from '@/features/admin-shell/server';

export default async function NewEventLoading() {
  const t = await getTranslations('events');
  return createDashboardLoadingPage({
    title: t('newPageTitle'),
    activeItem: 'events',
    children: <DetailFormSkeleton />,
  });
}
