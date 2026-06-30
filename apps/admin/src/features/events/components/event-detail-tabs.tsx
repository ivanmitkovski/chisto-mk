'use client';

import { useCallback, useMemo, useState, type ReactNode } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useTranslations } from 'next-intl';
import {
  Button,
  ConfirmDialog,
  EmptyState,
  Input,
  PanelSkeleton,
  Pagination,
  SectionState,
  Tabs,
  useToast,
} from '@/components/ui';
import type {
  AuditLogAdminRow,
  CleanupEventParticipantAdminRow,
  CheckInRiskSignalRow,
  EventAnalyticsAdminPayload,
} from '@/features/events/data/events-adapter';
import {
  createEventNoteClient,
  deleteEventNoteClient,
  fetchCleanupEventAnalyticsClient,
  fetchCleanupEventAuditClient,
  fetchCleanupEventParticipantsClient,
  fetchEventNotesClient,
  fetchEventRiskSignalsClient,
  patchEventRiskSignalClient,
  removeEventParticipantClient,
} from '@/features/events/data/events-adapter-client';
import { cleanupEventMutationMessage } from '@/features/events/lib/cleanup-events-api-messages';
import {
  auditActionLabelKey,
  formatAuditMetadataSummary,
  sortAuditNewestFirst,
} from '@/features/events/lib/event-audit-display';
import { formatAdminDateTime, useAdminBcp47Locale } from '@/lib/i18n';
import { RiskSignalDetailsCell } from './risk-signal-details-cell';
import styles from './event-detail.module.css';

type EventDetailTabsProps = {
  eventId: string;
  canWrite: boolean;
  onParticipantCountChange?: () => void;
};

export function EventDetailTabs({ eventId, canWrite, onParticipantCountChange }: EventDetailTabsProps) {
  const tDetail = useTranslations('events.detail');
  const tRisk = useTranslations('events.riskSignals');
  const tErrors = useTranslations('errors');
  const tCommon = useTranslations('common');
  const locale = useAdminBcp47Locale();
  const router = useRouter();
  const { showToast } = useToast();

  const [loadedTab, setLoadedTab] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [analytics, setAnalytics] = useState<EventAnalyticsAdminPayload | null>(null);
  const [audit, setAudit] = useState<{
    data: AuditLogAdminRow[];
    meta: { total: number; page: number; limit: number };
  } | null>(null);
  const [auditPage, setAuditPage] = useState(1);
  const [participants, setParticipants] = useState<CleanupEventParticipantAdminRow[] | null>(null);
  const [participantQuery, setParticipantQuery] = useState('');
  const [removeTarget, setRemoveTarget] = useState<CleanupEventParticipantAdminRow | null>(null);
  const [removeBusy, setRemoveBusy] = useState(false);
  const [riskSignals, setRiskSignals] = useState<CheckInRiskSignalRow[] | null>(null);
  const [riskBusyId, setRiskBusyId] = useState<string | null>(null);
  const [notes, setNotes] = useState<
    Array<{ id: string; createdAt: string; body: string; authorEmail: string | null }> | null
  >(null);
  const [noteDraft, setNoteDraft] = useState('');
  const [noteBusy, setNoteBusy] = useState(false);

  const loadTab = useCallback(
    async (tabId: string, auditPageOverride?: number) => {
      setLoadedTab(tabId);
      setError(null);
      setLoading(true);
      try {
        if (tabId === 'analytics') {
          setAnalytics(await fetchCleanupEventAnalyticsClient(eventId));
        } else if (tabId === 'timeline') {
          const page = auditPageOverride ?? auditPage;
          const result = await fetchCleanupEventAuditClient(eventId, page, 50);
          setAudit(result);
          setAuditPage(result.meta.page);
        } else if (tabId === 'participants') {
          const r = await fetchCleanupEventParticipantsClient(eventId);
          setParticipants(r.data);
        } else if (tabId === 'risk') {
          const r = await fetchEventRiskSignalsClient({ eventId, status: 'all', limit: 50 });
          setRiskSignals(r.data);
        } else if (tabId === 'notes') {
          const r = await fetchEventNotesClient(eventId);
          setNotes(r.data);
        }
      } catch (e) {
        setError(cleanupEventMutationMessage(e, tDetail('loadDataFailed'), (key) => tErrors(key)));
      } finally {
        setLoading(false);
      }
    },
    [auditPage, eventId, tDetail, tErrors],
  );

  const filteredParticipants = useMemo(() => {
    if (!participants) return [];
    const q = participantQuery.trim().toLowerCase();
    if (!q) return participants;
    return participants.filter(
      (p) =>
        p.displayName.toLowerCase().includes(q) ||
        p.email.toLowerCase().includes(q) ||
        p.userId.toLowerCase().includes(q),
    );
  }, [participantQuery, participants]);

  async function confirmRemoveParticipant() {
    if (!removeTarget) return;
    setRemoveBusy(true);
    try {
      await removeEventParticipantClient(eventId, removeTarget.userId);
      setParticipants((prev) => prev?.filter((p) => p.userId !== removeTarget.userId) ?? []);
      setRemoveTarget(null);
      onParticipantCountChange?.();
      router.refresh();
      showToast({
        tone: 'success',
        title: tDetail('participantRemovedTitle'),
        message: tDetail('participantRemovedMessage'),
      });
    } catch (e) {
      showToast({
        tone: 'warning',
        title: tCommon('errorGeneric'),
        message: cleanupEventMutationMessage(e, tDetail('participantRemoveFailed'), (key) => tErrors(key)),
      });
    } finally {
      setRemoveBusy(false);
    }
  }

  async function submitNote() {
    const body = noteDraft.trim();
    if (!body) return;
    setNoteBusy(true);
    try {
      const created = await createEventNoteClient(eventId, body);
      setNotes((prev) => [created, ...(prev ?? [])]);
      setNoteDraft('');
      showToast({
        tone: 'success',
        title: tDetail('noteAddedTitle'),
        message: tDetail('noteAddedMessage'),
      });
    } catch (e) {
      showToast({
        tone: 'warning',
        title: tCommon('errorGeneric'),
        message: cleanupEventMutationMessage(e, tDetail('noteAddFailed'), (key) => tErrors(key)),
      });
    } finally {
      setNoteBusy(false);
    }
  }

  async function removeNote(noteId: string) {
    setNoteBusy(true);
    try {
      await deleteEventNoteClient(eventId, noteId);
      setNotes((prev) => prev?.filter((n) => n.id !== noteId) ?? []);
    } catch (e) {
      showToast({
        tone: 'warning',
        title: tCommon('errorGeneric'),
        message: cleanupEventMutationMessage(e, tDetail('noteDeleteFailed'), (key) => tErrors(key)),
      });
    } finally {
      setNoteBusy(false);
    }
  }

  async function patchRiskSignal(id: string, action: 'resolve' | 'dismiss') {
    setRiskBusyId(id);
    try {
      await patchEventRiskSignalClient(id, action);
      setRiskSignals((prev) =>
        prev?.map((row) =>
          row.id === id
            ? {
                ...row,
                resolvedAt: new Date().toISOString(),
                resolutionAction: action,
              }
            : row,
        ) ?? [],
      );
      showToast({
        tone: 'success',
        title: action === 'resolve' ? tRisk('toast.resolvedTitle') : tRisk('toast.dismissedTitle'),
        message: tRisk('toast.updatedMessage'),
      });
    } catch (e) {
      showToast({
        tone: 'warning',
        title: tRisk('toast.failedTitle'),
        message: cleanupEventMutationMessage(e, tRisk('toast.failedMessage'), (key) => tErrors(key)),
      });
    } finally {
      setRiskBusyId(null);
    }
  }

  function renderTabShell(content: ReactNode) {
    if (error) {
      return (
        <SectionState variant="error" message={error}>
          <Button variant="outline" size="sm" onClick={() => void loadTab(loadedTab ?? 'analytics')}>
            {tCommon('retry')}
          </Button>
        </SectionState>
      );
    }
    if (loading) {
      return <PanelSkeleton variant="list" listItems={4} />;
    }
    return content;
  }

  const tabItems = [
    {
      id: 'analytics',
      label: tDetail('analytics'),
      content: renderTabShell(
        analytics ? (
          <div className={styles.insightPanel}>
            <p className={styles.fieldHint}>
              {tDetail('joinersHeadline', {
                joiners: analytics.totalJoiners,
                checkedIn: analytics.checkedInCount,
                rate: analytics.attendanceRate,
              })}
            </p>
            {analytics.generatedAt ? (
              <p className={styles.fieldHint}>
                {tDetail('analyticsGeneratedAt', {
                  when: formatAdminDateTime(analytics.generatedAt, locale),
                })}
              </p>
            ) : null}
          </div>
        ) : (
          <EmptyState title={tDetail('noData')} />
        ),
      ),
    },
    {
      id: 'participants',
      label: tDetail('participantsTab'),
      content: renderTabShell(
        participants ? (
          <div className={styles.insightPanel}>
            <Input
              label={tDetail('searchParticipants')}
              value={participantQuery}
              onChange={(e) => setParticipantQuery(e.target.value)}
            />
            {filteredParticipants.length === 0 ? (
              <EmptyState title={tDetail('noData')} />
            ) : (
              <div className={styles.insightTableWrap}>
                <table className={styles.insightTable}>
                  <thead>
                    <tr>
                      <th scope="col">{tDetail('name')}</th>
                      <th scope="col">{tDetail('email')}</th>
                      <th scope="col">{tDetail('joined')}</th>
                      {canWrite ? <th scope="col">{tDetail('actionsColumn')}</th> : null}
                    </tr>
                  </thead>
                  <tbody>
                    {filteredParticipants.map((p) => (
                      <tr key={p.userId}>
                        <td>
                          <Link href={`/dashboard/users/${p.userId}`} className={styles.siteLink}>
                            {p.displayName}
                          </Link>
                        </td>
                        <td>{p.email}</td>
                        <td>{formatAdminDateTime(p.joinedAt, locale)}</td>
                        {canWrite ? (
                          <td>
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => setRemoveTarget(p)}
                            >
                              {tDetail('removeParticipant')}
                            </Button>
                          </td>
                        ) : null}
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        ) : (
          <EmptyState title={tDetail('noData')} />
        ),
      ),
    },
    {
      id: 'risk',
      label: tDetail('riskSignalsTab'),
      content: renderTabShell(
        riskSignals ? (
          riskSignals.length === 0 ? (
            <EmptyState title={tDetail('noRiskSignals')} />
          ) : (
            <div className={styles.insightTableWrap}>
              <table className={styles.insightTable}>
                <thead>
                  <tr>
                    <th scope="col">{tRisk('columns.recorded')}</th>
                    <th scope="col">{tRisk('columns.attendee')}</th>
                    <th scope="col">{tRisk('columns.signal')}</th>
                    <th scope="col">{tRisk('columns.actions')}</th>
                  </tr>
                </thead>
                <tbody>
                  {riskSignals.map((row) => (
                    <tr key={row.id}>
                      <td>{formatAdminDateTime(row.createdAt, locale)}</td>
                      <td>{row.userDisplayName}</td>
                      <td>
                        <RiskSignalDetailsCell row={row} />
                      </td>
                      <td>
                        {canWrite && !row.resolvedAt ? (
                          <div className={styles.inlineActions}>
                            <Button
                              size="sm"
                              variant="outline"
                              isLoading={riskBusyId === row.id}
                              onClick={() => void patchRiskSignal(row.id, 'resolve')}
                            >
                              {tRisk('resolve')}
                            </Button>
                            <Button
                              size="sm"
                              variant="ghost"
                              disabled={riskBusyId === row.id}
                              onClick={() => void patchRiskSignal(row.id, 'dismiss')}
                            >
                              {tRisk('dismiss')}
                            </Button>
                          </div>
                        ) : (
                          row.resolutionAction ?? '—'
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )
        ) : (
          <EmptyState title={tDetail('noData')} />
        ),
      ),
    },
    {
      id: 'notes',
      label: tDetail('notesTab'),
      content: renderTabShell(
        <div className={styles.insightPanel}>
          {canWrite ? (
            <div className={styles.noteComposer}>
              <label className={styles.field}>
                <span className={styles.fieldLabel}>{tDetail('addNote')}</span>
                <textarea
                  className={styles.textarea}
                  value={noteDraft}
                  rows={3}
                  onChange={(e) => setNoteDraft(e.target.value)}
                />
              </label>
              <Button size="sm" isLoading={noteBusy} disabled={!noteDraft.trim()} onClick={() => void submitNote()}>
                {tDetail('saveNote')}
              </Button>
            </div>
          ) : null}
          {notes && notes.length === 0 ? (
            <EmptyState title={tDetail('noNotes')} />
          ) : (
            <ul className={styles.notesList}>
              {(notes ?? []).map((note) => (
                <li key={note.id} className={styles.noteItem}>
                  <p className={styles.noteMeta}>
                    {note.authorEmail ?? tDetail('unknownAuthor')} ·{' '}
                    {formatAdminDateTime(note.createdAt, locale)}
                  </p>
                  <p className={styles.noteBody}>{note.body}</p>
                  {canWrite ? (
                    <Button variant="ghost" size="sm" disabled={noteBusy} onClick={() => void removeNote(note.id)}>
                      {tCommon('delete')}
                    </Button>
                  ) : null}
                </li>
              ))}
            </ul>
          )}
        </div>
      ),
    },
    {
      id: 'timeline',
      label: tDetail('activityTimeline'),
      content: renderTabShell(
        audit ? (
          <div className={styles.insightPanel}>
            <ul className={styles.timelineList}>
              {sortAuditNewestFirst(audit.data).map((row) => {
                const summary = formatAuditMetadataSummary(row.metadata);
                return (
                  <li key={row.id} className={styles.timelineItem}>
                    <p className={styles.timelineTitle}>{tDetail(auditActionLabelKey(row.action))}</p>
                    <p className={styles.fieldHint}>
                      {formatAdminDateTime(row.createdAt, locale)}
                      {row.actorEmail ? ` · ${row.actorEmail}` : ''}
                    </p>
                    {summary ? <p className={styles.timelineSummary}>{summary}</p> : null}
                  </li>
                );
              })}
            </ul>
            {audit.meta.total > audit.meta.limit ? (
              <div className={styles.insightPager}>
                <Pagination
                  totalPages={Math.ceil(audit.meta.total / audit.meta.limit)}
                  currentPage={audit.meta.page}
                  onPageChange={(page) => void loadTab('timeline', page)}
                />
              </div>
            ) : null}
          </div>
        ) : (
          <EmptyState title={tDetail('noData')} />
        ),
      ),
    },
  ];

  return (
    <section className={styles.sectionCard}>
      <span className={styles.sectionLabel}>{tDetail('insights')}</span>
      <Tabs
        ariaLabel={tDetail('insights')}
        items={tabItems.map((item) => ({
          ...item,
          content: (
            <>
              {loadedTab !== item.id ? (
                <div className={styles.tabLazyTrigger}>
                  <Button variant="outline" size="sm" onClick={() => void loadTab(item.id)}>
                    {tDetail('loadTab', { tab: item.label })}
                  </Button>
                </div>
              ) : (
                item.content
              )}
            </>
          ),
        }))}
      />

      <ConfirmDialog
        open={removeTarget != null}
        title={tDetail('removeParticipantTitle')}
        description={tDetail('removeParticipantDescription', {
          name: removeTarget?.displayName ?? '',
        })}
        confirmLabel={tDetail('removeParticipantConfirm')}
        cancelLabel={tCommon('cancel')}
        tone="danger"
        isLoading={removeBusy}
        onConfirm={() => void confirmRemoveParticipant()}
        onClose={() => setRemoveTarget(null)}
      />
    </section>
  );
}
