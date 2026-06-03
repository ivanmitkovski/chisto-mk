import { Injectable } from '@nestjs/common';
import { Role, UserStatus } from '../../prisma-client';

export type UserAuthSnapshot = {
  role: Role;
  status: UserStatus;
  email: string;
  phoneNumber: string;
};

type CacheEntry = {
  snapshot: UserAuthSnapshot;
  expiresAtMs: number;
};

/** Short-lived cache to avoid hammering User on every JWT validation. */
@Injectable()
export class UserAuthSnapshotCacheService {
  private readonly ttlMs = 30_000;
  private readonly store = new Map<string, CacheEntry>();

  get(userId: string): UserAuthSnapshot | undefined {
    const entry = this.store.get(userId);
    if (!entry) return undefined;
    if (Date.now() > entry.expiresAtMs) {
      this.store.delete(userId);
      return undefined;
    }
    return entry.snapshot;
  }

  set(userId: string, snapshot: UserAuthSnapshot): void {
    this.store.set(userId, {
      snapshot,
      expiresAtMs: Date.now() + this.ttlMs,
    });
  }

  invalidate(userId: string): void {
    this.store.delete(userId);
  }
}
