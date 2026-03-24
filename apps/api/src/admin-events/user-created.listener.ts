import { Injectable } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { UserEventsService } from './user-events.service';

type UserCreatedPayload = { userId: string };

@Injectable()
export class UserCreatedListener {
  constructor(private readonly userEventsService: UserEventsService) {}

  @OnEvent('user.created')
  handleUserCreated(payload: UserCreatedPayload): void {
    this.userEventsService.emitUserCreated(payload.userId);
  }
}
