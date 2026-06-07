import { adminBrowserFetch } from '@/lib/api';
import type { InviteStaffFormValues, StaffRole, TeamInvite } from '../types';

export async function createTeamInvite(values: InviteStaffFormValues): Promise<TeamInvite> {
  return adminBrowserFetch<TeamInvite>('/admin/invites', {
    method: 'POST',
    body: {
      email: values.email.trim(),
      firstName: values.firstName.trim(),
      lastName: values.lastName.trim(),
      role: values.role,
    },
  });
}

export async function resendTeamInvite(id: string): Promise<TeamInvite> {
  return adminBrowserFetch<TeamInvite>(`/admin/invites/${encodeURIComponent(id)}/resend`, {
    method: 'POST',
  });
}

export async function revokeTeamInvite(id: string): Promise<{ id: string; status: string }> {
  return adminBrowserFetch<{ id: string; status: string }>(
    `/admin/invites/${encodeURIComponent(id)}/revoke`,
    { method: 'POST' },
  );
}

export async function changeStaffRole(userId: string, role: StaffRole): Promise<void> {
  await adminBrowserFetch(`/admin/users/${encodeURIComponent(userId)}/role`, {
    method: 'PATCH',
    body: { role },
  });
}

export async function setStaffStatus(
  userId: string,
  status: 'ACTIVE' | 'SUSPENDED',
): Promise<void> {
  await adminBrowserFetch(`/admin/users/${encodeURIComponent(userId)}`, {
    method: 'PATCH',
    body: { status },
  });
}
