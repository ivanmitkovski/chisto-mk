import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { AuditModule } from '../audit/audit.module';
import { AdminModerationEmailModule } from '../admin-moderation-email/admin-moderation-email.module';
import { ModerationController } from './controllers/moderation.controller';
import { ModerationService } from './services/moderation.service';
import { UgcSubjectVisibilityService } from './services/ugc-subject-visibility.service';

@Module({
  imports: [PrismaModule, AuditModule, AdminModerationEmailModule],
  controllers: [ModerationController],
  providers: [ModerationService, UgcSubjectVisibilityService],
  exports: [ModerationService, UgcSubjectVisibilityService],
})
export class ModerationModule {}
