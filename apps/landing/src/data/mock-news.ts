import { locales, type AppLocale } from "@/i18n/routing";

export type NewsCategory = "release" | "partnership" | "community" | "product";

export type LocalizedNewsContent = {
  title: string;
  excerpt: string;
  body: string[];
};

export type NewsPostMock = {
  slug: string;
  publishedAt: string;
  category: NewsCategory;
  coverImage?: string;
  content: Record<AppLocale, LocalizedNewsContent>;
};

const LOCALES = locales;

function isAppLocale(s: string): s is AppLocale {
  return LOCALES.includes(s as AppLocale);
}

const MOCK_NEWS_POSTS: NewsPostMock[] = [
  {
    slug: "chisto-1-2-map-and-actions",
    publishedAt: "2026-03-15T10:00:00.000Z",
    category: "release",
    coverImage: "/news/cover-abstract-1.svg",
    content: {
      mk: {
        title: "Chisto.mk 1.2: појасна мапа и екo-акции до пријавите",
        excerpt:
          "Нова верзија на апликацијата со подобрена мапа, филтри и листа на акции за чистење покрај пријавите на истото место.",
        body: [
          "Објавуваме верзија 1.2 фокусирана на тоа што корисниците најмногу го бараа: полесно да се снајдат на мапата и побрзо да пронајдат начин да се вклучат.",
          "Мапата сега поддржува појасни филтри по тип на проблем и временски опсег. Пријавите се групираат поинтуитивно кога има многу пинови во иста област.",
          "Кога организатор објавува еко-акција или чистење, таа се појавува во контекст на пријавите за да видите каде веќе има иницијатива и како да се приклучите.",
          "Ажурирајте ја апликацијата од App Store или Google Play за да ги добиете сите промени.",
        ],
      },
      en: {
        title: "Chisto.mk 1.2: clearer map and eco-actions next to reports",
        excerpt:
          "A new app release with a clearer map, filters, and clean-up listings alongside reports in the same area.",
        body: [
          "We are shipping 1.2 with what people asked for most: easier map reading and faster ways to get involved.",
          "The map supports clearer filters by issue type and time range. Pins cluster more intuitively when many reports sit in the same neighbourhood.",
          "When someone publishes an eco action or clean-up, it appears in context with nearby reports so you can see where initiatives already exist and how to join.",
          "Update the app from the App Store or Google Play to get the full set of changes.",
        ],
      },
      sq: {
        title: "Chisto.mk 1.2: hartë më e qartë dhe veprime ekologjike pranë raporteve",
        excerpt:
          "Version i ri i aplikacionit me hartë më të qartë, filtra dhe lista pastrimi pranë raporteve në të njëjtën zonë.",
        body: [
          "Po publikojmë 1.2 me atë që përdoruesit kërkuan më shpesh: lexim më të lehtë të hartës dhe mënyra më të shpejta për t'u përfshirë.",
          "Harta mbështet filtra më të qartë sipas llojit të problemit dhe intervalit kohor. Pinat grupohen më intuitivisht kur ka shumë raporte në të njëjtin lagje.",
          "Kur dikush publikon një veprim ekologjik ose pastrim, ai shfaqet në kontekst me raportet aty pranë që të shihni ku ekzistojnë tashmë nisma dhe si të bashkoheni.",
          "Përditësoni aplikacionin nga App Store ose Google Play për të marrë të gjitha ndryshimet.",
        ],
      },
    },
  },
  {
    slug: "partnership-local-ngos-2026",
    publishedAt: "2026-03-08T14:30:00.000Z",
    category: "partnership",
    coverImage: "/news/cover-abstract-2.svg",
    content: {
      mk: {
        title: "Соработка со локални еколошки организации",
        excerpt:
          "Заедно со партнери од Скопје и регионот работиме на подобро поврзување на граѓански пријави со теренски активности.",
        body: [
          "Chisto.mk останува независна граѓанска платформа, но веруваме дека траен ефект доаѓа кога податоците од мапата ќе ги користат и групите што веќе чистат и едуцираат на терен.",
          "Оваа соработка значи заеднички настани, споделување на најдобри практики и понекогаш ко-брендирани акции каде што апликацијата е алатка за координација.",
          "Доколку сте дел од организација што сака да се поврзе, пишете ни преку контакт-формата со краток опис на вашата работа.",
        ],
      },
      en: {
        title: "Partnership with local environmental NGOs",
        excerpt:
          "Together with partners in Skopje and the region we are connecting civic reports more closely with field work.",
        body: [
          "Chisto.mk stays an independent civic platform, but lasting impact comes when map data is also used by groups already cleaning and educating on the ground.",
          "This partnership means joint events, sharing good practices, and occasionally co-branded actions where the app is a coordination tool.",
          "If you represent an organisation that wants to connect, write us via the contact form with a short description of your work.",
        ],
      },
      sq: {
        title: "Partneritet me OJQ-të vendase mjedisore",
        excerpt:
          "Bashkë me partnerë në Shkup dhe rajon lidhim më ngushtë raportet qytetare me punën në terren.",
        body: [
          "Chisto.mk mbetet platformë e pavarur qytetare, por ndikimi i qëndrueshëm vjen kur të dhënat e hartës përdoren edhe nga grupet që tashmë pastrojnë dhe edukojnë në terren.",
          "Ky partneritet do të thotë ngjarje të përbashkëta, ndarje praktikash të mira dhe herë pas here aksione me markë të përbashkët ku aplikacioni është mjet koordinimi.",
          "Nëse përfaqësoni një organizatë që dëshiron të lidhet, na shkruani përmes formës së kontaktit me një përshkrim të shkurtër të punës suaj.",
        ],
      },
    },
  },
  {
    slug: "vodno-cleanup-march-recap",
    publishedAt: "2026-03-01T09:00:00.000Z",
    category: "community",
    content: {
      mk: {
        title: "Рекапитулација: акција за чистење на Водно",
        excerpt:
          "Петнаесетина волонтери собраа отпад по обележаната патека. Дел од пријавите од апликацијата беа потврдени на терен.",
        body: [
          "Во саботата на крајот на февруари се сретнавме на паркингот под Водно и ја поминавме патеката кон средишниот крст, со фокус на пластика и мали отпадоци.",
          "Корисниците на Chisto.mk претходно беа пријавиле неколку точки долж патеката; дел од нив ги обележавме како решени по акцијата, дел останува за следниот круг.",
          "Благодарност до сите што дојдоа. Следна акција ќе ја објавиме во апликацијата кога ќе ја имаме датумот.",
        ],
      },
      en: {
        title: "Recap: Vodno trail clean-up",
        excerpt:
          "About fifteen volunteers collected litter along the marked trail. Some in-app reports were verified on the ground.",
        body: [
          "On the last Saturday of February we met at the Vodno car park and walked toward the middle cross, focusing on plastic and small litter.",
          "Chisto.mk users had already flagged several spots along the route; we marked some as addressed after the action and left others for a follow-up round.",
          "Thanks to everyone who joined. We will post the next action in the app once the date is fixed.",
        ],
      },
      sq: {
        title: "Përmbledhje: pastrim në shtigjet e Vodnos",
        excerpt:
          "Rreth pesëmbëdhjetë vullnetarë mblodhën mbeturina përgjatë shtigjit. Disa raporte nga aplikacioni u verifikuan në terren.",
        body: [
          "Të shtunën e fundit të shkurtit u takuam në parkingun e Vodnos dhe ecëm drejt kryqit të mesit, me fokus në plastikë dhe mbeturina të vogla.",
          "Përdoruesit e Chisto.mk kishin shënuar më parë disa pika përgjatë rrugës; disa i shënuam si të adresuara pas aksionit dhe të tjerat i lamë për një raund tjetër.",
          "Faleminderit të gjithëve që erdhën. Aksionin tjetër do ta postojmë në aplikacion sapo të kemi datën.",
        ],
      },
    },
  },
  {
    slug: "report-clusters-on-the-map",
    publishedAt: "2026-02-20T11:00:00.000Z",
    category: "product",
    coverImage: "/news/cover-abstract-1.svg",
    content: {
      mk: {
        title: "Како работат кластерите на мапата",
        excerpt:
          "Кога има многу пријави на исто место, мапата ги групира за полесно читање. Еве кратко објаснување.",
        body: [
          "Зумирајте на густа област и пријавите се собираат во еден пин со број. Допрете за да ја видите листата и да отворите детали.",
          "Ова не менува податоците зад секоја пријава — само начинот на приказ за да не се преклопуваат стотици маркери.",
          "Ако нешто изгледа погрешно групирано, пријавете ни преку контакт за да го провериме со следното ажурирање.",
        ],
      },
      en: {
        title: "How report clusters work on the map",
        excerpt:
          "When many reports sit in the same area, the map groups them for readability. Here is a short explanation.",
        body: [
          "Zoom into a dense area and reports bundle into one pin with a count. Tap to see the list and open details.",
          "This does not change the data behind each report — only the display so hundreds of markers do not overlap.",
          "If clustering ever looks wrong, contact us so we can review it for a future update.",
        ],
      },
      sq: {
        title: "Si funksionojnë grumbullimet e raporteve në hartë",
        excerpt:
          "Kur shumë raporte janë në të njëjtën zonë, harta i grupon për lexueshmëri. Ja një shpjegim i shkurtër.",
        body: [
          "Zmadhoni një zonë të dendur dhe raportet bashkohen në një pin me numër. Prekni për të parë listën dhe për të hapur detajet.",
          "Kjo nuk ndryshon të dhënat pas çdo raporti — vetëm mënyrën e shfaqjes që qindra shenja të mos mbivendosen.",
          "Nëse grupimi duket i gabuar, na kontaktoni që ta rishikojmë për një përditësim të ardhshëm.",
        ],
      },
    },
  },
  {
    slug: "air-quality-photos-beta",
    publishedAt: "2026-02-10T08:00:00.000Z",
    category: "product",
    content: {
      mk: {
        title: "Бета: пријави за загаден воздух со фотографија",
        excerpt:
          "Тестираме поедноставен тек за документирање чад и магла со слика и локација за подобра видливост на проблемот.",
        body: [
          "Загадениот воздух често е тежок за објаснување само со текст. Затоа додадовме можност за брза фотографија и пин на мапата.",
          "Оваа функција е во бета: може да се менува по повратни информации. Не ја користете за лични податоци на трети лица.",
          "Вашите пријави им помагаат на други граѓани и на организации да гледаат каде проблемот се повторува.",
        ],
      },
      en: {
        title: "Beta: air-quality reports with a photo",
        excerpt:
          "We are testing a simpler flow to document smoke and haze with a picture and location for better visibility.",
        body: [
          "Poor air is hard to explain with text alone. We added a quick photo plus map pin flow.",
          "This feature is in beta and may change with feedback. Do not capture identifiable third parties without consent.",
          "Your reports help other citizens and organisations see where problems repeat.",
        ],
      },
      sq: {
        title: "Beta: raporte për cilësinë e ajrit me foto",
        excerpt:
          "Po testojmë një rrjedhë më të thjeshtë për të dokumentuar tymin dhe mjegullën me foto dhe vendndodhje.",
        body: [
          "Ajri i keq është i vështirë për t'u shpjeguar vetëm me tekst. Shtuam një foto të shpejtë plus pin në hartë.",
          "Kjo veçori është në beta dhe mund të ndryshojë me komente. Mos kapni persona të tretë të identifikueshëm pa pëlqim.",
          "Raportet tuaja i ndihmojnë qytetarët dhe organizatat të shohin ku problemet përsëriten.",
        ],
      },
    },
  },
  {
    slug: "year-ahead-civic-mapping",
    publishedAt: "2026-01-15T12:00:00.000Z",
    category: "community",
    coverImage: "/news/cover-abstract-2.svg",
    content: {
      mk: {
        title: "Што планираме за граѓанското мапирање годинава",
        excerpt:
          "Краток преглед на приоритети: подобра мапа, повеќе акции и отворен дијалог со општини каде што е можно.",
        body: [
          "Почнуваме 2026 со јасна цел: Chisto.mk да остане доверлива алатка за документирање на теренот и за поврзување на волонтери.",
          "Ќе инвестираме во перформанси и пристапност, повеќе јазична поддржка каде што недостига, и појасни извештаи за јавноста.",
          "Сакаме дијалог со општините каде што има подготвеност за податочно поткрепени интервенции — без да ја замениме официјалната постапка.",
        ],
      },
      en: {
        title: "What we plan for civic mapping this year",
        excerpt:
          "A short look at priorities: a better map, more actions, and open dialogue with municipalities where possible.",
        body: [
          "We are starting 2026 with a clear goal: Chisto.mk should stay a trusted tool for documenting what people see on the ground and connecting volunteers.",
          "We will invest in performance and accessibility, language support where it is missing, and clearer public-facing summaries.",
          "We want dialogue with municipalities that are ready for data-informed interventions — without replacing official procedures.",
        ],
      },
      sq: {
        title: "Çfarë planifikojmë për hartimin qytetar këtë vit",
        excerpt:
          "Një vështrim i shkurtër në prioritete: hartë më e mirë, më shumë veprime dhe dialog i hapur me bashkitë ku është e mundur.",
        body: [
          "Fillojmë 2026 me një qëllim të qartë: Chisto.mk të mbetet një mjet i besueshëm për dokumentimin në terren dhe lidhjen e vullnetarëve.",
          "Do të investojmë në performancë dhe aksesueshmëri, mbështetje gjuhësore ku mungon dhe përmbledhje më të qarta për publikun.",
          "Duam dialog me bashkitë që janë gati për ndërhyrje të informuara nga të dhënat — pa zëvendësuar procedurat zyrtare.",
        ],
      },
    },
  },
];

export type ResolvedNewsPost = {
  slug: string;
  publishedAt: string;
  category: NewsCategory;
  coverImage?: string;
  title: string;
  excerpt: string;
  body: string[];
};

function normalizeLocale(locale: string): AppLocale {
  return isAppLocale(locale) ? locale : "mk";
}

export function getNewsPosts(locale: string): ResolvedNewsPost[] {
  const loc = normalizeLocale(locale);
  return [...MOCK_NEWS_POSTS]
    .sort((a, b) => Date.parse(b.publishedAt) - Date.parse(a.publishedAt))
    .map((p) => ({
      slug: p.slug,
      publishedAt: p.publishedAt,
      category: p.category,
      ...(p.coverImage !== undefined && p.coverImage !== ""
        ? { coverImage: p.coverImage }
        : {}),
      ...p.content[loc],
    }));
}

export function getNewsPostBySlug(locale: string, slug: string): ResolvedNewsPost | null {
  const post = MOCK_NEWS_POSTS.find((p) => p.slug === slug);
  if (!post) return null;
  const loc = normalizeLocale(locale);
  return {
    slug: post.slug,
    publishedAt: post.publishedAt,
    category: post.category,
    ...(post.coverImage !== undefined && post.coverImage !== ""
      ? { coverImage: post.coverImage }
      : {}),
    ...post.content[loc],
  };
}

export function getAllNewsSlugs(): string[] {
  return MOCK_NEWS_POSTS.map((p) => p.slug);
}

export function getAllNewsStaticParams(): { locale: AppLocale; slug: string }[] {
  const slugs = getAllNewsSlugs();
  const out: { locale: AppLocale; slug: string }[] = [];
  for (const locale of LOCALES) {
    for (const slug of slugs) {
      out.push({ locale, slug });
    }
  }
  return out;
}
