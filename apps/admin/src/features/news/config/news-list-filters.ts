import { NEWS_CATEGORIES } from '../types';

export const NEWS_LIST_PAGE_SIZE = 20;

export const NEWS_STATUS_FILTERS = ['', 'draft', 'scheduled', 'published', 'archived'] as const;
export type NewsStatusFilter = (typeof NEWS_STATUS_FILTERS)[number];

export const NEWS_CATEGORY_FILTERS = ['', ...NEWS_CATEGORIES] as const;
export type NewsCategoryFilter = (typeof NEWS_CATEGORY_FILTERS)[number];

export const NEWS_SORT_OPTIONS = ['publishedAt', 'updatedAt', 'title'] as const;
export type NewsSortOption = (typeof NEWS_SORT_OPTIONS)[number];

export type NewsListQuery = {
  status?: string;
  category?: string;
  q?: string;
  page?: number;
  sort?: NewsSortOption;
};
