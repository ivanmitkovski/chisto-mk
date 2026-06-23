import { Module } from '@nestjs/common';
import { AdminRealtimeModule } from '../admin-realtime/admin-realtime.module';
import { ReportsUploadModule } from '../reports/reports-upload.module';
import { AdminUsersController } from './controllers/admin-users.controller';
import { AdminUsersIdentifierService } from './services/admin-users-identifier.service';
import { AdminUsersModerationQueryService } from './services/admin-users-moderation-query.service';
import { AdminUsersQueryService } from './services/admin-users-query.service';
import { AdminUsersBulkWriteService } from './services/admin-users-bulk-write.service';
import { AdminUsersSessionWriteService } from './services/admin-users-session-write.service';
import { AdminUsersStatusHistoryService } from './services/admin-users-status-history.service';
import { AdminUsersModerationService } from './services/admin-users-moderation.service';
import { AdminUsersService } from './services/admin-users.service';
import { AdminUsersWriteService } from './services/admin-users-write.service';
import { AuditModule } from '../audit/audit.module';

@Module({
  imports: [AuditModule, AdminRealtimeModule, ReportsUploadModule],
  controllers: [AdminUsersController],
  providers: [
    AdminUsersQueryService,
    AdminUsersModerationQueryService,
    AdminUsersWriteService,
    AdminUsersBulkWriteService,
    AdminUsersSessionWriteService,
    AdminUsersStatusHistoryService,
    AdminUsersIdentifierService,
    AdminUsersModerationService,
    AdminUsersService,
  ],
})
export class AdminUsersModule {}
