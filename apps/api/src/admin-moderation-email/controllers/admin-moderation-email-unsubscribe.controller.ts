import { Controller, Get, HttpStatus, Query, Res } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import type { Response } from 'express';
import { Throttle } from '@nestjs/throttler';
import { ApiStandardHttpErrorResponses } from '../../common/openapi/standard-http-error-responses.decorator';
import { AdminModerationEmailPreferencesService } from '../services/admin-moderation-email-preferences.service';
import { AdminModerationEmailUnsubscribeTokenService } from '../services/admin-moderation-email-unsubscribe-token.service';

@ApiTags('admin-moderation-email')
@ApiStandardHttpErrorResponses()
@Controller('admin/moderation-email')
export class AdminModerationEmailUnsubscribeController {
  constructor(
    private readonly preferences: AdminModerationEmailPreferencesService,
    private readonly tokens: AdminModerationEmailUnsubscribeTokenService,
  ) {}

  @Get('unsubscribe')
  @Throttle({ default: { ttl: 60_000, limit: 60 } })
  @ApiOperation({ summary: 'Unsubscribe from admin moderation emails for one category (browser)' })
  async unsubscribeGet(
    @Query('token') token: string | undefined,
    @Res() res: Response,
  ): Promise<void> {
    const raw = token?.trim() ?? '';
    let ok = false;
    try {
      if (raw) {
        const payload = this.tokens.verify(raw);
        await this.preferences.disableFromUnsubscribe(payload.sub, payload.category);
        ok = true;
      }
    } catch {
      ok = false;
    }
    const message = ok
      ? 'You are unsubscribed from this moderation email category.'
      : 'This unsubscribe link is invalid or has expired.';
    res
      .status(HttpStatus.OK)
      .type('html')
      .send(
        `<!DOCTYPE html><html><head><meta charset="utf-8"/><meta name="viewport" content="width=device-width, initial-scale=1"/></head><body style="font-family:system-ui;padding:24px;max-width:560px;margin:0 auto;"><p>${message}</p><p style="color:#666;font-size:14px;">Re-enable anytime in Chisto.mk Admin → Settings → Moderation emails.</p></body></html>`,
      );
  }
}
