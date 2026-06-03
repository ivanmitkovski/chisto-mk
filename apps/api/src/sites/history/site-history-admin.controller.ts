import { Idempotent } from '../../common/idempotency/idempotency.decorator';
import { Body, Controller, Param, Post, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiCreatedResponse,
  ApiForbiddenResponse,
  ApiNotFoundResponse,
  ApiOperation,
  ApiTags,
  ApiTooManyRequestsResponse,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import { ADMIN_PANEL_ROLES } from '../../auth/constants/admin-roles';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';
import { Roles } from '../../auth/decorators/roles.decorator';
import { RolesGuard } from '../../auth/guards/roles.guard';
import type { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { ParseCuidPipe } from '../../common/pipes/parse-cuid.pipe';
import { ApiStandardHttpErrorResponses } from '../../common/openapi/standard-http-error-responses.decorator';
import { PostSiteHistoryNoteDto } from './dto/post-site-history-note.dto';
import { SiteHistoryEntryDto } from './dto/site-history-entry.dto';
import { SiteHistoryQueryService } from './site-history-query.service';
import { SiteHistoryWriterService } from './site-history-writer.service';

@ApiTags('sites')
@ApiStandardHttpErrorResponses()
@Controller('sites')
export class SiteHistoryAdminController {
  constructor(
    private readonly siteHistoryWriter: SiteHistoryWriterService,
    private readonly siteHistoryQuery: SiteHistoryQueryService,
  ) {}

  @Idempotent('sites_history_site-history-admin_35')
  @Post(':id/history/notes')
  @UseGuards(JwtAuthGuard, RolesGuard, ThrottlerGuard)
  @Throttle({ default: { limit: 60, ttl: 60_000 } })
  @Roles(...ADMIN_PANEL_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Add an admin note to the site timeline' })
  @ApiCreatedResponse({ type: SiteHistoryEntryDto })
  @ApiUnauthorizedResponse({ description: 'Missing or invalid JWT' })
  @ApiForbiddenResponse({ description: 'Caller is not an admin' })
  @ApiNotFoundResponse({ description: 'Site not found' })
  @ApiTooManyRequestsResponse({ description: 'Too many requests' })
  async postNote(
    @Param('id', ParseCuidPipe) id: string,
    @Body() dto: PostSiteHistoryNoteDto,
    @CurrentUser() admin: AuthenticatedUser,
  ): Promise<SiteHistoryEntryDto> {
    await this.siteHistoryQuery.list(id, { limit: 1 }, admin);

    await this.siteHistoryWriter.recordAdminNote({
      siteId: id,
      note: dto.note.trim(),
      ...(dto.occurredAt ? { occurredAt: new Date(dto.occurredAt) } : {}),
      actor: { userId: admin.userId, role: admin.role },
    });

    const page = await this.siteHistoryQuery.list(id, { limit: 1 }, admin);
    const created = page.items[0];
    if (!created) {
      throw new Error('Failed to load created history note');
    }
    return created;
  }
}
