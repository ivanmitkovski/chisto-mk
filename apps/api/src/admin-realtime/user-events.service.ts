import { Injectable } from '@nestjs/common';

import { AdminTopicEventBus } from './admin-topic-event-bus';

export type UserEventType = 'user_created' | 'user_updated';

export type UserEvent = {
  type: UserEventType;
  userId: string;
};

@Injectable()
export class UserEventsService {
  private readonly bus = new AdminTopicEventBus<UserEvent>();

  getEvents() {
    return this.bus.getEvents();
  }

  emitUserCreated(userId: string): void {
    this.bus.emit({ type: 'user_created', userId });
  }

  emitUserUpdated(userId: string): void {
    this.bus.emit({ type: 'user_updated', userId });
  }
}
