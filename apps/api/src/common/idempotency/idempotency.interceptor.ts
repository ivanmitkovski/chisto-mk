import {
  BadRequestException,
  CallHandler,
  ConflictException,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { createHash } from 'node:crypto';
import type { Request, Response } from 'express';
import { Observable, firstValueFrom, of } from 'rxjs';
import { IDEMPOTENCY_SCOPE_KEY } from './idempotency.decorator';
import { IdempotencyResponseStore } from './idempotency-response.store';

const TTL_MS = 24 * 60 * 60 * 1000;
const LOCK_TTL_MS = 2 * 60 * 1000;
const LOCK_WAIT_MS = 30_000;
const LOCK_POLL_MS = 100;

@Injectable()
export class IdempotencyInterceptor implements NestInterceptor {
  constructor(
    private readonly reflector: Reflector,
    private readonly store: IdempotencyResponseStore,
  ) {}

  async intercept(context: ExecutionContext, next: CallHandler): Promise<Observable<unknown>> {
    const scope = this.reflector.get<string | undefined>(IDEMPOTENCY_SCOPE_KEY, context.getHandler());
    if (!scope) {
      return next.handle();
    }

    const req = context.switchToHttp().getRequest<Request & { user?: { userId: string } }>();
    const res = context.switchToHttp().getResponse<Response>();
    const rawKey = req.headers['x-idempotency-key'] ?? req.headers['idempotency-key'];
    const key = Array.isArray(rawKey) ? rawKey[0] : rawKey;
    if (!key?.trim()) {
      return next.handle();
    }
    const clientKey = key.trim();
    if (clientKey.length < 8 || clientKey.length > 128) {
      throw new BadRequestException({
        code: 'INVALID_IDEMPOTENCY_KEY',
        message: 'Idempotency key must be 8–128 characters',
      });
    }

    const actorId = req.user?.userId ?? 'anonymous';
    const storageKey = createHash('sha256')
      .update(`${scope}:${req.method}:${req.path}:${actorId}:${clientKey}`)
      .digest('hex');

    const cached = await this.store.get(storageKey);
    if (cached) {
      res.status(cached.statusCode);
      return of(cached.body);
    }

    const acquired = await this.store.tryAcquireInFlightLock(storageKey, LOCK_TTL_MS);
    if (!acquired) {
      const replay = await this.waitForCachedResponse(storageKey);
      if (replay) {
        res.status(replay.statusCode);
        return of(replay.body);
      }
      throw new ConflictException({
        code: 'IDEMPOTENCY_IN_FLIGHT',
        message: 'An identical request is still being processed',
      });
    }

    try {
      const body = await firstValueFrom(next.handle());
      const statusCode = res.statusCode || 200;
      if (statusCode >= 200 && statusCode < 300) {
        await this.store.set(storageKey, { statusCode, body }, TTL_MS);
      }
      return of(body);
    } finally {
      await this.store.releaseInFlightLock(storageKey);
    }
  }

  private async waitForCachedResponse(
    storageKey: string,
  ): Promise<{ statusCode: number; body: unknown } | null> {
    const deadline = Date.now() + LOCK_WAIT_MS;
    while (Date.now() < deadline) {
      const cached = await this.store.get(storageKey);
      if (cached) {
        return cached;
      }
      await new Promise((r) => setTimeout(r, LOCK_POLL_MS));
    }
    return null;
  }
}
