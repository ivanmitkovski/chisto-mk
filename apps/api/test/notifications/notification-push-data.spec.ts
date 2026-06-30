/// <reference types="jest" />
import { NotificationType } from '../../src/prisma-client';
import { buildFcmDataPayload } from '../../src/notifications/util/notification-push-data';

describe('buildFcmDataPayload', () => {
  it('includes notificationId, string type, and stringified custom data', () => {
    const eventId = '550e8400-e29b-41d4-a716-446655440000';
    const payload = buildFcmDataPayload('notif-1', NotificationType.CLEANUP_EVENT, {
      eventId,
      kind: 'published',
    });
    expect(payload).toEqual({
      notificationId: 'notif-1',
      type: 'CLEANUP_EVENT',
      notificationType: 'CLEANUP_EVENT',
      eventId,
      kind: 'published',
    });
    expect(typeof payload.eventId).toBe('string');
  });

  it('includes unreadCount when provided in options', () => {
    const payload = buildFcmDataPayload('notif-3', NotificationType.COMMENT, undefined, {
      unreadCount: 12,
    });
    expect(payload.unreadCount).toBe('12');
    expect(payload.notificationId).toBe('notif-3');
  });

  it('includes title and body when provided in options', () => {
    const payload = buildFcmDataPayload('notif-4', NotificationType.COMMENT, undefined, {
      title: 'New comment',
      body: 'Someone replied',
    });
    expect(payload.title).toBe('New comment');
    expect(payload.body).toBe('Someone replied');
    expect(payload.notificationId).toBe('notif-4');
  });

  it('includes threadTitle for EVENT_CHAT payloads', () => {
    const eventId = '660e8400-e29b-41d4-a716-446655440001';
    const payload = buildFcmDataPayload('notif-2', NotificationType.EVENT_CHAT, {
      eventId,
      threadTitle: 'Park cleanup',
      messagePreview: 'hi',
    });
    expect(payload.threadTitle).toBe('Park cleanup');
    expect(payload.eventId).toBe(eventId);
  });
});
