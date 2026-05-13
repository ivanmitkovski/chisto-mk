import { Controller, Get, MessageEvent as NestMessageEvent, Sse, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { Observable, interval, map, merge } from 'rxjs';
import { ADMIN_PANEL_ROLES } from '../auth/admin-roles';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { CleanupEventRealtimeService } from './cleanup-event-realtime.service';
import { NotificationEventsService } from './notification-events.service';
import { ReportEventsService } from './report-events.service';
import { SiteEventsService } from './site-events.service';
import { UserEventsService } from './user-events.service';
import { ApiStandardHttpErrorResponses } from '../common/openapi/standard-http-error-responses.decorator';

/**
 * SSE hub for the admin console (single transport for dashboard, lists, map RQ, and RSC refresh).
 *
 * Operational expectations:
 * - One browser tab typically holds one `EventSource` (~1 connection per tab per admin user).
 * - Scale: active admins × average open tabs; cap at infra/proxy limits (e.g. nginx `limit_conn`).
 * - Heartbeats keep intermediaries from closing idle streams; clients treat >3× interval without
 *   any message as stale and reconnect.
 * - Payloads are small JSON objects per domain event; keep new event shapes compact (ids + labels).
 */
const HEARTBEAT_INTERVAL_MS = 30_000;

@ApiTags('admin')
@ApiStandardHttpErrorResponses()
@Controller('admin')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(...ADMIN_PANEL_ROLES)
@ApiBearerAuth()
export class AdminRealtimeController {
  constructor(
    private readonly reportEventsService: ReportEventsService,
    private readonly notificationEventsService: NotificationEventsService,
    private readonly siteEventsService: SiteEventsService,
    private readonly userEventsService: UserEventsService,
    private readonly cleanupEventRealtimeService: CleanupEventRealtimeService,
  ) {}

  @Get('events')
  @Sse()
  @ApiOperation({ summary: 'Server-Sent Events stream for real-time dashboard updates' })
  stream(): Observable<NestMessageEvent> {
    const reportEvents = this.reportEventsService.getEvents().pipe(
      map((event) => ({
        data: event as object,
        type: event.type,
      })),
    );

    const notificationEvents = this.notificationEventsService.getEvents().pipe(
      map((event) => ({
        data: event as object,
        type: event.type,
      })),
    );

    const siteEvents = this.siteEventsService.getEvents().pipe(
      map((event) => ({
        data: event as object,
        type: event.type,
      })),
    );

    const userEvents = this.userEventsService.getEvents().pipe(
      map((event) => ({
        data: event as object,
        type: event.type,
      })),
    );

    const cleanupEvents = this.cleanupEventRealtimeService.getEvents().pipe(
      map((event) => ({
        data: event as object,
        type: event.type,
      })),
    );

    const heartbeat = interval(HEARTBEAT_INTERVAL_MS).pipe(
      map(() => ({ data: { type: 'heartbeat' } } as NestMessageEvent)),
    );

    return merge(
      reportEvents,
      notificationEvents,
      siteEvents,
      userEvents,
      cleanupEvents,
      heartbeat,
    );
  }
}
