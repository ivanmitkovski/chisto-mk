import type { NewsBodyBlock, NewsCategoryApi } from '../news-api-types';

export type NewsContentTemplateId = NewsCategoryApi | 'blank';

export const NEWS_CONTENT_TEMPLATE_OPTIONS: NewsContentTemplateId[] = [
  'blank',
  'release',
  'partnership',
  'community',
  'product',
];

/** Starter EN body blocks per category; mk/sq stay empty for manual translation. */
export const NEWS_CONTENT_TEMPLATES: Record<Exclude<NewsContentTemplateId, 'blank'>, NewsBodyBlock[]> = {
  release: [
    { type: 'paragraph', text: 'We are excited to announce a new release on chisto.mk.' },
    { type: 'paragraph', text: 'What is new:' },
    { type: 'paragraph', text: '• Improved performance and reliability\n• New features for volunteers and organizers' },
    { type: 'paragraph', text: 'Thank you for being part of our community.' },
  ],
  partnership: [
    { type: 'paragraph', text: 'We are proud to announce a new partnership that strengthens our mission.' },
    { type: 'paragraph', text: 'Together we will:' },
    { type: 'paragraph', text: '• Expand cleanup activities across more communities\n• Share resources and expertise' },
    { type: 'paragraph', text: 'Stay tuned for updates on upcoming joint initiatives.' },
  ],
  community: [
    { type: 'paragraph', text: 'Our community continues to make a real difference.' },
    { type: 'paragraph', text: 'Highlights from recent activities:' },
    { type: 'paragraph', text: '• Volunteers joined local cleanup events\n• New members signed up through the app' },
    { type: 'paragraph', text: 'Join us at the next event — every contribution counts.' },
  ],
  product: [
    { type: 'paragraph', text: 'We have updated the chisto.mk app with improvements based on your feedback.' },
    { type: 'paragraph', text: 'Key updates:' },
    { type: 'paragraph', text: '• Smoother navigation and event discovery\n• Bug fixes and stability improvements' },
    { type: 'paragraph', text: 'Update the app to enjoy the latest experience.' },
  ],
};

export function applyContentTemplate(
  templateId: NewsContentTemplateId,
): NewsBodyBlock[] {
  if (templateId === 'blank') return [];
  return NEWS_CONTENT_TEMPLATES[templateId].map((block) =>
    block.type === 'paragraph' ? { type: 'paragraph', text: block.text } : { ...block },
  );
}
