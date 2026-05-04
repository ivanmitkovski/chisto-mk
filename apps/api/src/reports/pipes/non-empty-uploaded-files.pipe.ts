import { BadRequestException, Injectable, PipeTransform } from '@nestjs/common';

@Injectable()
export class NonEmptyUploadedFilesPipe implements PipeTransform<
  Express.Multer.File[] | undefined,
  Express.Multer.File[]
> {
  transform(value: Express.Multer.File[] | undefined): Express.Multer.File[] {
    const fileList = value ?? [];
    if (fileList.length === 0) {
      throw new BadRequestException({
        code: 'FILES_REQUIRED',
        message: 'At least one image file is required.',
      });
    }
    return fileList;
  }
}
