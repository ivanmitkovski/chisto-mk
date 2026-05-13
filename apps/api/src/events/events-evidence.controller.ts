import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import * as multer from 'multer';
import {
  ApiBearerAuth,
  ApiBody,
  ApiConsumes,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import { CurrentUser } from '../auth/current-user.decorator';
import { ParseCuidPipe } from '../common/pipes/parse-cuid.pipe';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import {
  DeleteEvidenceResponseDto,
  EvidencePhotoResponseDto,
} from './dto/events-openapi-responses.dto';
import { UploadEvidenceBodyDto } from './dto/upload-evidence-body.dto';
import { EventEvidenceService } from './event-evidence.service';
import { ApiEventsJwtStandardErrors } from './events-openapi.decorators';
import { ApiStandardHttpErrorResponses } from '../common/openapi/standard-http-error-responses.decorator';

@ApiTags('events')
@ApiStandardHttpErrorResponses()
@Controller('events')
@UseGuards(ThrottlerGuard)
export class EventsEvidenceController {
  constructor(private readonly evidence: EventEvidenceService) {}

  @Get(':id/evidence')
  @Throttle({ default: { ttl: 60_000, limit: 60 } })
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List structured evidence photos for an event' })
  @ApiOkResponse({ description: 'Evidence rows with signed URLs', type: [EvidencePhotoResponseDto] })
  @ApiEventsJwtStandardErrors()
  listEvidence(@CurrentUser() user: AuthenticatedUser, @Param('id', ParseCuidPipe) id: string) {
    return this.evidence.listForEvent(id, user);
  }

  @Post(':id/evidence')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @Throttle({ default: { ttl: 60_000, limit: 20 } })
  @UseInterceptors(
    FileInterceptor('file', {
      storage: multer.memoryStorage(),
      limits: { fileSize: 10 * 1024 * 1024 },
    }),
  )
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    description: 'Multipart: image `file` plus `kind` (BEFORE|AFTER|FIELD)',
    schema: {
      type: 'object',
      required: ['file', 'kind'],
      properties: {
        file: { type: 'string', format: 'binary' },
        kind: { type: 'string', enum: ['BEFORE', 'AFTER', 'FIELD'] },
      },
    },
  })
  @ApiOperation({ summary: 'Upload one evidence image (organizer only); form field `kind`: BEFORE|AFTER|FIELD' })
  @ApiOkResponse({ description: 'Created evidence row', type: EvidencePhotoResponseDto })
  @ApiEventsJwtStandardErrors()
  uploadEvidence(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseCuidPipe) id: string,
    @UploadedFile() file: Express.Multer.File,
    @Body() body: UploadEvidenceBodyDto,
  ) {
    return this.evidence.addPhoto(id, user, file, body.kind);
  }

  @Delete(':id/evidence/:photoId')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @Throttle({ default: { ttl: 60_000, limit: 30 } })
  @ApiOperation({ summary: 'Delete an evidence photo (organizer only)' })
  @ApiOkResponse({ description: 'No content semantics — returns { ok: true }', type: DeleteEvidenceResponseDto })
  @ApiEventsJwtStandardErrors()
  async deleteEvidence(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseCuidPipe) id: string,
    @Param('photoId', ParseCuidPipe) photoId: string,
  ): Promise<{ ok: true }> {
    await this.evidence.deletePhoto(id, photoId, user);
    return { ok: true };
  }
}
