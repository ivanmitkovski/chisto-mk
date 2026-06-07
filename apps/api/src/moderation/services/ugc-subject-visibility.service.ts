import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class UgcSubjectVisibilityService {
  constructor(private readonly prisma: PrismaService) {}

  async resolveContentStatus(subjectType: string, subjectId: string): Promise<string> {
    switch (subjectType) {
      case 'site_comment': {
        const row = await this.prisma.siteComment.findUnique({
          where: { id: subjectId },
          select: { isDeleted: true },
        });
        return row?.isDeleted ? 'hidden' : 'visible';
      }
      case 'event_chat_message': {
        const row = await this.prisma.eventChatMessage.findUnique({
          where: { id: subjectId },
          select: { deletedAt: true },
        });
        return row?.deletedAt ? 'hidden' : 'visible';
      }
      case 'site': {
        const row = await this.prisma.site.findUnique({
          where: { id: subjectId },
          select: { isArchivedByAdmin: true },
        });
        return row?.isArchivedByAdmin ? 'hidden' : 'visible';
      }
      case 'user': {
        const row = await this.prisma.user.findUnique({
          where: { id: subjectId },
          select: { status: true },
        });
        return row?.status === 'SUSPENDED' ? 'hidden' : 'visible';
      }
      case 'event': {
        const row = await this.prisma.cleanupEvent.findUnique({
          where: { id: subjectId },
          select: { status: true },
        });
        return row?.status === 'DECLINED' ? 'hidden' : 'visible';
      }
      default:
        return 'unknown';
    }
  }

  async applySubjectVisibility(subjectType: string, subjectId: string, hidden: boolean): Promise<void> {
    switch (subjectType) {
      case 'site_comment':
        await this.prisma.siteComment.updateMany({
          where: { id: subjectId },
          data: { isDeleted: hidden },
        });
        return;
      case 'event_chat_message':
        await this.prisma.eventChatMessage.updateMany({
          where: { id: subjectId },
          data: { deletedAt: hidden ? new Date() : null },
        });
        return;
      case 'site':
        await this.prisma.site.updateMany({
          where: { id: subjectId },
          data: {
            isArchivedByAdmin: hidden,
            archivedAt: hidden ? new Date() : null,
          },
        });
        return;
      case 'user':
        await this.prisma.user.updateMany({
          where: { id: subjectId },
          data: { status: hidden ? 'SUSPENDED' : 'ACTIVE' },
        });
        return;
      case 'event':
        await this.prisma.cleanupEvent.updateMany({
          where: { id: subjectId },
          data: { status: hidden ? 'DECLINED' : 'APPROVED' },
        });
        return;
      default:
        throw new BadRequestException({
          code: 'UNSUPPORTED_SUBJECT',
          message: `Cannot ${hidden ? 'hide' : 'restore'} subject type ${subjectType}`,
        });
    }
  }
}
