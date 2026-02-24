import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsString, MaxLength, MinLength } from 'class-validator';

export class LoginDto {
  @ApiProperty({ example: 'citizen@chisto.mk' })
  @IsEmail()
  email!: string;

  @ApiProperty({ minLength: 8, maxLength: 72, example: 'StrongPass123!' })
  @IsString()
  @MinLength(8)
  @MaxLength(72)
  password!: string;
}
