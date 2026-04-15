import {
  Body,
  Controller,
  Header,
  HttpCode,
  Post,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { TwilioStatusDto } from './dto/twilio-status.dto';
import { TwilioSignatureGuard } from './guards/twilio-signature.guard';
import { TwilioStatusBodySanitizeInterceptor } from './interceptors/twilio-status-body-sanitize.interceptor';
import { WebhooksService } from './webhooks.service';

@ApiTags('webhooks')
@Controller('webhooks')
export class WebhooksController {
  constructor(private readonly webhooksService: WebhooksService) {}

  @Post('twilio/status')
  @HttpCode(200)
  @Header('Content-Type', 'text/plain; charset=utf-8')
  @UseGuards(TwilioSignatureGuard)
  @UseInterceptors(TwilioStatusBodySanitizeInterceptor)
  @ApiOperation({ summary: 'Twilio SMS status callback (form-encoded)' })
  @ApiResponse({ status: 200, description: 'Acknowledged' })
  async handleTwilioSmsStatus(@Body() body: TwilioStatusDto): Promise<string> {
    await this.webhooksService.handleTwilioSmsStatus(body);
    return 'OK';
  }
}
