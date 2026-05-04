import { Injectable } from '@nestjs/common';
import { ThrottlerGuard } from '@nestjs/throttler';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';

@Injectable()
export class ReportsUserThrottlerGuard extends ThrottlerGuard {
  protected async getTracker(req: Record<string, unknown>): Promise<string> {
    const user = req['user'] as AuthenticatedUser | undefined;
    if (user?.userId) {
      return `reports:user:${user.userId}`;
    }
    const ip = typeof req['ip'] === 'string' ? req['ip'] : 'unknown';
    return `reports:ip:${ip}`;
  }
}
