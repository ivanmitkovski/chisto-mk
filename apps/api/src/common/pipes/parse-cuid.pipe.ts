import { BadRequestException, Injectable, PipeTransform } from '@nestjs/common';

/** Prisma default `@id @default(cuid())` — conservative ASCII pattern. */
const CUID_LIKE = /^c[a-z0-9]{8,32}$/i;

@Injectable()
export class ParseCuidPipe implements PipeTransform<string, string> {
  transform(value: string): string {
    if (typeof value !== 'string' || !CUID_LIKE.test(value.trim())) {
      throw new BadRequestException({
        code: 'INVALID_RESOURCE_ID',
        message: 'Invalid id format',
      });
    }
    return value.trim();
  }
}
