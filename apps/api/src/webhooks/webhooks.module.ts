import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { EmailModule } from '../email/email.module';
import { PrismaModule } from '../prisma/prisma.module';
import { EmailWebhooksController } from './controllers/email-webhooks.controller';
import { EmailWebhooksService } from './services/email-webhooks.service';
import { PostmarkWebhookBasicAuthGuard } from './guards/postmark-webhook-basic-auth.guard';
import { PostmarkWebhookSignatureGuard } from './guards/postmark-webhook-signature.guard';
import { TwilioWebhookDedupeService } from './services/twilio-webhook-dedupe.service';
import { TwilioSignatureGuard } from './guards/twilio-signature.guard';
import { TwilioStatusBodySanitizeInterceptor } from './interceptors/twilio-status-body-sanitize.interceptor';
import { WebhooksController } from './controllers/webhooks.controller';
import { WebhooksService } from './services/webhooks.service';

@Module({
  imports: [PrismaModule, ConfigModule, EmailModule],
  controllers: [WebhooksController, EmailWebhooksController],
  providers: [
    WebhooksService,
    EmailWebhooksService,
    TwilioSignatureGuard,
    PostmarkWebhookBasicAuthGuard,
    PostmarkWebhookSignatureGuard,
    TwilioWebhookDedupeService,
    TwilioStatusBodySanitizeInterceptor,
  ],
})
export class WebhooksModule {}
