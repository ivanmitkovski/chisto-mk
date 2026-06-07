'use client';

import { useCallback, useEffect, useState } from 'react';
import { useTranslations } from 'next-intl';
import { Button, Card, ConfirmDialog, Pagination, SectionState, useToast } from '@/components/ui';
import { Can } from '@/lib/auth/rbac';
import { adminBrowserFetch } from '@/lib/api';
import type { AuditEntry } from '@/features/users/data/users-adapter';
import { UserDetailForm } from './user-detail-form';
import { UserPointsPanel } from './user-points-panel';
import type { UserPointLedgerEntry } from '@/features/gamification';
import { formatAdminDateTime, useAdminBcp47Locale } from '@/lib/i18n';
import styles from './user-detail-tabs.module.css';

type SessionEntry = {
  id: string;
  createdAt: string;
  deviceInfo: string | null;
  ipAddress: string | null;
  expiresAt: string;
  revokedAt: string | null;
};

type TabId = 'profile' | 'privacy' | 'points' | 'sessions' | 'audit';

type UserDetailTabsProps = {
  userId: string;
  initialFirstName: string;
  initialLastName: string;
  initialRole: string;
  initialStatus: string;
  initialPhoneNumber: string;
  email: string;
  pointsBalance: number;
  totalPointsEarned: number;
  isPhoneVerified: boolean;
  organizerCertifiedAt: string | null;
  termsAcceptedAt: string | null;
  termsVersion: string | null;
  requiresTermsAcceptance: boolean;
  privacyAcceptedAt: string | null;
  createdAt: string;
  reportsCount: number;
  sessionsCount: number;
  canViewSessions: boolean;
  audit: { data: AuditEntry[]; meta: { page: number; limit: number; total: number } };
  auditError?: string | null;
  sessions: SessionEntry[];
  sessionsError?: string | null;
  pointLedger: UserPointLedgerEntry[];
  pointLedgerTotal: number;
  pointLedgerPage?: number;
  pointLedgerLimit?: number;
  pointsError?: string | null;
};

const AUDIT_PAGE_SIZE = 20;

export function UserDetailTabs(props: UserDetailTabsProps) {
  const t = useTranslations('users');
  const tCommon = useTranslations('common');
  const locale = useAdminBcp47Locale();
  const [activeTab, setActiveTab] = useState<TabId>('profile');
  const [profileDirty, setProfileDirty] = useState(false);
  const [pendingTab, setPendingTab] = useState<TabId | null>(null);
  const [discardConfirmOpen, setDiscardConfirmOpen] = useState(false);
  const [auditPage, setAuditPage] = useState(props.audit.meta.page);
  const [auditRows, setAuditRows] = useState(props.audit.data);
  const [auditTotal, setAuditTotal] = useState(props.audit.meta.total);
  const [auditLoading, setAuditLoading] = useState(false);
  const [sessionRows, setSessionRows] = useState(props.sessions);
  const [revokeTarget, setRevokeTarget] = useState<SessionEntry | null>(null);
  const [revokeBusy, setRevokeBusy] = useState(false);
  const { showToast } = useToast();

  useEffect(() => {
    setSessionRows(props.sessions);
  }, [props.sessions]);

  const loadAuditPage = useCallback(
    async (page: number) => {
      setAuditLoading(true);
      try {
        const result = await adminBrowserFetch<{
          data: AuditEntry[];
          meta: { page: number; limit: number; total: number };
        }>(`/admin/users/${props.userId}/audit?page=${page}&limit=${AUDIT_PAGE_SIZE}`);
        setAuditRows(result.data);
        setAuditTotal(result.meta.total);
        setAuditPage(page);
      } finally {
        setAuditLoading(false);
      }
    },
    [props.userId],
  );

  const formatDateTime = (value: string | null): string =>
    value ? formatAdminDateTime(value, locale) : '—';

  const tabItems: Array<{ id: TabId; label: string }> = [
    { id: 'profile', label: t('detail.tabs.profile') },
    { id: 'privacy', label: t('detail.tabs.privacy') },
    { id: 'points', label: t('detail.tabs.points') },
    ...(props.canViewSessions
      ? [{ id: 'sessions' as const, label: t('detail.tabs.sessions', { count: props.sessionsCount }) }]
      : []),
    { id: 'audit', label: t('detail.tabs.audit', { count: auditTotal }) },
  ];

  function requestTab(nextTab: TabId) {
    if (nextTab === activeTab) return;
    if (activeTab === 'profile' && profileDirty) {
      setPendingTab(nextTab);
      setDiscardConfirmOpen(true);
      return;
    }
    setActiveTab(nextTab);
  }

  function focusTab(id: TabId) {
    requestTab(id);
    document.getElementById(`user-tab-${id}`)?.focus();
  }

  function handleTabKeyDown(event: React.KeyboardEvent<HTMLDivElement>) {
    const currentIndex = tabItems.findIndex((item) => item.id === activeTab);
    if (currentIndex < 0) return;
    if (event.key === 'ArrowRight' || event.key === 'ArrowDown') {
      event.preventDefault();
      focusTab(tabItems[(currentIndex + 1) % tabItems.length]!.id);
    } else if (event.key === 'ArrowLeft' || event.key === 'ArrowUp') {
      event.preventDefault();
      focusTab(tabItems[(currentIndex - 1 + tabItems.length) % tabItems.length]!.id);
    } else if (event.key === 'Home') {
      event.preventDefault();
      focusTab(tabItems[0]!.id);
    } else if (event.key === 'End') {
      event.preventDefault();
      focusTab(tabItems[tabItems.length - 1]!.id);
    }
  }

  function confirmDiscardTabSwitch() {
    if (pendingTab) setActiveTab(pendingTab);
    setPendingTab(null);
    setDiscardConfirmOpen(false);
    setProfileDirty(false);
  }

  async function confirmRevokeSession() {
    if (!revokeTarget) return;
    setRevokeBusy(true);
    try {
      await adminBrowserFetch(`/admin/users/${props.userId}/sessions/${encodeURIComponent(revokeTarget.id)}`, {
        method: 'DELETE',
      });
      setSessionRows((current) =>
        current.map((row) =>
          row.id === revokeTarget.id ? { ...row, revokedAt: new Date().toISOString() } : row,
        ),
      );
      showToast({
        tone: 'success',
        title: t('detail.sessions.revokeSuccessTitle'),
        message: t('detail.sessions.revokeSuccessMessage'),
      });
      setRevokeTarget(null);
    } catch (error) {
      showToast({
        tone: 'warning',
        title: t('detail.sessions.revokeFailedTitle'),
        message: error instanceof Error ? error.message : t('detail.sessions.revokeFailedMessage'),
      });
    } finally {
      setRevokeBusy(false);
    }
  }

  return (
    <div>
      <div
        className={styles.tabs}
        role="tablist"
        aria-label={t('detail.tabsAria')}
        onKeyDown={handleTabKeyDown}
      >
        {tabItems.map((item) => {
          const selected = activeTab === item.id;
          return (
            <button
              key={item.id}
              type="button"
              role="tab"
              id={`user-tab-${item.id}`}
              aria-selected={selected}
              aria-controls={`user-panel-${item.id}`}
              tabIndex={selected ? 0 : -1}
              className={selected ? styles.tabActive : styles.tab}
              onClick={() => requestTab(item.id)}
            >
              {item.label}
            </button>
          );
        })}
      </div>

      <div
        id="user-panel-profile"
        role="tabpanel"
        aria-labelledby="user-tab-profile"
        hidden={activeTab !== 'profile'}
      >
        <UserDetailForm
          userId={props.userId}
          initialFirstName={props.initialFirstName}
          initialLastName={props.initialLastName}
          initialRole={props.initialRole}
          initialStatus={props.initialStatus}
          initialPhoneNumber={props.initialPhoneNumber}
          email={props.email}
          pointsBalance={props.pointsBalance}
          reportsCount={props.reportsCount}
          sessionsCount={props.sessionsCount}
          hidden={activeTab !== 'profile'}
          onDirtyChange={setProfileDirty}
        />
      </div>

      {activeTab === 'privacy' && (
        <div id="user-panel-privacy" role="tabpanel" aria-labelledby="user-tab-privacy">
        <Card padding="md">
          <dl className={styles.privacyGrid}>
            <div>
              <dt>{t('detail.privacy.organizerCert')}</dt>
              <dd>{props.organizerCertifiedAt ? formatDateTime(props.organizerCertifiedAt) : t('detail.privacy.notCertified')}</dd>
            </div>
            <div>
              <dt>{t('detail.privacy.phoneVerification')}</dt>
              <dd>{props.isPhoneVerified ? t('detail.privacy.verified') : t('detail.privacy.notVerified')}</dd>
            </div>
            <div>
              <dt>{t('detail.privacy.termsAccepted')}</dt>
              <dd>{props.termsAcceptedAt ? formatDateTime(props.termsAcceptedAt) : t('detail.privacy.missing')}</dd>
            </div>
            <div>
              <dt>{t('detail.privacy.termsVersion')}</dt>
              <dd>{props.termsVersion ?? '—'}</dd>
            </div>
            <div>
              <dt>{t('detail.privacy.privacyAccepted')}</dt>
              <dd>{props.privacyAcceptedAt ? formatDateTime(props.privacyAcceptedAt) : t('detail.privacy.missing')}</dd>
            </div>
            <div>
              <dt>{t('detail.privacy.requiresTerms')}</dt>
              <dd>{props.requiresTermsAcceptance ? tCommon('yes') : tCommon('no')}</dd>
            </div>
            <div>
              <dt>{t('detail.privacy.totalPointsEarned')}</dt>
              <dd>{props.totalPointsEarned}</dd>
            </div>
            <div>
              <dt>{t('detail.privacy.created')}</dt>
              <dd>{formatDateTime(props.createdAt)}</dd>
            </div>
          </dl>
        </Card>
        </div>
      )}

      {activeTab === 'points' && (
        <div id="user-panel-points" role="tabpanel" aria-labelledby="user-tab-points">
        <UserPointsPanel
          userId={props.userId}
          initialBalance={props.pointsBalance}
          initialLedger={props.pointLedger}
          initialTotal={props.pointLedgerTotal}
          initialPage={props.pointLedgerPage ?? 1}
          pageSize={props.pointLedgerLimit ?? 20}
          {...(props.pointsError != null ? { loadError: props.pointsError } : {})}
        />
        </div>
      )}

      {activeTab === 'sessions' && props.canViewSessions && (
        <div id="user-panel-sessions" role="tabpanel" aria-labelledby="user-tab-sessions">
        {props.sessionsError ? (
          <SectionState variant="error" message={props.sessionsError} />
        ) : (
        <Card padding="md">
          <table className={styles.table}>
            <thead>
              <tr>
                <th>{t('detail.sessions.created')}</th>
                <th>{t('detail.sessions.device')}</th>
                <th>{t('detail.sessions.ip')}</th>
                <th>{t('detail.sessions.expires')}</th>
                <th>{t('detail.sessions.status')}</th>
                <Can permission="users:write">
                  <th>{t('detail.sessions.actions')}</th>
                </Can>
              </tr>
            </thead>
            <tbody>
              {sessionRows.map((s) => (
                <tr key={s.id}>
                  <td>{formatDateTime(s.createdAt)}</td>
                  <td>{s.deviceInfo ?? '—'}</td>
                  <td>{s.ipAddress ?? '—'}</td>
                  <td>{formatDateTime(s.expiresAt)}</td>
                  <td>{s.revokedAt ? t('detail.sessions.revoked') : t('detail.sessions.active')}</td>
                  <Can permission="users:write">
                    <td>
                      {!s.revokedAt ? (
                        <Button
                          type="button"
                          variant="outline"
                          size="sm"
                          onClick={() => setRevokeTarget(s)}
                        >
                          {t('detail.sessions.revoke')}
                        </Button>
                      ) : (
                        '—'
                      )}
                    </td>
                  </Can>
                </tr>
              ))}
            </tbody>
          </table>
          {sessionRows.length === 0 && (
            <p className={styles.empty}>{t('detail.sessions.empty')}</p>
          )}
        </Card>
        )}
        </div>
      )}

      {activeTab === 'audit' && (
        <div id="user-panel-audit" role="tabpanel" aria-labelledby="user-tab-audit">
        {props.auditError ? (
          <SectionState variant="error" message={props.auditError} />
        ) : (
        <Card padding="md">
          <table className={styles.table}>
            <thead>
              <tr>
                <th>{t('detail.audit.time')}</th>
                <th>{t('detail.audit.action')}</th>
                <th>{t('detail.audit.resource')}</th>
                <th>{t('detail.audit.actor')}</th>
              </tr>
            </thead>
            <tbody>
              {auditRows.map((a) => (
                <tr key={a.id}>
                  <td>{formatDateTime(a.createdAt)}</td>
                  <td>{a.action}</td>
                  <td>
                    {a.resourceType}
                    {a.resourceId ? ` · ${a.resourceId}` : ''}
                  </td>
                  <td>{a.actorEmail ?? '—'}</td>
                </tr>
              ))}
            </tbody>
          </table>
          {auditRows.length === 0 && !auditLoading ? (
            <p className={styles.empty}>{t('detail.audit.empty')}</p>
          ) : null}
          {auditTotal > AUDIT_PAGE_SIZE ? (
            <div className={styles.auditFooter}>
              <Pagination
                totalPages={Math.ceil(auditTotal / AUDIT_PAGE_SIZE)}
                currentPage={auditPage}
                onPageChange={(page) => void loadAuditPage(page)}
              />
            </div>
          ) : null}
        </Card>
        )}
        </div>
      )}

      <ConfirmDialog
        open={discardConfirmOpen}
        title={t('detail.discardChangesTitle')}
        description={t('detail.discardChangesDescription')}
        tone="danger"
        confirmLabel={t('detail.discardChangesConfirm')}
        onConfirm={confirmDiscardTabSwitch}
        onClose={() => {
          setDiscardConfirmOpen(false);
          setPendingTab(null);
        }}
      />
      <ConfirmDialog
        open={revokeTarget != null}
        title={t('detail.sessions.revokeConfirmTitle')}
        description={t('detail.sessions.revokeConfirmDescription')}
        tone="danger"
        confirmLabel={t('detail.sessions.revoke')}
        isLoading={revokeBusy}
        onConfirm={() => void confirmRevokeSession()}
        onClose={() => setRevokeTarget(null)}
      />
    </div>
  );
}
