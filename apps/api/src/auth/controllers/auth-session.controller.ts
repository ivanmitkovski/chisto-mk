import { Body, Controller, Headers, HttpCode, HttpStatus, Post, Req } from '@nestjs/common';
import type { Request } from 'express';
import {
  ApiCreatedResponse,
  ApiNoContentResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { AdminLoginDto } from '../dto/admin-login.dto';
import { CitizenLoginDto } from '../dto/citizen-login.dto';
import { Complete2FALoginDto } from '../dto/complete-2fa-login.dto';
import { RefreshTokenDto } from '../dto/refresh-token.dto';
import { RegisterDto } from '../dto/register.dto';
import { RegisterResponseDto } from '../dto/register-response.dto';
import { SendOtpDto } from '../dto/send-otp.dto';
import { VerifyOtpDto } from '../dto/verify-otp.dto';
import { AuthResponseDto } from '../dto/auth-response.dto';
import { ApiStandardHttpErrorResponses } from '../../common/openapi/standard-http-error-responses.decorator';
import { AuthAdminLoginService } from '../services/auth-admin-login.service';
import { AuthRegistrationService } from '../services/auth-registration.service';
import { AuthSessionService } from '../services/auth-session.service';
import { AuthLoginService } from '../services/auth-login.service';
import { AuthOtpService } from '../services/auth-otp.service';
import { clientIp } from '../../sites/http/client-ip';

@ApiTags('auth')
@ApiStandardHttpErrorResponses()
@Controller('auth')
export class AuthSessionController {
  constructor(
    private readonly registration: AuthRegistrationService,
    private readonly login: AuthLoginService,
    private readonly adminLoginSvc: AuthAdminLoginService,
    private readonly session: AuthSessionService,
    private readonly authOtp: AuthOtpService,
  ) {}

  @Post('register')
  @Throttle({ default: { ttl: 60_000, limit: 5 } })
  @ApiOperation({ summary: 'Register a new citizen account (phone verification required before sign-in)' })
  @ApiCreatedResponse({
    description: 'User created; OTP sent to phone. Complete verification via POST /auth/otp/verify to receive tokens.',
    type: RegisterResponseDto,
  })
  register(
    @Body() dto: RegisterDto,
    @Headers('accept-language') acceptLanguage?: string,
  ) {
    return this.registration.register(dto, acceptLanguage);
  }

  @Post('login')
  @Throttle({ default: { ttl: 60_000, limit: 10 } })
  @ApiOperation({ summary: 'Citizen login with phone number and password' })
  @ApiOkResponse({
    description: 'Citizen authenticated and tokens issued',
    type: AuthResponseDto,
  })
  @HttpCode(HttpStatus.OK)
  citizenLogin(@Body() dto: CitizenLoginDto, @Req() req: Request) {
    return this.login.citizenLogin(dto, clientIp(req, req.headers['x-forwarded-for'] as string | undefined));
  }

  @Post('admin/login')
  @Throttle({ default: { ttl: 60_000, limit: 10 } })
  @ApiOperation({ summary: 'Admin login with email and password' })
  @ApiOkResponse({
    description: 'Admin authenticated and tokens issued, or requiresTotp + tempToken when 2FA enabled',
  })
  @HttpCode(HttpStatus.OK)
  adminLogin(@Body() dto: AdminLoginDto) {
    return this.adminLoginSvc.adminLogin(dto);
  }

  @Post('admin/2fa/complete-login')
  @Throttle({ default: { ttl: 60_000, limit: 10 } })
  @ApiOperation({ summary: 'Complete admin login with TOTP or backup code' })
  @ApiOkResponse({
    description: 'Admin authenticated and tokens issued',
    type: AuthResponseDto,
  })
  @HttpCode(HttpStatus.OK)
  completeAdmin2FALogin(@Body() dto: Complete2FALoginDto) {
    return this.adminLoginSvc.completeAdmin2FALogin(
      dto.tempToken,
      dto.code,
      dto.deviceId,
      dto.rememberMe,
    );
  }

  @Post('refresh')
  @Throttle({ default: { ttl: 60_000, limit: 30 } })
  @ApiOperation({ summary: 'Rotate access and refresh tokens using a valid refresh token' })
  @ApiOkResponse({
    description: 'New token pair issued, old refresh token revoked',
    type: AuthResponseDto,
  })
  @HttpCode(HttpStatus.OK)
  refresh(@Body() dto: RefreshTokenDto) {
    return this.session.refresh(dto.refreshToken, dto.deviceId);
  }

  @Post('logout')
  @Throttle({ default: { ttl: 60_000, limit: 30 } })
  @ApiOperation({ summary: 'Revoke refresh token session' })
  @ApiNoContentResponse({ description: 'Session revoked' })
  @HttpCode(HttpStatus.NO_CONTENT)
  async logout(@Body() dto: RefreshTokenDto): Promise<void> {
    await this.session.logout(dto.refreshToken);
  }

  @Post('otp/send')
  @Throttle({ default: { ttl: 60_000, limit: 5 } })
  @ApiOperation({ summary: 'Send OTP to registered phone for verification' })
  @ApiOkResponse({ description: 'OTP sent; in development devCode is returned' })
  @HttpCode(HttpStatus.OK)
  sendOtp(@Body() dto: SendOtpDto, @Headers('accept-language') acceptLanguage?: string) {
    return this.authOtp.sendPhoneVerificationOtp(
      dto.phoneNumber,
      acceptLanguage != null && acceptLanguage !== '' ? acceptLanguage : undefined,
    );
  }

  @Post('otp/verify')
  @Throttle({ default: { ttl: 60_000, limit: 10 } })
  @ApiOperation({ summary: 'Verify OTP, mark phone verified, and issue auth tokens' })
  @ApiOkResponse({
    description: 'Phone verified and session tokens issued',
    type: AuthResponseDto,
  })
  @HttpCode(HttpStatus.OK)
  verifyOtp(@Body() dto: VerifyOtpDto, @Req() req: Request) {
    return this.authOtp.verifyPhoneAndIssueSession(
      dto.phoneNumber,
      dto.code,
      dto.rememberMe ?? true,
      dto.deviceId,
      clientIp(req, req.headers['x-forwarded-for'] as string | undefined),
    );
  }
}
