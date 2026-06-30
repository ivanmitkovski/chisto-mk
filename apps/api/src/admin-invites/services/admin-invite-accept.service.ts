import {
  BadRequestException,
  ConflictException,
  Inject,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { generateSecret, generateURI, verify as verifyTotp } from 'otplib';
import { AdminInviteStatus, Prisma, Role, UserStatus } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditService } from '../../audit/services/audit.service';
import { AuthSessionService } from '../../auth/services/auth-session.service';
import { AUTH_ENV_RUNTIME, type AuthEnvRuntime } from '../../auth/constants/auth-env.config';
import {
  ADMIN_INVITE_MAX_ATTEMPTS,
  MFA_BACKUP_CODE_LENGTH,
  MFA_BACKUP_CODES_COUNT,
} from '../../auth/constants/auth.constants';
import type { AuthResponse } from '../../auth/types/auth-response.type';
import { AcceptAdminInviteDto } from '../dto/accept-admin-invite.dto';
import { BeginInviteMfaDto } from '../dto/begin-invite-mfa.dto';
import { ValidateAdminInviteQueryDto } from '../dto/validate-admin-invite-query.dto';

type VerifiedInvite = {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  role: Role;
  status: AdminInviteStatus;
  expiresAt: Date;
  mfaSecret: string | null;
  tokenHash: string;
  attemptCount: number;
};

@Injectable()
export class AdminInviteAcceptService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly sessionService: AuthSessionService,
    @Inject(AUTH_ENV_RUNTIME) private readonly env: AuthEnvRuntime,
  ) {}

  async validate(query: ValidateAdminInviteQueryDto): Promise<{
    id: string;
    email: string;
    firstName: string;
    lastName: string;
    role: Role;
    expiresAt: string;
  }> {
    const invite = await this.verifyInviteToken(query.id, query.token, { incrementAttempts: false });
    return {
      id: invite.id,
      email: invite.email,
      firstName: invite.firstName,
      lastName: invite.lastName,
      role: invite.role,
      expiresAt: invite.expiresAt.toISOString(),
    };
  }

  async beginMfa(dto: BeginInviteMfaDto): Promise<{ uri: string; secret: string }> {
    const invite = await this.verifyInviteToken(dto.id, dto.token, { incrementAttempts: true });

    const secret = generateSecret();
    const uri = generateURI({
      secret,
      issuer: 'Chisto.mk Admin',
      label: invite.email,
    });

    await this.prisma.adminInvite.update({
      where: { id: invite.id },
      data: { mfaSecret: secret, attemptCount: 0 },
    });

    return { uri, secret };
  }

  async accept(dto: AcceptAdminInviteDto): Promise<AuthResponse & { backupCodes: string[] }> {
    const invite = await this.verifyInviteToken(dto.id, dto.token, { incrementAttempts: true });

    const totpCode = dto.totpCode?.trim() ?? '';
    const enrollMfa = totpCode.length > 0;

    if (enrollMfa) {
      if (!invite.mfaSecret) {
        throw new BadRequestException({
          code: 'MFA_SETUP_REQUIRED',
          message: 'Complete two-factor setup before accepting the invite.',
        });
      }

      const totpResult = await verifyTotp({
        token: totpCode,
        secret: invite.mfaSecret,
        epochTolerance: 1,
      });
      if (!totpResult.valid) {
        await this.incrementAttemptCount(invite.id);
        throw new UnauthorizedException({
          code: 'INVALID_TOTP_CODE',
          message: 'Invalid code. Please try again.',
        });
      }
    }

    const email = invite.email.toLowerCase().trim();
    const phoneNumber = dto.phoneNumber.trim();
    const passwordHash = await bcrypt.hash(dto.password, this.env.saltRounds);
    const backupCodes = enrollMfa ? this.generateBackupCodes() : [];
    const hashedBackupCodes = enrollMfa
      ? await Promise.all(backupCodes.map((code) => bcrypt.hash(code, this.env.saltRounds)))
      : [];

    const existingEmail = await this.prisma.user.findUnique({
      where: { email },
      select: { id: true, status: true },
    });
    if (existingEmail && existingEmail.status !== UserStatus.DELETED) {
      throw new ConflictException({
        code: 'EMAIL_ALREADY_REGISTERED',
        message: 'A user with this email already exists.',
      });
    }

    const existingPhone = await this.prisma.user.findUnique({
      where: { phoneNumber },
      select: { id: true },
    });
    if (existingPhone) {
      throw new ConflictException({
        code: 'PHONE_NUMBER_IN_USE',
        message: 'Another user already has this phone number.',
      });
    }

    const user = await this.prisma.$transaction(async (tx) => {
      const freshInvite = await tx.adminInvite.findUnique({ where: { id: invite.id } });
      if (!freshInvite || freshInvite.status !== AdminInviteStatus.PENDING) {
        throw new BadRequestException({
          code: 'INVITE_NOT_PENDING',
          message: 'This invite is no longer valid.',
        });
      }

      const created = await tx.user.create({
        data: {
          firstName: invite.firstName,
          lastName: invite.lastName,
          email,
          phoneNumber,
          passwordHash,
          role: invite.role,
          status: UserStatus.ACTIVE,
          isPhoneVerified: false,
          totpSecret: enrollMfa ? invite.mfaSecret : null,
          mfaBackupCodes: hashedBackupCodes,
        },
      });

      await tx.adminInvite.update({
        where: { id: invite.id },
        data: {
          status: AdminInviteStatus.ACCEPTED,
          acceptedAt: new Date(),
          acceptedUserId: created.id,
          mfaSecret: null,
          attemptCount: 0,
        },
      });

      return created;
    });

    await this.audit.log({
      actorId: user.id,
      action: 'ADMIN_INVITE_ACCEPTED',
      resourceType: 'AdminInvite',
      resourceId: invite.id,
      metadata: { email, role: invite.role, mfaEnrolled: enrollMfa } as Prisma.InputJsonValue,
    });

    const auth = await this.sessionService.buildAuthResponse(user, true, {
      deviceId: dto.deviceId,
    });
    return { ...auth, backupCodes };
  }

  private async verifyInviteToken(
    id: string,
    token: string,
    options: { incrementAttempts: boolean },
  ): Promise<VerifiedInvite> {
    const invite = await this.prisma.adminInvite.findUnique({ where: { id } });
    if (!invite) {
      throw new UnauthorizedException({
        code: 'INVALID_INVITE',
        message: 'Invite link is invalid or expired.',
      });
    }

    if (invite.status === AdminInviteStatus.REVOKED) {
      throw new UnauthorizedException({
        code: 'INVITE_REVOKED',
        message: 'This invite was revoked.',
      });
    }
    if (invite.status === AdminInviteStatus.ACCEPTED) {
      throw new UnauthorizedException({
        code: 'INVITE_ALREADY_ACCEPTED',
        message: 'This invite has already been used.',
      });
    }
    if (invite.status !== AdminInviteStatus.PENDING || invite.expiresAt <= new Date()) {
      if (invite.status === AdminInviteStatus.PENDING && invite.expiresAt <= new Date()) {
        await this.prisma.adminInvite.update({
          where: { id },
          data: { status: AdminInviteStatus.EXPIRED },
        });
      }
      throw new UnauthorizedException({
        code: 'INVITE_EXPIRED',
        message: 'Invite link is invalid or expired.',
      });
    }

    if (invite.attemptCount >= ADMIN_INVITE_MAX_ATTEMPTS) {
      throw new UnauthorizedException({
        code: 'INVITE_LOCKED',
        message: 'Too many failed attempts. Ask a super admin to resend the invite.',
      });
    }

    const tokenOk = await bcrypt.compare(token, invite.tokenHash);
    if (!tokenOk) {
      if (options.incrementAttempts) {
        await this.incrementAttemptCount(invite.id);
      }
      throw new UnauthorizedException({
        code: 'INVALID_INVITE',
        message: 'Invite link is invalid or expired.',
      });
    }

    await this.prisma.adminInvite.update({
      where: { id: invite.id },
      data: { attemptCount: 0 },
    });

    return invite;
  }

  private async incrementAttemptCount(id: string): Promise<void> {
    await this.prisma.adminInvite.update({
      where: { id },
      data: { attemptCount: { increment: 1 } },
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
