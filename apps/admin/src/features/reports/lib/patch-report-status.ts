import type { ReportStatus } from '../types';

export type PatchReportStatusAction = 'approve' | 'reject' | 'in-review';

export type PatchReportStatusFailure = {
  ok: false;
  status: number;
  message: string;
};

export type PatchReportStatusSuccess = {
  ok: true;
  status: number;
};

export type PatchReportStatusResult = PatchReportStatusFailure | PatchReportStatusSuccess;

const defaultErrorMessage = 'Unable to update this report right now.';

/**
 * PATCH moderator status for a report via the admin BFF route.
 * Shared by inline list actions and the review detail card.
 */
export async function patchReportStatus(
  reportId: string,
  nextStatus: ReportStatus,
  action: PatchReportStatusAction,
  reason?: string,
): Promise<PatchReportStatusResult> {
  const trimmed = (reason ?? '').trim();
  const rejectDefault = 'Rejected by moderator.';
  const bodyPayload: { status: ReportStatus; reason?: string } =
    action === 'reject'
      ? { status: nextStatus, reason: trimmed.length > 0 ? trimmed : rejectDefault }
      : trimmed.length > 0
        ? { status: nextStatus, reason: trimmed }
        : { status: nextStatus };

  const res = await fetch(`/api/reports/${encodeURIComponent(reportId)}/status`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    credentials: 'include',
    body: JSON.stringify(bodyPayload),
  });

  const body: unknown = await res.json().catch(() => ({}));
  const message =
    body &&
    typeof body === 'object' &&
    body !== null &&
    'message' in body &&
    typeof (body as { message?: unknown }).message === 'string'
      ? (body as { message: string }).message
      : defaultErrorMessage;

  if (!res.ok) {
    return { ok: false, status: res.status, message };
  }

  return { ok: true, status: res.status };
}
