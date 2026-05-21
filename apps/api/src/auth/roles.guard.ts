import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Role } from '../prisma-client';
import { Request } from 'express';
import { ROLES_KEY } from './roles.decorator';
import { AuthenticatedUser } from './types/authenticated-user.type';
import { AuditService } from '../audit/audit.service';
import { recordAuditWriteFailure } from '../common/audit/audit-log-failure.util';

type AuthenticatedRequest = Request & { user?: AuthenticatedUser };

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly audit: AuditService,
  ) {}

  canActivate(context: ExecutionContext): boolean {
    // SECURITY: Fail closed — JwtAuthGuard + RolesGuard must always pair with @Roles(); missing metadata means deny.
    const requiredRoles = this.reflector.getAllAndOverride<Role[]>(ROLES_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);

    if (!requiredRoles || requiredRoles.length === 0) {
      throw new ForbiddenException({
        code: 'FORBIDDEN',
        message: 'Access denied',
      });
    }

    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const user = request.user;

    if (!user) {
      throw new ForbiddenException({
        code: 'FORBIDDEN',
        message: 'Access denied',
      });
    }

    if (!requiredRoles.includes(user.role)) {
      // SECURITY: Forensic trail for privilege probing (async fire-and-forget).
      const route = `${request.method ?? '?'} ${request.path ?? request.url ?? '?'}`;
      void this.audit
        .log({
          actorId: user.userId,
          action: 'ACCESS_DENIED_ROLE',
          resourceType: 'HttpRoute',
          resourceId: null,
          metadata: { route, requiredRoles, actualRole: user.role },
        })
        .catch((err) => recordAuditWriteFailure('ACCESS_DENIED_ROLE', err));
      throw new ForbiddenException({
        code: 'FORBIDDEN',
        message: 'Insufficient role permissions',
      });
    }

    return true;
  }
}
