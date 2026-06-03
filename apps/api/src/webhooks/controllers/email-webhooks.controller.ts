import { Body, Controller, HttpCode, Post, UseGuards } from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { ApiStandardHttpErrorResponses } from '../../common/openapi/standard-http-error-responses.decorator';
import { PostmarkWebhookDto } from '../dto/postmark-webhook.dto';
import { EmailWebhooksService } from '../services/email-webhooks.service';
import { PostmarkWebhookSignatureGuard } from '../guards/postmark-webhook-signature.guard';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';

@ApiTags('webhooks')
@ApiStandardHttpErrorResponses()
@Controller('webhooks')
export class EmailWebhooksController {
  constructor(private readonly emailWebhooks: EmailWebhooksService) {}

  @Post('postmark')
  @HttpCode(200)
  @UseGuards(ThrottlerGuard, PostmarkWebhookSignatureGuard)
  @Throttle({ default: { limit: 300, ttl: 60_000 } })
  @ApiOperation({ summary: 'Postmark bounce/complaint webhook (JSON)' })
  @ApiResponse({ status: 200, description: 'Acknowledged' })
  async handlePostmark(@Body() body: PostmarkWebhookDto): Promise<{ ok: true }> {
    await this.emailWebhooks.handlePostmarkEvent(body);
    return { ok: true };
  }
}
