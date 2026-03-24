'use client';

import { DataTable, DataTableLink } from '@/components/ui';
import type { SiteRow } from '@/features/sites/data/sites-adapter';

const columns = [
  {
    key: 'location',
    header: 'Location',
    render: (s: SiteRow) => (
      <>
        <DataTableLink href={`/dashboard/sites/${s.id}`}>
          {s.latitude.toFixed(4)}, {s.longitude.toFixed(4)}
        </DataTableLink>
        {s.description ? (
          <span style={{ display: 'block', color: 'var(--text-secondary)', fontSize: 'var(--font-size-sm)' }}>
            {s.description}
          </span>
        ) : null}
      </>
    ),
  },
  { key: 'status', header: 'Status', render: (s: SiteRow) => s.status },
  { key: 'reports', header: 'Reports', render: (s: SiteRow) => String(s.reportCount) },
];

type SitesTableProps = {
  data: SiteRow[];
  meta: string;
};

export function SitesTable({ data, meta }: SitesTableProps) {
  return (
    <DataTable
      columns={columns}
      data={data}
      getRowId={(s) => s.id}
      meta={meta}
    />
  );
}
