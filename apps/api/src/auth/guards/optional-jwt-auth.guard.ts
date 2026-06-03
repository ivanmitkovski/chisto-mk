import { ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { Observable } from 'rxjs';

/** Exported for unit tests — marks that `canActivate` sent a non-empty Bearer to Passport. */
export const OPTIONAL_JWT_BEARER_ENFORCED = Symbol('optionalJwtBearerEnforced');

/**
 * Runs JWT validation when `Authorization: Bearer …` is present; otherwise allows the request
 * through with no `request.user`. Malformed Bearer or invalid/expired tokens fail closed (401).
 *
 * Use on public GET routes that still personalize payloads (`isUpvotedByMe`, etc.).
 */
@Injectable()
export class OptionalJwtAuthGuard extends AuthGuard('jwt') {
  canActivate(context: ExecutionContext): boolean | Promise<boolean> | Observable<boolean> {
    const request = context.switchToHttp().getRequest<{
      headers?: { authorization?: string };
      [OPTIONAL_JWT_BEARER_ENFORCED]?: boolean;
    }>();
    const authHeader = request.headers?.authorization;
    if (!authHeader?.startsWith('Bearer ')) {
      delete request[OPTIONAL_JWT_BEARER_ENFORCED];
      return true;
    }
    const token = authHeader.slice(7).trim();
    if (!token) {
      throw new UnauthorizedException({
        code: 'INVALID_AUTH_HEADER',
        message: 'Malformed Authorization header',
      });
    }
    request[OPTIONAL_JWT_BEARER_ENFORCED] = true;
    return super.canActivate(context);
  }

  handleRequest<TUser>(
    err: Error | undefined,
    user: TUser | false,
    _info: unknown,
    context: ExecutionContext,
  ): TUser | undefined {
    const request = context.switchToHttp().getRequest<{ [OPTIONAL_JWT_BEARER_ENFORCED]?: boolean }>();
    const enforced = request[OPTIONAL_JWT_BEARER_ENFORCED];
    delete request[OPTIONAL_JWT_BEARER_ENFORCED];

    if (enforced) {
      if (err || !user) {
        throw new UnauthorizedException({
          code: 'INVALID_TOKEN',
          message: 'Invalid or expired authentication token',
        });
      }
      return user as TUser;
    }

    if (err || !user) {
      return undefined;
    }
    return user as TUser;
  }
}
