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
import { FcmPushService } from '../services/fcm-push.service';
import { DeviceTokenService } from '../services/device-token.service';
import { remediationForFcmErrorCode } from '../util/fcm-error-codes';
import {
  DeadLetterPageDto,
  DeadLetterPurgeResultDto,
  DeadLetterRequeueOneResultDto,
  DeadLetterRequeueResultDto,
  DeliveryReportDto,
  PushDiagnosticsDto,
  PushStatsDto,
  TestPushResultDto,
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
    private readonly fcm: FcmPushService,
    private readonly deviceTokens: DeviceTokenService,
  ) {}

  @Idempotent('notifications_admin_test_push')
  @Post('admin/test-push')
  @RequirePermission(ADMIN_PERMISSIONS['operations:write'])
  @ApiOperation({
    summary: 'Send a test push to the current admin user (full outbox → FCM pipeline)',
  })
  @ApiOkResponse({ type: TestPushResultDto })
  async testPush(@CurrentUser() user: AuthenticatedUser): Promise<TestPushResultDto> {
    const localeBy = await userLocalesByUserId(this.prisma, [user.userId]);
    const copy = adminTestPushCopy(localeBy.get(user.userId)!);
    const pushEnabled = this.fcm.isEnabled();
    const fcmReady = this.fcm.isReady();
    const activeTokenCount = (await this.deviceTokens.getActiveTokensForUser(user.userId)).length;

    await this.dispatcher.dispatchToUser(user.userId, {
      title: copy.title,
      body: copy.body,
      type: NotificationType.SYSTEM,
      data: { kind: 'test_push' },
    });

    const notification = await this.prisma.userNotification.findFirst({
      where: {
        userId: user.userId,
        type: NotificationType.SYSTEM,
        data: { path: ['kind'], equals: 'test_push' },
      },
      orderBy: { createdAt: 'desc' },
      select: { id: true },
    });

    const outboxEnqueued =
      notification != null
        ? await this.prisma.notificationOutbox.count({
            where: { userNotificationId: notification.id },
          })
        : 0;

    const inboxCreated = notification != null;
    let remediation: string | null = null;
    if (!inboxCreated) {
      remediation = 'Inbox notification was not created. Check NOTIFICATIONS_INBOX_ENABLED and user mute settings.';
    } else if (!pushEnabled) {
      remediation = 'Push is disabled (PUSH_FCM_ENABLED=false). Enable FCM to deliver test pushes.';
    } else if (!fcmReady) {
      remediation =
        remediationForFcmErrorCode('FCM_NOT_READY') ??
        'FCM is enabled but not ready. Check FIREBASE_SERVICE_ACCOUNT_JSON.';
    } else if (activeTokenCount === 0) {
      remediation =
        'No active device tokens for this user. Log in on a physical device with notifications allowed.';
    } else if (outboxEnqueued === 0) {
      remediation = 'Push was skipped after inbox write. Check API logs for dispatch skip reason.';
    }

    return {
      success: true,
      funnel: {
        inboxCreated,
        pushEnabled,
        fcmReady,
        activeTokenCount,
        outboxEnqueued,
        notificationId: notification?.id ?? null,
      },
      remediation,
    };
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
