import { ListWorkspaceSkeleton } from '@/components/ui';
import { createDashboardLoadingPage } from '@/features/admin-shell/server';

export default async function ActiveUsersLoading() {
  return createDashboardLoadingPage({
    activeItem: 'active-users',
    children: <ListWorkspaceSkeleton statCount={4} tableCols={7} />,
  });
}
