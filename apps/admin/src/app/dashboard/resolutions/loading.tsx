import { ListWorkspaceSkeleton } from '@/components/ui';
import { createDashboardLoadingPage } from '@/features/admin-shell/server';

export default async function ResolutionsLoading() {
  return createDashboardLoadingPage({
    activeItem: 'resolutions',
    children: <ListWorkspaceSkeleton showStats={false} tableCols={6} />,
  });
}
