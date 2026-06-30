import { createDashboardLoadingPage } from '@/features/admin-shell/server';
import { ActiveUsersWorkspaceSkeleton } from '@/features/active-users/components/active-users-workspace-skeleton';

export default async function ActiveUsersLoading() {
  return createDashboardLoadingPage({
    activeItem: 'active-users',
    children: <ActiveUsersWorkspaceSkeleton />,
  });
}
