import { getAdminCsrfHeaders } from '@/features/auth/lib/admin-auth';
import type { ReportStatus } from '../types';

export type PatchReportAssignResult =
  | { ok: true; assignedModeratorId: string | null; assignedModeratorName: string | null; status: ReportStatus }
  | { ok: false; status: number; message: string };

const defaultErrorMessage = 'Unable to update assignment right now.';

export async function patchReportAssign(
  reportId: string,
  body: { moderatorId?: string; unassign?: boolean },
): Promise<PatchReportAssignResult> {
  const res = await fetch(`/api/reports/${encodeURIComponent(reportId)}/assign`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json', ...getAdminCsrfHeaders() },
    credentials: 'include',
    body: JSON.stringify(body),
  });

  const payload: unknown = await res.json().catch(() => ({}));
  const message =
    payload &&
    typeof payload === 'object' &&
    payload !== null &&
    'message' in payload &&
    typeof (payload as { message?: unknown }).message === 'string'
      ? (payload as { message: string }).message
      : defaultErrorMessage;

  if (!res.ok) {
    return { ok: false, status: res.status, message };
  }

  const data = payload as {
    assignedModeratorId?: string | null;
    assignedModeratorName?: string | null;
    status?: ReportStatus;
  };

  return {
    ok: true,
    assignedModeratorId: data.assignedModeratorId ?? null,
    assignedModeratorName: data.assignedModeratorName ?? null,
    status: data.status ?? 'IN_REVIEW',
  };
}
