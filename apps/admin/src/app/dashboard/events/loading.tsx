import { ListWorkspaceSkeleton } from '@/components/ui';
import { createDashboardLoadingPage } from '@/features/admin-shell/server';

export default async function EventsLoading() {
  return createDashboardLoadingPage({
    activeItem: 'events',
    children: <ListWorkspaceSkeleton statCount={5} tableCols={7} />,
  });
}
