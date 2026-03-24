import { Controller, Get, MessageEvent as NestMessageEvent, Sse, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { Observable, interval, map, merge } from 'rxjs';
import { ADMIN_PANEL_ROLES } from '../auth/admin-roles';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { NotificationEventsService } from './notification-events.service';
import { ReportEventsService } from './report-events.service';
import { SiteEventsService } from './site-events.service';
import { UserEventsService } from './user-events.service';

const HEARTBEAT_INTERVAL_MS = 30_000;

@ApiTags('admin')
@Controller('admin')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(...ADMIN_PANEL_ROLES)
@ApiBearerAuth()
export class AdminEventsController {
  constructor(
    private readonly reportEventsService: ReportEventsService,
    private readonly notificationEventsService: NotificationEventsService,
    private readonly siteEventsService: SiteEventsService,
    private readonly userEventsService: UserEventsService,
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

    const heartbeat = interval(HEARTBEAT_INTERVAL_MS).pipe(
      map(() => ({ data: { type: 'heartbeat' } } as NestMessageEvent)),
    );

    return merge(reportEvents, notificationEvents, siteEvents, userEvents, heartbeat);
  }
}
