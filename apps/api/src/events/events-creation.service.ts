import { Injectable } from '@nestjs/common';
import { CleanupEventStatus } from '../prisma-client';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { CreatePublicEventDto } from './dto/create-public-event.dto';
import { EventCreationPersistenceService } from './event-creation-persistence.service';
import { EventCreationValidationService } from './event-creation-validation.service';

@Injectable()
export class EventsCreationService {
  constructor(
    private readonly validation: EventCreationValidationService,
    private readonly persistence: EventCreationPersistenceService,
  ) {}

  async create(dto: CreatePublicEventDto, user: AuthenticatedUser) {
    await this.validation.ensureCreatorAllowed(user);
    const createData = await this.validation.buildUncheckedCreateInput(dto, user);

    if (dto.recurrenceRule != null && dto.recurrenceRule.trim() !== '') {
      const scheduledAt = createData.scheduledAt as Date;
      const endAt = createData.endAt as Date | null;
      const { dates, durationMs } = this.validation.parseRecurrenceDates(dto, scheduledAt, endAt);
      await this.validation.assertSeriesSlotsFree(dto.siteId, dates, durationMs, endAt);
      return this.persistence.createSeries(
        dto,
        createData,
        user,
        dates,
        durationMs,
        endAt,
      );
    }

    const scheduledAt = createData.scheduledAt instanceof Date ? createData.scheduledAt : new Date(createData.scheduledAt);
    const endAt =
      createData.endAt == null
        ? null
        : createData.endAt instanceof Date
          ? createData.endAt
          : new Date(createData.endAt);
    await this.validation.assertSlotFree(dto.siteId, scheduledAt, endAt);

    return this.persistence.createSingle(
      createData,
      dto,
      user,
      createData.status as CleanupEventStatus,
    );
  }
}
