import { GamificationSkeleton } from '@/components/ui';
import { createDashboardLoadingPage } from '@/features/admin-shell/server';

export default async function GamificationLoading() {
  return createDashboardLoadingPage({
    activeItem: 'gamification',
    children: <GamificationSkeleton />,
  });
}
