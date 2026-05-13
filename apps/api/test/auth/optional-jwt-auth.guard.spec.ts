/// <reference types="jest" />

import { ExecutionContext, UnauthorizedException } from '@nestjs/common';
import {
  OPTIONAL_JWT_BEARER_ENFORCED,
  OptionalJwtAuthGuard,
} from '../../src/auth/optional-jwt-auth.guard';

function ctx(
  req: Record<string, unknown> & { headers: Record<string, string>; [OPTIONAL_JWT_BEARER_ENFORCED]?: boolean },
): ExecutionContext {
  return {
    switchToHttp: () => ({
      getRequest: () => req,
    }),
  } as unknown as ExecutionContext;
}

describe('OptionalJwtAuthGuard', () => {
  it('allows anonymous when Authorization is missing', () => {
    const g = new OptionalJwtAuthGuard();
    expect(g.canActivate(ctx({ headers: {} }))).toBe(true);
  });

  it('throws when Bearer is present but token is empty', () => {
    const g = new OptionalJwtAuthGuard();
    expect(() => g.canActivate(ctx({ headers: { authorization: 'Bearer ' } }))).toThrow(
      UnauthorizedException,
    );
  });

  it('throws INVALID_TOKEN when Bearer path was enforced and user is missing', () => {
    const g = new OptionalJwtAuthGuard();
    const request = { headers: { authorization: 'Bearer x' }, [OPTIONAL_JWT_BEARER_ENFORCED]: true };
    try {
      g.handleRequest(undefined, false, {}, ctx(request));
      throw new Error('expected throw');
    } catch (e) {
      expect(e).toBeInstanceOf(UnauthorizedException);
      const body = (e as UnauthorizedException).getResponse() as { code?: string };
      expect(body.code).toBe('INVALID_TOKEN');
    }
    expect(request[OPTIONAL_JWT_BEARER_ENFORCED]).toBeUndefined();
  });

  it('returns undefined when enforcement flag is absent and user is missing', () => {
    const g = new OptionalJwtAuthGuard();
    const out = g.handleRequest(undefined, false, {}, ctx({ headers: {} }));
    expect(out).toBeUndefined();
  });
});
