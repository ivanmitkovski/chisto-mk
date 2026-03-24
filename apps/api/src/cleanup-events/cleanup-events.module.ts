import { Module } from '@nestjs/common';
import { CleanupEventsController } from './cleanup-events.controller';
import { CleanupEventsService } from './cleanup-events.service';
import { AuditModule } from '../audit/audit.module';

@Module({
  imports: [AuditModule],
  controllers: [CleanupEventsController],
  providers: [CleanupEventsService],
})
export class CleanupEventsModule {}
