import { ApiProperty } from '@nestjs/swagger';

export class OperationsReadinessDto {
  @ApiProperty({ enum: ['ok', 'degraded'] })
  status!: 'ok' | 'degraded';

  @ApiProperty({ enum: ['ok', 'fail'] })
  database!: 'ok' | 'fail';

  @ApiProperty({ example: 'ok' })
  redis!: string;

  @ApiProperty({ example: 'ok' })
  s3!: string;
}
