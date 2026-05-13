import { ApiProperty } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsIn, IsString } from 'class-validator';

const EVIDENCE_KINDS = ['BEFORE', 'AFTER', 'FIELD'] as const;

export type EvidenceUploadKind = (typeof EVIDENCE_KINDS)[number];

/** Multipart body fields alongside `file` for evidence upload. */
export class UploadEvidenceBodyDto {
  @ApiProperty({
    enum: EVIDENCE_KINDS,
    description: 'Evidence category',
  })
  @Transform(({ value }) => (typeof value === 'string' ? value.trim().toUpperCase() : value))
  @IsString()
  @IsIn([...EVIDENCE_KINDS], { message: 'kind must be BEFORE, AFTER, or FIELD' })
  kind!: EvidenceUploadKind;
}
