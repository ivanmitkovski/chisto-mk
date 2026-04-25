import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
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
import { ParseCuidPipe } from '../common/pipes/parse-cuid.pipe';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import {
  CheckInAttendeeRowDto,
  CheckInQrResponseDto,
  ListCheckInAttendeesMetaDto,
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
import { ListCheckInAttendeesQueryDto } from './dto/list-check-in-attendees-query.dto';
import { EventsCheckInThrottlerGuard } from './events-check-in-throttler.guard';
import { ApiEventsCheckInStandardErrors } from './events-check-in-openapi.decorators';
import { EventsCheckInService } from './events-check-in.service';

@ApiTags('events')
@ApiExtraModels(
  PatchCheckInOpenResponseDto,
  RotateSessionResponseDto,
  CheckInQrResponseDto,
  ListCheckInAttendeesResponseDto,
  ListCheckInAttendeesMetaDto,
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
  @ApiEventsCheckInStandardErrors()
  async patchOpen(
    @Param('eventId', ParseCuidPipe) eventId: string,
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
  @ApiEventsCheckInStandardErrors()
  async rotateSession(
    @Param('eventId', ParseCuidPipe) eventId: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<{ ok: true }> {
    await this.checkIn.rotateSession(eventId, user);
    return { ok: true };
  }

  @Get('qr')
  @Throttle({ default: { ttl: 60_000, limit: 120 } })
  @ApiOperation({ summary: 'Issue a signed QR payload for attendees (organizer only)' })
  @ApiOkResponse({ type: CheckInQrResponseDto })
  @ApiEventsCheckInStandardErrors()
  getQr(
    @Param('eventId', ParseCuidPipe) eventId: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.checkIn.getQrPayload(eventId, user);
  }

  @Get('attendees')
  @Throttle({ default: { ttl: 60_000, limit: 120 } })
  @ApiOperation({ summary: 'List checked-in attendees (organizer only)' })
  @ApiOkResponse({ type: ListCheckInAttendeesResponseDto })
  @ApiEventsCheckInStandardErrors()
  listAttendees(
    @Param('eventId', ParseCuidPipe) eventId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Query() query: ListCheckInAttendeesQueryDto,
  ) {
    return this.checkIn.listAttendees(eventId, user, query);
  }

  @Post('manual')
  @Throttle({ default: { ttl: 60_000, limit: 40 } })
  @ApiOperation({
    summary:
      'Manually check in a joined volunteer by user id (organizer only)',
  })
  @ApiOkResponse({ type: ManualCheckInResponseDto })
  @ApiEventsCheckInStandardErrors()
  manualAdd(
    @Param('eventId', ParseCuidPipe) eventId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: ManualEventCheckInDto,
  ) {
    return this.checkIn.manualAdd(eventId, user, dto);
  }

  @Delete('attendees/:checkInId')
  @Throttle({ default: { ttl: 60_000, limit: 30 } })
  @ApiOperation({ summary: 'Remove a check-in row (organizer only)' })
  @ApiOkResponse({ type: RemoveCheckInAttendeeResponseDto })
  @ApiEventsCheckInStandardErrors()
  async removeAttendee(
    @Param('eventId', ParseCuidPipe) eventId: string,
    @Param('checkInId', ParseCuidPipe) checkInId: string,
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
  @ApiEventsCheckInStandardErrors()
  redeem(
    @Param('eventId', ParseCuidPipe) eventId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: RedeemEventCheckInDto,
  ) {
    const geo =
      dto.redeemLatitude != null && dto.redeemLongitude != null
        ? { lat: dto.redeemLatitude, lng: dto.redeemLongitude }
        : undefined;
    return this.checkIn.redeem(eventId, user, dto.qrPayload, geo);
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
  @ApiEventsCheckInStandardErrors()
  async resolveCheckIn(
    @Param('eventId', ParseCuidPipe) eventId: string,
    @Param('pendingId', ParseCuidPipe) pendingId: string,
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
  @ApiEventsCheckInStandardErrors()
  getPendingStatus(
    @Param('eventId', ParseCuidPipe) eventId: string,
    @Param('pendingId', ParseCuidPipe) pendingId: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.checkIn.getPendingStatus(eventId, pendingId, user);
  }
}
