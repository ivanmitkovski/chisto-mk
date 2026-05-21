import { Controller, Get, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiOperation, ApiTags } from '@nestjs/swagger';
import { ADMIN_PANEL_ROLES } from './admin-roles';
import { JwtAuthGuard } from './jwt-auth.guard';
import { Roles } from './roles.decorator';
import { RolesGuard } from './roles.guard';
import { ApiStandardHttpErrorResponses } from '../common/openapi/standard-http-error-responses.decorator';

@ApiTags('auth')
@ApiStandardHttpErrorResponses()
@Controller('auth')
export class AuthAdminController {
  @Get('admin/ping')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Admin-only authorization check endpoint' })
  @ApiOkResponse({ description: 'Admin role validated' })
  adminPing() {
    return { message: 'Admin access granted' };
  }
}
