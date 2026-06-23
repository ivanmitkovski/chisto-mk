export type NewsBodyBlock =
  | { type: 'paragraph'; text: string }
  | { type: 'image'; mediaId: string; caption?: string }
  | { type: 'video'; mediaId: string; caption?: string };

export type NewsLocale = 'en' | 'mk' | 'sq';

export type NewsTranslations = Record<
  NewsLocale,
  {
    title: string;
    excerpt: string;
    body: NewsBodyBlock[];
  }
>;

export type NewsCategoryApi = 'release' | 'partnership' | 'community' | 'product';
export type NewsPostStatusApi = 'draft' | 'scheduled' | 'published' | 'archived';

export type NewsMediaDto = {
  id: string;
  kind: 'cover' | 'inline_image' | 'inline_video';
  url: string | null;
  mimeType: string;
  fileName: string | null;
};

export type NewsPostAdminDto = {
  id: string;
  slug: string;
  category: NewsCategoryApi;
  status: NewsPostStatusApi;
  publishedAt: string | null;
  scheduledAt: string | null;
  translations: NewsTranslations;
  coverMediaId: string | null;
  coverImageUrl: string | null;
  media: NewsMediaDto[];
  createdAt: string;
  updatedAt: string;
};
