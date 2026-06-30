'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useTranslations } from 'next-intl';
import { Button, ConfirmDialog, Icon, useToast } from '@/components/ui';
import { Can, useReadOnlyUnless } from '@/lib/auth/rbac';
import { useOptimisticMutation } from '@/features/admin-shell/hooks/use-optimistic-mutation';
import { adminBrowserFetch } from '@/lib/api';
import { useAdminBcp47Locale } from '@/lib/i18n';
import { SITE_STATUS_TRANSITIONS } from '@/features/sites/lib/sites-status-transitions';
import styles from './site-detail.module.css';

function formatStatus(s: string): string {
  return s.replace(/_/g, ' ').toLowerCase().replace(/\b\w/g, (c) => c.toUpperCase());
}

const STATUS_LABEL_KEY_BY_VALUE: Record<string, string> = {
  REPORTED: 'filters.reported',
  VERIFIED: 'filters.verified',
  CLEANUP_SCHEDULED: 'filters.cleanupScheduled',
  IN_PROGRESS: 'filters.inProgress',
  CLEANED: 'filters.cleaned',
  DISPUTED: 'filters.disputed',
};

function statusPillClass(status: string): string {
  const map: Record<string, string> = {
    REPORTED: styles.statusReported,
    VERIFIED: styles.statusVerified,
    CLEANUP_SCHEDULED: styles.statusScheduled,
    IN_PROGRESS: styles.statusInProgress,
    CLEANED: styles.statusCleaned,
    DISPUTED: styles.statusDisputed,
  };
  return `${styles.statusPill} ${map[status] ?? ''}`;
}

type SiteStatusFormProps = {
  siteId: string;
  initialStatus: string;
  initialArchivedByAdmin: boolean;
  initialArchiveReason: string | null;
  latitude: number;
  longitude: number;
  description: string | null;
  reportCount: number;
  createdAt: string;
};

export function SiteStatusForm({
  siteId,
  initialStatus,
  initialArchivedByAdmin,
  initialArchiveReason,
  latitude,
  longitude,
  description,
  reportCount,
  createdAt,
}: SiteStatusFormProps) {
  const t = useTranslations('sites');
  const tCommon = useTranslations('common');
  const locale = useAdminBcp47Locale();
  const router = useRouter();
  const readOnly = useReadOnlyUnless('sites:write');
  const [currentStatus, setCurrentStatus] = useState(initialStatus);
  const [status, setStatus] = useState(initialStatus);
  const [isArchived, setIsArchived] = useState(initialArchivedByAdmin);
  const [archiveReason, setArchiveReason] = useState(initialArchiveReason ?? '');
  const [confirmTransitionOpen, setConfirmTransitionOpen] = useState(false);
  const { showToast, clearToast } = useToast();

  useEffect(() => {
    setCurrentStatus(initialStatus);
    setStatus(initialStatus);
    setIsArchived(initialArchivedByAdmin);
    setArchiveReason(initialArchiveReason ?? '');
  }, [initialStatus, initialArchivedByAdmin, initialArchiveReason, siteId]);

  const allowedNext = SITE_STATUS_TRANSITIONS[currentStatus] ?? [];
  const canChange = !readOnly && allowedNext.length > 0;

  const gm = `https://www.google.com/maps?q=${latitude},${longitude}`;
  const am = `https://maps.apple.com/?q=${latitude},${longitude}`;

  const createdDate = new Date(createdAt).toLocaleDateString(locale, {
    dateStyle: 'medium',
  });

  const statusLabel = (statusValue: string): string => {
    const labelKey = STATUS_LABEL_KEY_BY_VALUE[statusValue];
    return labelKey ? t(labelKey) : formatStatus(statusValue);
  };

  const statusMutation = useOptimisticMutation({
    mutate: async () => {
      await adminBrowserFetch(`/sites/${siteId}/status`, {
        method: 'PATCH',
        body: { status },
      });
      return status;
    },
    successToast: { title: tCommon('saved'), message: t('detail.savedMessage') },
    errorToast: { title: tCommon('error'), message: tCommon('updateFailed') },
    onSuccess: (nextStatus) => {
      setCurrentStatus(nextStatus);
      setConfirmTransitionOpen(false);
      router.refresh();
    },
  });

  const archiveMutation = useOptimisticMutation({
    mutate: async () => {
      await adminBrowserFetch(`/sites/${siteId}/archive`, {
        method: 'PATCH',
        body: { archived: isArchived, reason: archiveReason.trim() || undefined },
      });
      return null;
    },
    successToast: {
      title: tCommon('saved'),
      message: isArchived ? t('detail.archivedMessage') : t('detail.unarchivedMessage'),
    },
    errorToast: { title: tCommon('error'), message: tCommon('updateFailed') },
    onSuccess: () => router.refresh(),
  });

  function requestSaveStatus() {
    if (status === 'DISPUTED' || status === 'CLEANED') {
      setConfirmTransitionOpen(true);
      return;
    }
    void saveStatus();
  }

  async function saveStatus() {
    clearToast();
    await statusMutation.run(null);
  }

  async function saveArchive() {
    if (isArchived && !archiveReason.trim()) {
      showToast({
        tone: 'warning',
        title: t('detail.reasonRequiredTitle'),
        message: t('detail.reasonRequiredMessage'),
      });
      return;
    }
    clearToast();
    await archiveMutation.run(null);
  }

  const saving = statusMutation.isPending || archiveMutation.isPending;

  return (
    <div className={styles.layout}>
      <Link href="/dashboard/sites" className={styles.backLink}>
        <Icon name="chevron-left" size={16} />
        {t('backToSites')}
      </Link>

      <section className={styles.sectionCard}>
        <span className={styles.sectionLabel}>{t('detail.location')}</span>
        <p className={styles.coordsValue}>
          {latitude.toFixed(6)}, {longitude.toFixed(6)}
        </p>
        {description ? <p className={styles.description}>{description}</p> : null}
        <div className={styles.mapLinks}>
          <a href={gm} target="_blank" rel="noopener noreferrer" className={styles.mapBtn}>
            {tCommon('openInGoogleMaps')}
          </a>
          <a href={am} target="_blank" rel="noopener noreferrer" className={styles.mapBtn}>
            {tCommon('openInAppleMaps')}
          </a>
        </div>
        <div className={styles.metaRow}>
          <Link href={`/dashboard/events/new?siteId=${siteId}`} className={styles.createEventLink}>
            <Icon name="calendar" size={14} />
            {t('detail.createCleanupEvent')}
          </Link>
          <div className={styles.metaItem}>
            <span className={styles.metaLabel}>{t('detail.reports')}</span>
            <span className={styles.metaValue}>
              {reportCount > 0 ? (
                <Link href={`/dashboard/reports?siteId=${siteId}`} className={styles.reportsLink}>
                  {reportCount}
                </Link>
              ) : (
                reportCount
              )}
            </span>
          </div>
          <div className={styles.metaItem}>
            <span className={styles.metaLabel}>{t('detail.reportedDate')}</span>
            <span className={styles.metaValue}>{createdDate}</span>
          </div>
        </div>
      </section>

      <section className={styles.sectionCard}>
        <span className={styles.sectionLabel}>{t('detail.lifecycleStatus')}</span>
        <div className={styles.statusForm}>
          <span className={statusPillClass(currentStatus)}>{statusLabel(currentStatus)}</span>
          {canChange ? (
            <>
              <label htmlFor="site-status">
                <span className={styles.metaLabel}>{t('detail.changeTo')}</span>
                <select
                  id="site-status"
                  value={status}
                  onChange={(e) => setStatus(e.target.value)}
                >
                  {allowedNext.map((st) => (
                    <option key={st} value={st}>
                      {statusLabel(st)}
                    </option>
                  ))}
                </select>
              </label>
              <div className={styles.formActions}>
                <Button type="button" onClick={() => void requestSaveStatus()} disabled={saving}>
                  {saving ? tCommon('saving') : t('detail.saveStatus')}
                </Button>
              </div>
            </>
          ) : readOnly ? (
            <p className={styles.readOnlyNote}>{t('detail.readOnlyNote')}</p>
          ) : null}
        </div>
      </section>

      <Can permission="sites:write">
        <section className={styles.sectionCard}>
          <span className={styles.sectionLabel}>{t('detail.visibilityModeration')}</span>
          <div className={styles.statusForm}>
            <label>
              <span className={styles.metaLabel}>{t('detail.mapVisibility')}</span>
              <select
                value={isArchived ? 'archived' : 'visible'}
                onChange={(e) => setIsArchived(e.target.value === 'archived')}
              >
                <option value="visible">{t('detail.visibleByDefault')}</option>
                <option value="archived">{t('detail.archivedHidden')}</option>
              </select>
            </label>
            <label>
              <span className={styles.metaLabel}>{t('detail.moderationReason')}</span>
              <textarea
                value={archiveReason}
                onChange={(e) => setArchiveReason(e.target.value)}
                placeholder={t('detail.archiveReasonPlaceholder')}
                rows={3}
              />
            </label>
            <div className={styles.formActions}>
              <Button type="button" onClick={() => void saveArchive()} disabled={saving}>
                {saving ? tCommon('saving') : t('detail.saveVisibility')}
              </Button>
            </div>
          </div>
        </section>
      </Can>

      <ConfirmDialog
        open={confirmTransitionOpen}
        title={t('detail.confirmStatusTitle')}
        description={t('detail.confirmStatusDescription', { status: statusLabel(status) })}
        confirmLabel={t('detail.updateStatus')}
        tone={status === 'DISPUTED' ? 'danger' : 'default'}
        isLoading={statusMutation.isPending}
        onConfirm={() => void saveStatus()}
        onClose={() => setConfirmTransitionOpen(false)}
      />
    </div>
  );
}
