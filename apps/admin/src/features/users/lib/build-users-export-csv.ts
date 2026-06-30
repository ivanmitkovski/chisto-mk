import type { UserRow } from '@/features/users/data/users-adapter';

function escapeCsv(value: string): string {
  if (value.includes('"') || value.includes(',') || value.includes('\n')) {
    return `"${value.replace(/"/g, '""')}"`;
  }
  return value;
}

export function buildUsersExportCsv(rows: UserRow[]): string {
  const header = ['id', 'firstName', 'lastName', 'email', 'phoneNumber', 'role', 'status', 'lastActiveAt', 'createdAt', 'pointsBalance'];
  const lines = [header.join(',')];
  for (const row of rows) {
    lines.push(
      [
        row.id,
        row.firstName,
        row.lastName,
        row.email,
        row.phoneNumber,
        row.role,
        row.status,
        row.lastActiveAt ?? '',
        row.createdAt,
        String(row.pointsBalance),
      ]
        .map((value) => escapeCsv(value))
        .join(','),
    );
  }
  return lines.join('\n');
}
