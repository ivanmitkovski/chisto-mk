'use client';

import { useEffect, useMemo, useState } from 'react';
import { useTranslations } from 'next-intl';
import { Combobox, ConfirmDialog } from '@/components/ui';
import type { EligibleModerator } from '../data/eligible-moderators';
import type { ReportAssignControls } from '../hooks/use-report-assign';
import type { ReportDetail } from '../types';
import styles from './report-review-card/report-review-operational-context.module.css';

const UNASSIGNED_VALUE = '';

type ReportModeratorAssignPickerProps = {
  report: ReportDetail;
  eligibleModerators: EligibleModerator[];
  assign: ReportAssignControls;
  disabled?: boolean;
};

function moderatorDisplayName(moderator: EligibleModerator): string {
  return `${moderator.firstName} ${moderator.lastName}`.trim() || moderator.email;
}

export function ReportModeratorAssignPicker({
  report,
  eligibleModerators,
  assign,
  disabled = false,
}: ReportModeratorAssignPickerProps) {
  const t = useTranslations('reports.operationalContext');
  const assignedId = report.moderation.assignedModeratorId ?? UNASSIGNED_VALUE;
  const [selectedValue, setSelectedValue] = useState(assignedId);
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [pendingValue, setPendingValue] = useState<string | null>(null);

  useEffect(() => {
    setSelectedValue(assignedId);
  }, [assignedId]);

  const roleLabel = (role: EligibleModerator['role']) => {
    if (role === 'SUPER_ADMIN') return t('roleSuperAdmin');
    if (role === 'ADMIN') return t('roleAdmin');
    return t('roleSupport');
  };

  const options = useMemo(
    () => [
      { value: UNASSIGNED_VALUE, label: t('unassigned') },
      ...eligibleModerators.map((moderator) => ({
        value: moderator.id,
        label: `${moderatorDisplayName(moderator)} · ${roleLabel(moderator.role)}`,
      })),
    ],
    [eligibleModerators, t],
  );

  const pendingModerator = eligibleModerators.find((moderator) => moderator.id === pendingValue);
  const pendingName = pendingModerator ? moderatorDisplayName(pendingModerator) : t('unassigned');
  const isUnassignPending = pendingValue === UNASSIGNED_VALUE;

  function handleSelectionChange(nextValue: string) {
    if (nextValue === assignedId) {
      setSelectedValue(nextValue);
      return;
    }
    setSelectedValue(nextValue);
    setPendingValue(nextValue);
    setConfirmOpen(true);
  }

  function handleCloseConfirm() {
    if (assign.isAssigning) return;
    setConfirmOpen(false);
    setPendingValue(null);
    setSelectedValue(assignedId);
  }

  async function handleConfirm() {
    if (pendingValue == null) return;
    if (isUnassignPending) {
      await assign.releaseAssignment();
    } else {
      const moderator = eligibleModerators.find((entry) => entry.id === pendingValue);
      if (!moderator) {
        handleCloseConfirm();
        return;
      }
      await assign.assignToModerator(pendingValue, moderatorDisplayName(moderator));
    }
    setConfirmOpen(false);
    setPendingValue(null);
  }

  return (
    <div className={styles.assignPicker}>
      <Combobox
        label={t('assignModeratorLabel')}
        value={selectedValue}
        options={options}
        placeholder={t('assignModeratorPlaceholder')}
        disabled={disabled || assign.isAssigning}
        onChange={handleSelectionChange}
      />
      <ConfirmDialog
        open={confirmOpen}
        title={isUnassignPending ? t('confirmUnassignTitle') : t('confirmAssignTitle')}
        description={
          isUnassignPending
            ? t('confirmUnassignDescription')
            : t('confirmAssignDescription', { name: pendingName })
        }
        confirmLabel={t('confirmAssignLabel')}
        isLoading={assign.isAssigning}
        onConfirm={() => void handleConfirm()}
        onClose={handleCloseConfirm}
      />
    </div>
  );
}
