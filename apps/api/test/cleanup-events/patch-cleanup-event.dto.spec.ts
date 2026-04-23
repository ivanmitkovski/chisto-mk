/// <reference types="jest" />

import { plainToInstance } from 'class-transformer';
import { validateSync } from 'class-validator';
import { CleanupEventStatus } from '../../src/prisma-client';
import { PatchCleanupEventDto } from '../../src/cleanup-events/dto/patch-cleanup-event.dto';

describe('PatchCleanupEventDto', () => {
  it('validates moderation-only approve without endAt (ValidateIf must not read value as object)', () => {
    const dto = plainToInstance(PatchCleanupEventDto, {
      status: CleanupEventStatus.APPROVED,
    });
    const errors = validateSync(dto, { forbidUnknownValues: false });
    expect(errors).toHaveLength(0);
  });

  it('validates endAt when present', () => {
    const dto = plainToInstance(PatchCleanupEventDto, {
      endAt: '2026-04-23T15:00:00.000Z',
    });
    const errors = validateSync(dto, { forbidUnknownValues: false });
    expect(errors).toHaveLength(0);
  });
});
