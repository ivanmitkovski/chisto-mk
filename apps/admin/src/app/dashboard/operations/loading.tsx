import { OperationsSkeleton } from '@/components/ui';
import { createDashboardLoadingPage } from '@/features/admin-shell/server';

export default async function OperationsLoading() {
  return createDashboardLoadingPage({
    activeItem: 'operations',
    children: <OperationsSkeleton />,
  });
}
