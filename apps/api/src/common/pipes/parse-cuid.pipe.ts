import { BadRequestException, Injectable, PipeTransform } from '@nestjs/common';
import { isPrismaCuid } from '../validators/is-cuid.validator';

/**
 * Validates `:id`-style path segments as Prisma `cuid()` before they reach services/Prisma.
 */
@Injectable()
export class ParseCuidPipe implements PipeTransform<string, string> {
  transform(value: string): string {
    const trimmed = typeof value === 'string' ? value.trim() : '';
    if (!isPrismaCuid(trimmed)) {
      throw new BadRequestException({
        code: 'INVALID_CUID',
        message: 'Invalid resource id',
      });
    }
    return trimmed;
  }
}
