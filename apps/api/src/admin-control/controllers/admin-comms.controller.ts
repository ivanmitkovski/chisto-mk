import { Body, Controller, Delete, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../auth/guards/roles.guard';
import { PermissionsGuard } from '../../auth/guards/permissions.guard';
import { Roles } from '../../auth/decorators/roles.decorator';
import { RequirePermission } from '../../auth/decorators/require-permission.decorator';
import { ADMIN_PANEL_ROLES, ADMIN_WRITE_ROLES } from '../../auth/constants/admin-roles';
import { ADMIN_PERMISSIONS } from '../../auth/constants/admin-permissions';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import type { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { AdminCommsService } from '../services/admin-comms.service';
import { CreateEmailSuppressionDto } from '../dto/create-email-suppression.dto';
import { EmailDeadLetterPageDto } from '../dto/email-dead-letter.dto';

@ApiTags('admin-comms')
@Controller('admin/comms')
@UseGuards(JwtAuthGuard, RolesGuard, PermissionsGuard)
@ApiBearerAuth()
export class AdminCommsController {
  constructor(private readonly comms: AdminCommsService) {}

  @Get('email-suppressions')
  @Roles(...ADMIN_PANEL_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['comms:read'])
  @ApiOperation({ summary: 'List email suppressions' })
  listSuppressions(
    @Query('page') page?: string,
    @Query('limit') limit?: string,
    @Query('search') search?: string,
    @Query('reason') reason?: string,
    @Query('source') source?: string,
  ) {
    return this.comms.listEmailSuppressions(
      page ? Number(page) : 1,
      limit ? Number(limit) : 50,
      search,
      reason,
      source,
    );
  }

  @Post('email-suppressions')
  @Roles(...ADMIN_WRITE_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['comms:write'])
  @ApiOperation({ summary: 'Create or update a manual email suppression' })
  @ApiOkResponse({ description: 'Suppression created' })
  createSuppression(@Body() dto: CreateEmailSuppressionDto, @CurrentUser() actor: AuthenticatedUser) {
    return this.comms.createEmailSuppression(
      dto.email,
      dto.reason ?? 'ManualSuppression',
      actor,
    );
  }

  @Delete('email-suppressions/:email')
  @Roles(...ADMIN_WRITE_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['comms:write'])
  @ApiOperation({ summary: 'Remove email suppression' })
  removeSuppression(@Param('email') email: string, @CurrentUser() actor: AuthenticatedUser) {
    return this.comms.removeEmailSuppression(decodeURIComponent(email), actor);
  }

  @Get('email-dead-letters')
  @Roles(...ADMIN_PANEL_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['comms:read'])
  @ApiOperation({ summary: 'List email delivery dead-letter outbox entries' })
  @ApiOkResponse({ type: EmailDeadLetterPageDto })
  listEmailDeadLetters(
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.comms.listEmailDeadLetters(
      page ? Number(page) : 1,
      limit ? Number(limit) : 20,
    );
  }

  @Get('webhook-logs')
  @Roles(...ADMIN_PANEL_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['comms:read'])
  @ApiOperation({ summary: 'List webhook delivery logs' })
  listWebhookLogs(
    @Query('page') page?: string,
    @Query('limit') limit?: string,
    @Query('action') action?: string,
  ) {
    return this.comms.listWebhookLogs(page ? Number(page) : 1, limit ? Number(limit) : 50, action);
  }
}
