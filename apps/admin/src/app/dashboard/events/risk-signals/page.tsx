import type { Metadata } from 'next';
import { getTranslations } from 'next-intl/server';
import { AdminShell } from '@/features/admin-shell';
import { readDashboardShellState } from '@/features/admin-shell/server';
import { SectionState } from '@/components/ui';
import { ApiError } from '@/lib/api';
import { redirect } from 'next/navigation';
import { getCheckInRiskSignals } from '@/features/events/data/events-adapter';
import {
  RiskSignalsWorkspace,
  SectionRefreshButton,
  type CheckInRiskSignalStatusFilter,
} from '@/features/events';
import { ADMIN_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import { requirePagePermission } from '@/lib/auth/rbac/server';
import { handleServerLoadError } from '@/lib/server/handle-server-load-error';

type PageProps = {
  searchParams: Promise<{ page?: string; status?: string }>;
};

function parseStatusFilter(value: string | undefined): CheckInRiskSignalStatusFilter {
  if (value === 'resolved' || value === 'all') return value;
  return 'active';
}

export async function generateMetadata(): Promise<Metadata> {
  const t = await getTranslations('events.riskSignals');
  return { title: t('pageTitle') };
}

export default async function CheckInRiskSignalsPage(props: PageProps) {
  await requirePagePermission(ADMIN_PERMISSIONS['events:read']);
  const tEvents = await getTranslations('events.riskSignals');
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
    const message = await handleServerLoadError(error, { fallbackMessageKey: 'unableToLoadRiskSignals' });
    return (
      <AdminShell
        title={tEvents('pageTitle')}
        activeItem="risk-signals"
        initialSidebarCollapsed={initialSidebarCollapsed}
      >
        <SectionState variant="error" message={message}>
          <SectionRefreshButton />
        </SectionState>
      </AdminShell>
    );
  }

  return (
    <AdminShell
      title={tEvents('pageTitle')}
      activeItem="risk-signals"
      initialSidebarCollapsed={initialSidebarCollapsed}
    >
      <RiskSignalsWorkspace initialResult={result} statusFilter={statusFilter} />
    </AdminShell>
  );
}
