import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { AuditModule } from '../audit/audit.module';
import { EmailModule } from '../email/email.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { GamificationModule } from '../gamification/gamification.module';
import { ReportsModule } from '../reports/reports.module';
import { AdminBroadcastsController } from './controllers/admin-broadcasts.controller';
import { AdminGamificationController } from './controllers/admin-gamification.controller';
import { AdminAppConfigController } from './controllers/admin-app-config.controller';
import { AdminCommsController } from './controllers/admin-comms.controller';
import { AdminOperationsController } from './controllers/admin-operations.controller';
import { AdminBroadcastsService } from './services/admin-broadcasts.service';
import { AdminBroadcastsDispatchService } from './services/admin-broadcasts-dispatch.service';
import { AdminBroadcastScheduleWorkerService } from './services/admin-broadcast-schedule-worker.service';
import { AdminGamificationService } from './services/admin-gamification.service';
import { AdminAppConfigService } from './services/admin-app-config.service';
import { AdminCommsService } from './services/admin-comms.service';

@Module({
  imports: [PrismaModule, AuditModule, EmailModule, NotificationsModule, GamificationModule, ReportsModule],
  controllers: [
    AdminBroadcastsController,
    AdminGamificationController,
    AdminAppConfigController,
    AdminCommsController,
    AdminOperationsController,
  ],
  providers: [
    AdminBroadcastsService,
    AdminBroadcastsDispatchService,
    AdminBroadcastScheduleWorkerService,
    AdminGamificationService,
    AdminAppConfigService,
    AdminCommsService,
  ],
})
export class AdminControlModule {}
