import { UgcModerationSkeleton } from '@/components/ui';
import { createDashboardLoadingPage } from '@/features/admin-shell/server';

export default async function UgcModerationLoading() {
  return createDashboardLoadingPage({
    activeItem: 'moderation',
    children: <UgcModerationSkeleton />,
  });
}
