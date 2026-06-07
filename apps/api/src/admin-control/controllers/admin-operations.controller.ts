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
import { OperationsMetricsSnapshotDto } from '../dto/operations-metrics-snapshot.dto';
import { OperationsReadinessDto } from '../dto/operations-readiness.dto';
import { ReportSideEffectPendingCountDto } from '../dto/report-side-effect-pending-count.dto';
import { SystemInfoDto } from '../dto/system-info.dto';
import { WorkerStatusListDto } from '../dto/worker-status.dto';
import { OperationsStatusService } from '../services/operations-status.service';

@ApiTags('admin-operations')
@Controller('admin/operations')
@UseGuards(JwtAuthGuard, RolesGuard, PermissionsGuard)
@ApiBearerAuth()
export class AdminOperationsController {
  constructor(
    private readonly reportSideEffects: ReportSideEffectQueryService,
    private readonly operationsStatus: OperationsStatusService,
  ) {}

  @Get('report-side-effects/pending-count')
  @Roles(...ADMIN_PANEL_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['operations:read'])
  @ApiOperation({ summary: 'Count pending report side-effect outbox jobs' })
  @ApiOkResponse({ type: ReportSideEffectPendingCountDto })
  async reportSideEffectPendingCount(): Promise<ReportSideEffectPendingCountDto> {
    const pendingCount = await this.reportSideEffects.countPending();
    return { pendingCount };
  }

  @Get('system-info')
  @Roles(...ADMIN_PANEL_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['operations:read'])
  @ApiOperation({ summary: 'API process version, uptime, and environment metadata' })
  @ApiOkResponse({ type: SystemInfoDto })
  systemInfo(): SystemInfoDto {
    return this.operationsStatus.getSystemInfo();
  }

  @Get('metrics-snapshot')
  @Roles(...ADMIN_PANEL_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['operations:read'])
  @ApiOperation({ summary: 'Curated in-process metrics snapshot for admin operations dashboard' })
  @ApiOkResponse({ type: OperationsMetricsSnapshotDto })
  metricsSnapshot(): OperationsMetricsSnapshotDto {
    return this.operationsStatus.getMetricsSnapshot();
  }

  @Get('workers')
  @Roles(...ADMIN_PANEL_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['operations:read'])
  @ApiOperation({ summary: 'In-process worker heartbeat status (per replica)' })
  @ApiOkResponse({ type: WorkerStatusListDto })
  workers(): WorkerStatusListDto {
    return this.operationsStatus.getWorkers();
  }

  @Get('readiness')
  @Roles(...ADMIN_PANEL_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['operations:read'])
  @ApiOperation({ summary: 'Dependency readiness for admin operations diagnostics' })
  @ApiOkResponse({ type: OperationsReadinessDto })
  readiness(): Promise<OperationsReadinessDto> {
    return this.operationsStatus.getReadiness();
  }
}
