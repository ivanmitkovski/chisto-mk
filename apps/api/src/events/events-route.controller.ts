import { Body, Controller, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiOperation, ApiTags } from '@nestjs/swagger';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import { CurrentUser } from '../auth/current-user.decorator';
import { ParseCuidPipe } from '../common/pipes/parse-cuid.pipe';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { EventRouteWaypointsBodyDto } from './dto/event-route-waypoint.dto';
import { EventMobileRouteSegmentDto } from './dto/event-mobile-response.dto';
import { EventRouteSegmentsService } from './event-route-segments.service';
import { ApiEventsJwtStandardErrors } from './events-openapi.decorators';
import { ApiStandardHttpErrorResponses } from '../common/openapi/standard-http-error-responses.decorator';

@ApiTags('events')
@ApiStandardHttpErrorResponses()
@Controller('events')
@UseGuards(ThrottlerGuard)
export class EventsRouteController {
  constructor(private readonly routeSegments: EventRouteSegmentsService) {}

  @Get(':id/route')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @Throttle({ default: { ttl: 60_000, limit: 120 } })
  @ApiOperation({ summary: 'List route segments for an event' })
  @ApiOkResponse({ description: 'Route segments', type: [EventMobileRouteSegmentDto] })
  @ApiEventsJwtStandardErrors()
  listRoute(@CurrentUser() user: AuthenticatedUser, @Param('id', ParseCuidPipe) id: string) {
    return this.routeSegments.listForEvent(id, user);
  }

  @Patch(':id/route')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @Throttle({ default: { ttl: 60_000, limit: 20 } })
  @ApiOperation({ summary: 'Replace route waypoints (organizer only)' })
  @ApiOkResponse({ description: 'Updated segments', type: [EventMobileRouteSegmentDto] })
  @ApiEventsJwtStandardErrors()
  patchRoute(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseCuidPipe) id: string,
    @Body() body: EventRouteWaypointsBodyDto,
  ) {
    return this.routeSegments.replaceWaypoints(id, user, body.waypoints);
  }

  @Post(':id/route/segments/:segmentId/claim')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @Throttle({ default: { ttl: 60_000, limit: 40 } })
  @ApiOperation({ summary: 'Claim an open route segment (joined volunteer)' })
  @ApiOkResponse({ description: 'Updated segments', type: [EventMobileRouteSegmentDto] })
  @ApiEventsJwtStandardErrors()
  claimRouteSegment(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseCuidPipe) _eventId: string,
    @Param('segmentId', ParseCuidPipe) segmentId: string,
  ) {
    return this.routeSegments.claimSegment(segmentId, user);
  }

  @Post(':id/route/segments/:segmentId/complete')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @Throttle({ default: { ttl: 60_000, limit: 40 } })
  @ApiOperation({ summary: 'Mark a route segment completed (claimer or organizer)' })
  @ApiOkResponse({ description: 'Updated segments', type: [EventMobileRouteSegmentDto] })
  @ApiEventsJwtStandardErrors()
  completeRouteSegment(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseCuidPipe) _eventId: string,
    @Param('segmentId', ParseCuidPipe) segmentId: string,
  ) {
    return this.routeSegments.completeSegment(segmentId, user);
  }
}
