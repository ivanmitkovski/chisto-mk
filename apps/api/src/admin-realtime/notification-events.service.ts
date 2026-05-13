import { Injectable } from '@nestjs/common';

import { AdminTopicEventBus } from './admin-topic-event-bus';

export type NotificationEventType = 'notification_created';

export type NotificationEvent = {
  type: NotificationEventType;
  notificationId: string;
  title?: string | undefined;
};

@Injectable()
export class NotificationEventsService {
  private readonly bus = new AdminTopicEventBus<NotificationEvent>();

  getEvents() {
    return this.bus.getEvents();
  }

  emitNotificationCreated(notificationId: string, title?: string): void {
    this.bus.emit({
      type: 'notification_created',
      notificationId,
      ...(title !== undefined && { title }),
    });
  }
}
