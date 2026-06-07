import {
  BadRequestException,
  ConflictException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { randomBytes } from 'crypto';
import * as bcrypt from 'bcrypt';
import { AdminInviteStatus, Prisma, Role } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import { EmailService } from '../../email/services/email.service';
import { AuditService } from '../../audit/services/audit.service';
import type { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import {
  ADMIN_INVITE_TOKEN_BYTES,
  DEFAULT_ADMIN_INVITE_TTL_HOURS,
} from '../../auth/constants/auth.constants';
import { AUTH_ENV_RUNTIME, type AuthEnvRuntime } from '../../auth/constants/auth-env.config';
import { CreateAdminInviteDto } from '../dto/create-admin-invite.dto';

const STAFF_ROLES: Role[] = [Role.SUPPORT, Role.ADMIN, Role.SUPER_ADMIN];

function roleLabel(role: Role): string {
  switch (role) {
    case Role.SUPPORT:
      return 'Moderator';
    case Role.ADMIN:
      return 'Admin';
    case Role.SUPER_ADMIN:
      return 'Super admin';
    default:
      return role;
  }
}

@Injectable()
export class AdminInvitesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
    private readonly email: EmailService,
    private readonly audit: AuditService,
    @Inject(AUTH_ENV_RUNTIME) private readonly env: AuthEnvRuntime,
  ) {}

  async list(): Promise<
    Array<{
      id: string;
      email: string;
      firstName: string;
      lastName: string;
      role: Role;
      status: AdminInviteStatus;
      expiresAt: string;
      createdAt: string;
      invitedBy: { id: string; email: string; firstName: string; lastName: string };
      acceptedAt: string | null;
      revokedAt: string | null;
    }>
  > {
    const rows = await this.prisma.adminInvite.findMany({
      orderBy: { createdAt: 'desc' },
      include: {
        invitedBy: {
          select: { id: true, email: true, firstName: true, lastName: true },
        },
      },
    });

    return rows.map((row) => ({
      id: row.id,
      email: row.email,
      firstName: row.firstName,
      lastName: row.lastName,
      role: row.role,
      status: row.status,
      expiresAt: row.expiresAt.toISOString(),
      createdAt: row.createdAt.toISOString(),
      invitedBy: row.invitedBy,
      acceptedAt: row.acceptedAt?.toISOString() ?? null,
      revokedAt: row.revokedAt?.toISOString() ?? null,
    }));
  }

  async create(dto: CreateAdminInviteDto, actor: AuthenticatedUser) {
    if (!STAFF_ROLES.includes(dto.role)) {
      throw new BadRequestException({
        code: 'INVALID_INVITE_ROLE',
        message: 'Invite role must be moderator, admin, or super admin.',
      });
    }

    const email = dto.email.toLowerCase().trim();
    const firstName = dto.firstName.trim();
    const lastName = dto.lastName.trim();

    const existingUser = await this.prisma.user.findUnique({
      where: { email },
      select: { id: true, status: true },
    });
    if (existingUser && existingUser.status !== 'DELETED') {
      throw new ConflictException({
        code: 'EMAIL_ALREADY_REGISTERED',
        message: 'A user with this email already exists.',
      });
    }

    const pendingInvite = await this.prisma.adminInvite.findFirst({
      where: { email, status: AdminInviteStatus.PENDING },
      orderBy: { createdAt: 'desc' },
    });
    if (pendingInvite) {
      return this.resend(pendingInvite.id, actor);
    }

    const { token, tokenHash, expiresAt } = await this.generateInviteToken();
    const invite = await this.prisma.adminInvite.create({
      data: {
        email,
        firstName,
        lastName,
        role: dto.role,
        tokenHash,
        invitedById: actor.userId,
        expiresAt,
      },
      include: {
        invitedBy: {
          select: { id: true, email: true, firstName: true, lastName: true },
        },
      },
    });

    await this.sendInviteEmail(invite, token);

    await this.audit.log({
      actorId: actor.userId,
      action: 'ADMIN_INVITE_CREATED',
      resourceType: 'AdminInvite',
      resourceId: invite.id,
      metadata: { email, role: dto.role } as Prisma.InputJsonValue,
    });

    return this.toInviteResponse(invite);
  }

  async resend(id: string, actor: AuthenticatedUser) {
    const invite = await this.prisma.adminInvite.findUnique({ where: { id } });
    if (!invite) {
      throw new NotFoundException({
        code: 'INVITE_NOT_FOUND',
        message: 'Invite not found.',
      });
    }
    if (invite.status === AdminInviteStatus.ACCEPTED) {
      throw new BadRequestException({
        code: 'INVITE_ALREADY_ACCEPTED',
        message: 'This invite has already been accepted.',
      });
    }
    if (invite.status === AdminInviteStatus.REVOKED) {
      throw new BadRequestException({
        code: 'INVITE_REVOKED',
        message: 'This invite was revoked. Create a new invite instead.',
      });
    }

    const { token, tokenHash, expiresAt } = await this.generateInviteToken();
    const updated = await this.prisma.adminInvite.update({
      where: { id },
      data: {
        tokenHash,
        expiresAt,
        status: AdminInviteStatus.PENDING,
        revokedAt: null,
        attemptCount: 0,
        mfaSecret: null,
        acceptedAt: null,
        acceptedUserId: null,
      },
      include: {
        invitedBy: {
          select: { id: true, email: true, firstName: true, lastName: true },
        },
      },
    });

    await this.sendInviteEmail(updated, token);

    await this.audit.log({
      actorId: actor.userId,
      action: 'ADMIN_INVITE_RESENT',
      resourceType: 'AdminInvite',
      resourceId: id,
      metadata: { email: updated.email } as Prisma.InputJsonValue,
    });

    return this.toInviteResponse(updated);
  }

  async revoke(id: string, actor: AuthenticatedUser) {
    const invite = await this.prisma.adminInvite.findUnique({ where: { id } });
    if (!invite) {
      throw new NotFoundException({
        code: 'INVITE_NOT_FOUND',
        message: 'Invite not found.',
      });
    }
    if (invite.status === AdminInviteStatus.ACCEPTED) {
      throw new BadRequestException({
        code: 'INVITE_ALREADY_ACCEPTED',
        message: 'Cannot revoke an accepted invite.',
      });
    }
    if (invite.status === AdminInviteStatus.REVOKED) {
      return { id, status: AdminInviteStatus.REVOKED };
    }

    const updated = await this.prisma.adminInvite.update({
      where: { id },
      data: {
        status: AdminInviteStatus.REVOKED,
        revokedAt: new Date(),
        mfaSecret: null,
      },
    });

    await this.audit.log({
      actorId: actor.userId,
      action: 'ADMIN_INVITE_REVOKED',
      resourceType: 'AdminInvite',
      resourceId: id,
      metadata: { email: invite.email } as Prisma.InputJsonValue,
    });

    return { id: updated.id, status: updated.status };
  }

  private async generateInviteToken(): Promise<{ token: string; tokenHash: string; expiresAt: Date }> {
    const token = randomBytes(ADMIN_INVITE_TOKEN_BYTES).toString('base64url');
    const tokenHash = await bcrypt.hash(token, this.env.saltRounds);
    const ttlHours = Number(
      this.config.get<string>('ADMIN_INVITE_TTL_HOURS') ?? DEFAULT_ADMIN_INVITE_TTL_HOURS,
    );
    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + ttlHours);
    return { token, tokenHash, expiresAt };
  }

  private buildInviteUrl(id: string, token: string): string {
    const base =
      this.config.get<string>('ADMIN_APP_BASE_URL')?.replace(/\/+$/, '') ??
      'http://localhost:3001';
    const url = new URL('/accept-invite', base);
    url.searchParams.set('id', id);
    url.searchParams.set('token', token);
    return url.toString();
  }

  private async sendInviteEmail(
    invite: {
      id: string;
      email: string;
      firstName: string;
      lastName: string;
      role: Role;
      expiresAt: Date;
    },
    token: string,
  ): Promise<void> {
    await this.email.sendAdminInviteEmail(invite.email, {
      firstName: invite.firstName,
      lastName: invite.lastName,
      roleLabel: roleLabel(invite.role),
      inviteUrl: this.buildInviteUrl(invite.id, token),
      expiresAt: invite.expiresAt.toISOString(),
    });
  }

  private toInviteResponse(invite: {
    id: string;
    email: string;
    firstName: string;
    lastName: string;
    role: Role;
    status: AdminInviteStatus;
    expiresAt: Date;
    createdAt: Date;
    acceptedAt: Date | null;
    revokedAt: Date | null;
    invitedBy: { id: string; email: string; firstName: string; lastName: string };
  }) {
    return {
      id: invite.id,
      email: invite.email,
      firstName: invite.firstName,
      lastName: invite.lastName,
      role: invite.role,
      status: invite.status,
      expiresAt: invite.expiresAt.toISOString(),
      createdAt: invite.createdAt.toISOString(),
      acceptedAt: invite.acceptedAt?.toISOString() ?? null,
      revokedAt: invite.revokedAt?.toISOString() ?? null,
      invitedBy: invite.invitedBy,
    };
  }
}

export { roleLabel, STAFF_ROLES };
