import { ListWorkspaceSkeleton } from '@/components/ui';
import { createDashboardLoadingPage } from '@/features/admin-shell/server';

export default async function WebhookLogsLoading() {
  return createDashboardLoadingPage({
    activeItem: 'webhook-logs',
    children: <ListWorkspaceSkeleton showStats={false} showToolbar={false} tableCols={4} />,
  });
}
