/**
 * One-off exporter: organizer-quiz-bank.questions.ts → quiz/*.json
 * Run: pnpm --filter @chisto/api exec tsx scripts/export-organizer-quiz-json.ts
 */
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { ORGANIZER_QUIZ_QUESTIONS } from '../src/auth/organizer-quiz-bank.questions';

const __dirname = dirname(fileURLToPath(import.meta.url));
const quizDir = join(__dirname, '../src/auth/quiz');
const localesDir = join(quizDir, 'locales');

mkdirSync(localesDir, { recursive: true });

const schema = ORGANIZER_QUIZ_QUESTIONS.map((q) => ({
  id: q.id,
  topic: q.topic,
  optionIds: q.options.map((o) => o.id),
  correctOptionId: q.correctOptionId,
}));

type LocaleBundle = {
  questions: Record<
    string,
    { text: string; options: Record<string, string> }
  >;
};

const en: LocaleBundle = { questions: {} };
const mk: LocaleBundle = { questions: {} };
const sq: LocaleBundle = { questions: {} };

for (const q of ORGANIZER_QUIZ_QUESTIONS) {
  for (const lang of ['en', 'mk', 'sq'] as const) {
    const bundle = lang === 'en' ? en : lang === 'mk' ? mk : sq;
    bundle.questions[q.id] = {
      text: q.text[lang],
      options: Object.fromEntries(q.options.map((o) => [o.id, o.text[lang]])),
    };
  }
}

writeFileSync(join(quizDir, 'questions.schema.json'), `${JSON.stringify(schema, null, 2)}\n`);
writeFileSync(join(localesDir, 'en.json'), `${JSON.stringify(en, null, 2)}\n`);
writeFileSync(join(localesDir, 'mk.json'), `${JSON.stringify(mk, null, 2)}\n`);
writeFileSync(join(localesDir, 'sq.json'), `${JSON.stringify(sq, null, 2)}\n`);

console.log(`Wrote ${schema.length} questions to ${quizDir}`);
