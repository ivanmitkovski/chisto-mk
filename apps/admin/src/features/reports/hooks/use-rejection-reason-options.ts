'use client';

import { useMemo } from 'react';
import { useTranslations } from 'next-intl';
import {
  REJECTION_REASON_VALUES,
  type RejectionReasonValue,
} from '../constants/rejection-reasons';

const REJECTION_REASON_MESSAGE_KEYS: Record<RejectionReasonValue, string> = {
  'False report': 'falseReport',
  'Duplicate submission': 'duplicateSubmission',
  'Insufficient evidence': 'insufficientEvidence',
  'Out of jurisdiction': 'outOfJurisdiction',
  'Policy violation': 'policyViolation',
};

export function useRejectionReasonOptions() {
  const t = useTranslations('reports.rejectionReasons');

  return useMemo(
    () =>
      REJECTION_REASON_VALUES.map((value) => ({
        value,
        label: t(REJECTION_REASON_MESSAGE_KEYS[value]),
      })),
    [t],
  );
}
