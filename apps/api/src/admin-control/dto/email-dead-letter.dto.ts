import { ApiProperty } from '@nestjs/swagger';
import { PaginationMetaDto } from '../../notifications/dto/push-operations.dto';

export class EmailDeadLetterRowDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  userId!: string;

  @ApiProperty()
  templateId!: string;

  @ApiProperty()
  attempts!: number;

  @ApiProperty({ nullable: true })
  lastError!: string | null;

  @ApiProperty({ nullable: true })
  lastAttemptAt!: string | null;

  @ApiProperty()
  createdAt!: string;
}

export class EmailDeadLetterPageDto {
  @ApiProperty({ type: [EmailDeadLetterRowDto] })
  data!: EmailDeadLetterRowDto[];

  @ApiProperty({ type: PaginationMetaDto })
  meta!: PaginationMetaDto;
}
