import { Body, Controller, Delete, Get, HttpCode, HttpStatus, Patch, Post, UnauthorizedException, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiCreatedResponse,
  ApiNoContentResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { Role } from '../prisma-client';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import { AuthService } from './auth.service';
import { CurrentUser } from './current-user.decorator';
import { AdminLoginDto } from './dto/admin-login.dto';
import { ChangePasswordDto } from './dto/change-password.dto';
import { CitizenLoginDto } from './dto/citizen-login.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { RegisterDto } from './dto/register.dto';
import { ResetPasswordConfirmDto } from './dto/reset-password-confirm.dto';
import { SendOtpDto } from './dto/send-otp.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { VerifyOtpDto } from './dto/verify-otp.dto';
import { JwtAuthGuard } from './jwt-auth.guard';
import { Roles } from './roles.decorator';
import { RolesGuard } from './roles.guard';
import { AuthenticatedUser } from './types/authenticated-user.type';
import { AuthResponseDto } from './dto/auth-response.dto';

@ApiTags('auth')
@Controller('auth')
@UseGuards(ThrottlerGuard)
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  @Throttle({ default: { ttl: 60_000, limit: 5 } })
  @ApiOperation({ summary: 'Register a new citizen account' })
  @ApiCreatedResponse({
    description: 'User registered and tokens issued',
    type: AuthResponseDto,
  })
  register(@Body() dto: RegisterDto): Promise<AuthResponseDto> {
    return this.authService.register(dto);
  }

  @Post('login')
  @Throttle({ default: { ttl: 60_000, limit: 10 } })
  @ApiOperation({ summary: 'Citizen login with phone number and password' })
  @ApiOkResponse({
    description: 'Citizen authenticated and tokens issued',
    type: AuthResponseDto,
  })
  @HttpCode(HttpStatus.OK)
  citizenLogin(@Body() dto: CitizenLoginDto): Promise<AuthResponseDto> {
    return this.authService.citizenLogin(dto);
  }

  @Post('admin/login')
  @Throttle({ default: { ttl: 60_000, limit: 10 } })
  @ApiOperation({ summary: 'Admin login with email and password' })
  @ApiOkResponse({
    description: 'Admin authenticated and tokens issued',
    type: AuthResponseDto,
  })
  @HttpCode(HttpStatus.OK)
  adminLogin(@Body() dto: AdminLoginDto): Promise<AuthResponseDto> {
    return this.authService.adminLogin(dto);
  }

  @Post('refresh')
  @Throttle({ default: { ttl: 60_000, limit: 15 } })
  @ApiOperation({ summary: 'Rotate access and refresh tokens using a valid refresh token' })
  @ApiOkResponse({
    description: 'New token pair issued, old refresh token revoked',
    type: AuthResponseDto,
  })
  @HttpCode(HttpStatus.OK)
  refresh(@Body() dto: RefreshTokenDto): Promise<AuthResponseDto> {
    return this.authService.refresh(dto.refreshToken);
  }

  @Post('logout')
  @ApiOperation({ summary: 'Revoke refresh token session' })
  @ApiNoContentResponse({ description: 'Session revoked' })
  @HttpCode(HttpStatus.NO_CONTENT)
  async logout(@Body() dto: RefreshTokenDto): Promise<void> {
    await this.authService.logout(dto.refreshToken);
  }

  @Post('otp/send')
  @Throttle({ default: { ttl: 60_000, limit: 5 } })
  @ApiOperation({ summary: 'Send OTP to registered phone for verification' })
  @ApiOkResponse({ description: 'OTP sent; in development devCode is returned' })
  @HttpCode(HttpStatus.OK)
  sendOtp(@Body() dto: SendOtpDto) {
    return this.authService.sendOtp(dto.phoneNumber);
  }

  @Post('otp/verify')
  @Throttle({ default: { ttl: 60_000, limit: 10 } })
  @ApiOperation({ summary: 'Verify OTP and mark phone as verified' })
  @ApiNoContentResponse({ description: 'Phone verified' })
  @HttpCode(HttpStatus.NO_CONTENT)
  async verifyOtp(@Body() dto: VerifyOtpDto): Promise<void> {
    await this.authService.verifyOtp(dto.phoneNumber, dto.code);
  }

  @Post('password-reset/request')
  @Throttle({ default: { ttl: 60_000, limit: 5 } })
  @ApiOperation({ summary: 'Request password reset; sends OTP to registered phone' })
  @ApiOkResponse({ description: 'OTP sent; in development devCode is returned when SMS_PROVIDER is not Twilio' })
  @HttpCode(HttpStatus.OK)
  requestPasswordReset(@Body() dto: SendOtpDto) {
    return this.authService.sendOtp(dto.phoneNumber);
  }

  @Post('password-reset/confirm')
  @Throttle({ default: { ttl: 60_000, limit: 10 } })
  @ApiOperation({ summary: 'Confirm password reset with OTP and new password' })
  @ApiOkResponse({ description: 'Password reset successful; all sessions invalidated' })
  @HttpCode(HttpStatus.OK)
  confirmPasswordReset(@Body() dto: ResetPasswordConfirmDto): Promise<{ message: string }> {
    return this.authService.confirmPasswordReset(dto);
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
    await this.authService.changePassword(user.userId, dto);
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get authenticated user profile' })
  @ApiOkResponse({ description: 'Authenticated user profile' })
  me(@CurrentUser() user?: AuthenticatedUser) {
    if (!user) {
      throw new UnauthorizedException({
        code: 'UNAUTHORIZED',
        message: 'Authentication required',
      });
    }

    return this.authService.me(user);
  }

  @Patch('me')
  @UseGuards(JwtAuthGuard)
  @Throttle({ default: { ttl: 60_000, limit: 10 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update authenticated user profile (name only)' })
  @ApiOkResponse({ description: 'Profile updated' })
  updateProfile(
    @CurrentUser() user: AuthenticatedUser | undefined,
    @Body() dto: UpdateProfileDto,
  ) {
    if (!user) {
      throw new UnauthorizedException({
        code: 'UNAUTHORIZED',
        message: 'Authentication required',
      });
    }
    return this.authService.updateProfile(user.userId, dto);
  }

  @Delete('me')
  @UseGuards(JwtAuthGuard)
  @Throttle({ default: { ttl: 60_000, limit: 3 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Delete account (soft delete)' })
  @ApiNoContentResponse({ description: 'Account deleted' })
  @HttpCode(HttpStatus.NO_CONTENT)
  async deleteAccount(@CurrentUser() user?: AuthenticatedUser): Promise<void> {
    if (!user) {
      throw new UnauthorizedException({
        code: 'UNAUTHORIZED',
        message: 'Authentication required',
      });
    }
    await this.authService.deleteAccount(user.userId);
  }

  @Get('admin/ping')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Admin-only authorization check endpoint' })
  @ApiOkResponse({ description: 'Admin role validated' })
  adminPing() {
    return { message: 'Admin access granted' };
  }
}
