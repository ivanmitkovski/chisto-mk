'use client';

import { useTranslations } from 'next-intl';
import { motion } from 'framer-motion';
import { Icon, SectionState } from '@/components/ui';
import type { ReportEvidence } from '../../types';
import { formatDateTime } from '../../utils/report-display';
import styles from '../report-review-card.module.css';

function evidenceIconName(kind: ReportEvidence['kind']) {
  if (kind === 'video') {
    return 'document-forward' as const;
  }
  if (kind === 'document') {
    return 'clipboard-close' as const;
  }
  return 'document-text' as const;
}

type ReportReviewEvidencePanelProps = {
  evidence: ReportEvidence[];
  onOpenImageEvidence: (evidenceId: string) => void;
};

export function ReportReviewEvidencePanel({ evidence, onOpenImageEvidence }: ReportReviewEvidencePanelProps) {
  const t = useTranslations('reports.evidence');

  return (
    <motion.article
      className={styles.panel}
      whileHover={{ y: -2 }}
      transition={{ duration: 0.15 }}
      aria-label={t('filesAria')}
    >
      <div className={styles.sectionHeader}>
        <h3>{t('title')}</h3>
        <span>{t('filesCount', { count: evidence.length })}</span>
      </div>
      {evidence.length === 0 ? (
        <div className={styles.sectionEmpty}>
          <SectionState variant="empty" message={t('empty')} />
        </div>
      ) : (
        <ul className={styles.evidenceList}>
          {evidence.map((item) => {
            const isImageWithPreview = item.kind === 'image' && item.previewUrl;
            const hasDownload = Boolean(item.previewUrl) && item.kind !== 'image';
            const content = (
              <>
                <span className={styles.evidenceIcon}>
                  <Icon name={evidenceIconName(item.kind)} size={14} />
                </span>
                <span className={styles.evidenceLabel}>{item.label}</span>
                <span className={styles.evidenceMeta}>
                  {item.sizeLabel} • {formatDateTime(item.uploadedAt)}
                </span>
              </>
            );
            return (
              <li key={item.id} className={styles.evidenceItem}>
                {isImageWithPreview ? (
                  <button
                    type="button"
                    className={styles.evidenceItemButton}
                    onClick={() => onOpenImageEvidence(item.id)}
                    aria-label={t('openFullscreenAria')}
                  >
                    {content}
                  </button>
                ) : hasDownload ? (
                  <a
                    className={styles.evidenceItemButton}
                    href={item.previewUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                    download
                  >
                    {content}
                    <span className={styles.evidenceDownloadHint}>{t('downloadFile')}</span>
                  </a>
                ) : item.previewUrl ? (
                  <a
                    className={styles.evidenceItemButton}
                    href={item.previewUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    {content}
                    <span className={styles.evidenceDownloadHint}>{t('openPreview')}</span>
                  </a>
                ) : (
                  <span className={styles.evidenceItemInner}>{content}</span>
                )}
              </li>
            );
          })}
        </ul>
      )}
    </motion.article>
  );
}
