import { getTranslations } from 'next-intl/server';
import { DetailFormSkeleton } from '@/components/ui';
import { createDashboardLoadingPage } from '@/features/admin-shell/server';

export default async function NewsPreviewLoading() {
  const t = await getTranslations('news');
  return createDashboardLoadingPage({
    title: t('preview.fullPageTitle'),
    activeItem: 'news',
    children: <DetailFormSkeleton />,
  });
}
