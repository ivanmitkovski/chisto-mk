import { Injectable } from '@nestjs/common';
import { Subject } from 'rxjs';

export type UserEventType = 'user_created' | 'user_updated';

export type UserEvent = {
  type: UserEventType;
  userId: string;
};

@Injectable()
export class UserEventsService {
  private readonly events$ = new Subject<UserEvent>();

  getEvents() {
    return this.events$.asObservable();
  }

  emitUserCreated(userId: string): void {
    this.events$.next({ type: 'user_created', userId });
  }

  emitUserUpdated(userId: string): void {
    this.events$.next({ type: 'user_updated', userId });
  }
}
