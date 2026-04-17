import { Injectable } from '@nestjs/common';
import { ThrottlerGuard } from '@nestjs/throttler';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';

type RequestWithUser = { user?: AuthenticatedUser; ip?: string };

/**
 * Authenticated check-in routes: rate-limit per user (JWT) instead of only per IP,
 * so a shared venue IP does not block unrelated volunteers.
 */
@Injectable()
export class EventsCheckInThrottlerGuard extends ThrottlerGuard {
  protected async getTracker(req: Record<string, unknown>): Promise<string> {
    const u = (req as RequestWithUser).user?.userId;
    if (typeof u === 'string' && u.length > 0) {
      return `u:${u}`;
    }
    const ip = typeof req.ip === 'string' && req.ip.length > 0 ? req.ip : 'unknown';
    return `ip:${ip}`;
  }
}
