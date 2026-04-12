import { Module } from '@nestjs/common';
import { CleanupEventsController } from './cleanup-events.controller';
import { CleanupEventsService } from './cleanup-events.service';
import { AuditModule } from '../audit/audit.module';
import { GamificationModule } from '../gamification/gamification.module';

@Module({
  imports: [AuditModule, GamificationModule],
  controllers: [CleanupEventsController],
  providers: [CleanupEventsService],
})
export class CleanupEventsModule {}
