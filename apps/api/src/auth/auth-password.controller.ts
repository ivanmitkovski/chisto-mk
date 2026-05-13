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
import { CurrentUser } from './current-user.decorator';
import { ChangePasswordDto } from './dto/change-password.dto';
import { ResetPasswordConfirmDto } from './dto/reset-password-confirm.dto';
import { SendOtpDto } from './dto/send-otp.dto';
import { VerifyOtpDto } from './dto/verify-otp.dto';
import { JwtAuthGuard } from './jwt-auth.guard';
import { AuthenticatedUser } from './types/authenticated-user.type';
import { OtpSmsPurpose } from '../otp/otp-sender.interface';
import { ApiStandardHttpErrorResponses } from '../common/openapi/standard-http-error-responses.decorator';

@ApiTags('auth')
@ApiStandardHttpErrorResponses()
@Controller('auth')
export class AuthPasswordController {
  constructor(private readonly credential: AuthCredentialService) {}

  @Post('password-reset/request')
  @Throttle({ default: { ttl: 60_000, limit: 5 } })
  @ApiOperation({ summary: 'Request password reset; sends OTP to registered phone' })
  @ApiOkResponse({ description: 'OTP sent; in development devCode is returned when SMS_PROVIDER is not Twilio' })
  @HttpCode(HttpStatus.OK)
  requestPasswordReset(@Body() dto: SendOtpDto, @Headers('accept-language') acceptLanguage?: string) {
    return this.credential.sendOtp(dto.phoneNumber, {
      purpose: OtpSmsPurpose.PasswordReset,
      ...(acceptLanguage != null && acceptLanguage !== '' ? { acceptLanguage } : {}),
    });
  }

  @Post('password-reset/verify-code')
  @Throttle({ default: { ttl: 60_000, limit: 10 } })
  @ApiOperation({ summary: 'Verify password-reset OTP before setting a new password' })
  @ApiNoContentResponse({ description: 'Code is valid; OTP is not consumed until confirm' })
  @HttpCode(HttpStatus.NO_CONTENT)
  async verifyPasswordResetCode(@Body() dto: VerifyOtpDto): Promise<void> {
    await this.credential.verifyPasswordResetCode(dto.phoneNumber, dto.code);
  }

  @Post('password-reset/confirm')
  @Throttle({ default: { ttl: 60_000, limit: 10 } })
  @ApiOperation({ summary: 'Confirm password reset with OTP and new password' })
  @ApiOkResponse({ description: 'Password reset successful; all sessions invalidated' })
  @HttpCode(HttpStatus.OK)
  confirmPasswordReset(@Body() dto: ResetPasswordConfirmDto): Promise<{ message: string }> {
    return this.credential.confirmPasswordReset(dto);
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
