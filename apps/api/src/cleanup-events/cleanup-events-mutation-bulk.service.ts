import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { CleanupEventStatus, Prisma } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { BulkModerateCleanupEventsDto } from './dto/bulk-moderate-cleanup-events.dto';
import { CleanupEventsPatchMutationService } from './cleanup-events-mutation-patch.service';

@Injectable()
export class CleanupEventsBulkModerateMutationService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly patchMutation: CleanupEventsPatchMutationService,
  ) {}

  async bulkModerate(dto: BulkModerateCleanupEventsDto, actor: AuthenticatedUser) {
    if (dto.eventIds.length === 0) {
      throw new BadRequestException({
        code: 'BULK_MODERATION_EMPTY',
        message: 'eventIds must not be empty',
      });
    }

    const existingJob = await this.prisma.adminMutationIdempotency.findUnique({
      where: {
        actorUserId_purpose_clientJobId: {
          actorUserId: actor.userId,
          purpose: 'bulk_cleanup_moderate',
          clientJobId: dto.clientJobId,
        },
      },
      select: { id: true },
    });
    if (existingJob != null) {
      throw new ConflictException({
        code: 'DUPLICATE_BULK_MODERATION_JOB',
        message: 'This moderation job was already submitted.',
      });
    }

    const failed: Array<{ id: string; code: string; message: string }> = [];
    let processed = 0;
    for (const eventId of dto.eventIds) {
      try {
        if (dto.action === 'APPROVED') {
          await this.patchMutation.patch(eventId, { status: CleanupEventStatus.APPROVED }, actor);
        } else {
          await this.patchMutation.patch(
            eventId,
            {
              status: CleanupEventStatus.DECLINED,
              declineReason: dto.declineReason ?? '',
            },
            actor,
          );
        }
        processed += 1;
      } catch (err: unknown) {
        const body = err instanceof BadRequestException || err instanceof NotFoundException ? err.getResponse() : null;
        const code =
          typeof body === 'object' && body !== null && 'code' in body && typeof (body as { code: unknown }).code === 'string'
            ? (body as { code: string }).code
            : 'BULK_MODERATION_ITEM_FAILED';
        const message =
          typeof body === 'object' && body !== null && 'message' in body && typeof (body as { message: unknown }).message === 'string'
            ? (body as { message: string }).message
            : 'Request failed';
        failed.push({ id: eventId, code, message });
      }
    }

    if (failed.length === 0) {
      try {
        await this.prisma.adminMutationIdempotency.create({
          data: {
            actorUserId: actor.userId,
            purpose: 'bulk_cleanup_moderate',
            clientJobId: dto.clientJobId,
          },
        });
      } catch (e: unknown) {
        if (e instanceof Prisma.PrismaClientKnownRequestError && e.code === 'P2002') {
          throw new ConflictException({
            code: 'DUPLICATE_BULK_MODERATION_JOB',
            message: 'This moderation job was already submitted.',
          });
        }
        throw e;
      }
    }

    return { processed, failed, clientJobId: dto.clientJobId };
  }
}
