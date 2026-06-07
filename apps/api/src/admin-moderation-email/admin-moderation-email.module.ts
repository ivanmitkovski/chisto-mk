import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from '../prisma/prisma.module';
import { EmailModule } from '../email/email.module';
import { FeatureFlagsModule } from '../feature-flags/feature-flags.module';
import { AuditModule } from '../audit/audit.module';
import { AdminModerationEmailPreferencesController } from './controllers/admin-moderation-email-preferences.controller';
import { AdminModerationEmailUnsubscribeController } from './controllers/admin-moderation-email-unsubscribe.controller';
import { AdminModerationEmailPreferencesService } from './services/admin-moderation-email-preferences.service';
import { AdminModerationEmailUnsubscribeTokenService } from './services/admin-moderation-email-unsubscribe-token.service';
import { AdminModerationRecipientsService } from './services/admin-moderation-recipients.service';
import { AdminModerationEmailOutboxService } from './services/admin-moderation-email-outbox.service';
import { AdminModerationEmailWorkerService } from './services/admin-moderation-email-worker.service';
import { AdminModerationNotifierService } from './services/admin-moderation-notifier.service';

@Module({
  imports: [PrismaModule, ConfigModule, EmailModule, FeatureFlagsModule, AuditModule],
  controllers: [AdminModerationEmailPreferencesController, AdminModerationEmailUnsubscribeController],
  providers: [
    AdminModerationEmailPreferencesService,
    AdminModerationEmailUnsubscribeTokenService,
    AdminModerationRecipientsService,
    AdminModerationEmailOutboxService,
    AdminModerationEmailWorkerService,
    AdminModerationNotifierService,
  ],
  exports: [AdminModerationNotifierService],
})
export class AdminModerationEmailModule {}
