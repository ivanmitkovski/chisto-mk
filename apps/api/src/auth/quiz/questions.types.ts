export type OrganizerQuizTopic =
  | 'safety'
  | 'moderation'
  | 'check_in'
  | 'operations'
  | 'inclusion'
  | 'privacy'
  | 'integrity'
  | 'communication';

export interface OrganizerQuizQuestion {
  id: string;
  topic: OrganizerQuizTopic;
  text: Record<'en' | 'mk' | 'sq', string>;
  options: Array<{ id: string; text: Record<'en' | 'mk' | 'sq', string> }>;
  correctOptionId: string;
}

export type QuizLocale = 'en' | 'mk' | 'sq';

export type QuizQuestionSchemaEntry = {
  id: string;
  topic: OrganizerQuizTopic;
  optionIds: string[];
  correctOptionId: string;
};

export type QuizLocaleFile = {
  questions: Record<
    string,
    { text: string; options: Record<string, string> }
  >;
};
