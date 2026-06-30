import { Injectable } from '@nestjs/common';
import type { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { AdminUsersModerationQueryService } from './admin-users-moderation-query.service';
import { AdminUsersSessionWriteService } from './admin-users-session-write.service';

@Injectable()
export class AdminUsersModerationService {
  constructor(
    private readonly moderationQuery: AdminUsersModerationQueryService,
    private readonly sessionWrite: AdminUsersSessionWriteService,
  ) {}

  getSafetySummary(userId: string) {
    return this.moderationQuery.getSafetySummary(userId);
  }

  getModerationNotes(userId: string, page: number, limit: number) {
    return this.moderationQuery.getModerationNotes(userId, page, limit);
  }

  getStatusHistory(userId: string, page: number, limit: number) {
    return this.moderationQuery.getStatusHistory(userId, page, limit);
  }

  createModerationNote(userId: string, body: string, actor: AuthenticatedUser) {
    return this.sessionWrite.createModerationNote(userId, body, actor);
  }

  revokeSession(userId: string, sessionId: string, actor: AuthenticatedUser) {
    return this.sessionWrite.revokeSession(userId, sessionId, actor);
  }

  revokeAllSessions(userId: string, actor: AuthenticatedUser) {
    return this.sessionWrite.revokeAllSessions(userId, actor);
  }
}
