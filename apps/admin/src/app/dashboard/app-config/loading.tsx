import { AppConfigSkeleton } from '@/components/ui';
import { createDashboardLoadingPage } from '@/features/admin-shell/server';

export default async function AppConfigLoading() {
  return createDashboardLoadingPage({
    activeItem: 'app-config',
    children: <AppConfigSkeleton />,
  });
}
