import { ExecutionContext, Injectable } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { Observable } from 'rxjs';
import { catchError, map } from 'rxjs/operators';
import { of } from 'rxjs';

/**
 * Runs JWT validation when `Authorization: Bearer …` is present; otherwise allows the request
 * through with no `request.user`. Invalid/expired tokens are treated as anonymous (no user).
 *
 * Use on public GET routes that still personalize payloads (`isUpvotedByMe`, etc.).
 */
@Injectable()
export class OptionalJwtAuthGuard extends AuthGuard('jwt') {
  canActivate(context: ExecutionContext): boolean | Promise<boolean> | Observable<boolean> {
    const request = context.switchToHttp().getRequest<{ headers?: { authorization?: string } }>();
    const authHeader = request.headers?.authorization;
    if (!authHeader?.startsWith('Bearer ')) {
      return true;
    }
    const outcome = super.canActivate(context);
    if (outcome instanceof Observable) {
      return outcome.pipe(
        map(() => true),
        catchError(() => of(true)),
      );
    }
    if (outcome instanceof Promise) {
      return outcome.catch(() => true);
    }
    return outcome;
  }

  handleRequest<TUser>(err: Error | undefined, user: TUser | false): TUser | undefined {
    if (err || !user) {
      return undefined;
    }
    return user;
  }
}
