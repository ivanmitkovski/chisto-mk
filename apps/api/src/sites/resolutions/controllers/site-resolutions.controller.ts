import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  UploadedFiles,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import { FilesInterceptor } from '@nestjs/platform-express';
import * as multer from 'multer';
import {
  ApiBearerAuth,
  ApiCreatedResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { Idempotent } from '../../../common/idempotency/idempotency.decorator';
import { JwtAuthGuard } from '../../../auth/guards/jwt-auth.guard';
import { PhoneVerifiedGuard } from '../../../auth/guards/phone-verified.guard';
import { CurrentUser } from '../../../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../../auth/types/authenticated-user.type';
import { ParseCuidPipe } from '../../../common/pipes/parse-cuid.pipe';
import { ApiStandardHttpErrorResponses } from '../../../common/openapi/standard-http-error-responses.decorator';
import { NonEmptyUploadedFilesPipe } from '../../../reports/pipes/non-empty-uploaded-files.pipe';
import { ReportMediaUrlsResponseDto } from '../../../reports/dto/report-media-urls-response.dto';
import { CreateSiteResolutionDto } from '../dto/create-site-resolution.dto';
import {
  SiteResolutionListResponseDto,
  SiteResolutionResponseDto,
} from '../dto/site-resolution-response.dto';
import { SiteResolutionUploadService } from '../services/site-resolution-upload.service';
import { SiteResolutionSubmitService } from '../services/site-resolution-submit.service';
import { SiteResolutionQueryService } from '../services/site-resolution-query.service';
import { OptionalJwtAuthGuard } from '../../../auth/guards/optional-jwt-auth.guard';

@ApiTags('sites')
@ApiStandardHttpErrorResponses()
@Controller('sites/:siteId/resolutions')
export class SiteResolutionsController {
  constructor(
    private readonly upload: SiteResolutionUploadService,
    private readonly submit: SiteResolutionSubmitService,
    private readonly query: SiteResolutionQueryService,
  ) {}

  @Idempotent('site_resolution_upload')
  @Post('upload')
  @Throttle({ default: { limit: 30, ttl: 60_000 } })
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @ApiBearerAuth()
  @UseInterceptors(
    FilesInterceptor('files', 5, {
      storage: multer.memoryStorage(),
      limits: { fileSize: 10 * 1024 * 1024 },
    }),
  )
  @ApiOperation({ summary: 'Upload cleanup evidence photos (max 5, jpeg/png/webp, 10MB each)' })
  @ApiOkResponse({ type: ReportMediaUrlsResponseDto })
  async uploadPhotos(
    @CurrentUser() user: AuthenticatedUser,
    @UploadedFiles(new NonEmptyUploadedFilesPipe()) files: Express.Multer.File[],
  ): Promise<ReportMediaUrlsResponseDto> {
    const urls = await this.upload.uploadFiles(user.userId, files);
    return { urls };
  }

  @Idempotent('site_resolution_submit')
  @Post()
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  @UseGuards(JwtAuthGuard, PhoneVerifiedGuard, ThrottlerGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Submit cleanup confirmation with evidence for a pollution site' })
  @ApiCreatedResponse({ type: SiteResolutionResponseDto })
  submitResolution(
    @Param('siteId', ParseCuidPipe) siteId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateSiteResolutionDto,
  ): Promise<SiteResolutionResponseDto> {
    return this.submit.submit(siteId, user, dto);
  }

  @Get()
  @UseGuards(ThrottlerGuard, OptionalJwtAuthGuard)
  @Throttle({ default: { limit: 120, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List approved resolutions and caller pending submissions for a site' })
  @ApiOkResponse({ type: SiteResolutionListResponseDto })
  listResolutions(
    @Param('siteId', ParseCuidPipe) siteId: string,
    @CurrentUser() user?: AuthenticatedUser,
  ): Promise<SiteResolutionListResponseDto> {
    return this.query.listForSite(siteId, user);
  }
}
