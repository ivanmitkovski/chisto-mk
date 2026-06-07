import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ReportStatus, Role } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { ADMIN_PANEL_ROLES } from '../../auth/constants/admin-roles';
import { AssignReportDto, AssignReportResponseDto } from '../dto/assign-report.dto';

const ASSIGNABLE_STATUSES: ReportStatus[] = ['NEW', 'IN_REVIEW'];

@Injectable()
export class ReportsModerationAssignService {
  constructor(private readonly prisma: PrismaService) {}

  async assignReport(
    reportId: string,
    dto: AssignReportDto,
    actor: AuthenticatedUser,
  ): Promise<AssignReportResponseDto> {
    const report = await this.prisma.report.findUnique({
      where: { id: reportId },
      select: {
        id: true,
        status: true,
        moderatedById: true,
      },
    });

    if (!report) {
      throw new NotFoundException({
        code: 'REPORT_NOT_FOUND',
        message: `Report with id '${reportId}' was not found`,
      });
    }

    if (!ASSIGNABLE_STATUSES.includes(report.status)) {
      throw new BadRequestException({
        code: 'REPORT_NOT_ASSIGNABLE',
        message: `Report in status '${report.status}' cannot be assigned or reassigned`,
      });
    }

    if (dto.unassign) {
      if (
        report.moderatedById != null &&
        report.moderatedById !== actor.userId &&
        actor.role !== Role.ADMIN &&
        actor.role !== Role.SUPER_ADMIN
      ) {
        throw new ForbiddenException({
          code: 'CANNOT_UNASSIGN_OTHER',
          message: 'You can only release your own assignment',
        });
      }

      const updated = await this.prisma.report.update({
        where: { id: reportId },
        data: { moderatedById: null },
        select: { id: true, status: true, moderatedById: true },
      });
      return {
        reportId: updated.id,
        assignedModeratorId: null,
        assignedModeratorName: null,
        status: updated.status,
      };
    }

    const targetModeratorId = dto.moderatorId ?? actor.userId;
    const targetModerator = await this.prisma.user.findUnique({
      where: { id: targetModeratorId },
      select: { id: true, firstName: true, lastName: true, role: true },
    });

    if (!targetModerator) {
      throw new NotFoundException({
        code: 'MODERATOR_NOT_FOUND',
        message: `Moderator with id '${targetModeratorId}' was not found`,
      });
    }

    if (!ADMIN_PANEL_ROLES.includes(targetModerator.role as Role)) {
      throw new BadRequestException({
        code: 'INVALID_MODERATOR',
        message: 'Target user is not eligible for report assignment',
      });
    }

    if (
      targetModeratorId !== actor.userId &&
      actor.role !== Role.ADMIN &&
      actor.role !== Role.SUPER_ADMIN
    ) {
      throw new ForbiddenException({
        code: 'CANNOT_ASSIGN_TO_OTHER',
        message: 'You can only assign reports to yourself',
      });
    }

    const updated = await this.prisma.report.update({
      where: { id: reportId },
      data: {
        moderatedById: targetModeratorId,
        ...(report.status === 'NEW' ? { status: 'IN_REVIEW' as ReportStatus } : {}),
      },
      select: { id: true, status: true, moderatedById: true },
    });

    const assignedModeratorName =
      `${targetModerator.firstName} ${targetModerator.lastName}`.trim() || 'Moderator';

    return {
      reportId: updated.id,
      assignedModeratorId: updated.moderatedById,
      assignedModeratorName,
      status: updated.status,
    };
  }
}
