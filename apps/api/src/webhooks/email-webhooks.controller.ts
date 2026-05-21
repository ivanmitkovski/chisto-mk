import { Body, Controller, HttpCode, Post, UseGuards } from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { ApiStandardHttpErrorResponses } from '../common/openapi/standard-http-error-responses.decorator';
import { PostmarkWebhookDto } from './dto/postmark-webhook.dto';
import { EmailWebhooksService } from './email-webhooks.service';
import { PostmarkWebhookBasicAuthGuard } from './guards/postmark-webhook-basic-auth.guard';

@ApiTags('webhooks')
@ApiStandardHttpErrorResponses()
@Controller('webhooks')
export class EmailWebhooksController {
  constructor(private readonly emailWebhooks: EmailWebhooksService) {}

  @Post('postmark')
  @HttpCode(200)
  @UseGuards(PostmarkWebhookBasicAuthGuard)
  @ApiOperation({ summary: 'Postmark bounce/complaint webhook (JSON)' })
  @ApiResponse({ status: 200, description: 'Acknowledged' })
  async handlePostmark(@Body() body: PostmarkWebhookDto): Promise<{ ok: true }> {
    await this.emailWebhooks.handlePostmarkEvent(body);
    return { ok: true };
  }
}
