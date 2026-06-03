import { Idempotent } from '../../common/idempotency/idempotency.decorator';
import {
  Body,
  Controller,
  HttpCode,
  HttpStatus,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiNoContentResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import { AuthIdentifierChangeService } from '../services/auth-identifier-change.service';
import { ConfirmEmailChangeDto, RequestEmailChangeDto } from '../dto/change-email.dto';
import { ConfirmPhoneChangeDto, RequestPhoneChangeDto } from '../dto/change-phone.dto';
import { CurrentUser } from '../decorators/current-user.decorator';
import { JwtAuthGuard } from '../guards/jwt-auth.guard';
import { AuthenticatedUser } from '../types/authenticated-user.type';
import { ApiStandardHttpErrorResponses } from '../../common/openapi/standard-http-error-responses.decorator';
import { requireAuthenticatedUser } from '../util/auth-require-user.util';

@ApiTags('auth')
@ApiStandardHttpErrorResponses()
@Controller('auth')
export class AuthProfileIdentifierController {
  constructor(private readonly identifierChange: AuthIdentifierChangeService) {}

  @Patch('me/email')
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @Throttle({ default: { ttl: 3_600_000, limit: 3 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Request email change (OTP sent to new address)' })
  requestEmailChange(
    @CurrentUser() user: AuthenticatedUser | undefined,
    @Body() dto: RequestEmailChangeDto,
  ) {
    return this.identifierChange.requestEmailChange(
      requireAuthenticatedUser(user).userId,
      dto.newEmail,
    );
  }

  @Idempotent('auth_email_confirm')
  @Post('me/email/confirm')
  @HttpCode(HttpStatus.NO_CONTENT)
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @Throttle({ default: { ttl: 3_600_000, limit: 10 } })
  @ApiBearerAuth()
  @ApiNoContentResponse({ description: 'Email updated; all sessions revoked' })
  @ApiOperation({ summary: 'Confirm email change with OTP' })
  async confirmEmailChange(
    @CurrentUser() user: AuthenticatedUser | undefined,
    @Body() dto: ConfirmEmailChangeDto,
  ): Promise<void> {
    const u = requireAuthenticatedUser(user);
    await this.identifierChange.confirmEmailChange(u.userId, dto.newEmail, dto.code);
  }

  @Patch('me/phone')
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @Throttle({ default: { ttl: 3_600_000, limit: 3 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Request phone change (OTP to new number)' })
  requestPhoneChange(
    @CurrentUser() user: AuthenticatedUser | undefined,
    @Body() dto: RequestPhoneChangeDto,
  ) {
    return this.identifierChange.requestPhoneChange(
      requireAuthenticatedUser(user).userId,
      dto.newPhoneNumber,
    );
  }

  @Idempotent('auth_phone_confirm')
  @Post('me/phone/confirm')
  @HttpCode(HttpStatus.NO_CONTENT)
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @Throttle({ default: { ttl: 3_600_000, limit: 10 } })
  @ApiBearerAuth()
  @ApiNoContentResponse({ description: 'Phone updated; all sessions revoked' })
  async confirmPhoneChange(
    @CurrentUser() user: AuthenticatedUser | undefined,
    @Body() dto: ConfirmPhoneChangeDto,
  ): Promise<void> {
    const u = requireAuthenticatedUser(user);
    await this.identifierChange.confirmPhoneChange(u.userId, dto.newPhoneNumber, dto.code);
  }
}
