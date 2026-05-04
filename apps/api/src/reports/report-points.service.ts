import { Injectable } from '@nestjs/common';
import {
  REPORT_APPROVED_REPEAT_SITE_MULTIPLIER,
  REPORT_APPROVAL_POINTS_BASE,
  REPORT_APPROVAL_POINTS_CLEANUP_EFFORT,
  REPORT_APPROVAL_POINTS_MEDIA_PER_PHOTO_MAX,
  REPORT_APPROVAL_POINTS_MEDIA_PER_PHOTO,
  REPORT_APPROVAL_POINTS_SEVERITY_THRESHOLD,
  REPORT_APPROVAL_POINTS_SEVERITY_BONUS,
  REPORT_APPROVAL_POINTS_SITE_PIONEER,
} from '../gamification/gamification.constants';
import { ReportCleanupEffort } from '../prisma-client';

export type ReportPointsBreakdownLine = { code: string; points: number };

/** @deprecated Use {@link ReportApprovalPointsInput} / {@link ReportPointsService.computeApprovalPoints}. */
export type ReportSubmitPointsInput = ReportApprovalPointsInput;

export type ReportApprovalPointsInput = {
  mediaCount: number;
  severity: number | null;
  cleanupEffort: ReportCleanupEffort | null;
  /** Count of other APPROVED reports on the same site (excludes the report being approved). */
  otherApprovedReportCountOnSite: number;
};

/**
 * Pure rules for report approval XP (persisted as one {@link PointTransaction} with {@link REASON_REPORT_APPROVED}).
 */
@Injectable()
export class ReportPointsService {
  computeApprovalPoints(input: ReportApprovalPointsInput): {
    preCapTotal: number;
    breakdown: ReportPointsBreakdownLine[];
  } {
    const breakdown: ReportPointsBreakdownLine[] = [];
    let nominalCore = 0;

    nominalCore += REPORT_APPROVAL_POINTS_BASE;
    breakdown.push({ code: 'REPORT_APPROVED_BASE', points: REPORT_APPROVAL_POINTS_BASE });

    const cappedMedia = Math.min(
      REPORT_APPROVAL_POINTS_MEDIA_PER_PHOTO_MAX,
      Math.max(0, input.mediaCount),
    );
    const mediaPts = cappedMedia * REPORT_APPROVAL_POINTS_MEDIA_PER_PHOTO;
    if (mediaPts > 0) {
      breakdown.push({ code: 'REPORT_APPROVED_MEDIA', points: mediaPts });
      nominalCore += mediaPts;
    }

    const sev = input.severity ?? 0;
    if (sev >= REPORT_APPROVAL_POINTS_SEVERITY_THRESHOLD) {
      breakdown.push({
        code: 'REPORT_APPROVED_SEVERITY',
        points: REPORT_APPROVAL_POINTS_SEVERITY_BONUS,
      });
      nominalCore += REPORT_APPROVAL_POINTS_SEVERITY_BONUS;
    }

    if (input.cleanupEffort != null && input.cleanupEffort !== 'NOT_SURE') {
      breakdown.push({
        code: 'REPORT_APPROVED_CLEANUP_EFFORT',
        points: REPORT_APPROVAL_POINTS_CLEANUP_EFFORT,
      });
      nominalCore += REPORT_APPROVAL_POINTS_CLEANUP_EFFORT;
    }

    const pioneer = input.otherApprovedReportCountOnSite === 0;
    let coreAfterMultiplier = nominalCore;
    if (!pioneer) {
      coreAfterMultiplier = Math.floor(nominalCore * REPORT_APPROVED_REPEAT_SITE_MULTIPLIER);
      const discount = coreAfterMultiplier - nominalCore;
      if (discount !== 0) {
        breakdown.push({ code: 'REPORT_APPROVED_REPEAT_SITE_ADJUSTMENT', points: discount });
      }
    }

    let preCapTotal = coreAfterMultiplier;
    if (pioneer) {
      breakdown.push({ code: 'REPORT_APPROVED_SITE_PIONEER', points: REPORT_APPROVAL_POINTS_SITE_PIONEER });
      preCapTotal += REPORT_APPROVAL_POINTS_SITE_PIONEER;
    }

    return { preCapTotal, breakdown };
  }
}
