import type { AuditLogAdminRow } from '@/features/events/data/events-adapter';

const ACTION_LABEL_KEYS: Record<string, string> = {
  CLEANUP_EVENT_CREATED: 'auditActionCreated',
  CLEANUP_EVENT_APPROVED: 'auditActionApproved',
  CLEANUP_EVENT_DECLINED: 'auditActionDeclined',
  CLEANUP_EVENT_RETURNED_TO_PENDING: 'auditActionReturnedToPending',
  CLEANUP_EVENT_UPDATED: 'auditActionUpdated',
  CLEANUP_EVENT_PARTICIPANT_REMOVED: 'auditActionParticipantRemoved',
  CLEANUP_EVENT_NOTE_ADDED: 'auditActionNoteAdded',
  CLEANUP_EVENT_NOTE_REMOVED: 'auditActionNoteRemoved',
};

export function auditActionLabelKey(action: string): string {
  return ACTION_LABEL_KEYS[action] ?? 'auditActionGeneric';
}

export function formatAuditMetadataSummary(meta: unknown): string | null {
  if (meta == null || typeof meta !== 'object') {
    return null;
  }
  const record = meta as Record<string, unknown>;
  if (typeof record.declineReason === 'string' && record.declineReason.trim()) {
    return record.declineReason.trim();
  }
  if (typeof record.status === 'string') {
    return record.status;
  }
  if (typeof record.lifecycleStatus === 'string') {
    return record.lifecycleStatus;
  }
  if (typeof record.userId === 'string') {
    return record.userId;
  }
  if (typeof record.noteId === 'string') {
    return record.noteId;
  }
  return null;
}

export function sortAuditNewestFirst(rows: AuditLogAdminRow[]): AuditLogAdminRow[] {
  return [...rows].sort(
    (a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime(),
  );
}
