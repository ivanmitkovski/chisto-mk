import { Controller, Get, Param, Query, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  ApiTooManyRequestsResponse,
} from '@nestjs/swagger';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import { OptionalJwtAuthGuard } from '../../auth/optional-jwt-auth.guard';
import { CurrentUser } from '../../auth/current-user.decorator';
import type { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { ParseCuidPipe } from '../../common/pipes/parse-cuid.pipe';
import { ApiStandardHttpErrorResponses } from '../../common/openapi/standard-http-error-responses.decorator';
import { ListSiteHistoryQueryDto } from './dto/list-site-history-query.dto';
import { SiteHistoryListResponseDto } from './dto/site-history-entry.dto';
import { SiteHistoryQueryService } from './site-history-query.service';

@ApiTags('sites')
@ApiStandardHttpErrorResponses()
@Controller('sites')
export class SiteHistoryController {
  constructor(private readonly siteHistoryQuery: SiteHistoryQueryService) {}

  @Get(':id/history')
  @UseGuards(ThrottlerGuard, OptionalJwtAuthGuard)
  @Throttle({ default: { limit: 120, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List chronological site history entries' })
  @ApiOkResponse({ type: SiteHistoryListResponseDto })
  @ApiNotFoundResponse({ description: 'Site not found' })
  @ApiTooManyRequestsResponse({ description: 'Too many requests' })
  listHistory(
    @Param('id', ParseCuidPipe) id: string,
    @Query() query: ListSiteHistoryQueryDto,
    @CurrentUser() user?: AuthenticatedUser,
  ): Promise<SiteHistoryListResponseDto> {
    return this.siteHistoryQuery.list(id, query, user);
  }
}
