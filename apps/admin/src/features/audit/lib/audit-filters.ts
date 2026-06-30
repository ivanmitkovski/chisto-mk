type AuditDateTranslate = (key: 'invalidDates' | 'fromBeforeTo') => string;

export function validateAuditDateRange(
  from: string,
  to: string,
  t?: AuditDateTranslate,
): string | null {
  if (!from || !to) return null;
  const fromDate = new Date(`${from}T00:00:00`);
  const toDate = new Date(`${to}T23:59:59`);
  if (Number.isNaN(fromDate.getTime()) || Number.isNaN(toDate.getTime())) {
    return t?.('invalidDates') ?? 'Enter valid dates.';
  }
  if (fromDate > toDate) {
    return t?.('fromBeforeTo') ?? '"From" must be on or before "To".';
  }
  return null;
}

export function buildAuditExportCsv(rows: Array<{
  createdAt: string;
  action: string;
  resourceType: string;
  resourceId: string | null;
  actorEmail: string | null;
}>): string {
  const header = ['createdAt', 'action', 'resourceType', 'resourceId', 'actorEmail'];
  const lines = rows.map((row) =>
    [
      row.createdAt,
      row.action,
      row.resourceType,
      row.resourceId ?? '',
      row.actorEmail ?? '',
    ]
      .map((value) => `"${String(value).replace(/"/g, '""')}"`)
      .join(','),
  );
  return [header.join(','), ...lines].join('\n');
}
