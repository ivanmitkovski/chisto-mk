import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import type {
  OrganizerQuizQuestion,
  OrganizerQuizTopic,
  QuizLocale,
  QuizLocaleFile,
  QuizQuestionSchemaEntry,
} from './questions.types';

const QUIZ_DIR = join(__dirname);
const LOCALES: QuizLocale[] = ['en', 'mk', 'sq'];

const TOPICS = new Set<OrganizerQuizTopic>([
  'safety',
  'moderation',
  'check_in',
  'operations',
  'inclusion',
  'privacy',
  'integrity',
  'communication',
]);

function loadJson<T>(filename: string): T {
  const raw = readFileSync(join(QUIZ_DIR, filename), 'utf8');
  return JSON.parse(raw) as T;
}

function assertSchema(entries: QuizQuestionSchemaEntry[]): void {
  if (!Array.isArray(entries) || entries.length === 0) {
    throw new Error('organizer quiz schema is empty');
  }
  const ids = new Set<string>();
  for (const entry of entries) {
    if (!entry.id || ids.has(entry.id)) {
      throw new Error(`invalid quiz schema id: ${entry.id}`);
    }
    ids.add(entry.id);
    if (!TOPICS.has(entry.topic)) {
      throw new Error(`invalid quiz topic for ${entry.id}: ${entry.topic}`);
    }
    if (!Array.isArray(entry.optionIds) || entry.optionIds.length < 2) {
      throw new Error(`quiz ${entry.id} needs at least 2 options`);
    }
    if (!entry.optionIds.includes(entry.correctOptionId)) {
      throw new Error(`quiz ${entry.id} correctOptionId not in optionIds`);
    }
  }
}

function assertLocaleFile(lang: QuizLocale, file: QuizLocaleFile, schema: QuizQuestionSchemaEntry[]): void {
  for (const entry of schema) {
    const q = file.questions[entry.id];
    if (!q?.text?.trim()) {
      throw new Error(`missing ${lang} text for ${entry.id}`);
    }
    for (const optionId of entry.optionIds) {
      const text = q.options[optionId];
      if (!text?.trim()) {
        throw new Error(`missing ${lang} option ${optionId} for ${entry.id}`);
      }
    }
  }
}

function buildQuestions(): OrganizerQuizQuestion[] {
  const schema = loadJson<QuizQuestionSchemaEntry[]>('questions.schema.json');
  assertSchema(schema);

  const localeFiles: Record<QuizLocale, QuizLocaleFile> = {
    en: loadJson<QuizLocaleFile>(join('locales', 'en.json')),
    mk: loadJson<QuizLocaleFile>(join('locales', 'mk.json')),
    sq: loadJson<QuizLocaleFile>(join('locales', 'sq.json')),
  };

  for (const lang of LOCALES) {
    assertLocaleFile(lang, localeFiles[lang], schema);
  }

  return schema.map((entry) => {
    const text = {
      en: localeFiles.en.questions[entry.id]!.text,
      mk: localeFiles.mk.questions[entry.id]!.text,
      sq: localeFiles.sq.questions[entry.id]!.text,
    };
    const options = entry.optionIds.map((optionId) => ({
      id: optionId,
      text: {
        en: localeFiles.en.questions[entry.id]!.options[optionId]!,
        mk: localeFiles.mk.questions[entry.id]!.options[optionId]!,
        sq: localeFiles.sq.questions[entry.id]!.options[optionId]!,
      },
    }));
    return {
      id: entry.id,
      topic: entry.topic,
      text,
      options,
      correctOptionId: entry.correctOptionId,
    };
  });
}

/** Loaded once at module init; immutable question bank. */
export const ORGANIZER_QUIZ_QUESTIONS: readonly OrganizerQuizQuestion[] =
  Object.freeze(buildQuestions()) as OrganizerQuizQuestion[];
