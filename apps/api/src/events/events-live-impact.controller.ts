import { Body, Controller, Get, MessageEvent, Param, Patch, Sse, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiOperation, ApiTags } from '@nestjs/swagger';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import { Observable, interval, merge } from 'rxjs';
import { map } from 'rxjs/operators';
import { CurrentUser } from '../auth/current-user.decorator';
import { ParseCuidPipe } from '../common/pipes/parse-cuid.pipe';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { PatchLiveImpactDto } from './dto/patch-live-impact.dto';
import {
  LiveImpactSnapshotResponseDto,
} from './dto/events-openapi-responses.dto';
import { EventMobileResponseDto } from './dto/event-mobile-response.dto';
import { EventLiveImpactService } from './event-live-impact.service';
import { EventsQueryService } from './events-query.service';
import { ApiEventsJwtStandardErrors } from './events-openapi.decorators';
import { ApiStandardHttpErrorResponses } from '../common/openapi/standard-http-error-responses.decorator';

const LIVE_IMPACT_SSE_HEARTBEAT_MS = 30_000;

@ApiTags('events')
@ApiStandardHttpErrorResponses()
@Controller('events')
@UseGuards(ThrottlerGuard)
export class EventsLiveImpactController {
  constructor(
    private readonly liveImpact: EventLiveImpactService,
    private readonly query: EventsQueryService,
  ) {}

  @Get(':id/live-impact')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @Throttle({ default: { ttl: 60_000, limit: 120 } })
  @ApiOperation({ summary: 'Aggregated live impact counters for an event' })
  @ApiOkResponse({ description: 'Live impact snapshot', type: LiveImpactSnapshotResponseDto })
  @ApiEventsJwtStandardErrors()
  getLiveImpact(@CurrentUser() user: AuthenticatedUser, @Param('id', ParseCuidPipe) id: string) {
    return this.liveImpact.getSnapshot(id, user);
  }

  @Get(':id/live-impact/stream')
  @Sse()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @Throttle({ default: { ttl: 60_000, limit: 30 } })
  @ApiOperation({ summary: 'SSE stream for live impact updates on this event' })
  @ApiEventsJwtStandardErrors()
  streamLiveImpact(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseCuidPipe) id: string,
  ): Observable<MessageEvent> {
    const live$ = this.liveImpact.watchLiveImpactSse(id, user);
    const heartbeat$ = interval(LIVE_IMPACT_SSE_HEARTBEAT_MS).pipe(
      map(() => ({ data: { type: 'heartbeat' } } as MessageEvent)),
    );
    return merge(live$, heartbeat$);
  }

  @Patch(':id/live-impact')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @Throttle({ default: { ttl: 60_000, limit: 60 } })
  @ApiOperation({ summary: 'Update organizer-reported live impact (organizer only)' })
  @ApiOkResponse({ description: 'Updated snapshot', type: EventMobileResponseDto })
  @ApiEventsJwtStandardErrors()
  async patchLiveImpact(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseCuidPipe) id: string,
    @Body() dto: PatchLiveImpactDto,
  ) {
    await this.liveImpact.patch(id, dto, user);
    return this.query.findOne(id, user);
  }
}
