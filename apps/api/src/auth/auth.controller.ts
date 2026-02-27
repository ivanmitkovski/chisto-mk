import { Body, Controller, Get, Post, UnauthorizedException, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiCreatedResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { Role } from '@prisma/client';
import { AuthService } from './auth.service';
import { CurrentUser } from './current-user.decorator';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';
import { JwtAuthGuard } from './jwt-auth.guard';
import { Roles } from './roles.decorator';
import { RolesGuard } from './roles.guard';
import { AuthenticatedUser } from './types/authenticated-user.type';
import { AuthResponseDto } from './dto/auth-response.dto';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  @ApiOperation({ summary: 'Register a new user account' })
  @ApiCreatedResponse({
    description: 'User registered and token issued',
    type: AuthResponseDto,
  })
  register(@Body() dto: RegisterDto): Promise<AuthResponseDto> {
    return this.authService.register(dto);
  }

  @Post('login')
  @ApiOperation({ summary: 'Authenticate existing user' })
  @ApiOkResponse({
    description: 'User authenticated and token issued',
    type: AuthResponseDto,
  })
  login(@Body() dto: LoginDto): Promise<AuthResponseDto> {
    return this.authService.login(dto);
  }

  @Post('admin/login')
  @ApiOperation({ summary: 'Authenticate admin user for admin console' })
  @ApiOkResponse({
    description: 'Admin authenticated and token issued',
    type: AuthResponseDto,
  })
  adminLogin(@Body() dto: LoginDto): Promise<AuthResponseDto> {
    return this.authService.adminLogin(dto);
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get authenticated user profile' })
  @ApiOkResponse({ description: 'Authenticated user profile' })
  me(@CurrentUser() user?: AuthenticatedUser) {
    if (!user) {
      throw new UnauthorizedException({
        code: 'UNAUTHORIZED',
        message: 'Authentication required',
      });
    }

    return this.authService.me(user);
  }

  @Get('admin/ping')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Admin-only authorization check endpoint' })
  @ApiOkResponse({ description: 'Admin role validated' })
  adminPing() {
    return { message: 'Admin access granted' };
  }
}
