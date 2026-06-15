import { Idempotent } from '../../common/idempotency/idempotency.decorator';
import { Controller, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import { Roles } from '../../auth/decorators/roles.decorator';
import { RolesGuard } from '../../auth/guards/roles.guard';
import { PermissionsGuard } from '../../auth/guards/permissions.guard';
import { RequirePermission } from '../../auth/decorators/require-permission.decorator';
import { ADMIN_PANEL_ROLES } from '../../auth/constants/admin-roles';
import { ADMIN_PERMISSIONS } from '../../auth/constants/admin-permissions';
import { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { NotificationInboxService } from '../services/notification-inbox.service';
import { NotificationDispatcherService } from '../services/notification-dispatcher.service';
import { NotificationType } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import { userLocalesByUserId } from '../../common/i18n/notification-locale.resolver';
import { adminTestPushCopy } from '../util/notification-templates';
import { ObservabilityStore } from '../../observability/observability.store';
import { PushDeadLetterRequeueService } from '../services/push-dead-letter-requeue.service';
import { PushDiagnosticsService } from '../services/push-diagnostics.service';
import {
  DeadLetterPageDto,
  DeadLetterPurgeResultDto,
  DeadLetterRequeueOneResultDto,
  DeadLetterRequeueResultDto,
  DeliveryReportDto,
  PushDiagnosticsDto,
  PushStatsDto,
} from '../dto/push-operations.dto';
import { ApiStandardHttpErrorResponses } from '../../common/openapi/standard-http-error-responses.decorator';

@ApiTags('notifications')
@ApiStandardHttpErrorResponses()
@Controller('notifications')
@UseGuards(JwtAuthGuard, RolesGuard, PermissionsGuard)
@Roles(...ADMIN_PANEL_ROLES)
@ApiBearerAuth()
export class NotificationsAdminController {
  constructor(
    private readonly inbox: NotificationInboxService,
    private readonly dispatcher: NotificationDispatcherService,
    private readonly prisma: PrismaService,
    private readonly deadLetterRequeue: PushDeadLetterRequeueService,
    private readonly pushDiagnostics: PushDiagnosticsService,
  ) {}

  @Idempotent('notifications_admin_test_push')
  @Post('admin/test-push')
  @RequirePermission(ADMIN_PERMISSIONS['operations:write'])
  @ApiOperation({
    summary: 'Send a test push to the current admin user (full outbox → FCM pipeline)',
  })
  @ApiOkResponse({ description: 'Test notification dispatched' })
  async testPush(@CurrentUser() user: AuthenticatedUser) {
    const localeBy = await userLocalesByUserId(this.prisma, [user.userId]);
    const copy = adminTestPushCopy(localeBy.get(user.userId)!);
    await this.dispatcher.dispatchToUser(user.userId, {
      title: copy.title,
      body: copy.body,
      type: NotificationType.SYSTEM,
      data: { kind: 'test_push' },
    });
    return { success: true };
  }

  @Get('admin/push-stats')
  @RequirePermission(ADMIN_PERMISSIONS['operations:read'])
  @ApiOperation({ summary: 'Push delivery statistics (admin only)' })
  @ApiOkResponse({ type: PushStatsDto })
  async pushStats(): Promise<PushStatsDto> {
    const s = ObservabilityStore.snapshot();
    const outbox = await this.inbox.countOutboxTotals();
    return {
      sendsTotal: s.pushSendsTotal,
      sendsSuccess: s.pushSendsSuccess,
      sendsFailure: s.pushSendsFailure,
      sendsRevoked: s.pushSendsRevoked,
      sendsByType: s.pushSendsByType,
      tokenRevocations: s.pushTokenRevocations,
      queueRetries: s.pushQueueRetries,
      inboxReads: s.pushInboxReads,
      queueDepth: s.pushQueueDepth,
      activeLeases: s.pushActiveLeases,
      deadLetterCount: s.pushDeadLetterCount,
      outbox,
    };
  }

  @Get('admin/delivery-report')
  @RequirePermission(ADMIN_PERMISSIONS['operations:read'])
  @ApiOperation({ summary: 'Push delivery funnel (admin only)' })
  @ApiOkResponse({ type: DeliveryReportDto })
  async deliveryReport(): Promise<DeliveryReportDto> {
    const s = ObservabilityStore.snapshot();
    const [sent, opened, outbox] = await Promise.all([
      this.inbox.countSentNotifications(),
      this.inbox.countOpenedNotifications(),
      this.inbox.countOutboxTotals(),
    ]);
    return {
      sends: {
        total: s.pushSendsTotal,
        success: s.pushSendsSuccess,
        failure: s.pushSendsFailure,
        revoked: s.pushSendsRevoked,
        byType: s.pushSendsByType,
      },
      inbox: {
        notificationsSent: sent,
        notificationsOpened: opened,
        openRate: sent > 0 ? Number((opened / sent).toFixed(4)) : 0,
      },
      queue: {
        depth: s.pushQueueDepth,
        activeLeases: s.pushActiveLeases,
        deadLetterCount: s.pushDeadLetterCount,
        retries: s.pushQueueRetries,
      },
      outbox,
    };
  }

  @Get('admin/push-diagnostics')
  @RequirePermission(ADMIN_PERMISSIONS['operations:read'])
  @ApiOperation({ summary: 'FCM/APNs push delivery diagnostics (admin only)' })
  @ApiOkResponse({ type: PushDiagnosticsDto })
  getPushDiagnostics(): Promise<PushDiagnosticsDto> {
    return this.pushDiagnostics.getDiagnostics();
  }

  @Get('admin/dead-letters')
  @RequirePermission(ADMIN_PERMISSIONS['operations:read'])
  @ApiOperation({ summary: 'List dead-letter push outbox entries (admin only)' })
  @ApiOkResponse({ type: DeadLetterPageDto })
  deadLetters(
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.inbox.listDeadLetters(
      Number(page ?? '1'),
      Number(limit ?? '20'),
    );
  }

  @Idempotent('notifications_admin_dead_letters_requeue')
  @Post('admin/dead-letters/requeue')
  @RequirePermission(ADMIN_PERMISSIONS['operations:write'])
  @ApiOperation({ summary: 'Requeue actionable push dead letters with active device tokens' })
  @ApiOkResponse({ type: DeadLetterRequeueResultDto })
  requeueDeadLetters(): Promise<DeadLetterRequeueResultDto> {
    return this.deadLetterRequeue.requeueAll();
  }

  @Idempotent('notifications_admin_dead_letters_purge')
  @Post('admin/dead-letters/purge-terminal')
  @RequirePermission(ADMIN_PERMISSIONS['operations:write'])
  @ApiOperation({ summary: 'Purge undeliverable push dead letters (revoked tokens / invalid registration)' })
  @ApiOkResponse({ type: DeadLetterPurgeResultDto })
  purgeTerminalDeadLetters(): Promise<DeadLetterPurgeResultDto> {
    return this.deadLetterRequeue.purgeTerminal();
  }

  @Idempotent('notifications_admin_dead_letter_requeue_one')
  @Post('admin/dead-letters/:id/requeue')
  @RequirePermission(ADMIN_PERMISSIONS['operations:write'])
  @ApiOperation({ summary: 'Requeue a single push dead letter when actionable' })
  @ApiOkResponse({ type: DeadLetterRequeueOneResultDto })
  requeueDeadLetter(@Param('id') id: string): Promise<DeadLetterRequeueOneResultDto> {
    return this.deadLetterRequeue.requeueOne(id);
  }
}
