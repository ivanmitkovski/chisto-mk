import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { EmailModule } from '../email/email.module';
import { PrismaModule } from '../prisma/prisma.module';
import { EmailWebhooksController } from './email-webhooks.controller';
import { EmailWebhooksService } from './email-webhooks.service';
import { PostmarkWebhookBasicAuthGuard } from './guards/postmark-webhook-basic-auth.guard';
import { TwilioSignatureGuard } from './guards/twilio-signature.guard';
import { TwilioStatusBodySanitizeInterceptor } from './interceptors/twilio-status-body-sanitize.interceptor';
import { WebhooksController } from './webhooks.controller';
import { WebhooksService } from './webhooks.service';

@Module({
  imports: [PrismaModule, ConfigModule, EmailModule],
  controllers: [WebhooksController, EmailWebhooksController],
  providers: [
    WebhooksService,
    EmailWebhooksService,
    TwilioSignatureGuard,
    PostmarkWebhookBasicAuthGuard,
    TwilioStatusBodySanitizeInterceptor,
  ],
})
export class WebhooksModule {}
