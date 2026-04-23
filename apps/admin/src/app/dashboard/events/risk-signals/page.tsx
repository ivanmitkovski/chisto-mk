import Link from 'next/link';
import { cookies } from 'next/headers';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell/constants';
import { SectionState } from '@/components/ui';
import { getCheckInRiskSignals } from '@/features/events/data/events-adapter';
import { SectionRefreshButton } from '@/features/events/components/section-refresh-button';
import styles from '@/features/events/components/events-workspace.module.css';

type PageProps = {
  searchParams: Promise<{ page?: string }>;
};

function formatDateTime(iso: string): string {
  const d = new Date(iso);
  return d.toLocaleString(undefined, {
    dateStyle: 'medium',
    timeStyle: 'short',
  });
}

function formatMetadata(meta: unknown): string {
  if (meta == null) {
    return '—';
  }
  if (typeof meta === 'string') {
    return meta;
  }
  try {
    return JSON.stringify(meta);
  } catch {
    return String(meta);
  }
}

export default async function CheckInRiskSignalsPage(props: PageProps) {
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';
  const params = await props.searchParams;
  const page = Math.max(1, parseInt(params.page ?? '1', 10) || 1);
  const limit = 25;

  let result: Awaited<ReturnType<typeof getCheckInRiskSignals>>;
  try {
    result = await getCheckInRiskSignals({ page, limit });
  } catch {
    return (
      <AdminShell
        title="Check-in risk signals"
        activeItem="events"
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

  const totalPages = Math.max(1, Math.ceil(result.total / result.limit));

  return (
    <AdminShell
      title="Check-in risk signals"
      activeItem="events"
      initialSidebarCollapsed={initialSidebarCollapsed}
    >
      <div className={styles.layout}>
        <p className={styles.riskSignalsIntro}>
          Non-expired signals from attendee check-in (for example redeem location far from the event
          site). Rows expire automatically; refresh to see the latest queue.
        </p>
        <p className={styles.backToEvents}>
          <Link href="/dashboard/events" className={styles.createHint}>
            ← Back to cleanup events
          </Link>
        </p>

        <div className={styles.tableCard}>
          <div className={styles.tableWrap}>
            {result.data.length === 0 ? (
              <div className={styles.empty}>No active check-in risk signals.</div>
            ) : (
              <table className={styles.table}>
                <thead>
                  <tr>
                    <th>Recorded</th>
                    <th>Expires</th>
                    <th>Signal</th>
                    <th>Event</th>
                    <th>Attendee</th>
                    <th>Metadata</th>
                  </tr>
                </thead>
                <tbody>
                  {result.data.map((row) => (
                    <tr key={row.id}>
                      <td className={styles.cellDateTime}>{formatDateTime(row.createdAt)}</td>
                      <td className={styles.cellDateTime}>{formatDateTime(row.expiresAt)}</td>
                      <td>{row.signalType}</td>
                      <td>
                        <Link href={`/dashboard/events/${row.eventId}`} className={styles.actionLink}>
                          {row.eventTitle || row.eventId}
                        </Link>
                      </td>
                      <td>{row.userDisplayName || row.userId}</td>
                      <td className={styles.metadataCell} title={formatMetadata(row.metadata)}>
                        {formatMetadata(row.metadata)}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
          <div className={styles.footer}>
            <p className={styles.meta}>
              {result.total} signal{result.total !== 1 ? 's' : ''} · page {result.page}
            </p>
            {result.total > result.limit ? (
              <nav className={styles.riskSignalsPager} aria-label="Pagination">
                {result.page > 1 ? (
                  <Link
                    className={styles.riskSignalsPagerLink}
                    href={
                      result.page === 2
                        ? '/dashboard/events/risk-signals'
                        : `/dashboard/events/risk-signals?page=${result.page - 1}`
                    }
                  >
                    Previous
                  </Link>
                ) : (
                  <span className={styles.riskSignalsPagerDisabled}>Previous</span>
                )}
                <span className={styles.riskSignalsPagerMeta}>
                  {result.page} / {totalPages}
                </span>
                {result.page < totalPages ? (
                  <Link
                    className={styles.riskSignalsPagerLink}
                    href={`/dashboard/events/risk-signals?page=${result.page + 1}`}
                  >
                    Next
                  </Link>
                ) : (
                  <span className={styles.riskSignalsPagerDisabled}>Next</span>
                )}
              </nav>
            ) : null}
          </div>
        </div>
      </div>
    </AdminShell>
  );
}
