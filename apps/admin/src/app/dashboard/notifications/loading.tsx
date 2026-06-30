import { NotificationsSkeleton } from '@/components/ui';
import { createDashboardLoadingPage } from '@/features/admin-shell/server';

export default async function NotificationsLoading() {
  return createDashboardLoadingPage({
    activeItem: 'notifications',
    children: <NotificationsSkeleton />,
  });
}
