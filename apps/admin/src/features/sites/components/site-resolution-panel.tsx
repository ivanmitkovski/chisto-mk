'use client';

import { useCallback, useMemo, useState } from 'react';
import Image from 'next/image';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useTranslations } from 'next-intl';
import { Button, ConfirmDialog, useToast } from '@/components/ui';
import { Can, useReadOnlyUnless } from '@/lib/auth/rbac';
import { useReportPhotoGallery } from '@/features/reports/hooks/use-report-photo-gallery';
import { ReportPhotoLightbox } from '@/features/reports/components/report-review-card/report-photo-lightbox';
import type { SiteResolutionRow } from '../data/resolutions-adapter';
import { patchSiteResolutionStatus } from '../lib/patch-site-resolution-status';
import styles from './site-resolution-panel.module.css';

type SiteResolutionPanelProps = {
  siteId: string;
  initialResolutions: SiteResolutionRow[];
};

export function SiteResolutionPanel({ siteId, initialResolutions }: SiteResolutionPanelProps) {
  const t = useTranslations('sites.resolutions');
  const tCommon = useTranslations('common');
  const router = useRouter();
  const { showToast, clearToast } = useToast();
  const readOnly = useReadOnlyUnless('sites:resolve');
  const [rows, setRows] = useState(initialResolutions);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [rejectTarget, setRejectTarget] = useState<SiteResolutionRow | null>(null);
  const [rejectReason, setRejectReason] = useState('');
  const [confirmApprove, setConfirmApprove] = useState<SiteResolutionRow | null>(null);

  const galleryItems = useMemo(
    () =>
      rows.flatMap((row) =>
        row.mediaUrls.map((url, index) => ({
          id: `${row.id}:${index}`,
          label: `Photo ${index + 1}`,
          kind: 'image' as const,
          sizeLabel: '',
          uploadedAt: row.createdAt,
          previewUrl: url,
          previewAlt: row.note ?? 'Cleanup evidence',
        })),
      ),
    [rows],
  );
  const gallery = useReportPhotoGallery({ evidence: galleryItems });

  const refreshRow = useCallback((id: string, status: SiteResolutionRow['status']) => {
    setRows((prev) => prev.map((r) => (r.id === id ? { ...r, status } : r)));
  }, []);

  async function runPatch(
    row: SiteResolutionRow,
    status: 'APPROVED' | 'REJECTED',
    reason?: string,
  ) {
    setBusyId(row.id);
    clearToast();
    const result = await patchSiteResolutionStatus(row.id, status, reason);
    setBusyId(null);
    if (!result.ok) {
      showToast({ tone: 'danger', title: tCommon('error'), message: result.message });
      return;
    }
    refreshRow(row.id, status);
    showToast({
      tone: 'success',
      title: tCommon('saved'),
      message: status === 'APPROVED' ? t('approvedMessage') : t('rejectedMessage'),
    });
    router.refresh();
  }

  const pending = rows.filter((r) => r.status === 'PENDING');

  return (
    <section className={styles.panel}>
      <div className={styles.header}>
        <h2 className={styles.title}>{t('panelTitle')}</h2>
        <Link href={`/dashboard/resolutions?siteId=${encodeURIComponent(siteId)}`} className={styles.queueLink}>
          {t('openQueue')}
        </Link>
      </div>

      {pending.length === 0 ? (
        <p className={styles.empty}>{t('noPending')}</p>
      ) : (
        <ul className={styles.list}>
          {pending.map((row) => (
            <li key={row.id} className={styles.card}>
              <div className={styles.meta}>
                <span className={styles.badge}>{row.isReporterSubmission ? t('reporterSubmission') : t('communitySubmission')}</span>
                <span className={styles.date}>{new Date(row.createdAt).toLocaleString()}</span>
                {row.submitterDisplayLabel ? (
                  <span className={styles.submitter}>{row.submitterDisplayLabel}</span>
                ) : null}
              </div>
              {row.note ? <p className={styles.note}>{row.note}</p> : null}
              <div className={styles.thumbs}>
                {row.mediaUrls.slice(0, 4).map((url, index) => (
                  <button
                    key={`${row.id}-${index}`}
                    type="button"
                    className={styles.thumbButton}
                    onClick={() => gallery.openLightbox(`${row.id}:${index}`)}
                  >
                    <Image src={url} alt="" fill className={styles.thumbImage} sizes="80px" />
                  </button>
                ))}
              </div>
              <Can permission="sites:resolve">
                <div className={styles.actions}>
                  <Button
                    size="sm"
                    onClick={() => setConfirmApprove(row)}
                    disabled={readOnly || busyId === row.id}
                    isLoading={busyId === row.id}
                  >
                    {t('approve')}
                  </Button>
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() => {
                      setRejectTarget(row);
                      setRejectReason('');
                    }}
                    disabled={readOnly || busyId === row.id}
                  >
                    {t('reject')}
                  </Button>
                </div>
              </Can>
            </li>
          ))}
        </ul>
      )}

      <ReportPhotoLightbox
        isOpen={gallery.isLightboxOpen}
        photoEvidence={gallery.photoEvidence}
        activePhoto={gallery.activePhoto}
        activePhotoIndex={gallery.activePhotoIndex}
        filmstripRef={gallery.filmstripRef}
        thumbRefs={gallery.thumbRefs}
        onClose={() => gallery.setIsLightboxOpen(false)}
        onSelectPhoto={gallery.setActivePhotoId}
        onShowPrevious={gallery.showPreviousPhoto}
        onShowNext={gallery.showNextPhoto}
      />

      <ConfirmDialog
        open={confirmApprove != null}
        title={t('approveConfirmTitle')}
        description={t('approveConfirmDescription')}
        confirmLabel={t('approve')}
        isLoading={busyId != null}
        onConfirm={() => {
          if (confirmApprove) void runPatch(confirmApprove, 'APPROVED').then(() => setConfirmApprove(null));
        }}
        onClose={() => setConfirmApprove(null)}
      />

      <ConfirmDialog
        open={rejectTarget != null}
        title={t('rejectConfirmTitle')}
        description={t('rejectConfirmDescription')}
        confirmLabel={t('reject')}
        tone="danger"
        isLoading={busyId != null}
        onConfirm={() => {
          if (rejectTarget) void runPatch(rejectTarget, 'REJECTED', rejectReason).then(() => setRejectTarget(null));
        }}
        onClose={() => setRejectTarget(null)}
      >
        <label className={styles.reasonField}>
          <span>{t('rejectReasonLabel')}</span>
          <textarea
            value={rejectReason}
            onChange={(e) => setRejectReason(e.target.value)}
            rows={3}
            placeholder={t('rejectReasonPlaceholder')}
          />
        </label>
      </ConfirmDialog>
    </section>
  );
}
