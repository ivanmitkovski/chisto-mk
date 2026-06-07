import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Request } from 'express';
import { PERMISSIONS_KEY } from '../decorators/require-permission.decorator';
import {
  AdminPermission,
  roleHasPermission,
} from '../constants/admin-permissions';
import { AuthenticatedUser } from '../types/authenticated-user.type';
import { AuditService } from '../../audit/services/audit.service';
import { recordAuditWriteFailure } from '../../common/audit/audit-log-failure.util';

type AuthenticatedRequest = Request & { user?: AuthenticatedUser };

@Injectable()
export class PermissionsGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly audit: AuditService,
  ) {}

  canActivate(context: ExecutionContext): boolean {
    const required = this.reflector.getAllAndOverride<AdminPermission[]>(PERMISSIONS_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);

    if (!required || required.length === 0) {
      return true;
    }

    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const user = request.user;

    if (!user) {
      throw new ForbiddenException({ code: 'FORBIDDEN', message: 'Access denied' });
    }

    const allowed = required.some((p) => roleHasPermission(user.role, p));
    if (!allowed) {
      const route = `${request.method ?? '?'} ${request.path ?? request.url ?? '?'}`;
      void this.audit
        .log({
          actorId: user.userId,
          action: 'ACCESS_DENIED_PERMISSION',
          resourceType: 'HttpRoute',
          resourceId: null,
          metadata: { route, requiredPermissions: required, actualRole: user.role },
        })
        .catch((err) => recordAuditWriteFailure('ACCESS_DENIED_PERMISSION', err));
      throw new ForbiddenException({
        code: 'FORBIDDEN',
        message: 'Insufficient permissions',
      });
    }

    return true;
  }
}
