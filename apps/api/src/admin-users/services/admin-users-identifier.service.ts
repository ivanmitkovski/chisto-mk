import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Role, UserStatus } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import type { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import {
  AuthIdentifierChangeService,
  type AdminEmailChangeContext,
} from '../../auth/services/auth-identifier-change.service';
import { UserEventsService } from '../../admin-realtime/services/user-events.service';
import { AdminConfirmEmailChangeDto, AdminRequestEmailChangeDto } from '../dto/admin-email-change.dto';

function maskEmail(email: string): string {
  const at = email.indexOf('@');
  if (at <= 0) return '***';
  const local = email.slice(0, at);
  const domain = email.slice(at + 1);
  const visible = local.slice(0, 1);
  return `${visible}***@${domain}`;
}

@Injectable()
export class AdminUsersIdentifierService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly identifierChange: AuthIdentifierChangeService,
    private readonly userEventsService: UserEventsService,
  ) {}

  async requestEmailChange(
    userId: string,
    dto: AdminRequestEmailChangeDto,
    actor: AuthenticatedUser,
  ): Promise<{ expiresIn: number; devCode?: string }> {
    await this.assertModifiableTarget(userId, actor);

    const adminContext: AdminEmailChangeContext = {
      actorId: actor.userId,
      reasonCode: dto.reasonCode.trim(),
      ...(dto.note?.trim() ? { note: dto.note.trim() } : {}),
    };

    return this.identifierChange.requestEmailChange(userId, dto.newEmail, { adminContext });
  }

  async confirmEmailChange(
    userId: string,
    dto: AdminConfirmEmailChangeDto,
    actor: AuthenticatedUser,
  ): Promise<{ ok: true }> {
    const target = await this.assertModifiableTarget(userId, actor);
    const beforeEmail = target.email;

    const result = await this.identifierChange.confirmEmailChange(userId, dto.newEmail, dto.code);
    if (result.initiatedBy !== 'admin' || !result.adminContext) {
      throw new BadRequestException({
        code: 'INVALID_CODE',
        message: 'Invalid or expired code',
      });
    }
    if (result.adminContext.actorId !== actor.userId) {
      throw new BadRequestException({
        code: 'INVALID_CODE',
        message: 'Invalid or expired code',
      });
    }

    const noteBody = this.buildModerationNoteBody({
      reasonCode: result.adminContext.reasonCode,
      note: result.adminContext.note,
      fromEmail: beforeEmail,
      toEmail: dto.newEmail.trim().toLowerCase(),
    });

    await this.prisma.userModerationNote.create({
      data: {
        userId,
        authorId: actor.userId,
        body: noteBody,
      },
    });

    this.userEventsService.emitUserUpdated(userId);
    return { ok: true };
  }

  private buildModerationNoteBody(input: {
    reasonCode: string;
    note?: string | undefined;
    fromEmail: string;
    toEmail: string;
  }): string {
    const lines = [
      `Email changed (admin-assisted): ${maskEmail(input.fromEmail)} → ${maskEmail(input.toEmail)}`,
      `Reason: ${input.reasonCode}`,
    ];
    if (input.note) {
      lines.push(`Note: ${input.note}`);
    }
    return lines.join('\n');
  }

  private async assertModifiableTarget(userId: string, actor: AuthenticatedUser) {
    const target = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, email: true, role: true, status: true },
    });
    if (!target) {
      throw new NotFoundException({
        code: 'USER_NOT_FOUND',
        message: 'User not found',
      });
    }
    if (target.status === UserStatus.DELETED) {
      throw new BadRequestException({
        code: 'USER_DELETED',
        message: 'Cannot change email for a deleted user',
      });
    }
    if (target.role === Role.SUPER_ADMIN && actor.role !== Role.SUPER_ADMIN) {
      throw new ForbiddenException({
        code: 'FORBIDDEN',
        message: 'Only a super admin can modify this account',
      });
    }
    return target;
  }
}
