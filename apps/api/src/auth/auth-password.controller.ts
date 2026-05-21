import {
  Body,
  Controller,
  Headers,
  HttpCode,
  HttpStatus,
  Patch,
  Post,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiNoContentResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { AuthCredentialService } from './auth-credential.service';
import { PasswordResetService } from './password-reset.service';
import { CurrentUser } from './current-user.decorator';
import { ChangePasswordDto } from './dto/change-password.dto';
import { ResetPasswordConfirmDto } from './dto/reset-password-confirm.dto';
import { PasswordResetRequestDto } from './dto/password-reset-request.dto';
import { PasswordResetEmailConfirmDto } from './dto/password-reset-email-confirm.dto';
import { VerifyOtpDto } from './dto/verify-otp.dto';
import { JwtAuthGuard } from './jwt-auth.guard';
import { AuthenticatedUser } from './types/authenticated-user.type';
import { ApiStandardHttpErrorResponses } from '../common/openapi/standard-http-error-responses.decorator';

@ApiTags('auth')
@ApiStandardHttpErrorResponses()
@Controller('auth')
export class AuthPasswordController {
  constructor(
    private readonly credential: AuthCredentialService,
    private readonly passwordReset: PasswordResetService,
  ) {}

  @Post('password-reset/request')
  @Throttle({ default: { ttl: 60_000, limit: 5 } })
  @ApiOperation({ summary: 'Request password reset via SMS (phone) or email link' })
  @ApiOkResponse({
    description:
      'Generic success message. When an account exists, SMS OTP or email link is sent. devCode returned in development when SMS is used.',
  })
  @HttpCode(HttpStatus.OK)
  requestPasswordReset(
    @Body() dto: PasswordResetRequestDto,
    @Headers('accept-language') acceptLanguage?: string,
  ) {
    return this.passwordReset.request({
      ...(dto.phoneNumber != null ? { phoneNumber: dto.phoneNumber } : {}),
      ...(dto.email != null ? { email: dto.email } : {}),
      ...(acceptLanguage != null && acceptLanguage !== '' ? { acceptLanguage } : {}),
    });
  }

  @Post('password-reset/verify-code')
  @Throttle({ default: { ttl: 60_000, limit: 10 } })
  @ApiOperation({ summary: 'Verify password-reset OTP before setting a new password' })
  @ApiNoContentResponse({ description: 'Code is valid; OTP is not consumed until confirm' })
  @HttpCode(HttpStatus.NO_CONTENT)
  async verifyPasswordResetCode(@Body() dto: VerifyOtpDto): Promise<void> {
    await this.passwordReset.verifyPasswordResetCode(dto.phoneNumber, dto.code);
  }

  @Post('password-reset/confirm')
  @Throttle({ default: { ttl: 60_000, limit: 10 } })
  @ApiOperation({ summary: 'Confirm password reset with SMS OTP and new password' })
  @ApiOkResponse({
    description:
      'Password reset successful; all sessions invalidated. A password-changed confirmation email may be sent when transactional email is enabled.',
  })
  @HttpCode(HttpStatus.OK)
  confirmPasswordReset(@Body() dto: ResetPasswordConfirmDto): Promise<{ message: string }> {
    return this.passwordReset.confirmSmsReset(dto);
  }

  @Post('password-reset/email/confirm')
  @Throttle({ default: { ttl: 60_000, limit: 3 } })
  @ApiOperation({ summary: 'Confirm password reset using token from email link' })
  @ApiOkResponse({ description: 'Password reset successful; all sessions invalidated' })
  @HttpCode(HttpStatus.OK)
  confirmEmailPasswordReset(@Body() dto: PasswordResetEmailConfirmDto): Promise<{ message: string }> {
    return this.passwordReset.confirmEmailReset(dto.token, dto.newPassword);
  }

  @Patch('me/password')
  @UseGuards(JwtAuthGuard)
  @Throttle({ default: { ttl: 60_000, limit: 5 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Change password for authenticated user' })
  @ApiNoContentResponse({ description: 'Password changed' })
  @HttpCode(HttpStatus.NO_CONTENT)
  async changePassword(
    @CurrentUser() user: AuthenticatedUser | undefined,
    @Body() dto: ChangePasswordDto,
  ): Promise<void> {
    if (!user) {
      throw new UnauthorizedException({
        code: 'UNAUTHORIZED',
        message: 'Authentication required',
      });
    }
    await this.credential.changePassword(user.userId, dto);
  }
}
