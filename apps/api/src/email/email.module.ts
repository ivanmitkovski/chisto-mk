import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from '../prisma/prisma.module';
import { FeatureFlagsModule } from '../feature-flags/feature-flags.module';
import { EmailFooterLinksService } from './services/email-footer-links.service';
import { EmailPostmarkTransportService } from './services/email-postmark-transport.service';
import { EmailSendEligibilityService } from './services/email-send-eligibility.service';
import { EmailSuppressionService } from './services/email-suppression.service';
import { EmailService } from './services/email.service';
import { EmailTemplateService } from './services/email-template.service';
import { EmailUnsubscribeController } from './controllers/email-unsubscribe.controller';
import { EmailUnsubscribeTokenService } from './services/email-unsubscribe-token.service';
import { EmailDeliveryOutboxService } from './services/email-delivery-outbox.service';
import { EmailDeliveryWorkerService } from './services/email-delivery-worker.service';

@Module({
  imports: [PrismaModule, ConfigModule, FeatureFlagsModule],
  controllers: [EmailUnsubscribeController],
  providers: [
    EmailUnsubscribeTokenService,
    EmailFooterLinksService,
    EmailSendEligibilityService,
    EmailSuppressionService,
    EmailPostmarkTransportService,
    EmailTemplateService,
    EmailService,
    EmailDeliveryOutboxService,
    EmailDeliveryWorkerService,
  ],
  exports: [
    EmailService,
    EmailDeliveryOutboxService,
    EmailTemplateService,
    EmailSendEligibilityService,
    EmailSuppressionService,
  ],
})
export class EmailModule {}
