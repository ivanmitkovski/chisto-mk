/// <reference types="jest" />
import { BadRequestException } from '@nestjs/common';
import { parseSvgDimensions, sanitizeSvgBuffer } from '../../src/common/utils/sanitize-svg-buffer';

describe('sanitizeSvgBuffer', () => {
  it('rejects SVG containing foreignObject after sanitization', () => {
    const input = Buffer.from(
      '<svg xmlns="http://www.w3.org/2000/svg"><foreignObject><div>x</div></foreignObject></svg>',
      'utf8',
    );

    expect(() => sanitizeSvgBuffer(input)).toThrow(BadRequestException);
    try {
      sanitizeSvgBuffer(input);
    } catch (error) {
      expect((error as BadRequestException).getResponse()).toMatchObject({
        code: 'NEWS_UNSAFE_SVG',
      });
    }
  });
});

describe('parseSvgDimensions', () => {
  it('reads width and height attributes', () => {
    expect(
      parseSvgDimensions('<svg width="320" height="180" viewBox="0 0 320 180"></svg>'),
    ).toEqual({ width: 320, height: 180 });
  });

  it('falls back to viewBox dimensions', () => {
    expect(parseSvgDimensions('<svg viewBox="0 0 640 360"></svg>')).toEqual({
      width: 640,
      height: 360,
    });
  });
});
