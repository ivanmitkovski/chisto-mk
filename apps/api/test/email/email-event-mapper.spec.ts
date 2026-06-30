/// <reference types="jest" />

import { NotificationType } from '../../src/prisma-client';
import { mapNotificationEventToEmail } from '../../src/email/util/email-event-mapper';

describe('mapNotificationEventToEmail', () => {
  it('maps SYSTEM report_received', () => {
    const m = mapNotificationEventToEmail({
      type: NotificationType.SYSTEM,
      title: 'x',
      body: 'y',
      data: { kind: 'report_received', reportNumber: '#1', reportId: 'r1', siteId: 's1' },
    });
    expect(m?.templateId).toBe('report_received');
    expect(m?.context.reportNumber).toBe('#1');
  });

  it('maps REPORT_STATUS APPROVED', () => {
    const m = mapNotificationEventToEmail({
      type: NotificationType.REPORT_STATUS,
      title: 't',
      body: 'b',
      data: { status: 'APPROVED', reportNumber: '#2', reportId: 'r2' },
    });
    expect(m?.templateId).toBe('report_approved');
  });

  it('maps REPORT_STATUS DELETED with reason', () => {
    const m = mapNotificationEventToEmail({
      type: NotificationType.REPORT_STATUS,
      title: 't',
      body: 'b',
      data: { status: 'DELETED', reportNumber: '#3', reason: 'Spam' },
    });
    expect(m?.templateId).toBe('report_declined');
    expect(m?.context.reason).toBe('Spam');
  });

  it('maps cleanup event published', () => {
    const m = mapNotificationEventToEmail({
      type: NotificationType.CLEANUP_EVENT,
      title: 'Fallback title',
      body: 'b',
      data: { kind: 'published', eventTitle: 'River cleanup', eventId: 'e1', siteId: 's9' },
    });
    expect(m?.templateId).toBe('event_published');
    expect(m?.context.eventTitle).toBe('River cleanup');
  });

  it('maps cleanup completion award via pointsAwarded', () => {
    const m = mapNotificationEventToEmail({
      type: NotificationType.CLEANUP_EVENT,
      title: 'Done',
      body: 'b',
      data: { pointsAwarded: 50, eventId: 'e2', eventTitle: 'Park day' },
    });
    expect(m?.templateId).toBe('event_completed_award');
    expect(m?.context.points).toBe(50);
  });

  it('returns null for unmapped CLEANUP_EVENT kind', () => {
    expect(
      mapNotificationEventToEmail({
        type: NotificationType.CLEANUP_EVENT,
        title: 't',
        body: 'b',
        data: { kind: 'pending_review' },
      }),
    ).toBeNull();
  });
});
