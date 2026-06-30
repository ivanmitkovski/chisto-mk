/// <reference types="jest" />
import { BadRequestException } from '@nestjs/common';
import { ParseCuidPipe } from '../../src/common/pipes/parse-cuid.pipe';

describe('ParseCuidPipe', () => {
  const pipe = new ParseCuidPipe();

  it('accepts typical prisma cuid', () => {
    expect(pipe.transform('clh3q8x7n0000xyz1234567890')).toBe('clh3q8x7n0000xyz1234567890');
  });

  it('rejects empty and invalid', () => {
    expect(() => pipe.transform('')).toThrow(BadRequestException);
    expect(() => pipe.transform('not-a-cuid')).toThrow(BadRequestException);
    expect(() => pipe.transform('x' + 'a'.repeat(40))).toThrow(BadRequestException);
  });
});
