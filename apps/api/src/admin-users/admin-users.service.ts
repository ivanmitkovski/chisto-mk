import { Injectable } from '@nestjs/common';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { BulkAdminUsersDto } from './dto/bulk-admin-users.dto';
import { ListAdminUsersQueryDto } from './dto/list-admin-users-query.dto';
import { PatchAdminUserDto } from './dto/patch-admin-user.dto';
import { PatchAdminUserRoleDto } from './dto/patch-admin-user-role.dto';
import { AdminUsersQueryService } from './admin-users-query.service';
import { AdminUsersWriteService } from './admin-users-write.service';

@Injectable()
export class AdminUsersService {
  constructor(
    private readonly query: AdminUsersQueryService,
    private readonly write: AdminUsersWriteService,
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
    return this.write.bulk(dto, actor);
  }
}
