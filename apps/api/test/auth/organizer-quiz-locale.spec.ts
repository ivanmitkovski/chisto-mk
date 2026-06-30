/// <reference types="jest" />

import { ORGANIZER_QUIZ_QUESTIONS } from '../../src/auth/quiz/quiz-bank.loader';

describe('organizer quiz MK copy', () => {
  function mkText(id: string): string {
    const q = ORGANIZER_QUIZ_QUESTIONS.find((entry) => entry.id === id);
    if (!q) {
      throw new Error(`missing question ${id}`);
    }
    return q.text.mk;
  }

  function mkOption(id: string, optionId: string): string {
    const q = ORGANIZER_QUIZ_QUESTIONS.find((entry) => entry.id === id);
    const opt = q?.options.find((o) => o.id === optionId);
    if (!opt) {
      throw new Error(`missing option ${optionId} on ${id}`);
    }
    return opt.text.mk;
  }

  it('q16 uses standard ќеси за отпад wording and correct grammar', () => {
    const text = mkText('q16_integrity');
    expect(text).toContain('ќеси за отпад');
    expect(text).not.toContain('ќесии');
    expect(text).toContain('да ги пријавите');
    expect(text).not.toContain('да се пријават');
  });

  it('avoids nonstandard bag plurals in MK options', () => {
    for (const q of ORGANIZER_QUIZ_QUESTIONS) {
      for (const opt of q.options) {
        expect(opt.text.mk).not.toMatch(/ќесии/i);
        expect(opt.text.mk).not.toMatch(/ќесиња/i);
        expect(opt.text.mk).not.toMatch(/Џувал/i);
      }
    }
  });

  it('q5 correct answer aligns with disposal terminology', () => {
    expect(mkOption('q5_waste', 'q5_b')).toContain('отстранување');
  });
});
