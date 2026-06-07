import { Body, Controller, Get, Patch, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../auth/guards/roles.guard';
import { Roles } from '../../auth/decorators/roles.decorator';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import { ADMIN_PANEL_ROLES } from '../../auth/constants/admin-roles';
import type { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { ApiStandardHttpErrorResponses } from '../../common/openapi/standard-http-error-responses.decorator';
import { AdminModerationEmailPreferencesService } from '../services/admin-moderation-email-preferences.service';
import { PatchModerationEmailPreferenceDto } from '../dto/patch-moderation-email-preferences.dto';

@ApiTags('admin-moderation-email')
@ApiStandardHttpErrorResponses()
@Controller('admin/me/moderation-email-preferences')
@UseGuards(JwtAuthGuard, RolesGuard)
@ApiBearerAuth()
export class AdminModerationEmailPreferencesController {
  constructor(private readonly preferences: AdminModerationEmailPreferencesService) {}

  @Get()
  @Roles(...ADMIN_PANEL_ROLES)
  @ApiOperation({ summary: 'List moderation email preferences for the current admin' })
  @ApiOkResponse({ description: 'Preferences listed' })
  list(@CurrentUser() admin: AuthenticatedUser) {
    return this.preferences.listForUser(admin.userId, admin.role);
  }

  @Patch()
  @Roles(...ADMIN_PANEL_ROLES)
  @ApiOperation({ summary: 'Update one moderation email preference for the current admin' })
  @ApiOkResponse({ description: 'Preference updated' })
  async patch(@CurrentUser() admin: AuthenticatedUser, @Body() dto: PatchModerationEmailPreferenceDto) {
    await this.preferences.setPreference(admin.userId, dto.category, dto.enabled);
    return this.preferences.listForUser(admin.userId, admin.role);
  }
}
