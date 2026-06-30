export type AdminInviteStatus = 'PENDING' | 'ACCEPTED' | 'REVOKED' | 'EXPIRED';

export type StaffRole = 'SUPPORT' | 'ADMIN' | 'SUPER_ADMIN';

export type TeamInvite = {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  role: StaffRole;
  status: AdminInviteStatus;
  expiresAt: string;
  createdAt: string;
  acceptedAt: string | null;
  revokedAt: string | null;
  invitedBy: {
    id: string;
    email: string;
    firstName: string;
    lastName: string;
  };
};

export type TeamStaffMember = {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  phoneNumber: string;
  role: StaffRole;
  status: 'ACTIVE' | 'SUSPENDED' | 'DELETED';
  lastActiveAt: string | null;
};

export type InviteStaffFormValues = {
  email: string;
  firstName: string;
  lastName: string;
  role: StaffRole;
};
