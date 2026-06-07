import { SplitReviewSkeleton } from '@/components/ui';
import { createDashboardLoadingPage } from '@/features/admin-shell/server';

export default async function DuplicateReportsLoading() {
  return createDashboardLoadingPage({
    activeItem: 'duplicates',
    children: <SplitReviewSkeleton queueItems={6} />,
  });
}
