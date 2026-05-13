import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { EventEvidenceKind } from '../prisma-client';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { PrismaService } from '../prisma/prisma.service';
import { ReportsUploadService } from '../reports/reports-upload.service';
import { EventsCleanupMediaUploadService } from './events-cleanup-media-upload.service';
import { visibilityWhere } from './events-query.include.shared';

const MAX_EVIDENCE_PHOTOS_PER_EVENT = 32;

function parseEvidenceKind(raw: string): EventEvidenceKind | null {
  const u = raw.trim().toUpperCase();
  if (u === 'BEFORE') {
    return EventEvidenceKind.BEFORE;
  }
  if (u === 'AFTER') {
    return EventEvidenceKind.AFTER;
  }
  if (u === 'FIELD') {
    return EventEvidenceKind.FIELD;
  }
  return null;
}

@Injectable()
export class EventEvidenceService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly uploads: ReportsUploadService,
    private readonly cleanupMediaUpload: EventsCleanupMediaUploadService,
  ) {}

  async listForEvent(eventId: string, user: AuthenticatedUser) {
    const allowed = await this.prisma.cleanupEvent.findFirst({
      where: { id: eventId, ...visibilityWhere(user.userId) },
      select: { id: true },
    });
    if (allowed == null) {
      throw new NotFoundException({
        code: 'EVENT_NOT_FOUND',
        message: 'Event not found',
      });
    }
    const rows = await this.prisma.eventEvidencePhoto.findMany({
      where: { eventId },
      orderBy: { createdAt: 'asc' },
      take: MAX_EVIDENCE_PHOTOS_PER_EVENT,
      select: {
        id: true,
        kind: true,
        objectKey: true,
        caption: true,
        createdAt: true,
      },
    });
    const urls = await this.uploads.signUrls(this.uploads.getPublicUrlsForKeys(rows.map((r) => r.objectKey)));
    return rows.map((r, i) => ({
      id: r.id,
      kind: r.kind.toLowerCase(),
      imageUrl: urls[i] ?? '',
      caption: r.caption,
      createdAt: r.createdAt.toISOString(),
    }));
  }

  async addPhoto(
    eventId: string,
    user: AuthenticatedUser,
    file: Express.Multer.File | undefined,
    kindRaw: string | undefined,
  ) {
    const kind = kindRaw != null ? parseEvidenceKind(kindRaw) : null;
    if (kind == null) {
      throw new BadRequestException({
        code: 'INVALID_EVIDENCE_KIND',
        message: 'kind must be BEFORE, AFTER, or FIELD',
      });
    }
    if (file == null || !file.buffer?.length) {
      throw new BadRequestException({
        code: 'EVIDENCE_IMAGE_REQUIRED',
        message: 'Image file is required',
      });
    }

    const event = await this.prisma.cleanupEvent.findFirst({
      where: { id: eventId, ...visibilityWhere(user.userId) },
      select: { id: true, organizerId: true },
    });
    if (event == null) {
      throw new NotFoundException({
        code: 'EVENT_NOT_FOUND',
        message: 'Event not found',
      });
    }
    if (event.organizerId !== user.userId) {
      throw new ForbiddenException({
        code: 'NOT_EVENT_ORGANIZER',
        message: 'Only the organizer can upload evidence',
      });
    }

    const count = await this.prisma.eventEvidencePhoto.count({ where: { eventId } });
    if (count >= MAX_EVIDENCE_PHOTOS_PER_EVENT) {
      throw new BadRequestException({
        code: 'EVIDENCE_LIMIT_REACHED',
        message: 'Maximum evidence photos reached for this event',
      });
    }

    const [key] = await this.cleanupMediaUpload.uploadCleanupEventAfterImages(user.userId, eventId, [
      {
        buffer: file.buffer,
        mimetype: file.mimetype,
        size: file.size,
        originalname: file.originalname,
      },
    ]);

    const created = await this.prisma.eventEvidencePhoto.create({
      data: {
        eventId,
        kind,
        objectKey: key,
        uploadedById: user.userId,
      },
      select: {
        id: true,
        kind: true,
        objectKey: true,
        caption: true,
        createdAt: true,
      },
    });
    const signed = await this.uploads.signUrls(this.uploads.getPublicUrlsForKeys([created.objectKey]));
    return {
      id: created.id,
      kind: created.kind.toLowerCase(),
      imageUrl: signed[0] ?? '',
      caption: created.caption,
      createdAt: created.createdAt.toISOString(),
    };
  }

  async deletePhoto(eventId: string, photoId: string, user: AuthenticatedUser): Promise<void> {
    const event = await this.prisma.cleanupEvent.findFirst({
      where: { id: eventId, ...visibilityWhere(user.userId) },
      select: { id: true, organizerId: true },
    });
    if (event == null) {
      throw new NotFoundException({
        code: 'EVENT_NOT_FOUND',
        message: 'Event not found',
      });
    }
    if (event.organizerId !== user.userId) {
      throw new ForbiddenException({
        code: 'NOT_EVENT_ORGANIZER',
        message: 'Only the organizer can delete evidence',
      });
    }
    const row = await this.prisma.eventEvidencePhoto.findFirst({
      where: { id: photoId, eventId },
      select: { id: true },
    });
    if (row == null) {
      throw new NotFoundException({
        code: 'EVENT_NOT_FOUND',
        message: 'Evidence photo not found',
      });
    }
    await this.prisma.eventEvidencePhoto.delete({ where: { id: photoId } });
  }
}
