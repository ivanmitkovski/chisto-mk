/**
 * Server-owned organizer certification quiz bank.
 * GET returns a random subset with shuffled options + signed quizSession;
 * POST validates selectedOptionId against correctOptionId for the issued question set only.
 */

import { randomInt } from 'crypto';

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

/** Number of questions issued per certification attempt. */
export const ORGANIZER_QUIZ_DRAW_SIZE = 5;

/** JWT lifetime for binding POST answers to GET draw (seconds). */
export const ORGANIZER_QUIZ_SESSION_TTL_SEC = 900;

export const ORGANIZER_QUIZ_JWT_TYP = 'organizer_quiz' as const;

export const ORGANIZER_QUIZ_QUESTIONS: OrganizerQuizQuestion[] = [
  {
    id: 'q1_safety',
    topic: 'safety',
    text: {
      en: 'What should you do before starting a cleanup event?',
      mk: 'Што треба да направите пред да започнете настан за чистење?',
      sq: 'Çfarë duhet të bëni para se të filloni një ngjarje pastrimi?',
    },
    options: [
      {
        id: 'q1_a',
        text: {
          en: 'Start immediately without planning',
          mk: 'Започнете веднаш без планирање',
          sq: 'Filloni menjëherë pa planifikim',
        },
      },
      {
        id: 'q1_b',
        text: {
          en: 'Assess the site for hazards, prepare safety gear, and brief volunteers',
          mk: 'Проценете ја локацијата за опасности, подгответе безбедносна опрема и брифирајте ги доброволците',
          sq: 'Vlerësoni vendin për rreziqe, përgatitni pajisjet e sigurisë dhe informoni vullnetarët',
        },
      },
      {
        id: 'q1_c',
        text: {
          en: 'Only bring trash bags',
          mk: 'Донесете само ќесиња за отпад',
          sq: 'Sillni vetëm qese plehrash',
        },
      },
      {
        id: 'q1_d',
        text: {
          en: 'Wait for volunteers to figure it out themselves',
          mk: 'Чекајте доброволците сами да се снајдат',
          sq: 'Prisni që vullnetarët ta kuptojnë vetë',
        },
      },
    ],
    correctOptionId: 'q1_b',
  },
  {
    id: 'q2_moderation',
    topic: 'moderation',
    text: {
      en: 'What happens after you create a cleanup event?',
      mk: 'Што се случува откако ќе креирате настан за чистење?',
      sq: 'Çfarë ndodh pasi të krijoni një ngjarje pastrimi?',
    },
    options: [
      {
        id: 'q2_a',
        text: {
          en: 'It is immediately visible to all volunteers',
          mk: 'Веднаш е видлив за сите доброволци',
          sq: 'Bëhet menjëherë i dukshëm për të gjithë vullnetarët',
        },
      },
      {
        id: 'q2_b',
        text: {
          en: 'Moderators review it before volunteers can see and join it',
          mk: 'Модераторите го прегледуваат пред доброволците да можат да го видат и да се приклучат',
          sq: 'Moderatorët e shqyrtojnë para se vullnetarët ta shohin dhe të bashkohen',
        },
      },
      {
        id: 'q2_c',
        text: {
          en: 'It gets deleted after 24 hours',
          mk: 'Се брише по 24 часа',
          sq: 'Fshihet pas 24 orësh',
        },
      },
      {
        id: 'q2_d',
        text: {
          en: 'Only you can see it forever',
          mk: 'Само вие можете да го видите засекогаш',
          sq: 'Vetëm ju mund ta shihni përgjithmonë',
        },
      },
    ],
    correctOptionId: 'q2_b',
  },
  {
    id: 'q3_checkin',
    topic: 'check_in',
    text: {
      en: 'How do you verify that a volunteer actually attended your event?',
      mk: 'Како потврдувате дека доброволец навистина присуствувал на вашиот настан?',
      sq: 'Si verifikoni që një vullnetar ka marrë pjesë vërtet në ngjarjen tuaj?',
    },
    options: [
      {
        id: 'q3_a',
        text: {
          en: 'Trust everyone automatically',
          mk: 'Автоматски верувајте на сите',
          sq: 'Besoni të gjithëve automatikisht',
        },
      },
      {
        id: 'q3_b',
        text: {
          en: 'Ask them to send a selfie',
          mk: 'Побарајте да испратат селфи',
          sq: 'Kërkoni të dërgojnë një selfie',
        },
      },
      {
        id: 'q3_c',
        text: {
          en: 'Use the in-app QR check-in system so attendance is verified on-site',
          mk: 'Користете го системот за QR чекирање во апликацијата за да се потврди присуството на лице место',
          sq: 'Përdorni sistemin e check-in me QR në aplikacion për verifikim në vend',
        },
      },
      {
        id: 'q3_d',
        text: {
          en: 'Write down names on paper',
          mk: 'Запишете имиња на хартија',
          sq: 'Shkruani emrat në letër',
        },
      },
    ],
    correctOptionId: 'q3_c',
  },
  {
    id: 'q4_weather',
    topic: 'operations',
    text: {
      en: 'If dangerous weather is forecast for your cleanup window, what is the best practice?',
      mk: 'Ако се очекува опасно време за терминот на чистењето, која е најдобрата практика?',
      sq: 'Nëse parashikohet mot i rrezikshëm për pastrimin, cila është praktika më e mirë?',
    },
    options: [
      {
        id: 'q4_a',
        text: {
          en: 'Ignore the forecast and go ahead',
          mk: 'Игнорирајте ја прогнозата и продолжете',
          sq: 'Injoroni parashikimin dhe vazhdoni',
        },
      },
      {
        id: 'q4_b',
        text: {
          en: 'Cancel or postpone and clearly tell registered volunteers in the app',
          mk: 'Откажете или одложете и јасно известете ги регистрираните доброволци во апликацијата',
          sq: 'Anuloni ose shtyni dhe njoftoni qartë vullnetarët e regjistruar në aplikacion',
        },
      },
      {
        id: 'q4_c',
        text: {
          en: 'Only tell people who ask',
          mk: 'Кажете им само на оние што ќе прашаат',
          sq: 'Thuajuni vetëm atyre që pyesin',
        },
      },
      {
        id: 'q4_d',
        text: {
          en: 'Assume everyone will check the news themselves',
          mk: 'Претпоставете дека сите сами ќе ги проверат вестите',
          sq: 'Supozoni se të gjithë vetë do të shohin lajmet',
        },
      },
    ],
    correctOptionId: 'q4_b',
  },
  {
    id: 'q5_waste',
    topic: 'operations',
    text: {
      en: 'When sorting collected waste, what should organizers prioritize?',
      mk: 'При сортирање на собраниот отпад, на што организаторите треба да дадат приоритет?',
      sq: 'Kur renditni mbeturinat e mbledhura, çfarë duhet të përparësojnë organizatorët?',
    },
    options: [
      {
        id: 'q5_a',
        text: {
          en: 'Mix everything in one bag to save time',
          mk: 'Мешајте се во една ќесија за да заштедите време',
          sq: 'Përzieni gjithçka në një qese për të kursyer kohë',
        },
      },
      {
        id: 'q5_b',
        text: {
          en: 'Follow local guidance: separate recyclables and dispose at proper facilities when possible',
          mk: 'Следете ги локалните упатства: одделете рециклажа и отфрлајте на соодветни места кога е можно',
          sq: 'Ndiqni udhëzimet lokale: ndani riciklimin dhe hidhni në objekte të përshtatshme kur është e mundur',
        },
      },
      {
        id: 'q5_c',
        text: {
          en: 'Leave bags at the site for someone else',
          mk: 'Оставете ги ќесиите на локацијата за некој друг',
          sq: 'Lërni qeset në vend për dikë tjetër',
        },
      },
      {
        id: 'q5_d',
        text: {
          en: 'Burn waste if it is faster',
          mk: 'Палете отпад ако е побрзо',
          sq: 'Djegni mbeturinat nëse është më shpejt',
        },
      },
    ],
    correctOptionId: 'q5_b',
  },
  {
    id: 'q6_inclusion',
    topic: 'inclusion',
    text: {
      en: 'How should you welcome volunteers with different abilities or backgrounds?',
      mk: 'Како да ги пречекате доброволците со различни способности или потекло?',
      sq: 'Si duhet t’i mirëpresni vullnetarët me aftësi ose prejardhje të ndryshme?',
    },
    options: [
      {
        id: 'q6_a',
        text: {
          en: 'Assign only the hardest tasks to new people',
          mk: 'Доделувајте им само најтешките задачи на новите',
          sq: 'Caktoni vetëm detyrat më të vështira për personat e rinj',
        },
      },
      {
        id: 'q6_b',
        text: {
          en: 'Offer clear roles, reasonable pacing, and ask how you can support participation',
          mk: 'Понудете јасни улоги, разумен темпо и прашајте како можете да го поддржите учеството',
          sq: 'Ofroni role të qarta, ritëm të arsyeshëm dhe pyetni si mund të mbështesni pjesëmarrjen',
        },
      },
      {
        id: 'q6_c',
        text: {
          en: 'Assume everyone can lift the same weight',
          mk: 'Претпоставете дека сите можат да кренат иста тежина',
          sq: 'Supozoni se të gjithë mund të ngrejnë të njëjtën peshë',
        },
      },
      {
        id: 'q6_d',
        text: {
          en: 'Skip the safety briefing to save time',
          mk: 'Прескокнете го безбедносниот брифинг за да заштедите време',
          sq: 'Anashkaloni briefing-un e sigurisë për të kursyer kohë',
        },
      },
    ],
    correctOptionId: 'q6_b',
  },
  {
    id: 'q7_privacy',
    topic: 'privacy',
    text: {
      en: 'What is the safest approach to personal contact details in the public event chat?',
      mk: 'Кој е најбезбедниот пристап кон личните контакти во јавниот чат на настанот?',
      sq: 'Cila është mënyra më e sigurt për të dhënat personale në bisedën publike të ngjarjes?',
    },
    options: [
      {
        id: 'q7_a',
        text: {
          en: 'Post your phone number so everyone can call you',
          mk: 'Објавете го вашиот телефон за сите да ве јават',
          sq: 'Postoni numrin tuaj që të gjithë të telefonojnë',
        },
      },
      {
        id: 'q7_b',
        text: {
          en: 'Ask volunteers to post their emails publicly',
          mk: 'Побарајте од доброволците да ги објават е-поштите јавно',
          sq: 'Kërkoni nga vullnetarët të postojnë email-et publikisht',
        },
      },
      {
        id: 'q7_c',
        text: {
          en: 'Keep sensitive personal data out of public chat; use official in-app channels',
          mk: 'Држете ги чувствителните лични податоци надвор од јавниот чат; користете официјални канали во апликацијата',
          sq: 'Mbajini të dhënat personale jashtë bisedës publike; përdorni kanalet zyrtare në aplikacion',
        },
      },
      {
        id: 'q7_d',
        text: {
          en: 'Share home addresses for carpooling without asking',
          mk: 'Споделувајте домашни адреси за споделување возило без прашање',
          sq: 'Ndani adresat e shtëpisë për carpooling pa pyetur',
        },
      },
    ],
    correctOptionId: 'q7_c',
  },
  {
    id: 'q8_evidence',
    topic: 'operations',
    text: {
      en: 'Why upload honest “after” cleanup photos in the app?',
      mk: 'Зошто да прикачувате искрени фотографии „потоа“ од чистењето во апликацијата?',
      sq: 'Pse të ngarkoni foto të ndershme “pas” pastrimit në aplikacion?',
    },
    options: [
      {
        id: 'q8_a',
        text: {
          en: 'They are optional and never used',
          mk: 'Тие се опционални и никогаш не се користат',
          sq: 'Janë opsionale dhe nuk përdoren kurrë',
        },
      },
      {
        id: 'q8_b',
        text: {
          en: 'They help the community see real impact and keep the platform trustworthy',
          mk: 'Им помагаат на заедницата да види вистински ефект и ја одржуваат платформата доверлива',
          sq: 'I ndihmojnë komunitetit të shohë ndikimin real dhe e mbajnë platformën të besueshme',
        },
      },
      {
        id: 'q8_c',
        text: {
          en: 'Only moderators see photos, so any image is fine',
          mk: 'Само модераторите ги гледаат фотографиите, па секоја слика е во ред',
          sq: 'Vetëm moderatorët i shohin fotot, prandaj çdo imazh është në rregull',
        },
      },
      {
        id: 'q8_d',
        text: {
          en: 'Stock internet photos are preferred',
          mk: 'Предпочитани се готови слики од интернет',
          sq: 'Preferohen foto të internetit',
        },
      },
    ],
    correctOptionId: 'q8_b',
  },
  {
    id: 'q9_emergency',
    topic: 'safety',
    text: {
      en: 'If someone is injured during a cleanup, what should the organizer do first?',
      mk: 'Ако некој се повреди за време на чистење, што прво треба да направи организаторот?',
      sq: 'Nëse dikush lëndohet gjatë pastrimit, çfarë duhet të bëjë fillimisht organizatori?',
    },
    options: [
      {
        id: 'q9_a',
        text: {
          en: 'Continue the event and deal with it later',
          mk: 'Продолжете со настанот и решавајте подоцна',
          sq: 'Vazhdoni ngjarjen dhe merreni më vonë',
        },
      },
      {
        id: 'q9_b',
        text: {
          en: 'Stop unsafe work, provide basic first aid if trained, and call local emergency services when needed',
          mk: 'Запрете небезбедна работа, пружете основна прва помош ако сте обучени и повикајте итна помош кога е потребно',
          sq: 'Ndërprini punën e pasigurt, jepni ndihmën e parë nëse jeni trajnuar dhe thirrni emergjencën kur duhet',
        },
      },
      {
        id: 'q9_c',
        text: {
          en: 'Ask volunteers to diagnose injuries online',
          mk: 'Побарајте од доброволците да дијагностицираат повреди онлајн',
          sq: 'Kërkoni nga vullnetarët të diagnostikojnë lëndimet online',
        },
      },
      {
        id: 'q9_d',
        text: {
          en: 'Avoid calling help to prevent attention',
          mk: 'Избегнувајте повикување помош за да не привлечете внимание',
          sq: 'Shmangni thirrjen e ndihmës për të mos tërhequr vëmendje',
        },
      },
    ],
    correctOptionId: 'q9_b',
  },
  {
    id: 'q10_capacity',
    topic: 'operations',
    text: {
      en: 'If your event reaches the maximum participants set in the app, what should you do?',
      mk: 'Ако настанот го достигне максимумот на учесници во апликацијата, што треба да направите?',
      sq: 'Nëse ngjarja arrin numrin maksimal të pjesëmarrësve në aplikacion, çfarë duhet të bëni?',
    },
    options: [
      {
        id: 'q10_a',
        text: {
          en: 'Let extra people join unofficially anyway',
          mk: 'Дозволете дополнителни луѓе неофицијално',
          sq: 'Lini njerëz shtesë të bashkohen jo zyrtarisht',
        },
      },
      {
        id: 'q10_b',
        text: {
          en: 'Respect the limit for safety and logistics; offer a waitlist or schedule another date',
          mk: 'Почитувајте го лимитот заради безбедност и логистика; понудете листа на чекање или друг термин',
          sq: 'Respektoni kufirin për siguri dhe logjistikë; ofroni listë pritjeje ose një datë tjetër',
        },
      },
      {
        id: 'q10_c',
        text: {
          en: 'Lower the limit without telling anyone',
          mk: 'Намалете го лимитот без да кажете никому',
          sq: 'Uljeni kufirin pa i thënë askujt',
        },
      },
      {
        id: 'q10_d',
        text: {
          en: 'Charge money at the gate for entry',
          mk: 'Наплатувајте на влезот',
          sq: 'Merrni para në hyrje',
        },
      },
    ],
    correctOptionId: 'q10_b',
  },
  {
    id: 'q11_declined',
    topic: 'moderation',
    text: {
      en: 'If moderators decline your event, what can you typically do next?',
      mk: 'Ако модераторите го одбијат настанот, што обично можете да направите потоа?',
      sq: 'Nëse moderatorët e refuzojnë ngjarjen, çfarë zakonisht mund të bëni më pas?',
    },
    options: [
      {
        id: 'q11_a',
        text: {
          en: 'Create duplicate events until one is approved',
          mk: 'Креирајте дупликат настани додека некој не се одобри',
          sq: 'Krijoni ngjarje të dyfishta derisa të aprovohet njëra',
        },
      },
      {
        id: 'q11_b',
        text: {
          en: 'Read the feedback, fix the issues, and resubmit through the app',
          mk: 'Прочитајте го фидбекот, поправете ги проблемите и поднесете повторно преку апликацијата',
          sq: 'Lexoni komentin, ndreqni problemet dhe paraqitni përsëri përmes aplikacionit',
        },
      },
      {
        id: 'q11_c',
        text: {
          en: 'Delete your account',
          mk: 'Избришете ја сметката',
          sq: 'Fshini llogarinë',
        },
      },
      {
        id: 'q11_d',
        text: {
          en: 'Ignore the decline and advertise off-platform only',
          mk: 'Игнорирајте го одбивањето и рекламирајте само надвор од платформата',
          sq: 'Injoroni refuzimin dhe reklamoni vetëm jashtë platformës',
        },
      },
    ],
    correctOptionId: 'q11_b',
  },
  {
    id: 'q12_disposal',
    topic: 'operations',
    text: {
      en: 'After the cleanup, what is the best practice for collected waste?',
      mk: 'По чистењето, која е најдобрата практика за собраниот отпад?',
      sq: 'Pas pastrimit, cila është praktika më e mirë për mbeturinat e mbledhura?',
    },
    options: [
      {
        id: 'q12_a',
        text: {
          en: 'Leave bags hidden at the site',
          mk: 'Оставете ги ќесиите сокриени на локацијата',
          sq: 'Lërni qeset të fshehura në vend',
        },
      },
      {
        id: 'q12_b',
        text: {
          en: 'Take waste to authorized disposal or recycling points following local rules',
          mk: 'Однесете го отпадот на овластени места за одлагање или рециклажа според локалните правила',
          sq: 'Çojini mbeturinat në pika të autorizuara të hedhjes ose riciklimit sipas rregullave vendase',
        },
      },
      {
        id: 'q12_c',
        text: {
          en: 'Burn mixed waste on-site if it is cold',
          mk: 'Палете мешан отпад на место ако е ладно',
          sq: 'Djegni mbeturina të përziera në vend nëse është ftohtë',
        },
      },
      {
        id: 'q12_d',
        text: {
          en: 'Dump in any river to wash it away',
          mk: 'Фрлајте во која било река за да се испере',
          sq: 'Hidhini në çdo lum që të lahet',
        },
      },
    ],
    correctOptionId: 'q12_b',
  },
  {
    id: 'q13_meeting',
    topic: 'operations',
    text: {
      en: 'How should you choose the meeting point for volunteers?',
      mk: 'Како да го изберете местото за средување со доброволците?',
      sq: 'Si duhet të zgjidhni pikën e takimit për vullnetarët?',
    },
    options: [
      {
        id: 'q13_a',
        text: {
          en: 'Pick a random spot each time without a map pin',
          mk: 'Берете случајно место без пин на мапа',
          sq: 'Zgjidhni një vend të rastësishëm pa pin në hartë',
        },
      },
      {
        id: 'q13_b',
        text: {
          en: 'Use a clear, reachable location tied to the event site and describe access in the description',
          mk: 'Користете јасна, достапна локација поврзана со настанот и опишете пристап во описот',
          sq: 'Përdorni një vend të qartë, të arritshëm, të lidhur me vendngjarjen dhe përshkruani aksesin',
        },
      },
      {
        id: 'q13_c',
        text: {
          en: 'Share only voice directions in private messages',
          mk: 'Споделувајте само усни упатства во приватни пораки',
          sq: 'Ndani vetëm udhëzime gojore në mesazhe private',
        },
      },
      {
        id: 'q13_d',
        text: {
          en: 'Ask people to wander until they find you',
          mk: 'Побарајте луѓето да шетаат додека не ве најдат',
          sq: 'Kërkoni njerëzit të enden derisa t’ju gjejnë',
        },
      },
    ],
    correctOptionId: 'q13_b',
  },
  {
    id: 'q14_minors',
    topic: 'safety',
    text: {
      en: 'When families bring children to a cleanup, what is the organizer’s responsibility?',
      mk: 'Кога семејства донесуваат деца на чистење, која е одговорноста на организаторот?',
      sq: 'Kur familjet sjellin fëmijë në pastrim, cila është përgjegjësia e organizatorit?',
    },
    options: [
      {
        id: 'q14_a',
        text: {
          en: 'Organizers become legal guardians of every child',
          mk: 'Организаторите стануваат законски старатели на секое дете',
          sq: 'Organizatorët bëhen kujdestarë ligjorë i çdo fëmije',
        },
      },
      {
        id: 'q14_b',
        text: {
          en: 'Ensure activities match the stated difficulty; remind parents/guardians they supervise their children',
          mk: 'Осигурајте дека активностите одговараат на наведената тешкотија; потсетете ги родителите дека тие ги надгледуваат децата',
          sq: 'Sigurohuni që aktivitetet përputhen me vështirësinë; kujtoni prindërit se ata mbikëqyrin fëmijët',
        },
      },
      {
        id: 'q14_c',
        text: {
          en: 'Assign children to work alone far from adults',
          mk: 'Доделете деца да работат сами далеку од возрасни',
          sq: 'Caktoni fëmijë të punojnë vetëm larg të rriturve',
        },
      },
      {
        id: 'q14_d',
        text: {
          en: 'Children are not allowed at cleanups',
          mk: 'Децата не се дозволени на чистења',
          sq: 'Fëmijët nuk lejohen në pastrime',
        },
      },
    ],
    correctOptionId: 'q14_b',
  },
  {
    id: 'q15_updates',
    topic: 'communication',
    text: {
      en: 'If the start time or meeting place changes last minute, what should you do?',
      mk: 'Ако се промени времето на почеток или местото на средување во последен момент, што да направите?',
      sq: 'Nëse ndryshon ora e fillimit ose vendi i takimit në minutën e fundit, çfarë duhet të bëni?',
    },
    options: [
      {
        id: 'q15_a',
        text: {
          en: 'Assume everyone will notice the change automatically',
          mk: 'Претпоставете дека сите автоматски ќе ја забележат промената',
          sq: 'Supozoni se të gjithë do ta vërejnë ndryshimin automatikisht',
        },
      },
      {
        id: 'q15_b',
        text: {
          en: 'Update the event in the app and post a clear note in event chat so joined volunteers are informed',
          mk: 'Ажурирајте го настанот во апликацијата и објавете јасна порака во чатот за да се известат приклучените доброволци',
          sq: 'Përditësoni ngjarjen në aplikacion dhe postoni një shënim të qartë në chat që të informohen vullnetarët',
        },
      },
      {
        id: 'q15_c',
        text: {
          en: 'Only tell people you know personally',
          mk: 'Кажете им само на луѓето што ги познавате лично',
          sq: 'Thuajuni vetëm njerëzve që i njihni personalisht',
        },
      },
      {
        id: 'q15_d',
        text: {
          en: 'Cancel without explanation',
          mk: 'Откажете без објаснување',
          sq: 'Anuloni pa shpjegim',
        },
      },
    ],
    correctOptionId: 'q15_b',
  },
  {
    id: 'q16_integrity',
    topic: 'integrity',
    text: {
      en: 'Why is it important to report accurate bag counts and attendance?',
      mk: 'Зошто е важно точно да се пријават бројот на ќесии и присуството?',
      sq: 'Pse është e rëndësishme të raportoni saktë numrin e qeseve dhe pjesëmarrjen?',
    },
    options: [
      {
        id: 'q16_a',
        text: {
          en: 'Inflated numbers look better for social media only',
          mk: 'Преувеличените бројки подобро изгледаат само на социјални мрежи',
          sq: 'Numrat e fryrë duken më mirë vetëm në rrjete sociale',
        },
      },
      {
        id: 'q16_b',
        text: {
          en: 'Accurate data keeps credits fair, helps funders trust outcomes, and improves planning',
          mk: 'Точните податоци ги држат поените фер, им помагаат на поддржувачите да веруваат во резултатите и ја подобруваат планирањето',
          sq: 'Të dhënat e sakta mbajnë drejt pikët, ndihmojnë besimin e financuesve dhe planifikimin',
        },
      },
      {
        id: 'q16_c',
        text: {
          en: 'Rough guesses are always acceptable',
          mk: 'Груби процени секогаш се прифатливи',
          sq: 'Supozimet e përafërta janë gjithmonë në rregull',
        },
      },
      {
        id: 'q16_d',
        text: {
          en: 'Only organizers see totals, so accuracy does not matter',
          mk: 'Само организаторите ги гледаат збировите, па точноста не е важна',
          sq: 'Vetëm organizatorët i shohin totalet, prandaj saktësia nuk ka rëndësi',
        },
      },
    ],
    correctOptionId: 'q16_b',
  },
  {
    id: 'q17_qr_rotate',
    topic: 'check_in',
    text: {
      en: 'If a check-in QR code may have been shared or photographed outside your group, what should you do?',
      mk: 'Ако QR за чекирање можеби е споделен или фотографиран надвор од вашата група, што да направите?',
      sq: 'Nëse kodi QR i check-in mund të jetë ndarë ose fotografuar jashtë grupit tuaj, çfarë duhet të bëni?',
    },
    options: [
      {
        id: 'q17_a',
        text: {
          en: 'Ignore it; QR codes never expire',
          mk: 'Игнорирајте; QR кодовите никогаш не истекуваат',
          sq: 'Injorojeni; kodet QR skadojnë kurrë',
        },
      },
      {
        id: 'q17_b',
        text: {
          en: 'Use the organizer check-in tools to rotate the session so new scans require a fresh QR',
          mk: 'Користете ги алатките за чекирање на организаторот за да ја ротирате сесијата за нови скенирања',
          sq: 'Përdorni mjetet e organizatorit për check-in për të rrotulluar sesionin që skanimet e reja të kërkojnë QR të ri',
        },
      },
      {
        id: 'q17_c',
        text: {
          en: 'Turn off the internet at the site',
          mk: 'Исклучете го интернетот на локацијата',
          sq: 'Fikeni internetin në vend',
        },
      },
      {
        id: 'q17_d',
        text: {
          en: 'Ask attendees to uninstall the app',
          mk: 'Побарајте од учесниците да ја деинсталираат апликацијата',
          sq: 'Kërkoni nga pjesëmarrësit të çinstalojnë aplikacionin',
        },
      },
    ],
    correctOptionId: 'q17_b',
  },
  {
    id: 'q18_moderators',
    topic: 'moderation',
    text: {
      en: 'Where should you go first if you need help with moderation or a serious safety concern on the platform?',
      mk: 'Каде прво да се обратите ако ви треба помош со модерација или сериозна безбедносна грижа на платформата?',
      sq: 'Ku duhet të shkoni fillimisht nëse ju duhet ndihmë me moderim ose shqetësim serioz sigurie në platformë?',
    },
    options: [
      {
        id: 'q18_a',
        text: {
          en: 'Publicly name and shame other users in chat',
          mk: 'Јавно именувајте и понижувајте други корисници во чат',
          sq: 'Emërtoni publikisht përdorues të tjerë në chat',
        },
      },
      {
        id: 'q18_b',
        text: {
          en: 'Use official in-app reporting and moderator channels rather than escalating in public posts',
          mk: 'Користете официјално пријавување во апликацијата и канали за модератори наместо ескалација во јавни објави',
          sq: 'Përdorni raportimin zyrtar në aplikacion dhe kanalet e moderatorëve në vend të eskalimit në postime publike',
        },
      },
      {
        id: 'q18_c',
        text: {
          en: 'Share private screenshots on social media',
          mk: 'Споделувајте приватни снимки од екран на социјални мрежи',
          sq: 'Ndani pamje të ekranit private në rrjete sociale',
        },
      },
      {
        id: 'q18_d',
        text: {
          en: 'Delete the event to hide the problem',
          mk: 'Избришете го настанот за да ја сокриете проблемот',
          sq: 'Fshini ngjarjen për të fshehur problemin',
        },
      },
    ],
    correctOptionId: 'q18_b',
  },
];

const QUESTION_BY_ID = new Map(ORGANIZER_QUIZ_QUESTIONS.map((q) => [q.id, q]));

export function resolveQuizLocale(acceptLanguage: string): 'en' | 'mk' | 'sq' {
  const lang = acceptLanguage.slice(0, 2).toLowerCase();
  return lang === 'mk' || lang === 'sq' ? lang : 'en';
}

export function getOrganizerQuizQuestionById(id: string): OrganizerQuizQuestion | undefined {
  return QUESTION_BY_ID.get(id);
}

function shuffleCopy<T>(items: T[]): T[] {
  const out = [...items];
  for (let i = out.length - 1; i > 0; i--) {
    const j = randomInt(i + 1);
    const tmp = out[i]!;
    out[i] = out[j]!;
    out[j] = tmp;
  }
  return out;
}

/**
 * Cryptographically secure random subset of distinct question ids.
 */
export function pickRandomQuestionIds(count: number): string[] {
  const all = ORGANIZER_QUIZ_QUESTIONS.map((q) => q.id);
  if (count > all.length) {
    throw new Error(`ORGANIZER_QUIZ_DRAW_SIZE (${count}) exceeds bank size (${all.length})`);
  }
  const pool = shuffleCopy(all);
  return pool.slice(0, count);
}

export type LocalizedQuizOption = { id: string; text: string };

export type LocalizedQuizQuestion = {
  id: string;
  text: string;
  options: LocalizedQuizOption[];
};

export function localizeQuestion(q: OrganizerQuizQuestion, lang: 'en' | 'mk' | 'sq'): LocalizedQuizQuestion {
  const text = q.text[lang] ?? q.text.en;
  const options = q.options.map((o) => ({
    id: o.id,
    text: o.text[lang] ?? o.text.en,
  }));
  return { id: q.id, text, options: shuffleCopy(options) };
}

export function buildShuffledQuizForQuestionIds(
  questionIds: string[],
  lang: 'en' | 'mk' | 'sq',
): LocalizedQuizQuestion[] {
  const out: LocalizedQuizQuestion[] = [];
  for (const id of questionIds) {
    const q = QUESTION_BY_ID.get(id);
    if (!q) {
      throw new Error(`Unknown organizer quiz question id: ${id}`);
    }
    out.push(localizeQuestion(q, lang));
  }
  return out;
}

export type OrganizerQuizAnswer = { questionId: string; selectedOptionId: string };

/**
 * Score answers against the bank for the exact ordered question set from the quiz session.
 */
export function scoreOrganizerQuizAnswers(
  orderedQuestionIds: string[],
  answers: OrganizerQuizAnswer[],
): { correctCount: number; totalQuestions: number; passed: boolean } {
  const totalQuestions = orderedQuestionIds.length;
  const expected = new Set(orderedQuestionIds);
  const byQ = new Map(answers.map((a) => [a.questionId, a.selectedOptionId]));

  if (byQ.size !== answers.length || byQ.size !== totalQuestions) {
    return { correctCount: 0, totalQuestions, passed: false };
  }
  for (const k of byQ.keys()) {
    if (!expected.has(k)) {
      return { correctCount: 0, totalQuestions, passed: false };
    }
  }

  let correctCount = 0;
  for (const qid of orderedQuestionIds) {
    const q = QUESTION_BY_ID.get(qid);
    if (!q) {
      return { correctCount: 0, totalQuestions, passed: false };
    }
    const selected = byQ.get(qid);
    if (selected == null) {
      return { correctCount: 0, totalQuestions, passed: false };
    }
    const optionIds = new Set(q.options.map((o) => o.id));
    if (!optionIds.has(selected)) {
      return { correctCount: 0, totalQuestions, passed: false };
    }
    if (selected === q.correctOptionId) {
      correctCount += 1;
    }
  }

  const passed = correctCount === totalQuestions;
  return { correctCount, totalQuestions, passed };
}
