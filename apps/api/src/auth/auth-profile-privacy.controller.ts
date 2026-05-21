import { Idempotent } from '../common/idempotency/idempotency.decorator';
import {
  Controller,
  Delete,
  Get,
  Header,
  HttpCode,
  HttpStatus,
  Post,
  Res,
  UseGuards,
} from '@nestjs/common';
import type { Response } from 'express';
import {
  ApiBearerAuth,
  ApiNoContentResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { AuthProfileService } from './auth-profile.service';
import { AuthSessionService } from './auth-session.service';
import { UserDsarExportService } from './user-dsar-export.service';
import { CurrentUser } from './current-user.decorator';
import { JwtAuthGuard } from './jwt-auth.guard';
import { AuthenticatedUser } from './types/authenticated-user.type';
import { ApiStandardHttpErrorResponses } from '../common/openapi/standard-http-error-responses.decorator';
import { requireAuthenticatedUser } from './auth-require-user.util';

@ApiTags('auth')
@ApiStandardHttpErrorResponses()
@Controller('auth')
export class AuthProfilePrivacyController {
  constructor(
    private readonly profile: AuthProfileService,
    private readonly session: AuthSessionService,
    private readonly dsarExport: UserDsarExportService,
  ) {}

  @Get('me/data-export')
  @UseGuards(JwtAuthGuard)
  @Throttle({ default: { ttl: 3_600_000, limit: 1 } })
  @ApiBearerAuth()
  @Header('Content-Type', 'application/x-ndjson')
  @ApiOperation({ summary: 'Export personal data (GDPR access / portability, NDJSON stream)' })
  async exportMyData(
    @CurrentUser() user: AuthenticatedUser | undefined,
    @Res() res: Response,
  ): Promise<void> {
    const u = requireAuthenticatedUser(user);
    res.setHeader('Content-Type', 'application/x-ndjson');
    res.setHeader('Transfer-Encoding', 'chunked');
    for await (const line of this.dsarExport.streamSections(u.userId)) {
      res.write(line);
    }
    res.end();
  }

  @Idempotent('auth_revoke_other_sessions')
  @Post('sessions/revoke-others')
  @UseGuards(JwtAuthGuard)
  @Throttle({ default: { ttl: 60_000, limit: 10 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Revoke all sessions except the current access token session' })
  revokeOtherSessions(@CurrentUser() user: AuthenticatedUser | undefined) {
    return this.session.revokeOthersForCurrentUser(requireAuthenticatedUser(user));
  }

  @Delete('me')
  @UseGuards(JwtAuthGuard)
  @Throttle({ default: { ttl: 60_000, limit: 3 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Delete account (soft delete)' })
  @ApiNoContentResponse({ description: 'Account deleted' })
  @HttpCode(HttpStatus.NO_CONTENT)
  async deleteAccount(@CurrentUser() user?: AuthenticatedUser): Promise<void> {
    await this.profile.deleteAccount(requireAuthenticatedUser(user).userId);
  }
}
