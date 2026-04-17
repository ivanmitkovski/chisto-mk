import { Injectable } from '@nestjs/common';
import { ThrottlerGuard } from '@nestjs/throttler';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';

type RequestWithUser = {
  user?: AuthenticatedUser;
  ip?: string;
  params?: { eventId?: string };
};

/**
 * Event chat mutations: rate-limit per authenticated user **and** `eventId` route param
 * so one hot thread cannot exhaust another user's budget on a shared IP.
 */
@Injectable()
export class EventChatThrottlerGuard extends ThrottlerGuard {
  protected async getTracker(req: Record<string, unknown>): Promise<string> {
    const typed = req as RequestWithUser;
    const u = typed.user?.userId;
    const eid =
      typeof typed.params?.eventId === 'string' && typed.params.eventId.length > 0
        ? typed.params.eventId
        : '';
    if (typeof u === 'string' && u.length > 0 && eid.length > 0) {
      return `u:${u}:evt:${eid}`;
    }
    if (typeof u === 'string' && u.length > 0) {
      return `u:${u}`;
    }
    const ip = typeof typed.ip === 'string' && typed.ip.length > 0 ? typed.ip : 'unknown';
    return `ip:${ip}`;
  }
}
