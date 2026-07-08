import type { NewsBlockInsertMenuSection } from '../components/news-block-insert-menu';
import {
  BLOCK_INSERT_OPTIONS,
  type BlockInsertOption,
  type BlockInsertType,
} from './news-block-insert-config';
import { readBlockInsertRecents } from './news-block-insert-recents';
import {
  applyContentTemplate,
  NEWS_CONTENT_TEMPLATE_OPTIONS,
  type NewsContentTemplateId,
} from './news-content-templates';
import { fuzzyMatchSubsequence, fuzzyScore } from './news-slash-filter';

type BuildSlashSectionsArgs = {
  t: (key: string) => string;
  filter: string;
  onSelect: (type: BlockInsertType) => void;
  onTemplate: (templateId: Exclude<NewsContentTemplateId, 'blank'>) => void;
};

function optionToItem(
  option: BlockInsertOption,
  t: (key: string) => string,
  onSelect: () => void,
) {
  return {
    id: option.type,
    icon: option.icon,
    tone: option.tone,
    label: t(option.labelKey),
    description: t(option.descriptionKey),
    onSelect,
  };
}

function filterOptions(
  options: BlockInsertOption[],
  filter: string,
  t: (key: string) => string,
): BlockInsertOption[] {
  const q = filter.trim();
  if (!q) return options;
  return options
    .map((option) => ({
      option,
      score: Math.max(
        fuzzyScore(q, t(option.labelKey)),
        fuzzyScore(q, t(option.descriptionKey)),
        fuzzyMatchSubsequence(q, option.type) ? 1 : -1,
      ),
    }))
    .filter((row) => row.score >= 0)
    .sort((a, b) => b.score - a.score)
    .map((row) => row.option);
}

export function buildSlashInsertSections({
  t,
  filter,
  onSelect,
  onTemplate,
}: BuildSlashSectionsArgs): NewsBlockInsertMenuSection[] {
  const sections: NewsBlockInsertMenuSection[] = [];
  const recents = readBlockInsertRecents().filter((type) => type !== 'paragraph');
  const baseOptions = BLOCK_INSERT_OPTIONS.filter((option) => option.type !== 'paragraph');
  const filtered = filterOptions(baseOptions, filter, t);

  if (!filter.trim() && recents.length > 0) {
    const recentOptions = recents
      .map((type) => baseOptions.find((option) => option.type === type))
      .filter((option): option is BlockInsertOption => Boolean(option));
    if (recentOptions.length > 0) {
      sections.push({
        id: 'recents',
        label: t('insert.recents'),
        items: recentOptions.map((option) =>
          optionToItem(option, t, () => onSelect(option.type)),
        ),
      });
    }
  }

  if (filtered.length > 0) {
    sections.push({
      id: 'blocks',
      label: t('toolbar.insertBlocks'),
      items: filtered.map((option) =>
        optionToItem(option, t, () => onSelect(option.type)),
      ),
    });
  }

  if (!filter.trim()) {
    const templateItems = NEWS_CONTENT_TEMPLATE_OPTIONS.filter((id) => id !== 'blank').map(
      (templateId) => ({
        id: `template-${templateId}`,
        icon: 'document-duplicate' as const,
        tone: 'text' as const,
        label: t(`templates.${templateId}`),
        description: t(`insert.template.${templateId}`),
        onSelect: () => onTemplate(templateId),
      }),
    );
    sections.push({
      id: 'templates',
      label: t('insert.templates'),
      items: templateItems,
    });
  }

  return sections;
}

export function templateBlocksForSlash(
  templateId: Exclude<NewsContentTemplateId, 'blank'>,
  locale: 'en' | 'mk' | 'sq',
) {
  return applyContentTemplate(templateId, locale);
}
