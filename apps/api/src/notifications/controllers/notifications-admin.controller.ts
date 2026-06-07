import { Idempotent } from '../../common/idempotency/idempotency.decorator';
import { Controller, Get, Post, Query, UseGuards } from '@nestjs/common';
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
import { ObservabilityStore } from '../../observability/observability.store';
import {
  DeadLetterPageDto,
  DeliveryReportDto,
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
  ) {}

  @Idempotent('notifications_admin_test_push')
  @Post('admin/test-push')
  @RequirePermission(ADMIN_PERMISSIONS['operations:write'])
  @ApiOperation({
    summary: 'Send a test push to the current admin user (full outbox → FCM pipeline)',
  })
  @ApiOkResponse({ description: 'Test notification dispatched' })
  async testPush(@CurrentUser() user: AuthenticatedUser) {
    await this.dispatcher.dispatchToUser(user.userId, {
      title: 'Chisto test push',
      body: 'If you see this, push delivery is working.',
      type: NotificationType.SYSTEM,
      data: { kind: 'test_push' },
    });
    return { success: true };
  }

  @Get('admin/push-stats')
  @RequirePermission(ADMIN_PERMISSIONS['operations:read'])
  @ApiOperation({ summary: 'Push delivery statistics (admin only)' })
  @ApiOkResponse({ type: PushStatsDto })
  pushStats(): PushStatsDto {
    const s = ObservabilityStore.snapshot();
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
    };
  }

  @Get('admin/delivery-report')
  @RequirePermission(ADMIN_PERMISSIONS['operations:read'])
  @ApiOperation({ summary: 'Push delivery funnel (admin only)' })
  @ApiOkResponse({ type: DeliveryReportDto })
  async deliveryReport(): Promise<DeliveryReportDto> {
    const s = ObservabilityStore.snapshot();
    const [sent, opened] = await Promise.all([
      this.inbox.countSentNotifications(),
      this.inbox.countOpenedNotifications(),
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
    };
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
}
