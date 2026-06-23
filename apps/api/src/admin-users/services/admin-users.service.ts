import { Injectable } from '@nestjs/common';
import type { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { UserDsarExportService } from '../../auth/services/user-dsar-export.service';
import { BulkAdminUsersDto } from '../dto/bulk-admin-users.dto';
import { ListAdminUsersQueryDto } from '../dto/list-admin-users-query.dto';
import { PatchAdminUserDto } from '../dto/patch-admin-user.dto';
import { PatchAdminUserRoleDto } from '../dto/patch-admin-user-role.dto';
import {
  AdminConfirmEmailChangeDto,
  AdminRequestEmailChangeDto,
} from '../dto/admin-email-change.dto';
import { AdminUsersIdentifierService } from './admin-users-identifier.service';
import { AdminUsersQueryService } from './admin-users-query.service';
import { AdminUsersWriteService } from './admin-users-write.service';

@Injectable()
export class AdminUsersService {
  constructor(
    private readonly query: AdminUsersQueryService,
    private readonly write: AdminUsersWriteService,
    private readonly identifier: AdminUsersIdentifierService,
    private readonly dsarExport: UserDsarExportService,
  ) {}

  list(query: ListAdminUsersQueryDto) {
    return this.query.list(query);
  }

  findOne(id: string) {
    return this.query.findOne(id);
  }

  patch(id: string, dto: PatchAdminUserDto, actor: AuthenticatedUser) {
    return this.write.patch(id, dto, actor);
  }

  patchRole(id: string, dto: PatchAdminUserRoleDto, actor: AuthenticatedUser) {
    return this.write.patchRole(id, dto, actor);
  }

  getAudit(userId: string, page: number, limit: number) {
    return this.query.getAudit(userId, page, limit);
  }

  getSessions(userId: string) {
    return this.query.getSessions(userId);
  }

  getSafetySummary(userId: string) {
    return this.query.getSafetySummary(userId);
  }

  revokeSession(userId: string, sessionId: string, actor: AuthenticatedUser) {
    return this.write.revokeSession(userId, sessionId, actor);
  }

  revokeAllSessions(userId: string, actor: AuthenticatedUser) {
    return this.write.revokeAllSessions(userId, actor);
  }

  getModerationNotes(userId: string, page: number, limit: number) {
    return this.query.getModerationNotes(userId, page, limit);
  }

  getStatusHistory(userId: string, page: number, limit: number) {
    return this.query.getStatusHistory(userId, page, limit);
  }

  createModerationNote(userId: string, body: string, actor: AuthenticatedUser) {
    return this.write.createModerationNote(userId, body, actor);
  }

  bulk(dto: BulkAdminUsersDto, actor: AuthenticatedUser) {
    return this.write.bulk(dto, actor);
  }

  getDataExport(userId: string) {
    return this.dsarExport.buildExport(userId);
  }

  requestEmailChange(userId: string, dto: AdminRequestEmailChangeDto, actor: AuthenticatedUser) {
    return this.identifier.requestEmailChange(userId, dto, actor);
  }

  confirmEmailChange(userId: string, dto: AdminConfirmEmailChangeDto, actor: AuthenticatedUser) {
    return this.identifier.confirmEmailChange(userId, dto, actor);
  }
}
