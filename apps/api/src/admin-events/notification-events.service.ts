import { Injectable } from '@nestjs/common';
import { Subject } from 'rxjs';

export type NotificationEventType = 'notification_created';

export type NotificationEvent = {
  type: NotificationEventType;
  notificationId: string;
  title?: string | undefined;
};

@Injectable()
export class NotificationEventsService {
  private readonly events$ = new Subject<NotificationEvent>();

  getEvents() {
    return this.events$.asObservable();
  }

  emitNotificationCreated(notificationId: string, title?: string): void {
    this.events$.next({
      type: 'notification_created',
      notificationId,
      ...(title !== undefined && { title }),
    });
  }
}
