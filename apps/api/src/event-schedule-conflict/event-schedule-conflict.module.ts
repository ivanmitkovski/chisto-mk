import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { EventScheduleConflictService } from './event-schedule-conflict.service';

@Module({
  imports: [PrismaModule],
  providers: [EventScheduleConflictService],
  exports: [EventScheduleConflictService],
})
export class EventScheduleConflictModule {}
