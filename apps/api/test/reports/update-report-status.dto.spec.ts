/// <reference types="jest" />
import { plainToInstance } from 'class-transformer';
import { validateSync } from 'class-validator';
import { UpdateReportStatusDto } from '../../src/reports/dto/update-report-status.dto';

describe('UpdateReportStatusDto', () => {
  it('allows optional reason when not deleting', () => {
    const dto = plainToInstance(UpdateReportStatusDto, {
      status: 'APPROVED',
    });
    expect(validateSync(dto, { forbidUnknownValues: false })).toHaveLength(0);
  });

  it('requires reason when status is DELETED', () => {
    const dto = plainToInstance(UpdateReportStatusDto, {
      status: 'DELETED',
    });
    expect(validateSync(dto, { forbidUnknownValues: false }).length).toBeGreaterThan(0);
  });

  it('accepts delete with reason', () => {
    const dto = plainToInstance(UpdateReportStatusDto, {
      status: 'DELETED',
      reason: 'Spam / not verifiable.',
    });
    expect(validateSync(dto, { forbidUnknownValues: false })).toHaveLength(0);
  });
});
