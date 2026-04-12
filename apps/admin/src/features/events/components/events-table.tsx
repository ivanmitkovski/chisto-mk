'use client';

import { DataTable } from '@/components/ui';
import type { CleanupEventRow } from '@/features/events/data/events-adapter';

function truncate(s: string, max: number): string {
  const t = s.trim();
  if (t.length <= max) return t;
  return `${t.slice(0, max - 1)}…`;
}

const columns = [
  {
    key: 'title',
    header: 'Title',
    render: (e: CleanupEventRow) => truncate(e.title || '—', 48),
  },
  {
    key: 'scheduled',
    header: 'Scheduled',
    render: (e: CleanupEventRow) => new Date(e.scheduledAt).toLocaleString(),
  },
  {
    key: 'lifecycle',
    header: 'Lifecycle',
    render: (e: CleanupEventRow) => e.lifecycleStatus,
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
