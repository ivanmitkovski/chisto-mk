import { Idempotent } from '../../common/idempotency/idempotency.decorator';
import { Body, Controller, Get, Patch, Post, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';
import { Roles } from '../../auth/decorators/roles.decorator';
import { RolesGuard } from '../../auth/guards/roles.guard';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import type { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { ADMIN_PANEL_ROLES, SUPER_ADMIN_ROLES } from '../../auth/constants/admin-roles';
import { SystemConfigService } from '../services/system-config.service';
import { PatchSystemConfigDto } from '../dto/patch-system-config.dto';
import { ApiStandardHttpErrorResponses } from '../../common/openapi/standard-http-error-responses.decorator';

@ApiTags('admin-config')
@ApiStandardHttpErrorResponses()
@Controller('admin/config')
export class SystemConfigController {
  constructor(private readonly systemConfigService: SystemConfigService) {}

  @Get()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List system configuration entries' })
  @ApiOkResponse({ description: 'Configuration entries' })
  getAll() {
    return this.systemConfigService.getAll();
  }

  @Idempotent('system-config_system-config_34')
  @Post('validate')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...SUPER_ADMIN_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Validate configuration changes without applying' })
  @ApiOkResponse({ description: 'Validation result' })
  validate(@Body() dto: PatchSystemConfigDto) {
    return this.systemConfigService.validate(dto);
  }

  // safe-to-retry: repeated Patch is acceptable
  @Patch()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...SUPER_ADMIN_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Upsert system configuration entries' })
  @ApiOkResponse({ description: 'Configuration updated' })
  patch(@Body() dto: PatchSystemConfigDto, @CurrentUser() actor: AuthenticatedUser) {
    return this.systemConfigService.patch(dto, actor);
  }
}

