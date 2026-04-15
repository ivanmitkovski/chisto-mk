import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { TwilioSignatureGuard } from './guards/twilio-signature.guard';
import { TwilioStatusBodySanitizeInterceptor } from './interceptors/twilio-status-body-sanitize.interceptor';
import { WebhooksController } from './webhooks.controller';
import { WebhooksService } from './webhooks.service';

@Module({
  imports: [PrismaModule],
  controllers: [WebhooksController],
  providers: [WebhooksService, TwilioSignatureGuard, TwilioStatusBodySanitizeInterceptor],
})
export class WebhooksModule {}
