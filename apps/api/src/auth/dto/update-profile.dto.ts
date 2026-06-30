import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';
import { SanitizePlainText } from '../../common/sanitize/sanitize-transform.decorator';

const SUPPORTED_APP_LOCALES = ['en', 'mk', 'sq'] as const;

export class UpdateProfileDto {
  @ApiPropertyOptional({ example: 'John', maxLength: 100 })
  @IsOptional()
  @SanitizePlainText()
  @IsString()
  @MinLength(1)
  @MaxLength(100)
  firstName?: string;

  @ApiPropertyOptional({ example: 'Doe', maxLength: 100 })
  @IsOptional()
  @SanitizePlainText()
  @IsString()
  @MinLength(1)
  @MaxLength(100)
  lastName?: string;

  @ApiPropertyOptional({
    example: 'mk',
    enum: SUPPORTED_APP_LOCALES,
    description: 'Authoritative app UI locale for notifications (en | mk | sq).',
  })
  @IsOptional()
  @IsString()
  @IsIn(SUPPORTED_APP_LOCALES)
  locale?: (typeof SUPPORTED_APP_LOCALES)[number];
}
