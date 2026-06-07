import type { StaffRole } from '../types';

export const TEAM_ROLE_OPTIONS: ReadonlyArray<{ value: StaffRole; labelKey: string }> = [
  { value: 'SUPPORT', labelKey: 'roles.moderator' },
  { value: 'ADMIN', labelKey: 'roles.admin' },
  { value: 'SUPER_ADMIN', labelKey: 'roles.superAdmin' },
];

export function teamRoleLabelKey(role: StaffRole): string {
  return TEAM_ROLE_OPTIONS.find((option) => option.value === role)?.labelKey ?? role;
}

export function inviteStatusTone(
  status: import('../types').AdminInviteStatus,
): 'neutral' | 'success' | 'warning' | 'danger' | 'info' {
  switch (status) {
    case 'PENDING':
      return 'warning';
    case 'ACCEPTED':
      return 'success';
    case 'REVOKED':
      return 'neutral';
    case 'EXPIRED':
      return 'danger';
    default:
      return 'neutral';
  }
}
