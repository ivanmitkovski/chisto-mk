import { Body, Controller, Get, Param, Patch, UseGuards } from '@nestjs/common';
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
import { ADMIN_PANEL_ROLES, ADMIN_WRITE_ROLES } from '../auth/admin-roles';
import { FeatureFlagsService } from './feature-flags.service';
import { PatchFeatureFlagDto } from './dto/patch-feature-flag.dto';

@ApiTags('admin-feature-flags')
@Controller('admin/feature-flags')
export class FeatureFlagsController {
  constructor(private readonly featureFlagsService: FeatureFlagsService) {}

  @Get()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List feature flags' })
  @ApiOkResponse({ description: 'Feature flags' })
  list() {
    return this.featureFlagsService.listForAdmin();
  }

  @Patch(':key')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_WRITE_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update a feature flag' })
  @ApiOkResponse({ description: 'Feature flag updated' })
  patch(
    @Param('key') key: string,
    @Body() dto: PatchFeatureFlagDto,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    return this.featureFlagsService.patch(key, dto, actor);
  }
}
