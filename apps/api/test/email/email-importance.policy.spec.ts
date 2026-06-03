/// <reference types="jest" />

import { NotificationType } from '../../src/prisma-client';
import { isImportantNotificationEmail } from '../../src/email/util/email-importance.policy';

describe('isImportantNotificationEmail', () => {
  it('returns true for event completion points awarded', () => {
    expect(
      isImportantNotificationEmail({
        type: NotificationType.CLEANUP_EVENT,
        title: 'Done',
        body: 'b',
        data: { pointsAwarded: 50, eventId: 'e1', eventTitle: 'Park day' },
      }),
    ).toBe(true);
  });

  it('returns true for event completion no-show clawback', () => {
    expect(
      isImportantNotificationEmail({
        type: NotificationType.CLEANUP_EVENT,
        title: 'Adjusted',
        body: 'b',
        data: { pointsAdjusted: -10, eventId: 'e2', eventTitle: 'River cleanup' },
      }),
    ).toBe(true);
  });

  it('returns false for report received', () => {
    expect(
      isImportantNotificationEmail({
        type: NotificationType.SYSTEM,
        title: 'x',
        body: 'y',
        data: { kind: 'report_received', reportNumber: '#1', reportId: 'r1', siteId: 's1' },
      }),
    ).toBe(false);
  });

  it('returns false for report approved', () => {
    expect(
      isImportantNotificationEmail({
        type: NotificationType.REPORT_STATUS,
        title: 't',
        body: 'b',
        data: { status: 'APPROVED', reportNumber: '#2', reportId: 'r2' },
      }),
    ).toBe(false);
  });

  it('returns false for report declined', () => {
    expect(
      isImportantNotificationEmail({
        type: NotificationType.REPORT_STATUS,
        title: 't',
        body: 'b',
        data: { status: 'DELETED', reportNumber: '#3', reason: 'Spam' },
      }),
    ).toBe(false);
  });

  it('returns false for report merged', () => {
    expect(
      isImportantNotificationEmail({
        type: NotificationType.REPORT_STATUS,
        title: 't',
        body: 'b',
        data: { mergeRole: 'primary', reportNumber: '#4', reportId: 'r4' },
      }),
    ).toBe(false);
  });

  it('returns false for event published', () => {
    expect(
      isImportantNotificationEmail({
        type: NotificationType.CLEANUP_EVENT,
        title: 'Fallback title',
        body: 'b',
        data: { kind: 'published', eventTitle: 'River cleanup', eventId: 'e1', siteId: 's9' },
      }),
    ).toBe(false);
  });

  it('returns false for event approved', () => {
    expect(
      isImportantNotificationEmail({
        type: NotificationType.CLEANUP_EVENT,
        title: 't',
        body: 'b',
        data: { kind: 'approved', eventTitle: 'Park day', eventId: 'e3' },
      }),
    ).toBe(false);
  });

  it('returns false for event declined', () => {
    expect(
      isImportantNotificationEmail({
        type: NotificationType.CLEANUP_EVENT,
        title: 't',
        body: 'b',
        data: { kind: 'declined', eventTitle: 'Park day', eventId: 'e4' },
      }),
    ).toBe(false);
  });

  it('returns false for site upvote', () => {
    expect(
      isImportantNotificationEmail({
        type: NotificationType.UPVOTE,
        title: 't',
        body: 'b',
        data: { siteId: 's1' },
      }),
    ).toBe(false);
  });

  it('returns false for site comment', () => {
    expect(
      isImportantNotificationEmail({
        type: NotificationType.COMMENT,
        title: 't',
        body: 'b',
        data: { siteId: 's1', messagePreview: 'Hello' },
      }),
    ).toBe(false);
  });

  it('returns false for unmapped cleanup event kind', () => {
    expect(
      isImportantNotificationEmail({
        type: NotificationType.CLEANUP_EVENT,
        title: 't',
        body: 'b',
        data: { kind: 'pending_review' },
      }),
    ).toBe(false);
  });
});
