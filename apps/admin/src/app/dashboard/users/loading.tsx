import { ListWorkspaceSkeleton } from '@/components/ui';
import { createDashboardLoadingPage } from '@/features/admin-shell/server';

export default async function UsersLoading() {
  return createDashboardLoadingPage({
    activeItem: 'users',
    children: <ListWorkspaceSkeleton statCount={3} tableCols={8} />,
  });
}
