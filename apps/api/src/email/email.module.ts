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
import { EmailPipelineHealthService } from './services/email-pipeline-health.service';
import { EmailDeadLetterRequeueService } from './services/email-dead-letter-requeue.service';
import { AuditModule } from '../audit/audit.module';

@Module({
  imports: [PrismaModule, ConfigModule, FeatureFlagsModule, AuditModule],
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
    EmailPipelineHealthService,
    EmailDeadLetterRequeueService,
  ],
  exports: [
    EmailService,
    EmailDeliveryOutboxService,
    EmailTemplateService,
    EmailSendEligibilityService,
    EmailSuppressionService,
    EmailPipelineHealthService,
    EmailDeadLetterRequeueService,
  ],
})
export class EmailModule {}
