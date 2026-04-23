import { BadRequestException, Injectable } from '@nestjs/common';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import type { FieldBatchDto, FieldBatchResultDto } from './dto/field-batch.dto';
import { EventLiveImpactService } from './event-live-impact.service';

@Injectable()
export class EventsFieldBatchService {
  constructor(private readonly liveImpact: EventLiveImpactService) {}

  async applyBatch(user: AuthenticatedUser, dto: FieldBatchDto): Promise<FieldBatchResultDto> {
    if (dto.operations.length === 0) {
      throw new BadRequestException({
        code: 'FIELD_BATCH_EMPTY',
        message: 'No operations to apply',
      });
    }
    let applied = 0;
    let failed = 0;
    const errors: Array<{ index: number; code: string; message: string }> = [];
    for (let i = 0; i < dto.operations.length; i++) {
      const op = dto.operations[i];
      try {
        if (op.type === 'live_impact_bags') {
          await this.liveImpact.patch(
            op.eventId,
            { reportedBagsCollected: op.reportedBagsCollected },
            user,
          );
          applied += 1;
        }
      } catch (err: unknown) {
        failed += 1;
        const body =
          err != null && typeof err === 'object' && 'getResponse' in err
            ? (err as { getResponse: () => unknown }).getResponse()
            : null;
        const code =
          body != null && typeof body === 'object' && 'code' in body
            ? String((body as { code?: string }).code ?? 'HTTP_ERROR')
            : 'HTTP_ERROR';
        const message =
          body != null && typeof body === 'object' && 'message' in body
            ? String((body as { message?: string }).message ?? 'Operation failed')
            : 'Operation failed';
        errors.push({ index: i, code, message });
      }
    }
    const result: FieldBatchResultDto = { applied, failed };
    if (errors.length > 0) {
      result.errors = errors;
    }
    return result;
  }
}
