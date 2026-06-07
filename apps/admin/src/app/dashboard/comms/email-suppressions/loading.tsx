import { ListWorkspaceSkeleton } from '@/components/ui';
import { createDashboardLoadingPage } from '@/features/admin-shell/server';

export default async function EmailSuppressionsLoading() {
  return createDashboardLoadingPage({
    activeItem: 'email-suppressions',
    children: <ListWorkspaceSkeleton showStats={false} showToolbar tableCols={5} />,
  });
}
