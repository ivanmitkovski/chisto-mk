import { ListWorkspaceSkeleton } from '@/components/ui';
import { createDashboardLoadingPage } from '@/features/admin-shell/server';

export default async function NewsLoading() {
  return createDashboardLoadingPage({
    activeItem: 'news',
    children: <ListWorkspaceSkeleton statCount={0} showStats={false} tableCols={6} />,
  });
}
