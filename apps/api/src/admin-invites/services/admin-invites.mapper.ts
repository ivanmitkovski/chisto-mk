import { AdminInviteStatus, Role } from '../../prisma-client';

export const STAFF_ROLES: Role[] = [Role.SUPPORT, Role.ADMIN, Role.SUPER_ADMIN];

export function roleLabel(role: Role): string {
  switch (role) {
    case Role.SUPPORT:
      return 'Moderator';
    case Role.ADMIN:
      return 'Admin';
    case Role.SUPER_ADMIN:
      return 'Super admin';
    default:
      return role;
  }
}

export function toInviteResponse(invite: {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  role: Role;
  status: AdminInviteStatus;
  expiresAt: Date;
  createdAt: Date;
  acceptedAt: Date | null;
  revokedAt: Date | null;
  invitedBy: { id: string; email: string; firstName: string; lastName: string };
}) {
  return {
    id: invite.id,
    email: invite.email,
    firstName: invite.firstName,
    lastName: invite.lastName,
    role: invite.role,
    status: invite.status,
    expiresAt: invite.expiresAt.toISOString(),
    createdAt: invite.createdAt.toISOString(),
    acceptedAt: invite.acceptedAt?.toISOString() ?? null,
    revokedAt: invite.revokedAt?.toISOString() ?? null,
    invitedBy: invite.invitedBy,
  };
}
