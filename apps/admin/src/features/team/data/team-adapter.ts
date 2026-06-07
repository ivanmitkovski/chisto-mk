import { serverAuthenticatedFetch } from '@/lib/auth/server-api-with-refresh';
import type { StaffRole, TeamInvite, TeamStaffMember } from '../types';

const STAFF_ROLES: StaffRole[] = ['SUPPORT', 'ADMIN', 'SUPER_ADMIN'];
const STAFF_FETCH_LIMIT = 100;

type UserListResponse = {
  data: Array<{
    id: string;
    firstName: string;
    lastName: string;
    email: string;
    phoneNumber: string;
    role: string;
    status: string;
    lastActiveAt: string | null;
  }>;
  meta: { page: number; limit: number; total: number };
};

function mapStaffRow(row: UserListResponse['data'][number]): TeamStaffMember {
  return {
    id: row.id,
    firstName: row.firstName,
    lastName: row.lastName,
    email: row.email,
    phoneNumber: row.phoneNumber,
    role: row.role as TeamStaffMember['role'],
    status: row.status as TeamStaffMember['status'],
    lastActiveAt: row.lastActiveAt,
  };
}

async function listStaffForRole(role: StaffRole): Promise<TeamStaffMember[]> {
  const rows: TeamStaffMember[] = [];
  let page = 1;
  let total = 0;

  do {
    const response = await serverAuthenticatedFetch<UserListResponse>(
      `/admin/users?${new URLSearchParams({
        role,
        limit: String(STAFF_FETCH_LIMIT),
        page: String(page),
        sort: 'name',
        dir: 'asc',
      }).toString()}`,
      { method: 'GET' },
    );

    total = response.meta.total;
    for (const row of response.data) {
      if (!STAFF_ROLES.includes(row.role as StaffRole)) continue;
      rows.push(mapStaffRow(row));
    }

    if (response.data.length === 0) break;
    page += 1;
  } while (rows.length < total);

  return rows;
}

export async function listTeamInvites(): Promise<TeamInvite[]> {
  return serverAuthenticatedFetch<TeamInvite[]>('/admin/invites', {
    method: 'GET',
  });
}

export async function listTeamStaff(): Promise<TeamStaffMember[]> {
  const responses = await Promise.all(STAFF_ROLES.map((role) => listStaffForRole(role)));

  const byId = new Map<string, TeamStaffMember>();
  for (const roleRows of responses) {
    for (const row of roleRows) {
      byId.set(row.id, row);
    }
  }

  return [...byId.values()].sort((a, b) =>
    `${a.lastName} ${a.firstName}`.localeCompare(`${b.lastName} ${b.firstName}`),
  );
}

export async function loadTeamWorkspace(): Promise<{ staff: TeamStaffMember[]; invites: TeamInvite[] }> {
  const [staff, invites] = await Promise.all([listTeamStaff(), listTeamInvites()]);
  return { staff, invites };
}
