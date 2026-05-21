import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, MaxLength, MinLength } from 'class-validator';
import { SanitizePlainText } from '../../common/sanitize/sanitize-transform.decorator';

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
}
