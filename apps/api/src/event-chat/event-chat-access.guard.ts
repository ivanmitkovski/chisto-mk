import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { EventChatAccessService } from './event-chat-access.service';

@Injectable()
export class EventChatAccessGuard implements CanActivate {
  constructor(private readonly eventChatAccess: EventChatAccessService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const req = context.switchToHttp().getRequest<{
      user?: AuthenticatedUser;
      params: { eventId?: string };
    }>();
    const user = req.user;
    const eventId = req.params?.eventId?.trim();
    if (!user || !eventId) {
      throw new ForbiddenException({
        code: 'EVENT_CHAT_FORBIDDEN',
        message: 'Chat access denied',
      });
    }
    await this.eventChatAccess.assertCanAccessEventChat(user.userId, eventId);
    return true;
  }
}
