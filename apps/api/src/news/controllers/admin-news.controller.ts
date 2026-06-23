import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import * as multer from 'multer';
import {
  ApiBearerAuth,
  ApiConsumes,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../auth/guards/roles.guard';
import { PermissionsGuard } from '../../auth/guards/permissions.guard';
import { Roles } from '../../auth/decorators/roles.decorator';
import { RequirePermission } from '../../auth/decorators/require-permission.decorator';
import { ADMIN_PANEL_ROLES, ADMIN_WRITE_ROLES } from '../../auth/constants/admin-roles';
import { ADMIN_PERMISSIONS } from '../../auth/constants/admin-permissions';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import type { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { ParseCuidPipe } from '../../common/pipes/parse-cuid.pipe';
import { Idempotent } from '../../common/idempotency/idempotency.decorator';
import { ApiStandardHttpErrorResponses } from '../../common/openapi/standard-http-error-responses.decorator';
import {
  CreateNewsPostDto,
  UpdateNewsPostDto,
  UploadNewsMediaQueryDto,
} from '../dto/news.dto';
import { NewsPostsService } from '../services/news-posts.service';
import { NewsMediaUploadService } from '../services/news-media-upload.service';

const NEWS_MULTER_MAX_BYTES = 25 * 1024 * 1024;

@ApiTags('admin-news')
@Controller('admin/news')
@UseGuards(JwtAuthGuard, RolesGuard, PermissionsGuard)
@ApiBearerAuth()
@ApiStandardHttpErrorResponses()
export class AdminNewsController {
  constructor(
    private readonly posts: NewsPostsService,
    private readonly media: NewsMediaUploadService,
  ) {}

  @Get('posts')
  @Roles(...ADMIN_PANEL_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['news:read'])
  @ApiOperation({ summary: 'List all news posts' })
  list() {
    return this.posts.list();
  }

  @Get('posts/:id')
  @Roles(...ADMIN_PANEL_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['news:read'])
  @ApiOperation({ summary: 'Get news post by id' })
  getById(@Param('id', ParseCuidPipe) id: string) {
    return this.posts.getById(id);
  }

  @Idempotent('admin_news_create')
  @Post('posts')
  @Roles(...ADMIN_WRITE_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['news:write'])
  @ApiOperation({ summary: 'Create news post draft' })
  create(@Body() body: CreateNewsPostDto, @CurrentUser() actor: AuthenticatedUser) {
    return this.posts.create(
      {
        ...(body.slug !== undefined ? { slug: body.slug } : {}),
        category: body.category,
        translations: body.translations,
      },
      actor,
    );
  }

  // safe-to-retry: repeated Patch is acceptable
  @Patch('posts/:id')
  @Roles(...ADMIN_WRITE_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['news:write'])
  @ApiOperation({ summary: 'Update news post' })
  update(
    @Param('id', ParseCuidPipe) id: string,
    @Body() body: UpdateNewsPostDto,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    return this.posts.update(
      id,
      {
        ...(body.slug !== undefined ? { slug: body.slug } : {}),
        ...(body.category !== undefined ? { category: body.category } : {}),
        ...(body.translations !== undefined ? { translations: body.translations } : {}),
        ...(body.scheduledAt !== undefined ? { scheduledAt: body.scheduledAt } : {}),
      },
      actor,
    );
  }

  // safe-to-retry: repeated Delete is acceptable
  @Delete('posts/:id')
  @Roles(...ADMIN_WRITE_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['news:write'])
  @ApiOperation({ summary: 'Delete news post' })
  async delete(@Param('id', ParseCuidPipe) id: string, @CurrentUser() actor: AuthenticatedUser) {
    await this.posts.delete(id, actor);
    return { ok: true };
  }

  // safe-to-retry: repeated publish is acceptable
  @Post('posts/:id/publish')
  @Roles(...ADMIN_WRITE_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['news:write'])
  @ApiOperation({ summary: 'Publish news post' })
  publish(@Param('id', ParseCuidPipe) id: string, @CurrentUser() actor: AuthenticatedUser) {
    return this.posts.publish(id, actor);
  }

  // safe-to-retry: repeated unpublish is acceptable
  @Post('posts/:id/unpublish')
  @Roles(...ADMIN_WRITE_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['news:write'])
  @ApiOperation({ summary: 'Unpublish news post to draft' })
  unpublish(@Param('id', ParseCuidPipe) id: string, @CurrentUser() actor: AuthenticatedUser) {
    return this.posts.unpublish(id, actor);
  }

  // safe-to-retry: repeated archive is acceptable
  @Post('posts/:id/archive')
  @Roles(...ADMIN_WRITE_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['news:write'])
  @ApiOperation({ summary: 'Archive news post' })
  archive(@Param('id', ParseCuidPipe) id: string, @CurrentUser() actor: AuthenticatedUser) {
    return this.posts.archive(id, actor);
  }

  @Idempotent('admin_news_media_upload')
  @Post('posts/:id/media')
  @Roles(...ADMIN_WRITE_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['news:write'])
  @ApiConsumes('multipart/form-data')
  @ApiOperation({ summary: 'Upload news media (cover or inline)' })
  @UseInterceptors(
    FileInterceptor('file', {
      storage: multer.memoryStorage(),
      limits: { fileSize: NEWS_MULTER_MAX_BYTES },
    }),
  )
  uploadMedia(
    @Param('id', ParseCuidPipe) id: string,
    @Query() query: UploadNewsMediaQueryDto,
    @UploadedFile() file: Express.Multer.File,
  ) {
    if (!file) {
      return this.posts.getById(id);
    }
    return this.media.upload({
      postId: id,
      kind: query.kind,
      file: {
        buffer: file.buffer,
        mimetype: file.mimetype,
        size: file.size,
        originalname: file.originalname,
      },
    });
  }

  // safe-to-retry: repeated Delete is acceptable
  @Delete('media/:mediaId')
  @Roles(...ADMIN_WRITE_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['news:write'])
  @ApiOperation({ summary: 'Delete news media' })
  async deleteMedia(@Param('mediaId', ParseCuidPipe) mediaId: string) {
    await this.media.deleteMedia(mediaId);
    return { ok: true };
  }
}
