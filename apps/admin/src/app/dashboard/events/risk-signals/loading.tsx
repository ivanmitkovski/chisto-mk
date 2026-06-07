import { RiskSignalsSkeleton } from '@/components/ui';
import { createDashboardLoadingPage } from '@/features/admin-shell/server';

export default async function RiskSignalsLoading() {
  return createDashboardLoadingPage({
    activeItem: 'risk-signals',
    children: <RiskSignalsSkeleton />,
  });
}
