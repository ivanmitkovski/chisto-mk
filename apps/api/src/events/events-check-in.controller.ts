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
  ApiExtraModels,
  ApiGoneResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  getSchemaPath,
} from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import {
  CheckInAttendeeRowDto,
  CheckInQrResponseDto,
  ListCheckInAttendeesResponseDto,
  ManualCheckInResponseDto,
  PatchCheckInOpenResponseDto,
  PendingStatusResponseDto,
  RedeemCheckInResponseDto,
  RemoveCheckInAttendeeResponseDto,
  ResolveCheckInApproveResponseDto,
  ResolveCheckInRejectResponseDto,
  RotateSessionResponseDto,
} from './dto/check-in-response.dto';
import { ManualEventCheckInDto } from './dto/manual-event-check-in.dto';
import { PatchEventCheckInDto } from './dto/patch-event-check-in.dto';
import { RedeemEventCheckInDto } from './dto/redeem-event-check-in.dto';
import { ResolveCheckInDto } from './dto/resolve-check-in.dto';
import { EventsCheckInThrottlerGuard } from './events-check-in-throttler.guard';
import { EventsCheckInService } from './events-check-in.service';

@ApiTags('events')
@ApiExtraModels(
  PatchCheckInOpenResponseDto,
  RotateSessionResponseDto,
  CheckInQrResponseDto,
  ListCheckInAttendeesResponseDto,
  CheckInAttendeeRowDto,
  ManualCheckInResponseDto,
  RemoveCheckInAttendeeResponseDto,
  RedeemCheckInResponseDto,
  ResolveCheckInApproveResponseDto,
  ResolveCheckInRejectResponseDto,
  PendingStatusResponseDto,
)
@Controller('events/:eventId/check-in')
@UseGuards(JwtAuthGuard, EventsCheckInThrottlerGuard)
@ApiBearerAuth()
export class EventsCheckInController {
  constructor(private readonly checkIn: EventsCheckInService) {}

  @Patch()
  @Throttle({ default: { ttl: 60_000, limit: 40 } })
  @ApiOperation({ summary: 'Open or pause QR check-in (organizer only)' })
  @ApiOkResponse({ type: PatchCheckInOpenResponseDto })
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
  @ApiOkResponse({ type: RotateSessionResponseDto })
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
  @ApiOkResponse({ type: CheckInQrResponseDto })
  getQr(
    @Param('eventId') eventId: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.checkIn.getQrPayload(eventId, user);
  }

  @Get('attendees')
  @Throttle({ default: { ttl: 60_000, limit: 120 } })
  @ApiOperation({ summary: 'List checked-in attendees (organizer only)' })
  @ApiOkResponse({ type: ListCheckInAttendeesResponseDto })
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
  @ApiOkResponse({ type: ManualCheckInResponseDto })
  manualAdd(
    @Param('eventId') eventId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: ManualEventCheckInDto,
  ) {
    return this.checkIn.manualAdd(eventId, user, dto);
  }

  @Delete('attendees/:checkInId')
  @Throttle({ default: { ttl: 60_000, limit: 30 } })
  @ApiOperation({ summary: 'Remove a check-in row (organizer only)' })
  @ApiOkResponse({ type: RemoveCheckInAttendeeResponseDto })
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
  @ApiOperation({
    summary:
      'Redeem an organizer QR token (participant only). Returns pending_confirmation status awaiting organizer approval.',
  })
  @ApiOkResponse({ type: RedeemCheckInResponseDto })
  redeem(
    @Param('eventId') eventId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: RedeemEventCheckInDto,
  ) {
    return this.checkIn.redeem(eventId, user, dto.qrPayload);
  }

  @Post('pending/:pendingId/resolve')
  @Throttle({ default: { ttl: 60_000, limit: 60 } })
  @ApiOperation({
    summary: 'Approve or reject a pending QR check-in request (organizer only)',
  })
  @ApiOkResponse({
    description: 'On approve: check-in row. On reject: `{ ok: true }`.',
    schema: {
      oneOf: [
        { $ref: getSchemaPath(ResolveCheckInApproveResponseDto) },
        { $ref: getSchemaPath(ResolveCheckInRejectResponseDto) },
      ],
    },
  })
  @ApiGoneResponse({ description: 'Pending request expired' })
  @ApiNotFoundResponse({ description: 'Pending id does not belong to this event' })
  async resolveCheckIn(
    @Param('eventId') eventId: string,
    @Param('pendingId') pendingId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: ResolveCheckInDto,
  ) {
    const result = await this.checkIn.resolveCheckIn(
      eventId,
      pendingId,
      user,
      dto.action,
    );
    if (result == null) {
      return { ok: true as const };
    }
    return result;
  }

  @Get('pending/:pendingId')
  @Throttle({ default: { ttl: 60_000, limit: 120 } })
  @ApiOperation({ summary: 'Poll pending check-in status (volunteer fallback)' })
  @ApiOkResponse({ type: PendingStatusResponseDto })
  @ApiNotFoundResponse({
    description:
      'Unknown pending id, wrong event, or pending owned by another user (same shape to avoid cross-user probing)',
  })
  getPendingStatus(
    @Param('eventId') eventId: string,
    @Param('pendingId') pendingId: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.checkIn.getPendingStatus(eventId, pendingId, user);
  }
}
