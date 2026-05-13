import { Body, Controller, HttpCode, HttpStatus, Post, UnauthorizedException, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiNoContentResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { ADMIN_PANEL_ROLES } from './admin-roles';
import { AuthMfaService } from './auth-mfa.service';
import { CurrentUser } from './current-user.decorator';
import { Disable2FADto } from './dto/disable-2fa.dto';
import { Enable2FADto } from './dto/enable-2fa.dto';
import { JwtAuthGuard } from './jwt-auth.guard';
import { Roles } from './roles.decorator';
import { RolesGuard } from './roles.guard';
import { AuthenticatedUser } from './types/authenticated-user.type';
import { ApiStandardHttpErrorResponses } from '../common/openapi/standard-http-error-responses.decorator';

@ApiTags('auth')
@ApiStandardHttpErrorResponses()
@Controller('auth')
export class AuthMfaController {
  constructor(private readonly mfa: AuthMfaService) {}

  @Post('me/2fa/setup')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @Throttle({ default: { ttl: 60_000, limit: 5 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Start 2FA setup; returns QR URI and secret' })
  @ApiOkResponse({ description: 'Setup data for QR code' })
  @HttpCode(HttpStatus.OK)
  async setupMfa(@CurrentUser() user?: AuthenticatedUser) {
    if (!user) {
      throw new UnauthorizedException({
        code: 'UNAUTHORIZED',
        message: 'Authentication required',
      });
    }
    return this.mfa.setupMfa(user.userId);
  }

  @Post('me/2fa/enable')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @Throttle({ default: { ttl: 60_000, limit: 5 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Enable 2FA after verifying TOTP code' })
  @ApiOkResponse({ description: '2FA enabled; backup codes returned' })
  @HttpCode(HttpStatus.OK)
  async enableMfa(
    @CurrentUser() user: AuthenticatedUser | undefined,
    @Body() dto: Enable2FADto,
  ) {
    if (!user) {
      throw new UnauthorizedException({
        code: 'UNAUTHORIZED',
        message: 'Authentication required',
      });
    }
    return this.mfa.enableMfa(user.userId, dto);
  }

  @Post('me/2fa/disable')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @Throttle({ default: { ttl: 60_000, limit: 5 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Disable 2FA; requires current password' })
  @ApiNoContentResponse({ description: '2FA disabled' })
  @HttpCode(HttpStatus.NO_CONTENT)
  async disableMfa(
    @CurrentUser() user: AuthenticatedUser | undefined,
    @Body() dto: Disable2FADto,
  ): Promise<void> {
    if (!user) {
      throw new UnauthorizedException({
        code: 'UNAUTHORIZED',
        message: 'Authentication required',
      });
    }
    await this.mfa.disableMfa(user.userId, dto);
  }
}
