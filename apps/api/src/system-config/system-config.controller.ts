import { Body, Controller, Get, Patch, Post, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { ADMIN_PANEL_ROLES, SUPER_ADMIN_ROLES } from '../auth/admin-roles';
import { SystemConfigService } from './system-config.service';
import { PatchSystemConfigDto } from './dto/patch-system-config.dto';

@ApiTags('admin-config')
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

  @Post('validate')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...SUPER_ADMIN_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Validate configuration changes without applying' })
  @ApiOkResponse({ description: 'Validation result' })
  validate(@Body() dto: PatchSystemConfigDto) {
    return this.systemConfigService.validate(dto);
  }

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

