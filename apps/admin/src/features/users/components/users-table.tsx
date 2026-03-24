'use client';

import { DataTable, DataTableLink } from '@/components/ui';
import type { UserRow } from '@/features/users/data/users-adapter';

const columns = [
  {
    key: 'name',
    header: 'Name',
    render: (u: UserRow) => (
      <DataTableLink href={`/dashboard/users/${u.id}`}>
        {u.firstName} {u.lastName}
      </DataTableLink>
    ),
  },
  { key: 'email', header: 'Email', render: (u: UserRow) => u.email },
  { key: 'phone', header: 'Phone', render: (u: UserRow) => u.phoneNumber },
  { key: 'role', header: 'Role', render: (u: UserRow) => u.role },
  { key: 'status', header: 'Status', render: (u: UserRow) => u.status },
  { key: 'points', header: 'Points', render: (u: UserRow) => String(u.pointsBalance) },
];

type UsersTableProps = {
  data: UserRow[];
  meta: string;
};

export function UsersTable({ data, meta }: UsersTableProps) {
  return (
    <DataTable
      columns={columns}
      data={data}
      getRowId={(u) => u.id}
      meta={meta}
    />
  );
}
