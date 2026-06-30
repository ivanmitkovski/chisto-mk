import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import type { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { PatchEventReminderDto } from '../dto/patch-event-reminder.dto';
import { EventsMobileMapperService } from './events-mobile-mapper.service';
import { eventDetailIncludeForViewer } from '../util/events-query.include.detail';
import { visibilityWhere } from '../util/events-query.include.shared';
import { EventsRepository } from '../repositories/events.repository';

/** Participant event reminders (enable/disable + custom reminder time). */
@Injectable()
export class EventsReminderService {
  constructor(
    private readonly eventsRepository: EventsRepository,
    private readonly mobileMapper: EventsMobileMapperService,
  ) {}

  async patchReminder(id: string, dto: PatchEventReminderDto, user: AuthenticatedUser) {
    const existing = await this.eventsRepository.prisma.cleanupEvent.findFirst({
      where: { id, ...visibilityWhere(user.userId) },
    });
    if (existing == null) {
      throw new NotFoundException({
        code: 'EVENT_NOT_FOUND',
        message: 'Event not found',
      });
    }

    const participant = await this.eventsRepository.prisma.eventParticipant.findUnique({
      where: {
        eventId_userId: { eventId: id, userId: user.userId },
      },
    });
    if (participant == null) {
      throw new ForbiddenException({
        code: 'REMINDER_REQUIRES_JOIN',
        message: 'Join the event before setting a reminder',
      });
    }

    let reminderAt: Date | null = null;
    if (dto.reminderEnabled && dto.reminderAt != null && dto.reminderAt !== '') {
      reminderAt = new Date(dto.reminderAt);
      if (Number.isNaN(reminderAt.getTime())) {
        throw new BadRequestException({
          code: 'INVALID_REMINDER_AT',
          message: 'Invalid reminderAt',
        });
      }
    }

    await this.eventsRepository.prisma.eventParticipant.update({
      where: { eventId_userId: { eventId: id, userId: user.userId } },
      data: {
        reminderEnabled: dto.reminderEnabled,
        reminderAt: dto.reminderEnabled ? reminderAt : null,
      },
    });

    const row = await this.eventsRepository.prisma.cleanupEvent.findFirstOrThrow({
      where: { id },
      include: eventDetailIncludeForViewer(user.userId),
    });
    return this.mobileMapper.toMobileEvent(row);
  }
}
