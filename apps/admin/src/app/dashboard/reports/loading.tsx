import { ReportsWorkspaceSkeleton } from '@/components/ui';
import { createDashboardLoadingPage } from '@/features/admin-shell/server';

export default async function ReportsLoading() {
  return createDashboardLoadingPage({
    activeItem: 'reports',
    children: <ReportsWorkspaceSkeleton />,
  });
}
