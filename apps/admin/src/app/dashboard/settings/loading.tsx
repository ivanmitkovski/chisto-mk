import { SettingsConsoleSkeleton } from '@/components/ui';
import { createDashboardLoadingPage } from '@/features/admin-shell/server';

export default async function SettingsLoading() {
  return createDashboardLoadingPage({
    activeItem: 'settings',
    children: <SettingsConsoleSkeleton />,
  });
}
