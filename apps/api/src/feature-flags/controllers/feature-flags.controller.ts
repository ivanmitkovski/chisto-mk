import { Body, Controller, Get, Param, Patch, UseGuards } from '@nestjs/common';
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
import { ADMIN_PANEL_ROLES, ADMIN_WRITE_ROLES } from '../../auth/constants/admin-roles';
import { FeatureFlagsService } from '../services/feature-flags.service';
import { PatchFeatureFlagDto } from '../dto/patch-feature-flag.dto';
import { ApiStandardHttpErrorResponses } from '../../common/openapi/standard-http-error-responses.decorator';

@ApiTags('admin-feature-flags')
@ApiStandardHttpErrorResponses()
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

  // safe-to-retry: repeated Patch is acceptable
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
