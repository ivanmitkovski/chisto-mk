import { ListWorkspaceSkeleton } from '@/components/ui';
import { createDashboardLoadingPage } from '@/features/admin-shell/server';

export default async function SitesLoading() {
  return createDashboardLoadingPage({
    activeItem: 'sites',
    children: <ListWorkspaceSkeleton statCount={4} tableCols={5} />,
  });
}
