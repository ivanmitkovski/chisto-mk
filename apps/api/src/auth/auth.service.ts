import {
  BadRequestException,
  ConflictException,
  Inject,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { JwtService } from '@nestjs/jwt';
import { Role, User, UserStatus } from '../prisma-client';
import * as bcrypt from 'bcrypt';
import { randomBytes } from 'crypto';
import { generateSecret, generateURI, verify as verifyTotp } from 'otplib';
import { OTP_SENDER, OtpSender } from '../otp/otp-sender.interface';
import { OtpService } from '../otp/otp.service';
import { PrismaService } from '../prisma/prisma.service';
import { AdminLoginDto } from './dto/admin-login.dto';
import { Disable2FADto } from './dto/disable-2fa.dto';
import { Enable2FADto } from './dto/enable-2fa.dto';
import { ChangePasswordDto } from './dto/change-password.dto';
import { CitizenLoginDto } from './dto/citizen-login.dto';
import { RegisterDto } from './dto/register.dto';
import { ResetPasswordConfirmDto } from './dto/reset-password-confirm.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import {
  AdminLoginResponse,
  AuthResponse,
} from './types/auth-response.type';
import { AuthenticatedUser } from './types/authenticated-user.type';
import { AuditService } from '../audit/audit.service';
import { ReportsUploadService } from '../reports/reports-upload.service';

const OTP_EXPIRES_SECONDS = 600;
const LOGIN_MAX_ATTEMPTS = 5;
const LOGIN_LOCKOUT_WINDOW_MINUTES = 15;
const REMEMBER_ME_SHORT_DAYS = 1;
const ADMIN_TEMP_TOKEN_EXPIRES_SECONDS = 5 * 60; // 5 minutes
const PENDING_MFA_EXPIRES_SECONDS = 5 * 60; // 5 minutes
const MFA_BACKUP_CODES_COUNT = 8;
const MFA_BACKUP_CODE_LENGTH = 10;

type PrismaWithLoginFailure = PrismaService & {
  loginFailure: {
    findUnique: (args: { where: { phoneNumber: string } }) => Promise<{ attemptCount: number; firstFailedAt: Date } | null>;
    deleteMany: (args: { where: { phoneNumber: string } }) => Promise<unknown>;
    create: (args: { data: { phoneNumber: string; firstFailedAt: Date; attemptCount: number } }) => Promise<unknown>;
    update: (args: { where: { phoneNumber: string }; data: { firstFailedAt?: Date; attemptCount: number } }) => Promise<unknown>;
  };
};

@Injectable()
export class AuthService {
  private readonly saltRounds = 12;
  private readonly accessTokenTtl: number;
  private readonly refreshTokenTtlDays: number;
  private readonly maxSessionsPerUser: number;
  private readonly shouldReturnDevCode: boolean;

  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    private readonly otpService: OtpService,
    configService: ConfigService,
    @Inject(OTP_SENDER) private readonly otpSender: OtpSender,
    private readonly audit: AuditService,
    private readonly eventEmitter: EventEmitter2,
    private readonly reportsUploadService: ReportsUploadService,
  ) {
    const isProduction = configService.get<string>('NODE_ENV') === 'production';
    const smsProvider = configService.get<string>('SMS_PROVIDER')?.toLowerCase() ?? 'none';
    this.shouldReturnDevCode = !isProduction && smsProvider !== 'twilio';
    const accessRaw = configService.get<string>('JWT_ACCESS_EXPIRES_IN');
    this.accessTokenTtl = accessRaw ? Number(accessRaw) : 900;
    const refreshRaw = configService.get<string>('JWT_REFRESH_EXPIRES_DAYS');
    this.refreshTokenTtlDays = refreshRaw ? Number(refreshRaw) : 7;
    const maxSessionsRaw = configService.get<string>('MAX_SESSIONS_PER_USER');
    this.maxSessionsPerUser = maxSessionsRaw ? Number(maxSessionsRaw) : 5;
  }

  async register(dto: RegisterDto): Promise<AuthResponse> {
    const firstName = dto.firstName.trim();
    const lastName = dto.lastName.trim();
    const email = dto.email.toLowerCase().trim();
    const phoneNumber = dto.phoneNumber.trim();

    const existingUser = await this.prisma.user.findFirst({
      where: {
        OR: [{ email }, { phoneNumber }],
      },
      select: { id: true, email: true, phoneNumber: true },
    });

    if (existingUser) {
      if (existingUser.email === email) {
        throw new ConflictException({
          code: 'EMAIL_ALREADY_REGISTERED',
          message: 'Email is already registered',
        });
      }
      throw new ConflictException({
        code: 'PHONE_ALREADY_REGISTERED',
        message: 'Phone number is already registered',
      });
    }

    const passwordHash = await bcrypt.hash(dto.password, this.saltRounds);
    const user = await this.prisma.user.create({
      data: {
        firstName,
        lastName,
        email,
        phoneNumber,
        passwordHash,
        role: Role.USER,
      },
    });

    this.eventEmitter.emit('user.created', { userId: user.id });
    return this.buildAuthResponse(user, true);
  }

  async citizenLogin(dto: CitizenLoginDto): Promise<AuthResponse> {
    const phoneNumber = dto.phoneNumber.trim();
    const db = this.prisma as PrismaWithLoginFailure;
    const failure = await db.loginFailure.findUnique({
      where: { phoneNumber },
    });
    const now = new Date();
    const windowMs = LOGIN_LOCKOUT_WINDOW_MINUTES * 60 * 1000;
    if (
      failure &&
      failure.attemptCount >= LOGIN_MAX_ATTEMPTS &&
      failure.firstFailedAt.getTime() > now.getTime() - windowMs
    ) {
      const unlockAt = new Date(failure.firstFailedAt.getTime() + windowMs);
      const retryAfterSeconds = Math.max(0, Math.ceil((unlockAt.getTime() - now.getTime()) / 1000));
      throw new UnauthorizedException({
        code: 'TOO_MANY_ATTEMPTS',
        message: 'Too many failed attempts. Try again later.',
        retryable: true,
        retryAfterSeconds,
      });
    }

    const user = await this.prisma.user.findUnique({
      where: { phoneNumber },
    });

    if (!user) {
      await this.recordLoginFailure(phoneNumber);
      throw new UnauthorizedException({
        code: 'INVALID_CREDENTIALS',
        message: 'Invalid phone number or password',
      });
    }

    if (user.status !== UserStatus.ACTIVE) {
      throw new UnauthorizedException({
        code: 'ACCOUNT_SUSPENDED',
        message: 'Account is not active',
      });
    }

    const isPasswordValid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!isPasswordValid) {
      await this.recordLoginFailure(phoneNumber);
      throw new UnauthorizedException({
        code: 'INVALID_CREDENTIALS',
        message: 'Invalid phone number or password',
      });
    }

    await db.loginFailure.deleteMany({ where: { phoneNumber } }).catch(() => {});

    return this.buildAuthResponse(user, dto.rememberMe ?? true);
  }

  private async recordLoginFailure(phoneNumber: string): Promise<void> {
    const db = this.prisma as PrismaWithLoginFailure;
    const now = new Date();
    const existing = await db.loginFailure.findUnique({
      where: { phoneNumber },
    });
    const windowMs = LOGIN_LOCKOUT_WINDOW_MINUTES * 60 * 1000;
    if (existing && existing.firstFailedAt.getTime() < now.getTime() - windowMs) {
      await db.loginFailure.update({
        where: { phoneNumber },
        data: { firstFailedAt: now, attemptCount: 1 },
      });
    } else if (existing) {
      await db.loginFailure.update({
        where: { phoneNumber },
        data: { attemptCount: existing.attemptCount + 1 },
      });
    } else {
      await db.loginFailure.create({
        data: { phoneNumber, firstFailedAt: now, attemptCount: 1 },
      });
    }
  }

  async adminLogin(dto: AdminLoginDto): Promise<AdminLoginResponse> {
    const email = dto.email.toLowerCase().trim();

    const failure = await this.prisma.adminLoginFailure.findUnique({
      where: { email },
    });
    const now = new Date();
    const windowMs = LOGIN_LOCKOUT_WINDOW_MINUTES * 60 * 1000;
    if (
      failure &&
      failure.attemptCount >= LOGIN_MAX_ATTEMPTS &&
      failure.firstFailedAt.getTime() > now.getTime() - windowMs
    ) {
      const unlockAt = new Date(failure.firstFailedAt.getTime() + windowMs);
      const retryAfterSeconds = Math.max(
        0,
        Math.ceil((unlockAt.getTime() - now.getTime()) / 1000),
      );
      throw new UnauthorizedException({
        code: 'TOO_MANY_ATTEMPTS',
        message: 'Too many failed attempts. Try again later.',
        details: { retryAfterSeconds },
      });
    }

    const user = await this.prisma.user.findUnique({
      where: { email },
    });

    if (!user) {
      await this.recordAdminLoginFailure(email);
      throw new UnauthorizedException({
        code: 'INVALID_CREDENTIALS',
        message: 'Invalid email or password',
      });
    }

    const isPasswordValid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!isPasswordValid) {
      await this.recordAdminLoginFailure(email);
      throw new UnauthorizedException({
        code: 'INVALID_CREDENTIALS',
        message: 'Invalid email or password',
      });
    }

    if (user.role !== Role.ADMIN && user.role !== Role.SUPER_ADMIN && user.role !== Role.SUPPORT) {
      throw new UnauthorizedException({
        code: 'ADMIN_ACCESS_REQUIRED',
        message: 'Admin role is required to access the admin console',
      });
    }

    if (user.status !== UserStatus.ACTIVE) {
      throw new UnauthorizedException({
        code: 'ACCOUNT_NOT_ACTIVE',
        message: 'Account is not active',
      });
    }

    await this.prisma.adminLoginFailure.deleteMany({ where: { email } }).catch(() => {});

    if (user.totpSecret) {
      const tempToken = randomBytes(24).toString('hex');
      const tokenHash = await bcrypt.hash(tempToken, this.saltRounds);
      const expiresAt = new Date();
      expiresAt.setSeconds(expiresAt.getSeconds() + ADMIN_TEMP_TOKEN_EXPIRES_SECONDS);

      await this.prisma.adminTempToken.create({
        data: {
          tokenHash,
          userId: user.id,
          email: user.email,
          expiresAt,
        },
      });

      return {
        requiresTotp: true,
        tempToken,
        expiresIn: ADMIN_TEMP_TOKEN_EXPIRES_SECONDS,
      };
    }

    await this.audit.log({
      actorId: user.id,
      action: 'ADMIN_LOGIN',
      resourceType: 'User',
      resourceId: user.id,
      metadata: { email: user.email },
    });

    return this.buildAuthResponse(user, true);
  }

  private async recordAdminLoginFailure(email: string): Promise<void> {
    const now = new Date();
    const existing = await this.prisma.adminLoginFailure.findUnique({
      where: { email },
    });
    const windowMs = LOGIN_LOCKOUT_WINDOW_MINUTES * 60 * 1000;
    if (existing && existing.firstFailedAt.getTime() < now.getTime() - windowMs) {
      await this.prisma.adminLoginFailure.update({
        where: { email },
        data: { firstFailedAt: now, attemptCount: 1 },
      });
    } else if (existing) {
      await this.prisma.adminLoginFailure.update({
        where: { email },
        data: { attemptCount: existing.attemptCount + 1 },
      });
    } else {
      await this.prisma.adminLoginFailure.create({
        data: { email, firstFailedAt: now, attemptCount: 1 },
      });
    }
  }

  async completeAdmin2FALogin(
    tempToken: string,
    code: string,
  ): Promise<AuthResponse> {
    const candidates = await this.prisma.adminTempToken.findMany({
      where: { expiresAt: { gt: new Date() } },
    });

    let matched: (typeof candidates)[number] | null = null;
    for (const c of candidates) {
      if (await bcrypt.compare(tempToken, c.tokenHash)) {
        matched = c;
        break;
      }
    }

    if (!matched) {
      throw new UnauthorizedException({
        code: 'INVALID_TEMP_TOKEN',
        message: 'Verification session expired. Please sign in again.',
      });
    }

    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: matched.userId },
    });
    if (user.status !== UserStatus.ACTIVE) {
      await this.prisma.adminTempToken.delete({ where: { id: matched.id } }).catch(() => {});
      throw new UnauthorizedException({
        code: 'ACCOUNT_NOT_ACTIVE',
        message: 'Account is not active',
      });
    }

    const trimmedCode = code.trim();
    const is6Digits = /^\d{6}$/.test(trimmedCode);
    let valid = false;

    if (is6Digits && user.totpSecret) {
      const result = await verifyTotp({
        token: trimmedCode,
        secret: user.totpSecret,
        epochTolerance: 1,
      });
      valid = result.valid;
    }

    if (!valid && user.mfaBackupCodes?.length) {
      for (let i = 0; i < user.mfaBackupCodes.length; i++) {
        if (await bcrypt.compare(trimmedCode, user.mfaBackupCodes[i])) {
          valid = true;
          const updated = [...user.mfaBackupCodes];
          updated.splice(i, 1);
          await this.prisma.user.update({
            where: { id: user.id },
            data: { mfaBackupCodes: updated },
          });
          break;
        }
      }
    }

    if (!valid) {
      throw new UnauthorizedException({
        code: 'INVALID_TOTP_CODE',
        message: 'Invalid verification code. Please try again.',
      });
    }

    await this.prisma.adminTempToken.delete({ where: { id: matched.id } }).catch(() => {});

    await this.audit.log({
      actorId: user.id,
      action: 'ADMIN_LOGIN',
      resourceType: 'User',
      resourceId: user.id,
      metadata: { email: user.email, mfa: true },
    });

    return this.buildAuthResponse(user, true);
  }

  async refresh(rawRefreshToken: string): Promise<AuthResponse> {
    const tokenId = this.parseTokenIdFromRefreshToken(rawRefreshToken);
    if (!tokenId) {
      throw new UnauthorizedException({
        code: 'INVALID_REFRESH_TOKEN',
        message: 'Refresh token is invalid or expired',
      });
    }

    const session = await this.prisma.userSession.findUnique({
      where: { tokenId },
      include: { user: true },
    });

    if (
      !session ||
      session.revokedAt != null ||
      session.expiresAt <= new Date() ||
      !(await bcrypt.compare(rawRefreshToken, session.refreshTokenHash))
    ) {
      throw new UnauthorizedException({
        code: 'INVALID_REFRESH_TOKEN',
        message: 'Refresh token is invalid or expired',
      });
    }

    await this.prisma.userSession.update({
      where: { id: session.id },
      data: { revokedAt: new Date() },
    });

    const { user } = session;
    if (user.status !== UserStatus.ACTIVE) {
      throw new UnauthorizedException({
        code: 'ACCOUNT_SUSPENDED',
        message: 'Account is not active',
      });
    }

    return this.buildAuthResponse(user, true);
  }

  private parseTokenIdFromRefreshToken(fullToken: string): string | null {
    const dotIndex = fullToken.indexOf('.');
    if (dotIndex <= 0 || dotIndex === fullToken.length - 1) return null;
    return fullToken.slice(0, dotIndex);
  }

  async logout(rawRefreshToken: string): Promise<void> {
    const tokenId = this.parseTokenIdFromRefreshToken(rawRefreshToken);
    if (!tokenId) return;

    const session = await this.prisma.userSession.findUnique({
      where: { tokenId },
    });
    if (
      !session ||
      session.revokedAt != null ||
      session.expiresAt <= new Date() ||
      !(await bcrypt.compare(rawRefreshToken, session.refreshTokenHash))
    ) {
      return;
    }
    await this.prisma.userSession.update({
      where: { id: session.id },
      data: { revokedAt: new Date() },
    });
  }

  async me(authenticatedUser: AuthenticatedUser): Promise<{
    id: string;
    firstName: string;
    lastName: string;
    email: string;
    phoneNumber: string;
    role: Role;
    status: UserStatus;
    isPhoneVerified: boolean;
    pointsBalance: number;
    totalPointsEarned: number;
    totalPointsSpent: number;
    mfaEnabled: boolean;
    avatarUrl: string | null;
  }> {
    const user = await this.prisma.user.findUnique({
      where: { id: authenticatedUser.userId },
      select: {
        id: true,
        firstName: true,
        lastName: true,
        email: true,
        phoneNumber: true,
        role: true,
        status: true,
        isPhoneVerified: true,
        pointsBalance: true,
        totalPointsEarned: true,
        totalPointsSpent: true,
        totpSecret: true,
        avatarObjectKey: true,
      },
    });

    if (!user) {
      throw new UnauthorizedException({
        code: 'INVALID_TOKEN_USER',
        message: 'User for token was not found',
      });
    }

    const avatarUrl = await this.reportsUploadService.signPrivateObjectKey(user.avatarObjectKey);
    const { totpSecret: _, avatarObjectKey: __, ...rest } = user;
    return { ...rest, mfaEnabled: !!user.totpSecret, avatarUrl };
  }

  async setupMfa(userId: string): Promise<{ uri: string; secret: string }> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, email: true, totpSecret: true },
    });

    if (!user) {
      throw new UnauthorizedException({
        code: 'INVALID_TOKEN_USER',
        message: 'User not found',
      });
    }

    if (user.totpSecret) {
      throw new BadRequestException({
        code: 'MFA_ALREADY_ENABLED',
        message: 'Two-factor authentication is already enabled.',
      });
    }

    const secret = generateSecret();
    const uri = generateURI({
      secret,
      issuer: 'Chisto.mk',
      label: user.email,
    });

    const expiresAt = new Date();
    expiresAt.setSeconds(expiresAt.getSeconds() + PENDING_MFA_EXPIRES_SECONDS);

    await this.prisma.adminPendingMfa.upsert({
      where: { userId },
      create: { userId, secret, expiresAt },
      update: { secret, expiresAt },
    });

    return { uri, secret };
  }

  async enableMfa(userId: string, dto: Enable2FADto): Promise<{ backupCodes: string[] }> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true },
    });

    if (!user) {
      throw new UnauthorizedException({
        code: 'INVALID_TOKEN_USER',
        message: 'User not found',
      });
    }

    const pending = await this.prisma.adminPendingMfa.findUnique({
      where: { userId },
    });

    if (!pending || pending.expiresAt <= new Date()) {
      throw new BadRequestException({
        code: 'MFA_SETUP_EXPIRED',
        message: 'Setup session expired. Please start again.',
      });
    }

    const result = await verifyTotp({
      token: dto.code.trim(),
      secret: pending.secret,
      epochTolerance: 1,
    });

    if (!result.valid) {
      throw new UnauthorizedException({
        code: 'INVALID_TOTP_CODE',
        message: 'Invalid code. Please try again.',
      });
    }

    const backupCodes = this.generateBackupCodes();
    const hashedBackupCodes = await Promise.all(
      backupCodes.map((code) => bcrypt.hash(code, this.saltRounds)),
    );

    await this.prisma.$transaction([
      this.prisma.user.update({
        where: { id: userId },
        data: {
          totpSecret: pending.secret,
          mfaBackupCodes: hashedBackupCodes,
        },
      }),
      this.prisma.adminPendingMfa.delete({ where: { userId } }),
    ]);

    await this.audit.log({
      actorId: userId,
      action: 'MFA_ENABLED',
      resourceType: 'User',
      resourceId: userId,
      metadata: {},
    });

    return { backupCodes };
  }

  private generateBackupCodes(): string[] {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    const codes: string[] = [];
    for (let i = 0; i < MFA_BACKUP_CODES_COUNT; i++) {
      let code = '';
      for (let j = 0; j < MFA_BACKUP_CODE_LENGTH; j++) {
        code += chars.charAt(Math.floor(Math.random() * chars.length));
      }
      codes.push(code);
    }
    return codes;
  }

  async disableMfa(userId: string, dto: Disable2FADto): Promise<void> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, passwordHash: true, totpSecret: true },
    });

    if (!user) {
      throw new UnauthorizedException({
        code: 'INVALID_TOKEN_USER',
        message: 'User not found',
      });
    }

    if (!user.totpSecret) {
      throw new BadRequestException({
        code: 'MFA_NOT_ENABLED',
        message: 'Two-factor authentication is not enabled.',
      });
    }

    const passwordValid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!passwordValid) {
      throw new UnauthorizedException({
        code: 'INVALID_PASSWORD',
        message: 'Incorrect password.',
      });
    }

    await this.prisma.user.update({
      where: { id: userId },
      data: { totpSecret: null, mfaBackupCodes: [] },
    });

    await this.prisma.adminPendingMfa.deleteMany({ where: { userId } }).catch(() => {});

    await this.audit.log({
      actorId: userId,
      action: 'MFA_DISABLED',
      resourceType: 'User',
      resourceId: userId,
      metadata: {},
    });
  }

  async updateProfile(
    userId: string,
    dto: UpdateProfileDto,
  ): Promise<{ id: string; firstName: string; lastName: string; email: string; phoneNumber: string; avatarUrl: string | null }> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, status: true },
    });
    if (!user) {
      throw new UnauthorizedException({
        code: 'INVALID_TOKEN_USER',
        message: 'User not found',
      });
    }
    if (user.status !== UserStatus.ACTIVE) {
      throw new UnauthorizedException({
        code: 'ACCOUNT_NOT_ACTIVE',
        message: 'Account is not active',
      });
    }
    const data: { firstName?: string; lastName?: string } = {};
    if (dto.firstName != null && dto.firstName.trim().length > 0) {
      data.firstName = dto.firstName.trim();
    }
    if (dto.lastName != null && dto.lastName.trim().length > 0) {
      data.lastName = dto.lastName.trim();
    }
    if (Object.keys(data).length === 0) {
      const updated = await this.prisma.user.findUnique({
        where: { id: userId },
        select: { id: true, firstName: true, lastName: true, email: true, phoneNumber: true, avatarObjectKey: true },
      });
      if (!updated) throw new UnauthorizedException({ code: 'INVALID_TOKEN_USER', message: 'User not found' });
      return {
        id: updated.id,
        firstName: updated.firstName,
        lastName: updated.lastName,
        email: updated.email,
        phoneNumber: updated.phoneNumber,
        avatarUrl: await this.reportsUploadService.signPrivateObjectKey(updated.avatarObjectKey),
      };
    }
    const updated = await this.prisma.user.update({
      where: { id: userId },
      data,
      select: { id: true, firstName: true, lastName: true, email: true, phoneNumber: true, avatarObjectKey: true },
    });
    return {
      id: updated.id,
      firstName: updated.firstName,
      lastName: updated.lastName,
      email: updated.email,
      phoneNumber: updated.phoneNumber,
      avatarUrl: await this.reportsUploadService.signPrivateObjectKey(updated.avatarObjectKey),
    };
  }

  async uploadAvatar(
    userId: string,
    file: Express.Multer.File | undefined,
  ): Promise<{ avatarUrl: string | null }> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, status: true, avatarObjectKey: true },
    });
    if (!user) {
      throw new UnauthorizedException({
        code: 'INVALID_TOKEN_USER',
        message: 'User not found',
      });
    }
    if (user.status !== UserStatus.ACTIVE) {
      throw new UnauthorizedException({
        code: 'ACCOUNT_NOT_ACTIVE',
        message: 'Account is not active',
      });
    }
    if (!file) {
      throw new BadRequestException({
        code: 'AVATAR_FILE_REQUIRED',
        message: 'Avatar image file is required.',
      });
    }
    const nextKey = await this.reportsUploadService.uploadProfileAvatar(userId, file);
    await this.prisma.user.update({
      where: { id: userId },
      data: { avatarObjectKey: nextKey, avatarUpdatedAt: new Date() },
    });
    const signedUrl = await this.reportsUploadService.signPrivateObjectKey(nextKey);
    if (user.avatarObjectKey) {
      void this.reportsUploadService.deleteObjectByKey(user.avatarObjectKey).catch(() => {});
    }
    return { avatarUrl: signedUrl };
  }

  async removeAvatar(userId: string): Promise<void> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, status: true, avatarObjectKey: true },
    });
    if (!user) {
      throw new UnauthorizedException({
        code: 'INVALID_TOKEN_USER',
        message: 'User not found',
      });
    }
    if (user.status !== UserStatus.ACTIVE) {
      throw new UnauthorizedException({
        code: 'ACCOUNT_NOT_ACTIVE',
        message: 'Account is not active',
      });
    }
    await this.prisma.user.update({
      where: { id: userId },
      data: {
        avatarObjectKey: null,
        avatarUpdatedAt: new Date(),
      },
    });
    if (user.avatarObjectKey) {
      void this.reportsUploadService.deleteObjectByKey(user.avatarObjectKey).catch(() => {});
    }
  }

  async deleteAccount(userId: string): Promise<void> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true },
    });
    if (!user) {
      throw new UnauthorizedException({
        code: 'INVALID_TOKEN_USER',
        message: 'User not found',
      });
    }
    const now = new Date();
    await this.prisma.$transaction([
      this.prisma.userSession.updateMany({
        where: { userId: user.id },
        data: { revokedAt: now },
      }),
      this.prisma.user.update({
        where: { id: userId },
        data: { status: UserStatus.DELETED },
      }),
    ]);
  }

  async sendOtp(phoneNumber: string): Promise<{ expiresIn: number; devCode?: string }> {
    const normalized = phoneNumber.trim();
    const user = await this.prisma.user.findUnique({
      where: { phoneNumber: normalized },
      select: { id: true },
    });
    if (!user) {
      throw new BadRequestException({
        code: 'PHONE_NOT_REGISTERED',
        message: 'No account found for this phone number',
      });
    }

    const code = String(Math.floor(1000 + Math.random() * 9000));
    const expiresAt = new Date(Date.now() + OTP_EXPIRES_SECONDS * 1000);

    await this.prisma.phoneOtp.upsert({
      where: { phoneNumber: normalized },
      create: { phoneNumber: normalized, code, expiresAt },
      update: { code, expiresAt, attemptCount: 0 } as Record<string, unknown>,
    });
    await this.otpSender.sendOtp(normalized, code);
    const payload: { expiresIn: number; devCode?: string } = {
      expiresIn: OTP_EXPIRES_SECONDS,
    };
    if (this.shouldReturnDevCode) {
      payload.devCode = code;
    }
    return payload;
  }

  async verifyOtp(phoneNumber: string, code: string): Promise<void> {
    const normalized = phoneNumber.trim();
    await this.otpService.verifyAndConsumeOtp(normalized, code);
    await this.prisma.user.update({
      where: { phoneNumber: normalized },
      data: { isPhoneVerified: true },
    });
  }

  async confirmPasswordReset(dto: ResetPasswordConfirmDto): Promise<{ message: string }> {
    const normalized = dto.phoneNumber.trim();
    await this.otpService.verifyAndConsumeOtp(normalized, dto.code);

    const user = await this.prisma.user.findUnique({
      where: { phoneNumber: normalized },
      select: { id: true },
    });
    if (!user) {
      throw new UnauthorizedException({
        code: 'USER_NOT_FOUND',
        message: 'User not found for this phone number',
      });
    }

    const passwordHash = await bcrypt.hash(dto.newPassword, this.saltRounds);
    const now = new Date();

    await this.prisma.$transaction([
      this.prisma.user.update({
        where: { phoneNumber: normalized },
        data: { passwordHash },
      }),
      this.prisma.userSession.updateMany({
        where: { userId: user.id, revokedAt: null },
        data: { revokedAt: now },
      }),
    ]);

    return { message: 'Password reset successful' };
  }

  async changePassword(userId: string, dto: ChangePasswordDto): Promise<void> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { passwordHash: true },
    });
    if (!user) {
      throw new UnauthorizedException({
        code: 'INVALID_TOKEN_USER',
        message: 'User not found',
      });
    }
    const currentValid = await bcrypt.compare(dto.currentPassword, user.passwordHash);
    if (!currentValid) {
      throw new UnauthorizedException({
        code: 'CURRENT_PASSWORD_INVALID',
        message: 'Current password is incorrect',
      });
    }
    const passwordHash = await bcrypt.hash(dto.newPassword, this.saltRounds);
    await this.prisma.user.update({
      where: { id: userId },
      data: { passwordHash },
    });
    await this.audit.log({
      actorId: userId,
      action: 'PASSWORD_CHANGED',
      resourceType: 'User',
      resourceId: userId,
    });
  }

  private async buildAuthResponse(user: User, rememberMe = true): Promise<AuthResponse> {
    const tokenId = randomBytes(16).toString('hex');
    const tokenSecret = randomBytes(20).toString('hex');
    const fullRefreshToken = `${tokenId}.${tokenSecret}`;
    const refreshTokenHash = await bcrypt.hash(
      fullRefreshToken,
      this.saltRounds,
    );

    const refreshDays = rememberMe ? this.refreshTokenTtlDays : REMEMBER_ME_SHORT_DAYS;
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + refreshDays);

    const activeCount = await this.prisma.userSession.count({
      where: {
        userId: user.id,
        revokedAt: null,
        expiresAt: { gt: new Date() },
      },
    });
    if (activeCount >= this.maxSessionsPerUser) {
      const toRevokeCount = activeCount - this.maxSessionsPerUser + 1;
      const toRevoke = await this.prisma.userSession.findMany({
        where: {
          userId: user.id,
          revokedAt: null,
          expiresAt: { gt: new Date() },
        },
        orderBy: { createdAt: 'asc' },
        take: toRevokeCount,
        select: { id: true },
      });
      const now = new Date();
      await Promise.all(
        toRevoke.map((s: { id: string }) =>
          this.prisma.userSession.update({
            where: { id: s.id },
            data: { revokedAt: now },
          }),
        ),
      );
    }

    const session = await this.prisma.userSession.create({
      data: {
        userId: user.id,
        tokenId,
        refreshTokenHash,
        expiresAt,
      },
    });

    const accessToken = this.jwtService.sign(
      {
        sub: user.id,
        email: user.email,
        phoneNumber: user.phoneNumber,
        role: user.role,
        sid: session.id,
      },
      { expiresIn: this.accessTokenTtl },
    );

    return {
      accessToken,
      refreshToken: fullRefreshToken,
      user: {
        id: user.id,
        firstName: user.firstName,
        lastName: user.lastName,
        email: user.email,
        phoneNumber: user.phoneNumber,
        role: user.role,
        status: user.status,
        isPhoneVerified: user.isPhoneVerified,
        pointsBalance: user.pointsBalance,
      },
    };
  }
}
