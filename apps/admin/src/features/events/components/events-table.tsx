'use client';

import { DataTable } from '@/components/ui';
import type { CleanupEventRow } from '@/features/events/data/events-adapter';

const columns = [
  {
    key: 'scheduled',
    header: 'Scheduled',
    render: (e: CleanupEventRow) => new Date(e.scheduledAt).toLocaleString(),
  },
  {
    key: 'site',
    header: 'Site',
    render: (e: CleanupEventRow) => `${e.site.latitude.toFixed(4)}, ${e.site.longitude.toFixed(4)}`,
  },
  {
    key: 'participants',
    header: 'Participants',
    render: (e: CleanupEventRow) => String(e.participantCount),
  },
  {
    key: 'completed',
    header: 'Completed',
    render: (e: CleanupEventRow) => (e.completedAt ? new Date(e.completedAt).toLocaleString() : '—'),
  },
];

type EventsTableProps = {
  data: CleanupEventRow[];
  meta: string;
};

export function EventsTable({ data, meta }: EventsTableProps) {
  return (
    <DataTable
      columns={columns}
      data={data}
      getRowId={(e) => e.id}
      meta={meta}
    />
  );
}
