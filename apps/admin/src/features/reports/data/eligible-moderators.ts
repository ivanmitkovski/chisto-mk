import { serverAuthenticatedFetch } from '@/lib/auth/server-api-with-refresh';

export type EligibleModeratorRole = 'SUPPORT' | 'ADMIN' | 'SUPER_ADMIN';

export type EligibleModerator = {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  role: EligibleModeratorRole;
};

const STAFF_ROLES: EligibleModeratorRole[] = ['SUPPORT', 'ADMIN', 'SUPER_ADMIN'];
const FETCH_LIMIT = 100;

type UserListResponse = {
  data: Array<{
    id: string;
    firstName: string;
    lastName: string;
    email: string;
    role: string;
    status: string;
  }>;
  meta: { page: number; limit: number; total: number };
};

async function listActiveStaffForRole(role: EligibleModeratorRole): Promise<EligibleModerator[]> {
  const rows: EligibleModerator[] = [];
  let page = 1;
  let total = 0;

  do {
    const response = await serverAuthenticatedFetch<UserListResponse>(
      `/admin/users?${new URLSearchParams({
        role,
        status: 'ACTIVE',
        limit: String(FETCH_LIMIT),
        page: String(page),
        sort: 'name',
        dir: 'asc',
      }).toString()}`,
      { method: 'GET' },
    );

    total = response.meta.total;
    for (const row of response.data) {
      if (row.status !== 'ACTIVE') continue;
      if (!STAFF_ROLES.includes(row.role as EligibleModeratorRole)) continue;
      rows.push({
        id: row.id,
        firstName: row.firstName,
        lastName: row.lastName,
        email: row.email,
        role: row.role as EligibleModeratorRole,
      });
    }

    if (response.data.length === 0) break;
    page += 1;
  } while (rows.length < total);

  return rows;
}

export async function listEligibleModerators(): Promise<EligibleModerator[]> {
  const responses = await Promise.all(STAFF_ROLES.map((role) => listActiveStaffForRole(role)));

  const byId = new Map<string, EligibleModerator>();
  for (const roleRows of responses) {
    for (const row of roleRows) {
      byId.set(row.id, row);
    }
  }

  return [...byId.values()].sort((a, b) =>
    `${a.lastName} ${a.firstName}`.localeCompare(`${b.lastName} ${b.firstName}`),
  );
}
