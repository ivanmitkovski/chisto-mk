import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class AcceptTermsDto {
  @ApiPropertyOptional({
    example: '1',
    description: 'Terms version being accepted; defaults to server TERMS_VERSION',
  })
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(32)
  termsVersion?: string;
}
