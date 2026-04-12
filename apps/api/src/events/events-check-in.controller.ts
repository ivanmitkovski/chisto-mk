import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { ManualEventCheckInDto } from './dto/manual-event-check-in.dto';
import { PatchEventCheckInDto } from './dto/patch-event-check-in.dto';
import { RedeemEventCheckInDto } from './dto/redeem-event-check-in.dto';
import { EventsCheckInService } from './events-check-in.service';

@ApiTags('events')
@Controller('events/:eventId/check-in')
@UseGuards(ThrottlerGuard, JwtAuthGuard)
@ApiBearerAuth()
export class EventsCheckInController {
  constructor(private readonly checkIn: EventsCheckInService) {}

  @Patch()
  @ApiOperation({ summary: 'Open or pause QR check-in (organizer only)' })
  @ApiOkResponse({ description: 'Check-in state updated' })
  async patchOpen(
    @Param('eventId') eventId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: PatchEventCheckInDto,
  ): Promise<{ ok: true }> {
    await this.checkIn.patchOpen(eventId, user, dto.isOpen);
    return { ok: true };
  }

  @Post('session/rotate')
  @Throttle({ default: { ttl: 60_000, limit: 30 } })
  @ApiOperation({ summary: 'Rotate check-in session (invalidates old QR codes)' })
  @ApiOkResponse({ description: 'Session rotated' })
  async rotateSession(
    @Param('eventId') eventId: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<{ ok: true }> {
    await this.checkIn.rotateSession(eventId, user);
    return { ok: true };
  }

  @Get('qr')
  @Throttle({ default: { ttl: 60_000, limit: 120 } })
  @ApiOperation({ summary: 'Issue a signed QR payload for attendees (organizer only)' })
  @ApiOkResponse({ description: 'QR payload and metadata' })
  getQr(
    @Param('eventId') eventId: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.checkIn.getQrPayload(eventId, user);
  }

  @Get('attendees')
  @ApiOperation({ summary: 'List checked-in attendees (organizer only)' })
  @ApiOkResponse({ description: 'Checked-in rows' })
  listAttendees(
    @Param('eventId') eventId: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.checkIn.listAttendees(eventId, user);
  }

  @Post('manual')
  @Throttle({ default: { ttl: 60_000, limit: 40 } })
  @ApiOperation({
    summary:
      'Manually check in a joined volunteer by user id (organizer only)',
  })
  @ApiOkResponse({ description: 'Check-in row and pointsAwarded for the volunteer' })
  manualAdd(
    @Param('eventId') eventId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: ManualEventCheckInDto,
  ) {
    return this.checkIn.manualAdd(eventId, user, dto);
  }

  @Delete('attendees/:checkInId')
  @ApiOperation({ summary: 'Remove a check-in row (organizer only)' })
  @ApiOkResponse({ description: 'Removed' })
  async removeAttendee(
    @Param('eventId') eventId: string,
    @Param('checkInId') checkInId: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<{ ok: true }> {
    await this.checkIn.removeAttendee(eventId, checkInId, user);
    return { ok: true };
  }

  @Post('redeem')
  @Throttle({ default: { ttl: 60_000, limit: 45 } })
  @ApiOperation({ summary: 'Redeem an organizer QR token (participant only)' })
  @ApiOkResponse({ description: 'Check-in timestamp and pointsAwarded' })
  redeem(
    @Param('eventId') eventId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: RedeemEventCheckInDto,
  ) {
    return this.checkIn.redeem(eventId, user, dto.qrPayload);
  }
}
