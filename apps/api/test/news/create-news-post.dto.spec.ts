/// <reference types="jest" />

import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { CreateNewsPostDto } from '../../src/news/dto/news.dto';

async function validateCreatePayload(payload: unknown) {
  const dto = plainToInstance(CreateNewsPostDto, payload);
  return validate(dto, {
    whitelist: true,
    forbidNonWhitelisted: true,
  });
}

describe('CreateNewsPostDto', () => {
  it('accepts a minimal draft create payload from the admin create flow', async () => {
    const payload = {
      category: 'release',
      translations: {
        en: {
          title: 'test',
          excerpt: 'test',
          body: [{ type: 'paragraph', text: 'test' }],
        },
        mk: {
          title: 'test',
          excerpt: 'test',
          body: [{ type: 'paragraph', text: 'test' }],
        },
        sq: {
          title: 'test',
          excerpt: 'test',
          body: [{ type: 'paragraph', text: 'test' }],
        },
      },
    };
    const errors = await validateCreatePayload(payload);
    expect(errors).toEqual([]);
  });

  it('rejects extra top-level form fields leaked from the admin form', async () => {
    const payload = {
      slug: '',
      category: 'release',
      scheduledAt: '',
      featured: false,
      translations: {
        en: { title: 'test', excerpt: 'test', body: [{ type: 'paragraph', text: 'test' }] },
        mk: { title: 'test', excerpt: 'test', body: [{ type: 'paragraph', text: 'test' }] },
        sq: { title: 'test', excerpt: 'test', body: [{ type: 'paragraph', text: 'test' }] },
      },
    };
    const errors = await validateCreatePayload(payload);
    expect(errors.length).toBeGreaterThan(0);
    expect(errors.map((e) => e.property).sort()).toEqual(['featured', 'scheduledAt']);
  });
});
