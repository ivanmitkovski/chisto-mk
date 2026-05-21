import { Body, Controller, Get, HttpCode, HttpStatus, Post, Query, Res } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import type { Response } from 'express';
import { Throttle } from '@nestjs/throttler';
import { PrismaService } from '../prisma/prisma.service';
import { EmailUnsubscribeTokenService } from './email-unsubscribe-token.service';
import { NotificationType } from '../prisma-client';
import { ApiStandardHttpErrorResponses } from '../common/openapi/standard-http-error-responses.decorator';
import { UnsubscribePostDto } from './dto/unsubscribe-post.dto';

@ApiTags('notifications')
@ApiStandardHttpErrorResponses()
@Controller('notifications/email')
export class EmailUnsubscribeController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly unsubscribeTokens: EmailUnsubscribeTokenService,
  ) {}

  @Post('unsubscribe')
  @Throttle({ default: { ttl: 60_000, limit: 30 } })
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'One-click unsubscribe (RFC 8058); use ?token= on POST URL or JSON body' })
  async unsubscribePost(
    @Query('token') queryToken: string | undefined,
    @Body() body: UnsubscribePostDto,
  ): Promise<void> {
    const token =
      (typeof queryToken === 'string' ? queryToken.trim() : '') ||
      (typeof body.token === 'string' ? body.token.trim() : '');
    if (!token) {
      return;
    }
    await this.applyToken(token);
  }

  @Get('unsubscribe')
  @Throttle({ default: { ttl: 60_000, limit: 60 } })
  @ApiOperation({ summary: 'Unsubscribe via link (browser)' })
  async unsubscribeGet(
    @Query('token') token: string | undefined,
    @Res() res: Response,
  ): Promise<void> {
    const raw = token?.trim() ?? '';
    let ok = false;
    try {
      if (raw) {
        await this.applyToken(raw);
        ok = true;
      }
    } catch {
      ok = false;
    }
    const message = ok
      ? 'You are unsubscribed from this email category.'
      : 'This unsubscribe link is invalid or has expired.';
    res
      .status(HttpStatus.OK)
      .type('html')
      .send(
        `<!DOCTYPE html><html><head><meta charset="utf-8"/><meta name="viewport" content="width=device-width, initial-scale=1"/></head><body style="font-family:system-ui;padding:24px;max-width:560px;margin:0 auto;"><p>${message}</p><p style="color:#666;font-size:14px;">You can re-enable emails anytime in the Chisto.mk app under Notifications → Preferences.</p></body></html>`,
      );
  }

  private async applyToken(token: string): Promise<void> {
    const payload = this.unsubscribeTokens.verify(token);
    const userId = payload.sub;
    const t = payload.notificationType;
    if (t === 'ALL') {
      for (const type of Object.values(NotificationType)) {
        await this.prisma.userNotificationPreference.upsert({
          where: { userId_type: { userId, type } },
          create: { userId, type, emailMuted: true },
          update: { emailMuted: true, emailMutedUntil: null },
        });
      }
      return;
    }
    if (!Object.values(NotificationType).includes(t)) {
      throw new Error('Invalid notification type');
    }
    await this.prisma.userNotificationPreference.upsert({
      where: { userId_type: { userId, type: t } },
      create: { userId, type: t, emailMuted: true },
      update: { emailMuted: true, emailMutedUntil: null },
    });
  }
}
