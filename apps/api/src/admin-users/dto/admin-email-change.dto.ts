import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEmail, IsOptional, IsString, Length, Matches, MaxLength, MinLength } from 'class-validator';

export class AdminRequestEmailChangeDto {
  @ApiProperty({ example: 'new.user@example.com' })
  @IsEmail()
  newEmail!: string;

  @ApiProperty({ example: 'user_request' })
  @IsString()
  @MinLength(1)
  @MaxLength(64)
  reasonCode!: string;

  @ApiPropertyOptional({ maxLength: 500 })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  note?: string;
}

export class AdminConfirmEmailChangeDto {
  @ApiProperty({ example: 'new.user@example.com' })
  @IsEmail()
  newEmail!: string;

  @ApiProperty({ example: '123456' })
  @IsString()
  @Length(6, 6)
  @Matches(/^\d{6}$/)
  code!: string;
}
