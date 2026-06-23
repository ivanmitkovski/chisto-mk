import { describe, expect, it } from 'vitest';
import { formatUserAuditAction, isIdentifierChangedEntry } from './format-user-audit-action';

describe('format-user-audit-action', () => {
  it('detects identifier changed audit rows', () => {
    expect(
      isIdentifierChangedEntry({
        id: '1',
        createdAt: '2026-01-01T00:00:00.000Z',
        action: 'IDENTIFIER_CHANGED',
        resourceType: 'User',
        resourceId: 'u1',
        actorEmail: 'admin@test.local',
        metadata: { field: 'email', initiatedBy: 'admin' },
      }),
    ).toBe(true);
  });

  it('formats identifier changed rows with labels', () => {
    const label = formatUserAuditAction(
      {
        id: '1',
        createdAt: '2026-01-01T00:00:00.000Z',
        action: 'IDENTIFIER_CHANGED',
        resourceType: 'User',
        resourceId: 'u1',
        actorEmail: null,
        metadata: { field: 'email', initiatedBy: 'admin' },
      },
      {
        identifierChanged: ({ field, initiatedBy }) => `${field}:${initiatedBy}`,
        defaultAction: (action) => action,
      },
    );
    expect(label).toBe('email:admin');
  });
});
