import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { AuditModule } from '../audit/audit.module';
import { ModerationController } from './controllers/moderation.controller';
import { ModerationService } from './services/moderation.service';

@Module({
  imports: [PrismaModule, AuditModule],
  controllers: [ModerationController],
  providers: [ModerationService],
  exports: [ModerationService],
})
export class ModerationModule {}
