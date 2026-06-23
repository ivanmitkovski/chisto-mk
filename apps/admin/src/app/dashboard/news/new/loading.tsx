import { getTranslations } from 'next-intl/server';
import { DetailFormSkeleton } from '@/components/ui';
import { createDashboardLoadingPage } from '@/features/admin-shell/server';

export default async function NewNewsPostLoading() {
  const t = await getTranslations('news');
  return createDashboardLoadingPage({
    title: t('create.title'),
    activeItem: 'news',
    children: <DetailFormSkeleton />,
  });
}
