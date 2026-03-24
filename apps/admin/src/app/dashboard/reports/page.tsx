import type { Metadata } from 'next';
import { cookies } from 'next/headers';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell/constants';
import { SectionState } from '@/components/ui';
import { getReports } from '@/features/reports';
import { ReportsPageClient } from '@/features/reports/components/reports-page-client';
import styles from './reports-page.module.css';

export const metadata: Metadata = {
  title: 'Reports',
};

function reportsErrorShell(
  initialSidebarCollapsed: boolean,
  message: string,
) {
  return (
    <AdminShell title="Reports" activeItem="reports" initialSidebarCollapsed={initialSidebarCollapsed}>
      <div className={styles.page}>
        <SectionState variant="error" message={message} />
      </div>
    </AdminShell>
  );
}

type ReportsPageProps = {
  searchParams: Promise<{ siteId?: string }>;
};

export default async function ReportsPage(props: ReportsPageProps) {
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';
  const params = await props.searchParams;
  const siteId = params.siteId;

  let reports: Awaited<ReturnType<typeof getReports>>;
  try {
    reports = await getReports(siteId ? { siteId } : undefined);
  } catch {
    return reportsErrorShell(
      initialSidebarCollapsed,
      'Unable to load reports. Please try again or sign in again.',
    );
  }

  return (
    <AdminShell title="Reports" activeItem="reports" initialSidebarCollapsed={initialSidebarCollapsed}>
      <ReportsPageClient
        reports={reports}
        {...(siteId ? { siteIdFilter: siteId } : {})}
      />
    </AdminShell>
  );
}
