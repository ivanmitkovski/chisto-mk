import { BroadcastsSkeleton } from '@/components/ui';
import { createDashboardLoadingPage } from '@/features/admin-shell/server';

export default async function BroadcastsLoading() {
  return createDashboardLoadingPage({
    activeItem: 'broadcasts',
    children: <BroadcastsSkeleton />,
  });
}
