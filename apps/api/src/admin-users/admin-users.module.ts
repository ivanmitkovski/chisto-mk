import { Module } from '@nestjs/common';
import { AdminRealtimeModule } from '../admin-realtime/admin-realtime.module';
import { ReportsUploadModule } from '../reports/reports-upload.module';
import { AdminUsersController } from './controllers/admin-users.controller';
import { AdminUsersIdentifierService } from './services/admin-users-identifier.service';
import { AdminUsersQueryService } from './services/admin-users-query.service';
import { AdminUsersService } from './services/admin-users.service';
import { AdminUsersWriteService } from './services/admin-users-write.service';
import { AuditModule } from '../audit/audit.module';

@Module({
  imports: [AuditModule, AdminRealtimeModule, ReportsUploadModule],
  controllers: [AdminUsersController],
  providers: [
    AdminUsersQueryService,
    AdminUsersWriteService,
    AdminUsersIdentifierService,
    AdminUsersService,
  ],
})
export class AdminUsersModule {}
