import { Body, Controller, Headers, HttpCode, HttpStatus, Post } from '@nestjs/common';
import {
  ApiCreatedResponse,
  ApiNoContentResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { AdminLoginDto } from './dto/admin-login.dto';
import { CitizenLoginDto } from './dto/citizen-login.dto';
import { Complete2FALoginDto } from './dto/complete-2fa-login.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { RegisterDto } from './dto/register.dto';
import { SendOtpDto } from './dto/send-otp.dto';
import { VerifyOtpDto } from './dto/verify-otp.dto';
import { AuthResponseDto } from './dto/auth-response.dto';
import { OtpSmsPurpose } from '../otp/otp-sender.interface';
import { ApiStandardHttpErrorResponses } from '../common/openapi/standard-http-error-responses.decorator';
import { AuthAdminLoginService } from './auth-admin-login.service';
import { AuthCredentialService } from './auth-credential.service';
import { AuthRegistrationService } from './auth-registration.service';
import { AuthSessionService } from './auth-session.service';

@ApiTags('auth')
@ApiStandardHttpErrorResponses()
@Controller('auth')
export class AuthSessionController {
  constructor(
    private readonly registration: AuthRegistrationService,
    private readonly adminLoginSvc: AuthAdminLoginService,
    private readonly session: AuthSessionService,
    private readonly credential: AuthCredentialService,
  ) {}

  @Post('register')
  @Throttle({ default: { ttl: 60_000, limit: 5 } })
  @ApiOperation({ summary: 'Register a new citizen account' })
  @ApiCreatedResponse({
    description: 'User registered and tokens issued',
    type: AuthResponseDto,
  })
  register(@Body() dto: RegisterDto) {
    return this.registration.register(dto);
  }

  @Post('login')
  @Throttle({ default: { ttl: 60_000, limit: 10 } })
  @ApiOperation({ summary: 'Citizen login with phone number and password' })
  @ApiOkResponse({
    description: 'Citizen authenticated and tokens issued',
    type: AuthResponseDto,
  })
  @HttpCode(HttpStatus.OK)
  citizenLogin(@Body() dto: CitizenLoginDto) {
    return this.registration.citizenLogin(dto);
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
    return this.adminLoginSvc.completeAdmin2FALogin(dto.tempToken, dto.code);
  }

  @Post('refresh')
  @Throttle({ default: { ttl: 60_000, limit: 15 } })
  @ApiOperation({ summary: 'Rotate access and refresh tokens using a valid refresh token' })
  @ApiOkResponse({
    description: 'New token pair issued, old refresh token revoked',
    type: AuthResponseDto,
  })
  @HttpCode(HttpStatus.OK)
  refresh(@Body() dto: RefreshTokenDto) {
    return this.session.refresh(dto.refreshToken);
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
    return this.credential.sendOtp(dto.phoneNumber, {
      purpose: OtpSmsPurpose.PhoneVerification,
      ...(acceptLanguage != null && acceptLanguage !== '' ? { acceptLanguage } : {}),
    });
  }

  @Post('otp/verify')
  @Throttle({ default: { ttl: 60_000, limit: 10 } })
  @ApiOperation({ summary: 'Verify OTP and mark phone as verified' })
  @ApiNoContentResponse({ description: 'Phone verified' })
  @HttpCode(HttpStatus.NO_CONTENT)
  async verifyOtp(@Body() dto: VerifyOtpDto): Promise<void> {
    await this.credential.verifyOtp(dto.phoneNumber, dto.code);
  }
}
