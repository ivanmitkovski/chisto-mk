import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import type { AuthenticatedUser } from './types/authenticated-user.type';

/**
 * Requires a verified phone number for citizen write actions.
 * Use together with JwtAuthGuard.
 */
@Injectable()
export class PhoneVerifiedGuard implements CanActivate {
  constructor(private readonly prisma: PrismaService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const req = context.switchToHttp().getRequest<{ user?: AuthenticatedUser }>();
    const user = req.user;
    if (!user?.userId) {
      throw new UnauthorizedException({
        code: 'UNAUTHORIZED',
        message: 'Authentication required',
      });
    }

    const row = await this.prisma.user.findUnique({
      where: { id: user.userId },
      select: { isPhoneVerified: true, status: true },
    });
    if (!row) {
      throw new UnauthorizedException({
        code: 'INVALID_TOKEN_USER',
        message: 'User not found',
      });
    }
    if (!row.isPhoneVerified) {
      throw new ForbiddenException({
        code: 'PHONE_NOT_VERIFIED',
        message: 'Phone verification is required for this action',
      });
    }
    return true;
  }
}
