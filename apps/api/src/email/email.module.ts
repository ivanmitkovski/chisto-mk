import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from '../prisma/prisma.module';
import { FeatureFlagsModule } from '../feature-flags/feature-flags.module';
import { EmailFooterLinksService } from './email-footer-links.service';
import { EmailPostmarkTransportService } from './email-postmark-transport.service';
import { EmailSendEligibilityService } from './email-send-eligibility.service';
import { EmailSuppressionService } from './email-suppression.service';
import { EmailService } from './email.service';
import { EmailTemplateService } from './email-template.service';
import { EmailUnsubscribeController } from './email-unsubscribe.controller';
import { EmailUnsubscribeTokenService } from './email-unsubscribe-token.service';
import { EmailDeliveryOutboxService } from './email-delivery-outbox.service';
import { EmailDeliveryWorkerService } from './email-delivery-worker.service';

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
