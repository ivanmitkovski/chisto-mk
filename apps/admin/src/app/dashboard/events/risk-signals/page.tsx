import { AdminShell } from '@/features/admin-shell';
import { readDashboardShellState } from '@/features/admin-shell/server';
import { SectionState } from '@/components/ui';
import { ApiError } from '@/lib/api';
import { redirect } from 'next/navigation';
import {
  getCheckInRiskSignals,
  RiskSignalsWorkspace,
  SectionRefreshButton,
  type CheckInRiskSignalStatusFilter,
} from '@/features/events';
import { ADMIN_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import { requirePagePermission } from '@/lib/auth/rbac/server';

type PageProps = {
  searchParams: Promise<{ page?: string; status?: string }>;
};

function parseStatusFilter(value: string | undefined): CheckInRiskSignalStatusFilter {
  if (value === 'resolved' || value === 'all') return value;
  return 'active';
}

export default async function CheckInRiskSignalsPage(props: PageProps) {
  await requirePagePermission(ADMIN_PERMISSIONS['events:read']);
  const { initialSidebarCollapsed } = await readDashboardShellState();
  const params = await props.searchParams;
  const page = Math.max(1, Number.parseInt(params.page ?? '1', 10) || 1);
  const statusFilter = parseStatusFilter(params.status);
  const limit = 25;

  let result: Awaited<ReturnType<typeof getCheckInRiskSignals>>;
  try {
    result = await getCheckInRiskSignals({ page, limit, status: statusFilter });
  } catch (error) {
    if (error instanceof ApiError && (error.status === 401 || error.status === 403)) {
      redirect('/login');
    }
    return (
      <AdminShell
        title="Check-in risk signals"
        activeItem="risk-signals"
        initialSidebarCollapsed={initialSidebarCollapsed}
      >
        <SectionState
          variant="error"
          message="Unable to load risk signals. Check your connection or sign in again."
        >
          <SectionRefreshButton />
        </SectionState>
      </AdminShell>
    );
  }

  return (
    <AdminShell
      title="Check-in risk signals"
      activeItem="risk-signals"
      initialSidebarCollapsed={initialSidebarCollapsed}
    >
      <RiskSignalsWorkspace initialResult={result} statusFilter={statusFilter} />
    </AdminShell>
  );
}
