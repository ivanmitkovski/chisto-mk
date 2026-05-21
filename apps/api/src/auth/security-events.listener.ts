import { Injectable } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { AuditService } from '../audit/audit.service';
import { UserAuthSnapshotCacheService } from './user-auth-snapshot-cache.service';
import { recordAuditWriteFailure } from '../common/audit/audit-log-failure.util';

@Injectable()
export class SecurityEventsListener {
  constructor(
    private readonly audit: AuditService,
    private readonly authSnapshotCache: UserAuthSnapshotCacheService,
  ) {}

  @OnEvent('security.refresh_token_reuse')
  async onRefreshTokenReuse(payload: { userId: string }): Promise<void> {
    this.authSnapshotCache.invalidate(payload.userId);
    await this.audit
      .log({
        actorId: payload.userId,
        action: 'REFRESH_TOKEN_REUSE_DETECTED',
        resourceType: 'User',
        resourceId: payload.userId,
        metadata: { source: 'event_bus' },
      })
      .catch((err) => recordAuditWriteFailure('REFRESH_TOKEN_REUSE_DETECTED', err));
  }

  @OnEvent('security.sessions_revoked')
  onSessionsRevoked(payload: { userId: string; reason: string }): void {
    this.authSnapshotCache.invalidate(payload.userId);
  }
}
