import { Module } from '@nestjs/common';
import { AdminRealtimeModule } from '../admin-realtime/admin-realtime.module';
import { AdminUsersController } from './admin-users.controller';
import { AdminUsersQueryService } from './admin-users-query.service';
import { AdminUsersService } from './admin-users.service';
import { AdminUsersWriteService } from './admin-users-write.service';
import { AuditModule } from '../audit/audit.module';

@Module({
  imports: [AuditModule, AdminRealtimeModule],
  controllers: [AdminUsersController],
  providers: [AdminUsersQueryService, AdminUsersWriteService, AdminUsersService],
})
export class AdminUsersModule {}
