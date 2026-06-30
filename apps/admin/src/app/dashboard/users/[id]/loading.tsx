import { getTranslations } from 'next-intl/server';
import { DetailTabsSkeleton } from '@/components/ui';
import { createDashboardLoadingPage } from '@/features/admin-shell/server';

export default async function UserDetailLoading() {
  const t = await getTranslations('users');
  return createDashboardLoadingPage({
    title: t('detailTitle'),
    activeItem: 'users',
    children: <DetailTabsSkeleton />,
  });
}
