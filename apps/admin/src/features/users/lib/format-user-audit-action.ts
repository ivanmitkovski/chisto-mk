import type { AuditEntry } from '@/features/users/data/users-adapter';

type IdentifierAuditMetadata = {
  field?: string;
  initiatedBy?: string;
  reasonCode?: string;
};

export function isIdentifierChangedEntry(entry: AuditEntry): boolean {
  return entry.action === 'IDENTIFIER_CHANGED';
}

export function formatUserAuditAction(
  entry: AuditEntry,
  labels: {
    identifierChanged: (params: { field: string; initiatedBy: string }) => string;
    defaultAction: (action: string) => string;
  },
): string {
  if (entry.action !== 'IDENTIFIER_CHANGED') {
    return labels.defaultAction(entry.action);
  }
  const metadata = (entry.metadata ?? {}) as IdentifierAuditMetadata;
  const field = metadata.field === 'phone' ? 'phone' : 'email';
  const initiatedBy = metadata.initiatedBy === 'admin' ? 'admin' : 'user';
  return labels.identifierChanged({ field, initiatedBy });
}

export function filterIdentifierHistory(entries: AuditEntry[]): AuditEntry[] {
  return entries.filter(isIdentifierChangedEntry);
}
