import { createBlockId, type NewsBodyBlock } from '@chisto/news-content';

export type NewsContentTemplateId =
  | 'blank'
  | 'release'
  | 'partnership'
  | 'community'
  | 'product';

export type NewsContentLocale = 'en' | 'mk' | 'sq';

export const NEWS_CONTENT_TEMPLATE_OPTIONS: NewsContentTemplateId[] = [
  'blank',
  'release',
  'partnership',
  'community',
  'product',
];

function block(block: NewsBodyBlock): NewsBodyBlock {
  return block.id ? block : { ...block, id: createBlockId() };
}

function tpl(blocks: NewsBodyBlock[]): NewsBodyBlock[] {
  return blocks.map((b) => block(b));
}

const TEMPLATES_EN: Record<Exclude<NewsContentTemplateId, 'blank'>, NewsBodyBlock[]> = {
  release: tpl([
    { type: 'paragraph', text: 'We are excited to announce a new release on chisto.mk.' },
    { type: 'heading', level: 2, text: 'What is new' },
    {
      type: 'list',
      ordered: false,
      items: [
        'Improved performance and reliability',
        'New features for volunteers and organizers',
      ],
    },
    { type: 'paragraph', text: 'Thank you for being part of our community.' },
  ]),
  partnership: tpl([
    { type: 'paragraph', text: 'We are proud to announce a new partnership that strengthens our mission.' },
    { type: 'heading', level: 2, text: 'Together we will' },
    {
      type: 'list',
      ordered: false,
      items: [
        'Expand cleanup activities across more communities',
        'Share resources and expertise',
      ],
    },
    { type: 'paragraph', text: 'Stay tuned for updates on upcoming joint initiatives.' },
  ]),
  community: tpl([
    { type: 'paragraph', text: 'Our community continues to make a real difference.' },
    { type: 'heading', level: 2, text: 'Highlights from recent activities' },
    {
      type: 'list',
      ordered: false,
      items: [
        'Volunteers joined local cleanup events',
        'New members signed up through the app',
      ],
    },
    { type: 'paragraph', text: 'Join us at the next event — every contribution counts.' },
  ]),
  product: tpl([
    { type: 'paragraph', text: 'We have updated the chisto.mk app with improvements based on your feedback.' },
    { type: 'heading', level: 2, text: 'Key updates' },
    {
      type: 'list',
      ordered: false,
      items: [
        'Smoother navigation and event discovery',
        'Bug fixes and stability improvements',
      ],
    },
    { type: 'paragraph', text: 'Update the app to enjoy the latest experience.' },
  ]),
};

const TEMPLATES_MK: Record<Exclude<NewsContentTemplateId, 'blank'>, NewsBodyBlock[]> = {
  release: tpl([
    { type: 'paragraph', text: 'Со задоволство објавуваме ново издание на chisto.mk.' },
    { type: 'heading', level: 2, text: 'Што е ново' },
    {
      type: 'list',
      ordered: false,
      items: [
        'Подобрена перформанса и стабилност',
        'Нови функции за волонтери и организатори',
      ],
    },
    { type: 'paragraph', text: 'Ви благодариме што сте дел од нашата заедница.' },
  ]),
  partnership: tpl([
    { type: 'paragraph', text: 'Горди сме што објавуваме ново партнерство кое ја зајакнува нашата мисија.' },
    { type: 'heading', level: 2, text: 'Заедно ќе' },
    {
      type: 'list',
      ordered: false,
      items: [
        'Прошириме активности за чистење низ повеќе заедници',
        'Споделиме ресурси и знаење',
      ],
    },
    { type: 'paragraph', text: 'Следете не за ажурирања за претстојните заеднички иницијативи.' },
  ]),
  community: tpl([
    { type: 'paragraph', text: 'Нашата заедница продолжува да прави реална разлика.' },
    { type: 'heading', level: 2, text: 'Истакнати моменти од неодамнешните активности' },
    {
      type: 'list',
      ordered: false,
      items: [
        'Волонтери се приклучија на локални акции за чистење',
        'Нови членови се регистрираа преку апликацијата',
      ],
    },
    { type: 'paragraph', text: 'Приклучете се на следниот настан — секој придонес е важен.' },
  ]),
  product: tpl([
    { type: 'paragraph', text: 'Ја ажуриравме апликацијата chisto.mk според вашите повратни информации.' },
    { type: 'heading', level: 2, text: 'Клучни новини' },
    {
      type: 'list',
      ordered: false,
      items: [
        'Пофлексибилна навигација и откривање настани',
        'Поправки на грешки и подобрена стабилност',
      ],
    },
    { type: 'paragraph', text: 'Ажурирајте ја апликацијата за најновото искуство.' },
  ]),
};

const TEMPLATES_SQ: Record<Exclude<NewsContentTemplateId, 'blank'>, NewsBodyBlock[]> = {
  release: tpl([
    { type: 'paragraph', text: 'Me kënaqësi njoftojmë një publikim të ri në chisto.mk.' },
    { type: 'heading', level: 2, text: 'Çfarë ka të re' },
    {
      type: 'list',
      ordered: false,
      items: [
        'Performancë dhe qëndrueshmëri më të mira',
        'Veçori të reja për vullnetarë dhe organizatorë',
      ],
    },
    { type: 'paragraph', text: 'Faleminderit që jeni pjesë e komunitetit tonë.' },
  ]),
  partnership: tpl([
    { type: 'paragraph', text: 'Jemi krenarë të njoftojmë një partneritet të ri që forcon misionin tonë.' },
    { type: 'heading', level: 2, text: 'Së bashku do të' },
    {
      type: 'list',
      ordered: false,
      items: [
        'Zgjerojmë aktivitetet e pastrimit në më shumë komunitete',
        'Ndajmë burime dhe ekspertizë',
      ],
    },
    { type: 'paragraph', text: 'Qëndroni në pritje për përditësime mbi iniciativat e përbashkëta.' },
  ]),
  community: tpl([
    { type: 'paragraph', text: 'Komuniteti ynë vazhdon të bëjë ndryshim real.' },
    { type: 'heading', level: 2, text: 'Momentet kryesore nga aktivitetet e fundit' },
    {
      type: 'list',
      ordered: false,
      items: [
        'Vullnetarët u bashkuan me eventet lokale të pastrimit',
        'Anëtarë të rinj u regjistruan përmes aplikacionit',
      ],
    },
    { type: 'paragraph', text: 'Bashkohuni me eventin e ardhshëm — çdo kontribut ka rëndësi.' },
  ]),
  product: tpl([
    { type: 'paragraph', text: 'Kemi përditësuar aplikacionin chisto.mk sipas feedback-ut tuaj.' },
    { type: 'heading', level: 2, text: 'Përditësimet kryesore' },
    {
      type: 'list',
      ordered: false,
      items: [
        'Navigim më i qetë dhe zbulim eventesh',
        'Rregullime gabimesh dhe stabilitet i përmirësuar',
      ],
    },
    { type: 'paragraph', text: 'Përditësoni aplikacionin për përvojën më të fundit.' },
  ]),
};

export const NEWS_CONTENT_TEMPLATES: Record<
  NewsContentLocale,
  Record<Exclude<NewsContentTemplateId, 'blank'>, NewsBodyBlock[]>
> = {
  en: TEMPLATES_EN,
  mk: TEMPLATES_MK,
  sq: TEMPLATES_SQ,
};

export function applyContentTemplate(
  templateId: NewsContentTemplateId,
  locale: NewsContentLocale = 'en',
): NewsBodyBlock[] {
  if (templateId === 'blank') return [];
  return tpl(NEWS_CONTENT_TEMPLATES[locale][templateId]);
}
