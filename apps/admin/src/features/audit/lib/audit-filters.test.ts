import { describe, expect, it } from 'vitest';
import { buildAuditExportCsv, validateAuditDateRange } from './audit-filters';

const auditDateT = (key: 'invalidDates' | 'fromBeforeTo') =>
  key === 'invalidDates' ? 'Enter valid dates.' : '"From" must be on or before "To".';

describe('validateAuditDateRange', () => {
  it('returns null when only one date is set', () => {
    expect(validateAuditDateRange('2026-01-01', '')).toBeNull();
  });

  it('rejects inverted ranges with fallback message', () => {
    expect(validateAuditDateRange('2026-02-01', '2026-01-01')).toBe('"From" must be on or before "To".');
  });

  it('rejects inverted ranges with translated message', () => {
    expect(validateAuditDateRange('2026-02-01', '2026-01-01', auditDateT)).toBe(
      '"From" must be on or before "To".',
    );
  });

  it('rejects invalid dates with translated message', () => {
    expect(validateAuditDateRange('not-a-date', '2026-01-01', auditDateT)).toBe('Enter valid dates.');
  });
});

describe('buildAuditExportCsv', () => {
  it('escapes quotes in CSV values', () => {
    const csv = buildAuditExportCsv([
      {
        createdAt: '2026-01-01T00:00:00.000Z',
        action: 'USER_UPDATED',
        resourceType: 'User',
        resourceId: 'abc',
        actorEmail: 'a"b@c.com',
      },
    ]);
    expect(csv).toContain('"a""b@c.com"');
  });
});
