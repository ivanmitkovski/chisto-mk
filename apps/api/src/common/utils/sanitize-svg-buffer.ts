import { BadRequestException } from '@nestjs/common';
import DOMPurify from 'isomorphic-dompurify';

const FORBIDDEN_PATTERNS = [
  /<script/i,
  /\bon\w+\s*=/i,
  /javascript:/i,
  /<foreignObject/i,
];

export function sanitizeSvgBuffer(buf: Buffer): Buffer {
  const xml = buf.toString('utf8');
  const sanitized = DOMPurify.sanitize(xml, {
    USE_PROFILES: { svg: true, svgFilters: true },
  });

  if (!sanitized.trim()) {
    throw new BadRequestException({
      code: 'NEWS_INVALID_SVG',
      message: 'SVG content is empty or invalid',
    });
  }

  for (const pattern of FORBIDDEN_PATTERNS) {
    if (pattern.test(sanitized)) {
      throw new BadRequestException({
        code: 'NEWS_UNSAFE_SVG',
        message: 'SVG contains disallowed content',
      });
    }
  }

  return Buffer.from(sanitized, 'utf8');
}

export function parseSvgDimensions(svg: string): { width: number | null; height: number | null } {
  const widthMatch = svg.match(/\bwidth=["'](\d+(?:\.\d+)?)/i);
  const heightMatch = svg.match(/\bheight=["'](\d+(?:\.\d+)?)/i);
  const viewBoxMatch = svg.match(/\bviewBox=["']([^"']+)["']/i);

  let width = widthMatch ? Math.round(parseFloat(widthMatch[1])) : null;
  let height = heightMatch ? Math.round(parseFloat(heightMatch[1])) : null;

  if ((!width || !height) && viewBoxMatch) {
    const parts = viewBoxMatch[1].trim().split(/[\s,]+/).map(Number);
    if (parts.length === 4 && parts.every((value) => Number.isFinite(value))) {
      width = width ?? Math.round(parts[2]);
      height = height ?? Math.round(parts[3]);
    }
  }

  return { width, height };
}
