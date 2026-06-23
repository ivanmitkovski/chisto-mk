import { DetailFormSkeleton } from '@/components/ui';
import { createDashboardLoadingPage } from '@/features/admin-shell/server';

export default async function NewsEditorLoading() {
  return createDashboardLoadingPage({
    activeItem: 'news',
    children: <DetailFormSkeleton />,
  });
}
