import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsString, Matches, MaxLength, MinLength } from 'class-validator';

export class RegisterDto {
  @ApiProperty({ example: 'Ivan' })
  @IsString()
  @MinLength(2)
  @MaxLength(60)
  firstName!: string;

  @ApiProperty({ example: 'Mitkovski' })
  @IsString()
  @MinLength(2)
  @MaxLength(60)
  lastName!: string;

  @ApiProperty({ example: 'citizen@chisto.mk' })
  @IsEmail()
  email!: string;

  @ApiProperty({
    example: '+38970123456',
    description: 'Phone number in E.164 format for future verification flows',
  })
  @IsString()
  @Matches(/^\+[1-9]\d{7,14}$/, {
    message: 'phoneNumber must be in E.164 format (e.g. +38970123456)',
  })
  phoneNumber!: string;

  @ApiProperty({ minLength: 8, maxLength: 72, example: 'StrongPass123!' })
  @IsString()
  @MinLength(8)
  @MaxLength(72)
  password!: string;
}
