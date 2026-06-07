import { TeamSkeleton } from '@/components/ui';
import { createDashboardLoadingPage } from '@/features/admin-shell/server';

export default async function TeamLoading() {
  return createDashboardLoadingPage({
    activeItem: 'team',
    children: <TeamSkeleton />,
  });
}
