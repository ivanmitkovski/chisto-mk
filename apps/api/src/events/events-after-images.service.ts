import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { CleanupEventStatus } from '../prisma-client';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { EventsCleanupMediaUploadService } from './events-cleanup-media-upload.service';
import { EventsMobileMapperService } from './events-mobile-mapper.service';
import { eventDetailIncludeForViewer } from './events-query.include.detail';
import { EventsRepository } from './events.repository';

/**
 * Organizer after-cleanup photo uploads (S3 keys merged onto the event).
 */
@Injectable()
export class EventsAfterImagesService {
  constructor(
    private readonly eventsRepository: EventsRepository,
    private readonly cleanupMediaUpload: EventsCleanupMediaUploadService,
    private readonly mobileMapper: EventsMobileMapperService,
  ) {}

  async appendAfterImages(
    id: string,
    files: Express.Multer.File[],
    user: AuthenticatedUser,
  ) {
    const existing = await this.eventsRepository.prisma.cleanupEvent.findUnique({
      where: { id },
    });
    if (existing == null) {
      throw new NotFoundException({
        code: 'EVENT_NOT_FOUND',
        message: 'Event not found',
      });
    }
    if (existing.organizerId !== user.userId) {
      throw new ForbiddenException({
        code: 'NOT_EVENT_ORGANIZER',
        message: 'Only the organizer can upload after photos',
      });
    }
    if (existing.status !== CleanupEventStatus.APPROVED) {
      throw new BadRequestException({
        code: 'EVENT_NOT_APPROVED',
        message: 'After photos can only be added to approved events',
      });
    }

    const buffers = (files ?? []).map((f) => ({
      buffer: f.buffer,
      mimetype: f.mimetype,
      size: f.size,
      originalname: f.originalname,
    }));

    const keys = await this.cleanupMediaUpload.uploadCleanupEventAfterImages(user.userId, id, buffers);
    const merged = [...existing.afterImageKeys, ...keys];

    const updated = await this.eventsRepository.prisma.cleanupEvent.update({
      where: { id },
      data: { afterImageKeys: merged },
      include: eventDetailIncludeForViewer(user.userId),
    });

    return this.mobileMapper.toMobileEvent(updated);
  }
}
