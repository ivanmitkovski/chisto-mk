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
import { AdminUsersBulkWriteService } from './admin-users-bulk-write.service';
import { AdminUsersWriteService } from './admin-users-write.service';

@Injectable()
export class AdminUsersService {
  constructor(
    private readonly query: AdminUsersQueryService,
    private readonly write: AdminUsersWriteService,
    private readonly bulkWrite: AdminUsersBulkWriteService,
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

  bulk(dto: BulkAdminUsersDto, actor: AuthenticatedUser) {
    return this.bulkWrite.bulk(dto, actor);
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
