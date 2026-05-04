/// <reference types="jest" />
import { moderationQueueMetaForStatus } from '../../src/reports/report-moderation-queue-meta';

describe('moderationQueueMetaForStatus', () => {
  it('maps NEW and IN_REVIEW to SLA hints', () => {
    const n = moderationQueueMetaForStatus('NEW');
    expect(n.moderationSlaLabel).toBe('4h remaining');
    const r = moderationQueueMetaForStatus('IN_REVIEW');
    expect(r.moderationSlaLabel).toBe('2h remaining');
    const a = moderationQueueMetaForStatus('APPROVED');
    expect(a.moderationSlaLabel).toBe('Completed');
  });
});
