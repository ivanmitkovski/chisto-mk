import { ReportCleanupEffort } from '../prisma-client';

export const REPORT_CLEANUP_EFFORT_KEYS = [
  'ONE_TO_TWO',
  'THREE_TO_FIVE',
  'SIX_TO_TEN',
  'TEN_PLUS',
  'NOT_SURE',
] as const satisfies readonly ReportCleanupEffort[];

export type ReportCleanupEffortKey = (typeof REPORT_CLEANUP_EFFORT_KEYS)[number];

const LABELS: Record<ReportCleanupEffort, string> = {
  ONE_TO_TWO: '1–2 people',
  THREE_TO_FIVE: '3–5 people',
  SIX_TO_TEN: '6–10 people',
  TEN_PLUS: '10+ people',
  NOT_SURE: 'Not sure',
};

export function reportCleanupEffortLabel(
  value: ReportCleanupEffort | string | null | undefined,
): string | null {
  if (value == null) return null;
  const label = LABELS[value as ReportCleanupEffort];
  return label ?? null;
}

export function parseReportCleanupEffort(
  raw: string | undefined,
): ReportCleanupEffort | null {
  if (raw == null || raw.trim() === '') return null;
  if ((REPORT_CLEANUP_EFFORT_KEYS as readonly string[]).includes(raw)) {
    return raw as ReportCleanupEffort;
  }
  return null;
}
