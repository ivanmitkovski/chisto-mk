import { Body, Controller, Delete, Get, HttpCode, HttpStatus, Patch, Post, UnauthorizedException, UseGuards, UseInterceptors, UploadedFiles } from '@nestjs/common';
import { FilesInterceptor } from '@nestjs/platform-express';
import * as multer from 'multer';
import {
  ApiBearerAuth,
  ApiCreatedResponse,
  ApiNoContentResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { ADMIN_PANEL_ROLES } from './admin-roles';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import { AuthService } from './auth.service';
import { CurrentUser } from './current-user.decorator';
import { AdminLoginDto } from './dto/admin-login.dto';
import { ChangePasswordDto } from './dto/change-password.dto';
import { Complete2FALoginDto } from './dto/complete-2fa-login.dto';
import { Disable2FADto } from './dto/disable-2fa.dto';
import { Enable2FADto } from './dto/enable-2fa.dto';
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
    description: 'Admin authenticated and tokens issued, or requiresTotp + tempToken when 2FA enabled',
  })
  @HttpCode(HttpStatus.OK)
  adminLogin(@Body() dto: AdminLoginDto) {
    return this.authService.adminLogin(dto);
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
    return this.authService.completeAdmin2FALogin(dto.tempToken, dto.code);
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
    return this.authService.setupMfa(user.userId);
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
    return this.authService.enableMfa(user.userId, dto);
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
    await this.authService.disableMfa(user.userId, dto);
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

  @Post(['me/avatar', 'avatar'])
  @UseGuards(JwtAuthGuard)
  @Throttle({ default: { ttl: 60_000, limit: 10 } })
  @ApiBearerAuth()
  @UseInterceptors(
    FilesInterceptor('files', 1, {
      storage: multer.memoryStorage(),
      limits: { fileSize: 8 * 1024 * 1024 },
    }),
  )
  @ApiOperation({
    summary:
      'Upload or replace profile avatar (canonical: POST /auth/me/avatar; alias: POST /auth/avatar)',
  })
  @ApiOkResponse({ description: 'Avatar uploaded successfully' })
  uploadAvatar(
    @CurrentUser() user: AuthenticatedUser | undefined,
    @UploadedFiles() files: Express.Multer.File[],
  ): Promise<{ avatarUrl: string | null }> {
    if (!user) {
      throw new UnauthorizedException({
        code: 'UNAUTHORIZED',
        message: 'Authentication required',
      });
    }
    return this.authService.uploadAvatar(user.userId, files?.[0]);
  }

  @Delete(['me/avatar', 'avatar'])
  @UseGuards(JwtAuthGuard)
  @Throttle({ default: { ttl: 60_000, limit: 10 } })
  @ApiBearerAuth()
  @ApiOperation({
    summary:
      'Remove profile avatar (canonical: DELETE /auth/me/avatar; alias: DELETE /auth/avatar)',
  })
  @ApiNoContentResponse({ description: 'Avatar removed' })
  @HttpCode(HttpStatus.NO_CONTENT)
  async removeAvatar(
    @CurrentUser() user: AuthenticatedUser | undefined,
  ): Promise<void> {
    if (!user) {
      throw new UnauthorizedException({
        code: 'UNAUTHORIZED',
        message: 'Authentication required',
      });
    }
    await this.authService.removeAvatar(user.userId);
  }

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
