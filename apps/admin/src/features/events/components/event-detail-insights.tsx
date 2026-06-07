'use client';

import { useCallback, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useTranslations } from 'next-intl';
import { Button, ConfirmDialog, PanelSkeleton, Pagination } from '@/components/ui';
import type {
  AuditLogAdminRow,
  CleanupEventParticipantAdminRow,
  EventAnalyticsAdminPayload,
} from '@/features/events/data/events-adapter';
import {
  fetchCleanupEventAnalyticsClient,
  fetchCleanupEventAuditClient,
  fetchCleanupEventParticipantsClient,
} from '@/features/events/data/events-adapter-client';
import { adminBrowserFetch } from '@/lib/api';
import { formatAdminDateTime, useAdminBcp47Locale } from '@/lib/i18n';
import { cleanupEventMutationMessage } from '@/features/events/lib/cleanup-events-api-messages';
import styles from './event-detail.module.css';

type InsightTab = 'analytics' | 'audit' | 'participants' | 'lifecycle';

function formatAuditMetadata(meta: unknown): string {
  if (meta == null) {
    return '—';
  }
  try {
    const s = JSON.stringify(meta);
    return s.length > 200 ? `${s.slice(0, 200)}…` : s;
  } catch {
    return String(meta);
  }
}

export function EventDetailInsights(props: {
  eventId: string;
  lifecycleStatus: string;
  canWrite: boolean;
}) {
  const router = useRouter();
  const t = useTranslations('events.detail');
  const tErrors = useTranslations('errors');
  const locale = useAdminBcp47Locale();
  const [tab, setTab] = useState<InsightTab | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [analytics, setAnalytics] = useState<EventAnalyticsAdminPayload | null>(null);
  const [audit, setAudit] = useState<{ data: AuditLogAdminRow[]; meta: { total: number; page: number; limit: number } } | null>(null);
  const [auditPage, setAuditPage] = useState(1);
  const [participants, setParticipants] = useState<CleanupEventParticipantAdminRow[] | null>(null);
  const [lifecycleBusy, setLifecycleBusy] = useState(false);
  const [cancelOpen, setCancelOpen] = useState(false);

  const loadTab = useCallback(async (next: InsightTab, auditPageOverride?: number) => {
    setTab(next);
    setError(null);
    setLoading(true);
    try {
      if (next === 'analytics') {
        setAnalytics(await fetchCleanupEventAnalyticsClient(props.eventId));
      } else if (next === 'audit') {
        const page = auditPageOverride ?? auditPage;
        const result = await fetchCleanupEventAuditClient(props.eventId, page, 50);
        setAudit(result);
        setAuditPage(result.meta.page);
      } else if (next === 'participants') {
        const r = await fetchCleanupEventParticipantsClient(props.eventId);
        setParticipants(r.data);
      }
    } catch (e) {
      setError(cleanupEventMutationMessage(e, t('loadDataFailed'), (key) => tErrors(key)));
    } finally {
      setLoading(false);
    }
  }, [auditPage, props.eventId, t, tErrors]);

  async function goToAuditPage(page: number) {
    setAuditPage(page);
    await loadTab('audit', page);
  }

  async function confirmCancelEvent() {
    if (!props.canWrite) {
      return;
    }
    setLifecycleBusy(true);
    setError(null);
    try {
      await adminBrowserFetch(`/admin/cleanup-events/${props.eventId}`, {
        method: 'PATCH',
        body: { lifecycleStatus: 'CANCELLED' },
      });
      setCancelOpen(false);
      router.refresh();
    } catch (e) {
      setError(cleanupEventMutationMessage(e, t('cancelFailed'), (key) => tErrors(key)));
    } finally {
      setLifecycleBusy(false);
    }
  }

  const showCancel =
    props.canWrite &&
    props.lifecycleStatus !== 'CANCELLED' &&
    props.lifecycleStatus !== 'COMPLETED';

  return (
    <section className={styles.sectionCard} aria-label={t('insights')}>
      <span className={styles.sectionLabel}>{t('insights')}</span>
      <div className={styles.insightActions}>
        <Button type="button" variant="outline" size="sm" onClick={() => void loadTab('analytics')}>
          {t('analytics')}
        </Button>
        <Button type="button" variant="outline" size="sm" onClick={() => void loadTab('audit')}>
          {t('auditLog')}
        </Button>
        <Button type="button" variant="outline" size="sm" onClick={() => void loadTab('participants')}>
          {t('participantsTab')}
        </Button>
        <Button type="button" variant="outline" size="sm" onClick={() => setTab('lifecycle')}>
          {t('lifecycle')}
        </Button>
        {tab != null ? (
          <Button type="button" variant="ghost" size="sm" onClick={() => setTab(null)}>
            {t('closePanel')}
          </Button>
        ) : null}
      </div>
      {error ? (
        <p className={styles.fieldError} role="alert">
          {error}
        </p>
      ) : null}
      {loading ? (
        <PanelSkeleton variant="list" listItems={3} />
      ) : null}
      {tab === 'analytics' && analytics != null ? (
        <div className={styles.insightPanel}>
          <p className={styles.fieldHint}>
            {t('joinersHeadline', {
              joiners: analytics.totalJoiners,
              checkedIn: analytics.checkedInCount,
              rate: analytics.attendanceRate,
            })}
          </p>
          <p className={styles.fieldHint}>{t('analyticsHint')}</p>
          <h3 className={styles.insightSubheading}>{t('cumulativeJoiners')}</h3>
          <div className={styles.insightTableWrap}>
            <table className={styles.insightTable}>
              <thead>
                <tr>
                  <th scope="col">{t('timeUtc')}</th>
                  <th scope="col">{t('cumulative')}</th>
                </tr>
              </thead>
              <tbody>
                {analytics.joinersCumulative.length === 0 ? (
                  <tr>
                    <td colSpan={2}>{t('noData')}</td>
                  </tr>
                ) : (
                  analytics.joinersCumulative.map((row) => (
                    <tr key={row.at}>
                      <td>{new Date(row.at).toISOString()}</td>
                      <td>{row.cumulativeJoiners}</td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
          <h3 className={styles.insightSubheading}>{t('checkInsByHour')}</h3>
          <div className={styles.insightTableWrap}>
            <table className={styles.insightTable}>
              <thead>
                <tr>
                  <th scope="col">{t('hour')}</th>
                  <th scope="col">{t('count')}</th>
                </tr>
              </thead>
              <tbody>
                {(() => {
                  const rows = analytics.checkInsByHour.filter((h) => h.count > 0);
                  return rows.length === 0 ? (
                    <tr>
                      <td colSpan={2}>{t('noData')}</td>
                    </tr>
                  ) : (
                    rows.map((h) => (
                      <tr key={h.hour}>
                        <td>{h.hour}</td>
                        <td>{h.count}</td>
                      </tr>
                    ))
                  );
                })()}
              </tbody>
            </table>
          </div>
        </div>
      ) : null}
      {tab === 'audit' && audit != null ? (
        <div className={styles.insightPanel}>
          <p className={styles.fieldHint}>
            {t('auditEntriesMeta', { count: audit.meta.total, page: audit.meta.page })}
          </p>
          <div className={styles.insightTableWrap}>
            <table className={styles.insightTable}>
              <thead>
                <tr>
                  <th scope="col">{t('when')}</th>
                  <th scope="col">{t('action')}</th>
                  <th scope="col">{t('actor')}</th>
                  <th scope="col">{t('resource')}</th>
                  <th scope="col">{t('metadata')}</th>
                </tr>
              </thead>
              <tbody>
                {audit.data.length === 0 ? (
                  <tr>
                    <td colSpan={5}>{t('noData')}</td>
                  </tr>
                ) : (
                  audit.data.map((row) => (
                    <tr key={row.id}>
                      <td>{formatAdminDateTime(row.createdAt, locale)}</td>
                      <td>{row.action}</td>
                      <td>{row.actorEmail ?? '—'}</td>
                      <td>
                        {row.resourceType}
                        {row.resourceId ? ` · ${row.resourceId}` : ''}
                      </td>
                      <td title={formatAuditMetadata(row.metadata)}>{formatAuditMetadata(row.metadata)}</td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
          {audit.meta.total > audit.meta.limit ? (
            <div className={styles.insightPager}>
              <Pagination
                totalPages={Math.ceil(audit.meta.total / audit.meta.limit)}
                currentPage={audit.meta.page}
                onPageChange={(page) => void goToAuditPage(page)}
              />
            </div>
          ) : null}
        </div>
      ) : null}
      {tab === 'participants' && participants != null ? (
        <div className={styles.insightPanel}>
          <table className={styles.insightTable}>
            <thead>
              <tr>
                <th scope="col">{t('name')}</th>
                <th scope="col">{t('email')}</th>
                <th scope="col">{t('joined')}</th>
              </tr>
            </thead>
            <tbody>
              {participants.length === 0 ? (
                <tr>
                  <td colSpan={3}>{t('noData')}</td>
                </tr>
              ) : (
                participants.map((p) => (
                  <tr key={p.userId}>
                    <td>{p.displayName}</td>
                    <td>{p.email}</td>
                    <td>{formatAdminDateTime(p.joinedAt, locale)}</td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      ) : null}
      {tab === 'lifecycle' ? (
        <div className={styles.insightPanel}>
          <p className={styles.fieldHint}>{t('currentLifecycle', { status: props.lifecycleStatus })}</p>
          {showCancel ? (
            <Button type="button" variant="outline" disabled={lifecycleBusy} onClick={() => setCancelOpen(true)}>
              {t('cancelEvent')}
            </Button>
          ) : (
            <p className={styles.fieldHint}>{t('noLifecycleActions')}</p>
          )}
        </div>
      ) : null}

      <ConfirmDialog
        open={cancelOpen}
        title={t('cancelConfirmTitle')}
        description={t('cancelConfirmDescription')}
        confirmLabel={t('confirmCancel')}
        cancelLabel={t('keepEvent')}
        tone="danger"
        isLoading={lifecycleBusy}
        onConfirm={() => void confirmCancelEvent()}
        onClose={() => setCancelOpen(false)}
      />
    </section>
  );
}
