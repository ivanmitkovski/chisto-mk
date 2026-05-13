import { ForbiddenException, HttpException, Injectable, InternalServerErrorException, Logger, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { CleanupEventStatus, EcoEventLifecycleStatus } from '../prisma-client';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { CheckInRepository } from './check-in.repository';
import { visibilityWhere } from './events-query.include.shared';

@Injectable()
export class EventsCheckInSharedService {
  private readonly logger = new Logger(EventsCheckInSharedService.name);

  constructor(
    private readonly checkInRepository: CheckInRepository,
    private readonly config: ConfigService,
  ) {}

  getCheckInSecret(): Buffer {
    const raw = this.config.get<string>('CHECK_IN_QR_SECRET')?.trim();
    const nodeEnv = this.config.get<string>('NODE_ENV') ?? 'development';
    if (raw != null && raw.length >= 24) {
      return Buffer.from(raw, 'utf8');
    }
    if (nodeEnv === 'production') {
      this.logger.error('CHECK_IN_QR_SECRET missing or too short in production');
      throw new InternalServerErrorException({
        code: 'CHECK_IN_MISCONFIG',
        message: 'Server misconfigured',
      });
    }
    this.logger.warn(
      'CHECK_IN_QR_SECRET not set; using insecure dev default. Set CHECK_IN_QR_SECRET (>= 24 chars) before production.',
    );
    return Buffer.from('dev_only_check_in_qr_secret_min_24', 'utf8');
  }

  httpExceptionLabel(err: unknown): string {
    if (err instanceof HttpException) {
      const body = err.getResponse();
      if (typeof body === 'object' && body !== null && 'code' in body) {
        return String((body as { code?: string }).code ?? err.name);
      }
      return err.name;
    }
    return err instanceof Error ? err.name : 'unknown';
  }

  async loadEventForOrganizer(
    eventId: string,
    user: AuthenticatedUser,
  ): Promise<{
    id: string;
    organizerId: string | null;
    lifecycleStatus: EcoEventLifecycleStatus;
    status: CleanupEventStatus;
    checkInSessionId: string | null;
    checkInOpen: boolean;
  }> {
    const row = await this.checkInRepository.prisma.cleanupEvent.findFirst({
      where: { id: eventId, ...visibilityWhere(user.userId) },
      select: {
        id: true,
        organizerId: true,
        lifecycleStatus: true,
        status: true,
        checkInSessionId: true,
        checkInOpen: true,
      },
    });
    if (row == null) {
      throw new NotFoundException({
        code: 'EVENT_NOT_FOUND',
        message: 'Event not found',
      });
    }
    if (row.organizerId !== user.userId) {
      throw new ForbiddenException({
        code: 'NOT_EVENT_ORGANIZER',
        message: 'Only the organizer can manage check-in',
      });
    }
    return row;
  }
}
