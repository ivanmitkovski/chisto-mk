import { ApiProperty } from '@nestjs/swagger';

export class SystemInfoDto {
  @ApiProperty({ example: '0.1.0' })
  version!: string;

  @ApiProperty({ nullable: true, example: 'abc1234' })
  gitSha!: string | null;

  @ApiProperty({ example: 'production' })
  nodeEnv!: string;

  @ApiProperty({ nullable: true, example: 'eu-central-1' })
  region!: string | null;

  @ApiProperty({ example: '2026-06-07T10:00:00.000Z' })
  startedAt!: string;

  @ApiProperty({ example: 86400 })
  uptimeSeconds!: number;

  @ApiProperty({ example: true })
  fcmEnabled!: boolean;

  @ApiProperty({ example: true })
  fcmReady!: boolean;

  @ApiProperty({ nullable: true, example: 'chisto-mk-dev' })
  fcmProjectId!: string | null;

  @ApiProperty({
    enum: ['valid', 'missing', 'invalid_json', 'invalid_structure'],
    example: 'valid',
  })
  credentialStatus!: 'valid' | 'missing' | 'invalid_json' | 'invalid_structure';
}
