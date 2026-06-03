import { Module } from '@nestjs/common';
import { AdminRealtimeModule } from '../admin-realtime/admin-realtime.module';
import { AdminUsersController } from './controllers/admin-users.controller';
import { AdminUsersQueryService } from './services/admin-users-query.service';
import { AdminUsersService } from './services/admin-users.service';
import { AdminUsersWriteService } from './services/admin-users-write.service';
import { AuditModule } from '../audit/audit.module';

@Module({
  imports: [AuditModule, AdminRealtimeModule],
  controllers: [AdminUsersController],
  providers: [AdminUsersQueryService, AdminUsersWriteService, AdminUsersService],
})
export class AdminUsersModule {}
