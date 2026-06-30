import { Idempotent } from '../../common/idempotency/idempotency.decorator';
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
import { SkipThrottle, Throttle } from '@nestjs/throttler';
import { AuthProfileService } from '../services/auth-profile.service';
import { CurrentUser } from '../decorators/current-user.decorator';
import { UpdateProfileDto } from '../dto/update-profile.dto';
import { UpdateHomeLocationDto } from '../dto/update-home-location.dto';
import { JwtAuthGuard } from '../guards/jwt-auth.guard';
import { AuthenticatedUser } from '../types/authenticated-user.type';
import { MeResponseDto } from '../dto/me-response.dto';
import { PointHistoryQueryDto } from '../dto/point-history-query.dto';
import { PointHistoryResponseDto } from '../dto/point-history-response.dto';
import { PointHistoryService } from '../../gamification/services/point-history.service';
import { localeFromAcceptLanguage } from '../../common/utils/format-relative-time-since';
import { OrganizerCertificationService } from '../services/organizer-certification.service';
import { SubmitOrganizerCertificationDto } from '../dto/submit-organizer-certification.dto';
import { ApiStandardHttpErrorResponses } from '../../common/openapi/standard-http-error-responses.decorator';
import { AcceptTermsDto } from '../dto/accept-terms.dto';
import { TermsConsentDto } from '../dto/terms-consent-response.dto';
import { requireAuthenticatedUser } from '../util/auth-require-user.util';

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
    return this.pointHistoryService.listForUser(
      requireAuthenticatedUser(user).userId,
      query,
      localeFromAcceptLanguage(acceptLanguage),
    );
  }

  @Get('me')
  @SkipThrottle()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get authenticated user profile' })
  @ApiOkResponse({ description: 'Authenticated user profile', type: MeResponseDto })
  me(
    @CurrentUser() user?: AuthenticatedUser,
    @Headers('accept-language') acceptLanguage?: string,
  ): Promise<MeResponseDto> {
    return this.profile.me(
      requireAuthenticatedUser(user),
      localeFromAcceptLanguage(acceptLanguage),
    );
  }

  @Idempotent('auth_accept_terms')
  @Post('me/accept-terms')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard)
  @Throttle({ default: { ttl: 60_000, limit: 20 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Record acceptance of current terms and community guidelines' })
  @ApiOkResponse({ description: 'Terms consent recorded', type: TermsConsentDto })
  acceptTerms(
    @CurrentUser() user: AuthenticatedUser | undefined,
    @Body() dto: AcceptTermsDto,
  ): Promise<TermsConsentDto> {
    return this.profile.acceptTerms(requireAuthenticatedUser(user).userId, dto);
  }

  @Idempotent('auth_home_location')
  @Patch('me/home-location')
  @UseGuards(JwtAuthGuard)
  @Throttle({ default: { ttl: 60_000, limit: 10 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Save citizen home map location (post-registration onboarding)' })
  @ApiOkResponse({ description: 'Home location saved' })
  updateHomeLocation(
    @CurrentUser() user: AuthenticatedUser | undefined,
    @Body() dto: UpdateHomeLocationDto,
  ) {
    return this.profile.updateHomeLocation(requireAuthenticatedUser(user).userId, dto);
  }

  // safe-to-retry: repeated Patch is acceptable
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
    return this.profile.updateProfile(requireAuthenticatedUser(user).userId, dto);
  }

  @Idempotent('auth_profile_avatar_upload')
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
    return this.profile.uploadAvatar(requireAuthenticatedUser(user).userId, files?.[0]);
  }

  // safe-to-retry: repeated Delete is acceptable
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
    await this.profile.removeAvatar(requireAuthenticatedUser(user).userId);
  }

  @Get('me/organizer-certification/quiz')
  @UseGuards(JwtAuthGuard)
  @Throttle({ default: { ttl: 60_000, limit: 60 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Fetch organizer certification quiz questions' })
  @ApiOkResponse({ description: 'Quiz questions for the caller locale' })
  async getOrganizerQuiz(
    @CurrentUser() user: AuthenticatedUser | undefined,
    @Headers('accept-language') acceptLanguage?: string,
  ) {
    return this.organizerCertification.getQuiz(
      requireAuthenticatedUser(user).userId,
      acceptLanguage ?? 'en',
    );
  }

  @Idempotent('auth_organizer_cert_submit')
  @Post('me/organizer-certification')
  @UseGuards(JwtAuthGuard)
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
    return this.organizerCertification.submit(requireAuthenticatedUser(user).userId, body);
  }
}
