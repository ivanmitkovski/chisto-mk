import {
  BadRequestException,
  Inject,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { generateSecret, generateURI, verify as verifyTotp } from 'otplib';
import { PrismaService } from '../prisma/prisma.service';
import { Disable2FADto } from './dto/disable-2fa.dto';
import { Enable2FADto } from './dto/enable-2fa.dto';
import { AuditService } from '../audit/audit.service';
import {
  MFA_BACKUP_CODE_LENGTH,
  MFA_BACKUP_CODES_COUNT,
  PENDING_MFA_EXPIRES_SECONDS,
} from './auth.constants';
import { AUTH_ENV_RUNTIME, type AuthEnvRuntime } from './auth-env.config';

@Injectable()
export class AuthMfaService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    @Inject(AUTH_ENV_RUNTIME) private readonly env: AuthEnvRuntime,
  ) {}

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
      backupCodes.map((code) => bcrypt.hash(code, this.env.saltRounds)),
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
}
