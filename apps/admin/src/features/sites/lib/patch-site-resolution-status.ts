import type { SiteResolutionStatus } from '../data/resolutions-adapter';
import { getAdminCsrfHeaders } from '@/features/auth/lib/admin-auth';

export async function patchSiteResolutionStatus(
  resolutionId: string,
  status: Extract<SiteResolutionStatus, 'APPROVED' | 'REJECTED'>,
  reason?: string,
): Promise<{ ok: true } | { ok: false; message: string }> {
  const trimmed = (reason ?? '').trim();
  const body: { status: SiteResolutionStatus; reason?: string } =
    status === 'REJECTED'
      ? { status, reason: trimmed.length > 0 ? trimmed : 'Rejected by moderator.' }
      : { status };

  const res = await fetch(
    `/api/proxy/sites/admin/resolutions/${encodeURIComponent(resolutionId)}/status`,
    {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json', ...getAdminCsrfHeaders() },
      credentials: 'include',
      body: JSON.stringify(body),
    },
  );

  const payload: unknown = await res.json().catch(() => ({}));
  if (!res.ok) {
    const message =
      payload &&
      typeof payload === 'object' &&
      payload !== null &&
      'message' in payload &&
      typeof (payload as { message?: unknown }).message === 'string'
        ? (payload as { message: string }).message
        : 'Unable to update resolution status.';
    return { ok: false, message };
  }
  return { ok: true };
}
