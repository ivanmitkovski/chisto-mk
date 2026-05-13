import {
  Body,
  Controller,
  Delete,
  Get,
  Headers,
  HttpCode,
  HttpStatus,
  Patch,
  Post,
  Query,
  UnauthorizedException,
  UploadedFiles,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FilesInterceptor } from '@nestjs/platform-express';
import * as multer from 'multer';
import {
  ApiBearerAuth,
  ApiBody,
  ApiNoContentResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import { ADMIN_PANEL_ROLES } from './admin-roles';
import { AuthProfileService } from './auth-profile.service';
import { CurrentUser } from './current-user.decorator';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { JwtAuthGuard } from './jwt-auth.guard';
import { Roles } from './roles.decorator';
import { RolesGuard } from './roles.guard';
import { AuthenticatedUser } from './types/authenticated-user.type';
import { MeResponseDto } from './dto/me-response.dto';
import { PointHistoryQueryDto } from './dto/point-history-query.dto';
import { PointHistoryResponseDto } from './dto/point-history-response.dto';
import { PointHistoryService } from '../gamification/point-history.service';
import { localeFromAcceptLanguage } from '../common/utils/format-relative-time-since';
import { OrganizerCertificationService } from './organizer-certification.service';
import { SubmitOrganizerCertificationDto } from './dto/submit-organizer-certification.dto';
import { ApiStandardHttpErrorResponses } from '../common/openapi/standard-http-error-responses.decorator';

@ApiTags('auth')
@ApiStandardHttpErrorResponses()
@Controller('auth')
export class AuthProfileController {
  constructor(
    private readonly profile: AuthProfileService,
    private readonly pointHistoryService: PointHistoryService,
    private readonly organizerCertification: OrganizerCertificationService,
  ) {}

  @Get('me/point-history')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Paginated point awards history and level-up milestones' })
  @ApiOkResponse({ description: 'Point transactions (newest first)', type: PointHistoryResponseDto })
  async pointHistory(
    @CurrentUser() user: AuthenticatedUser | undefined,
    @Query() query: PointHistoryQueryDto,
    @Headers('accept-language') acceptLanguage?: string,
  ): Promise<PointHistoryResponseDto> {
    if (!user) {
      throw new UnauthorizedException({
        code: 'UNAUTHORIZED',
        message: 'Authentication required',
      });
    }
    return this.pointHistoryService.listForUser(
      user.userId,
      query,
      localeFromAcceptLanguage(acceptLanguage),
    );
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get authenticated user profile' })
  @ApiOkResponse({ description: 'Authenticated user profile', type: MeResponseDto })
  me(
    @CurrentUser() user?: AuthenticatedUser,
    @Headers('accept-language') acceptLanguage?: string,
  ): Promise<MeResponseDto> {
    if (!user) {
      throw new UnauthorizedException({
        code: 'UNAUTHORIZED',
        message: 'Authentication required',
      });
    }

    return this.profile.me(user, localeFromAcceptLanguage(acceptLanguage));
  }

  @Patch('me')
  @UseGuards(JwtAuthGuard)
  @Throttle({ default: { ttl: 60_000, limit: 10 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update authenticated user profile (name only)' })
  @ApiOkResponse({ description: 'Profile updated' })
  updateProfile(
    @CurrentUser() user: AuthenticatedUser | undefined,
    @Body() dto: UpdateProfileDto,
  ) {
    if (!user) {
      throw new UnauthorizedException({
        code: 'UNAUTHORIZED',
        message: 'Authentication required',
      });
    }
    return this.profile.updateProfile(user.userId, dto);
  }

  @Delete('me')
  @UseGuards(JwtAuthGuard)
  @Throttle({ default: { ttl: 60_000, limit: 3 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Delete account (soft delete)' })
  @ApiNoContentResponse({ description: 'Account deleted' })
  @HttpCode(HttpStatus.NO_CONTENT)
  async deleteAccount(@CurrentUser() user?: AuthenticatedUser): Promise<void> {
    if (!user) {
      throw new UnauthorizedException({
        code: 'UNAUTHORIZED',
        message: 'Authentication required',
      });
    }
    await this.profile.deleteAccount(user.userId);
  }

  @Post(['me/avatar', 'avatar'])
  @UseGuards(JwtAuthGuard)
  @Throttle({ default: { ttl: 60_000, limit: 10 } })
  @ApiBearerAuth()
  @UseInterceptors(
    FilesInterceptor('files', 1, {
      storage: multer.memoryStorage(),
      limits: { fileSize: 8 * 1024 * 1024 },
    }),
  )
  @ApiOperation({
    summary:
      'Upload or replace profile avatar (canonical: POST /auth/me/avatar; alias: POST /auth/avatar)',
  })
  @ApiOkResponse({ description: 'Avatar uploaded successfully' })
  uploadAvatar(
    @CurrentUser() user: AuthenticatedUser | undefined,
    @UploadedFiles() files: Express.Multer.File[],
  ): Promise<{ avatarUrl: string | null }> {
    if (!user) {
      throw new UnauthorizedException({
        code: 'UNAUTHORIZED',
        message: 'Authentication required',
      });
    }
    return this.profile.uploadAvatar(user.userId, files?.[0]);
  }

  @Delete(['me/avatar', 'avatar'])
  @UseGuards(JwtAuthGuard)
  @Throttle({ default: { ttl: 60_000, limit: 10 } })
  @ApiBearerAuth()
  @ApiOperation({
    summary:
      'Remove profile avatar (canonical: DELETE /auth/me/avatar; alias: DELETE /auth/avatar)',
  })
  @ApiNoContentResponse({ description: 'Avatar removed' })
  @HttpCode(HttpStatus.NO_CONTENT)
  async removeAvatar(@CurrentUser() user: AuthenticatedUser | undefined): Promise<void> {
    if (!user) {
      throw new UnauthorizedException({
        code: 'UNAUTHORIZED',
        message: 'Authentication required',
      });
    }
    await this.profile.removeAvatar(user.userId);
  }

  @Get('me/organizer-certification/quiz')
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @ApiBearerAuth()
  @Throttle({ default: { ttl: 60_000, limit: 60 } })
  @ApiOperation({ summary: 'Fetch organizer certification quiz questions' })
  @ApiOkResponse({ description: 'Quiz questions for the caller locale' })
  async getOrganizerQuiz(
    @CurrentUser() user: AuthenticatedUser | undefined,
    @Headers('accept-language') acceptLanguage?: string,
  ) {
    if (!user) {
      throw new UnauthorizedException({ code: 'UNAUTHORIZED', message: 'Authentication required' });
    }
    return this.organizerCertification.getQuiz(user.userId, acceptLanguage ?? 'en');
  }

  @Post('me/organizer-certification')
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: { ttl: 60_000, limit: 10 } })
  @ApiOperation({ summary: 'Submit organizer certification quiz answers' })
  @ApiBody({ type: SubmitOrganizerCertificationDto })
  @ApiOkResponse({ description: 'Certification result' })
  submitOrganizerCertification(
    @CurrentUser() user: AuthenticatedUser | undefined,
    @Body() body: SubmitOrganizerCertificationDto,
  ) {
    if (!user) {
      throw new UnauthorizedException({ code: 'UNAUTHORIZED', message: 'Authentication required' });
    }
    return this.organizerCertification.submit(user.userId, body);
  }

  @Get('admin/ping')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Admin-only authorization check endpoint' })
  @ApiOkResponse({ description: 'Admin role validated' })
  adminPing() {
    return { message: 'Admin access granted' };
  }
}
