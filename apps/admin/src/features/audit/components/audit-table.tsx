'use client';

import { DataTable } from '@/components/ui';
import type { AuditRow } from '@/features/audit/data/audit-adapter';

const columns = [
  {
    key: 'time',
    header: 'Time',
    render: (row: AuditRow) => new Date(row.createdAt).toLocaleString(),
  },
  { key: 'action', header: 'Action', render: (row: AuditRow) => row.action },
  {
    key: 'resource',
    header: 'Resource',
    render: (row: AuditRow) =>
      `${row.resourceType}${row.resourceId ? ` · ${row.resourceId}` : ''}`,
  },
  { key: 'actor', header: 'Actor', render: (row: AuditRow) => row.actorEmail ?? '—' },
];

type AuditTableProps = {
  data: AuditRow[];
  meta: string;
};

export function AuditTable({ data, meta }: AuditTableProps) {
  return (
    <DataTable
      columns={columns}
      data={data}
      getRowId={(row: AuditRow) => row.id}
      meta={meta}
    />
  );
}
