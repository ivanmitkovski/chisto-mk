/// <reference types="jest" />

import {
  humanizeReportCategory,
  humanizeReportSeverity,
  humanizeUgcReason,
  humanizeUgcSubjectType,
  truncatePreview,
} from '../../src/email/util/email-labels';

describe('email-labels', () => {
  it('humanizes UGC subject types and reasons', () => {
    expect(humanizeUgcSubjectType('en', 'safety_issue')).toBe('Safety issue');
    expect(humanizeUgcSubjectType('mk', 'safety_issue')).toBe('Безбедносен проблем');
    expect(humanizeUgcReason('en', 'spam')).toBe('Spam');
    expect(humanizeUgcReason('mk', 'spam')).toBe('Спам');
  });

  it('falls back to generic humanization for unknown keys', () => {
    expect(humanizeUgcReason('en', 'custom_reason_code')).toBe('Custom Reason Code');
  });

  it('humanizes report category and severity', () => {
    expect(humanizeReportCategory('en', 'ILLEGAL_LANDFILL')).toBe('Illegal landfill');
    expect(humanizeReportSeverity('en', 4)).toBe('High');
    expect(humanizeReportSeverity('mk', 5)).toBe('Критично');
  });

  it('truncates long previews with ellipsis', () => {
    const long = 'a'.repeat(200);
    const out = truncatePreview(long, 140);
    expect(out.length).toBeLessThanOrEqual(140);
    expect(out.endsWith('…')).toBe(true);
  });
});
