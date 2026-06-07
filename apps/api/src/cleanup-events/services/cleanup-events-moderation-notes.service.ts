import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import type { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { AuditService } from '../../audit/services/audit.service';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateCleanupEventModerationNoteDto } from '../dto/create-cleanup-event-moderation-note.dto';

@Injectable()
export class CleanupEventsModerationNotesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
  ) {}

  async listNotes(eventId: string) {
    await this.assertEventExists(eventId);
    const rows = await this.prisma.cleanupEventModerationNote.findMany({
      where: { eventId },
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        createdAt: true,
        updatedAt: true,
        body: true,
        authorEmailSnapshot: true,
        authorId: true,
        author: { select: { id: true, email: true } },
      },
    });
    return {
      data: rows.map((row) => ({
        id: row.id,
        createdAt: row.createdAt.toISOString(),
        updatedAt: row.updatedAt.toISOString(),
        body: row.body,
        authorId: row.authorId,
        authorEmail: row.author?.email ?? row.authorEmailSnapshot ?? null,
      })),
    };
  }

  async createNote(
    eventId: string,
    dto: CreateCleanupEventModerationNoteDto,
    actor: AuthenticatedUser,
  ) {
    await this.assertEventExists(eventId);
    const body = dto.body.trim();
    if (body.length === 0) {
      throw new BadRequestException({
        code: 'NOTE_BODY_REQUIRED',
        message: 'Note body is required',
      });
    }

    const note = await this.prisma.cleanupEventModerationNote.create({
      data: {
        eventId,
        body,
        authorId: actor.userId,
        authorEmailSnapshot: actor.email ?? null,
      },
      select: {
        id: true,
        createdAt: true,
        updatedAt: true,
        body: true,
        authorId: true,
        authorEmailSnapshot: true,
        author: { select: { id: true, email: true } },
      },
    });

    await this.audit.log({
      actorId: actor.userId,
      action: 'CLEANUP_EVENT_NOTE_ADDED',
      resourceType: 'CleanupEvent',
      resourceId: eventId,
      metadata: { noteId: note.id },
    });

    return {
      id: note.id,
      createdAt: note.createdAt.toISOString(),
      updatedAt: note.updatedAt.toISOString(),
      body: note.body,
      authorId: note.authorId,
      authorEmail: note.author?.email ?? note.authorEmailSnapshot ?? null,
    };
  }

  async deleteNote(eventId: string, noteId: string, actor: AuthenticatedUser) {
    await this.assertEventExists(eventId);
    const existing = await this.prisma.cleanupEventModerationNote.findFirst({
      where: { id: noteId, eventId },
      select: { id: true },
    });
    if (!existing) {
      throw new NotFoundException({
        code: 'CLEANUP_EVENT_NOTE_NOT_FOUND',
        message: 'Moderation note not found',
      });
    }

    await this.prisma.cleanupEventModerationNote.delete({ where: { id: noteId } });

    await this.audit.log({
      actorId: actor.userId,
      action: 'CLEANUP_EVENT_NOTE_REMOVED',
      resourceType: 'CleanupEvent',
      resourceId: eventId,
      metadata: { noteId },
    });

    return { deleted: true, noteId };
  }

  private async assertEventExists(eventId: string) {
    const existing = await this.prisma.cleanupEvent.findUnique({
      where: { id: eventId },
      select: { id: true },
    });
    if (!existing) {
      throw new NotFoundException({
        code: 'CLEANUP_EVENT_NOT_FOUND',
        message: 'Cleanup event not found',
      });
    }
  }
}
