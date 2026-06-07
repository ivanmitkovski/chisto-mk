import { Controller, Get, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../auth/guards/roles.guard';
import { PermissionsGuard } from '../../auth/guards/permissions.guard';
import { Roles } from '../../auth/decorators/roles.decorator';
import { RequirePermission } from '../../auth/decorators/require-permission.decorator';
import { ADMIN_PANEL_ROLES } from '../../auth/constants/admin-roles';
import { ADMIN_PERMISSIONS } from '../../auth/constants/admin-permissions';
import { ReportSideEffectQueryService } from '../../reports/side-effects/report-side-effect-query.service';
import { ReportSideEffectPendingCountDto } from '../dto/report-side-effect-pending-count.dto';

@ApiTags('admin-operations')
@Controller('admin/operations')
@UseGuards(JwtAuthGuard, RolesGuard, PermissionsGuard)
@ApiBearerAuth()
export class AdminOperationsController {
  constructor(private readonly reportSideEffects: ReportSideEffectQueryService) {}

  @Get('report-side-effects/pending-count')
  @Roles(...ADMIN_PANEL_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['operations:read'])
  @ApiOperation({ summary: 'Count pending report side-effect outbox jobs' })
  @ApiOkResponse({ type: ReportSideEffectPendingCountDto })
  async reportSideEffectPendingCount(): Promise<ReportSideEffectPendingCountDto> {
    const pendingCount = await this.reportSideEffects.countPending();
    return { pendingCount };
  }
}
