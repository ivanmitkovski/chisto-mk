/// <reference types="jest" />

import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { UpdateNewsPostDto } from '../../src/news/dto/news.dto';

async function validateUpdatePayload(payload: unknown) {
  const dto = plainToInstance(UpdateNewsPostDto, payload);
  return validate(dto, {
    whitelist: true,
    forbidNonWhitelisted: true,
  });
}

const draftLocalesWithBody = (body: unknown[]) => ({
  en: { title: 'Everyone knows that spot', excerpt: 'Lead', body },
  mk: { title: 'Test', excerpt: 'Test', body: [{ type: 'paragraph', text: 'x' }] },
  sq: { title: 'Test', excerpt: 'Test', body: [{ type: 'paragraph', text: 'x' }] },
});

describe('UpdateNewsPostDto body blocks', () => {
  it('accepts quote, divider, and embed blocks used by the admin editor', async () => {
    const errors = await validateUpdatePayload({
      slug: 'everyone-knows-that-spot',
      category: 'release',
      featured: false,
      expectedUpdatedAt: '2026-07-11T00:00:00.000Z',
      translations: draftLocalesWithBody([
        { type: 'paragraph', text: 'Opening.' },
        { type: 'heading', level: 2, text: 'Section' },
        { type: 'quote', text: 'A memorable line.', attribution: 'Chisto.mk' },
        { type: 'divider' },
        {
          type: 'embed',
          provider: 'youtube',
          url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        },
      ]),
    });
    expect(errors).toEqual([]);
  });

  it('rejects unknown body block types (forbidNonWhitelisted / IsIn)', async () => {
    const errors = await validateUpdatePayload({
      translations: draftLocalesWithBody([{ type: 'callout', text: 'nope' }]),
    });
    expect(errors.length).toBeGreaterThan(0);
  });

  it('rejects unknown properties on body blocks', async () => {
    const errors = await validateUpdatePayload({
      translations: draftLocalesWithBody([
        { type: 'paragraph', text: 'ok', unexpectedField: true },
      ]),
    });
    expect(errors.length).toBeGreaterThan(0);
  });
});
