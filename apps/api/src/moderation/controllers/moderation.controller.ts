import { Idempotent } from '../../common/idempotency/idempotency.decorator';
import { Body, Controller, Delete, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { Roles } from '../../auth/decorators/roles.decorator';
import { RolesGuard } from '../../auth/guards/roles.guard';
import { ADMIN_PANEL_ROLES, ADMIN_WRITE_ROLES } from '../../auth/constants/admin-roles';
import { ModerationService } from '../services/moderation.service';
import { ListAdminUgcReportsQueryDto } from '../dto/list-admin-ugc-reports-query.dto';
import { PatchAdminUgcReportDto } from '../dto/patch-admin-ugc-report.dto';
import { PostUgcReportDto } from '../dto/post-ugc-report.dto';
import { PostUserBlockDto } from '../dto/post-user-block.dto';

@ApiTags('moderation')
@Controller()
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class ModerationController {
  constructor(private readonly moderation: ModerationService) {}

  @Get('admin/moderation/ugc-reports')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List UGC reports for admin moderation' })
  listAdminUgcReports(@Query() query: ListAdminUgcReportsQueryDto) {
    return this.moderation.listAdminUgcReports(query);
  }

  @Get('admin/moderation/ugc-reports/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get UGC report detail for admin moderation' })
  getAdminUgcReport(@Param('id') id: string) {
    return this.moderation.getAdminUgcReport(id);
  }

  @Idempotent('moderation_admin_ugc_patch')
  @Patch('admin/moderation/ugc-reports/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_WRITE_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Moderate a UGC report' })
  patchAdminUgcReport(
    @Param('id') id: string,
    @Body() dto: PatchAdminUgcReportDto,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    return this.moderation.patchAdminUgcReport(id, dto, actor);
  }

  @Idempotent('moderation_moderation_17')
  @Post('moderation/reports')
  @ApiOperation({ summary: 'Report UGC (comment, chat message, user, site, event)' })
  submitReport(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: PostUgcReportDto,
  ) {
    return this.moderation.submitReport(user, dto);
  }

  @Idempotent('moderation_moderation_26')
  @Post('users/me/blocks')
  @ApiOperation({ summary: 'Block a user' })
  blockUser(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: PostUserBlockDto,
  ) {
    return this.moderation.blockUser(user, dto);
  }

  @Get('users/me/blocks')
  @ApiOperation({ summary: 'List blocked users' })
  listBlocks(@CurrentUser() user: AuthenticatedUser) {
    return this.moderation.listBlocks(user);
  }

  // safe-to-retry: repeated Delete is acceptable
  @Delete('users/me/blocks/:blockedUserId')
  @ApiOperation({ summary: 'Unblock a user' })
  unblock(
    @CurrentUser() user: AuthenticatedUser,
    @Param('blockedUserId') blockedUserId: string,
  ) {
    return this.moderation.unblock(user, blockedUserId);
  }
}
