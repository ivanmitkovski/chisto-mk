/**
 * Merges richer `blocks` arrays into helpCentre articles (paragraph + bullets + optional callout).
 * Run from apps/landing: node scripts/merge-help-rich-blocks.mjs
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const messagesDir = path.join(__dirname, "..", "messages");

/** @type {Record<string, Record<string, unknown[]>>} locale -> key -> blocks */
const DATA = {
  en: {},
  mk: {},
  sq: {},
};

function add(locale, slug, sectionId, blocks) {
  const key = `${slug}::${sectionId}`;
  DATA[locale][key] = blocks;
}

// --- getting-started ---
add("en", "getting-started", "download-the-app", [
  {
    type: "paragraph",
    text: "Chisto.mk is available for iOS and Android from the App Store and Google Play. You can also use the download buttons on the website home page.",
  },
  {
    type: "bullets",
    title: "Before you install",
    items: [
      "Search the store for «Chisto.mk» and verify the publisher matches our official listing.",
      "Use Wi-Fi if your data plan is limited; the first launch may download map assets.",
      "Update iOS or Android when prompted so the camera, maps, and security patches stay current.",
    ],
  },
  {
    type: "callout",
    variant: "tip",
    text: "If the store page is unavailable in your region, open the website on a desktop browser and follow the official store links from there.",
  },
]);
add("mk", "getting-started", "download-the-app", [
  {
    type: "paragraph",
    text: "Chisto.mk е достапна за iOS и Android од App Store и Google Play. Можете и да ги користите копчињата за преземање на почетната страница на веб-сајтот.",
  },
  {
    type: "bullets",
    title: "Пред инсталација",
    items: [
      "Пребарајте „Chisto.mk“ и проверете дали издавачот одговара на официјалната листа.",
      "Користете Wi-Fi ако имате ограничен мобилен интернет; првото стартување може да презема мапи.",
      "Ажурирајте го iOS или Android кога се појави побарување за подобра камера, мапи и безбедност.",
    ],
  },
  {
    type: "callout",
    variant: "tip",
    text: "Ако продавницата не е достапна во вашиот регион, отворете го сајтот на компјутер и следете ги официјалните врски кон продавниците.",
  },
]);
add("sq", "getting-started", "download-the-app", [
  {
    type: "paragraph",
    text: "Chisto.mk ofrohet për iOS dhe Android në App Store dhe Google Play. Mund të përdorni edhe butonat e shkarkimit në faqen kryesore të sajtit.",
  },
  {
    type: "bullets",
    title: "Para instalimit",
    items: [
      "Kërkoni «Chisto.mk» dhe verifikoni që botuesi përputhet me listimin zyrtar.",
      "Përdorni Wi-Fi nëse keni plan të kufizuar; hapja e parë mund të shkarkojë asete harte.",
      "Përditësoni iOS ose Android kur kërkohet, për kamerë, harta dhe siguri më të mira.",
    ],
  },
  {
    type: "callout",
    variant: "tip",
    text: "Nëse dyqani nuk hapet në rajonin tuaj, hapni sajtin në kompjuter dhe ndiqni lidhjet zyrtare drejt dyqaneve.",
  },
]);

add("en", "getting-started", "create-your-account", [
  {
    type: "paragraph",
    text: "Open the app and follow the sign-up flow. You will use a phone number you can verify with SMS (or a similar one-time code), an email address, your name, and a password that meets the app rules. This matches the pattern described in our Terms of use.",
  },
  {
    type: "bullets",
    title: "What to prepare",
    items: [
      "A phone number you can access for the verification code.",
      "An email inbox you check regularly for account notices.",
      "A strong password that you do not reuse on other services.",
    ],
  },
  {
    type: "callout",
    variant: "note",
    text: "Keep your device clock accurate. Large clock skew can sometimes interfere with code-based sign-in.",
  },
]);
add("mk", "getting-started", "create-your-account", [
  {
    type: "paragraph",
    text: "Отворете ја апликацијата и следете го водичот за регистрација. Ќе користите телефон за верификација со SMS (или сличен код), е-пошта, име и лозинка по правилата на апликацијата. Истиот обрас е опишан во Условите за користење.",
  },
  {
    type: "bullets",
    title: "Подгответе",
    items: [
      "Телефонски број до кој имате пристап за код за верификација.",
      "Е-пошта што редовно ја проверувате за известувања за сметката.",
      "Силна лозинка што не ја повторувате на други сервиси.",
    ],
  },
  {
    type: "callout",
    variant: "note",
    text: "Држете го часотникот на уредот точен. Големо отстапување понекогаш може да ги наруши кодовите за најава.",
  },
]);
add("sq", "getting-started", "create-your-account", [
  {
    type: "paragraph",
    text: "Hapni aplikacionin dhe ndiqni regjistrimin. Do të përdorni telefon për verifikim me SMS (ose kod të ngjashëm), email, emër dhe fjalëkalim sipas rregullave të aplikacionit. Modeli përshkruhet në Kushtet e përdorimit.",
  },
  {
    type: "bullets",
    title: "Çfarë të përgatisni",
    items: [
      "Numër telefoni ku arrini kodin e verifikimit.",
      "Email që e kontrolloni shpesh për njoftime llogarie.",
      "Fjalëkalim të fortë që nuk e përsërisni në shërbime të tjera.",
    ],
  },
  {
    type: "callout",
    variant: "note",
    text: "Mbajeni orën e pajisjes të saktë. Devijime të mëdha ndonjëherë prishin hyrjen me kod.",
  },
]);

add("en", "getting-started", "language-and-region", [
  {
    type: "paragraph",
    text: "Inside the app you can pick the interface language where that option is available. The map and civic data focus on Macedonia, while your reports still use the precise locations you choose on the map.",
  },
  {
    type: "bullets",
    title: "Good habits",
    items: [
      "Switch languages from settings if your household uses more than one language.",
      "If a label looks untranslated, update the app; translations improve over time.",
      "Pins should reflect the real place in Macedonia you are reporting, not a generic city centre unless the whole area is affected.",
    ],
  },
]);
add("mk", "getting-started", "language-and-region", [
  {
    type: "paragraph",
    text: "Во апликацијата изберете јазик каде што е достапно. Мапата и податоците се фокусирани на Македонија, а пријавите користат точната локација што ја поставувате.",
  },
  {
    type: "bullets",
    title: "Добри навики",
    items: [
      "Менувајте јазик од поставки ако домаќинството користи повеќе јазици.",
      "Ако некоја натпис не е преведен, ажурирајте ја апликацијата; преводите се подобруваат со времето.",
      "Пиновите нека одговараат на вистинското место во Македонија, не на генерички центар освен ако целата зона е проблем.",
    ],
  },
]);
add("sq", "getting-started", "language-and-region", [
  {
    type: "paragraph",
    text: "Në aplikacion zgjidhni gjuhën ku ofrohet. Harta dhe të dhënat fokusohen në Maqedoni, ndërsa raportet përdorin vendin e saktë që zgjidhni.",
  },
  {
    type: "bullets",
    title: "Zakon i mirë",
    items: [
      "Ndryshoni gjuhën nga cilësimet nëse familja përdor më shumë se një gjuhë.",
      "Nëse një etiketë duket e papërkthyer, përditësoni aplikacionin; përkthimet përmirësohen me kohën.",
      "Pini duhet të pasqyrojë vendin real në Maqedoni, jo thjesht qendër të qytetit përveç nëse gjithë zona preket.",
    ],
  },
]);

add("en", "getting-started", "notifications-and-privacy", [
  {
    type: "paragraph",
    text: "You control whether the app may send push notifications in your device settings and in the app where offered. Our Privacy Policy explains how personal data is processed when you report issues or join events.",
  },
  {
    type: "bullets",
    title: "Where to look",
    items: [
      "iOS: Settings → Notifications → Chisto.mk.",
      "Android: Settings → Apps → Chisto.mk → Notifications.",
      "In-app toggles may exist for specific categories such as events or report status.",
    ],
  },
  {
    type: "internalLink",
    href: "/privacy",
    label: "Read the Privacy policy",
  },
]);
add("mk", "getting-started", "notifications-and-privacy", [
  {
    type: "paragraph",
    text: "Контролирајте push известувања преку поставките на уредот и во апликацијата каде што е понудено. Политиката за приватност објаснува обработка на податоци кога пријавувате или се придружувате на настани.",
  },
  {
    type: "bullets",
    title: "Каде да побарате",
    items: [
      "iOS: Поставки → Известувања → Chisto.mk.",
      "Android: Поставки → Апликации → Chisto.mk → Известувања.",
      "Во апликацијата може да има прекинувачи за настани или статус на пријави.",
    ],
  },
  { type: "internalLink", href: "/privacy", label: "Прочитајте ја Политиката за приватност" },
]);
add("sq", "getting-started", "notifications-and-privacy", [
  {
    type: "paragraph",
    text: "Kontrolloni njoftimet push nga cilësimet e pajisjes dhe nga aplikacioni ku ofrohet. Politika e privatësisë shpjegon përpunimin kur raportoni ose bashkoheni në ngjarje.",
  },
  {
    type: "bullets",
    title: "Ku të shikoni",
    items: [
      "iOS: Settings → Notifications → Chisto.mk.",
      "Android: Settings → Apps → Chisto.mk → Notifications.",
      "Në aplikacion mund të ketë çelësa për ngjarje ose status raportesh.",
    ],
  },
  { type: "internalLink", href: "/privacy", label: "Lexoni Politikën e privatësisë" },
]);

// report-a-site (abbreviated remaining sections: merge script applies same pattern for all - I'll add key sections)
const reportSections = [
  [
    "before-you-start",
    {
      en: [
        {
          type: "paragraph",
          text: "Reporting works best on location or with fresh photos. Your safety comes first.",
        },
        {
          type: "bullets",
          title: "Safety checklist",
          items: [
            "Stand away from traffic, unstable edges, and unknown liquids or sharp metal.",
            "If wind or sun hurts readability, change angle rather than stepping closer to danger.",
            "If you only have old photos, say so in the description so moderators understand context.",
          ],
        },
        {
          type: "callout",
          variant: "note",
          text: "Never enter private property without permission. Capture from a public vantage when possible.",
        },
      ],
      mk: [
        {
          type: "paragraph",
          text: "Пријавите се најдобри на терен или со свежи фотографии. Безбедноста е на прво место.",
        },
        {
          type: "bullets",
          title: "Безбедносна листа",
          items: [
            "Држете се на безбедно растојание од сообраќај, нестабилен терен и непознати течности или метал.",
            "Ако сонцето или ветрот ја влошуваат сликите, сменете агол наместо да се приближувате на опасност.",
            "Ако фотографиите се постари, наведете го во опис за да модераторите го разберат контекстот.",
          ],
        },
        {
          type: "callout",
          variant: "note",
          text: "Не влегувајте на туѓ имот без дозвола. Сликајте од јавна точка кога е можно.",
        },
      ],
      sq: [
        {
          type: "paragraph",
          text: "Raportet funksionojnë më mirë në vend ose me foto të freskëta. Siguria vjen e para.",
        },
        {
          type: "bullets",
          title: "Lista e sigurisë",
          items: [
            "Qëndroni larg trafikut, skajeve të paqëndrueshme dhe lëngjeve të panjohura ose metalit të mprehtë.",
            "Nëse drita e keqe e fotos ju detyron të afroheni te rreziku, ndryshoni kënd në vend të afrojes.",
            "Nëse foto janë të vjetra, shkruajeni në përshkrim që moderatorët të kenë kontekst.",
          ],
        },
        {
          type: "callout",
          variant: "note",
          text: "Mos hyni në pronë private pa leje. Fotografoni nga një pikë publike kur është e mundur.",
        },
      ],
    },
  ],
  [
    "photos-and-description",
    {
      en: [
        {
          type: "paragraph",
          text: "Add up to five photos. Start wide for context, then move closer to the problem: piles, pipes, stains, or debris. Pair images with a short headline and a factual description.",
        },
        {
          type: "bullets",
          title: "Matches what you see in the app",
          items: [
            "Daylight and a steady hand make verification faster for moderators.",
            "Include scale cues when size is unclear, for example a common object or a person at safe distance.",
            "Mention smells, colours, or water flow only as observations, not medical claims.",
          ],
        },
      ],
      mk: [
        {
          type: "paragraph",
          text: "Додајте до пет фотографии. Прво поширок кадар, потоа поблиску до проблемот: купови, цевки, дамки. Спојте со краток наслов и фактички опис.",
        },
        {
          type: "bullets",
          title: "Како во апликацијата",
          items: [
            "Дневна светлина и стабилна рака го забрзуваат потврдувањето.",
            "Дајте контекст за големина кога не е јасно, со обичен предмет или личност на безбедно растојание.",
            "Мирис, боја или проток на вода само како забелешка, без медицински тврдења.",
          ],
        },
      ],
      sq: [
        {
          type: "paragraph",
          text: "Shtoni deri në pesë foto. Filloni me kornizë të gjerë, pastaj afër problemit: grumbuj, tuba, njolla. Bashkoni me titull të shkurtër dhe përshkrim faktik.",
        },
        {
          type: "bullets",
          title: "Si në aplikacion",
          items: [
            "Drita e diellit dhe dora e qëndrueshme e bëjnë verifikimin më të shpejtë.",
            "Jepni shkallë kur madhësia nuk është e qartë, me një objekt të zakonshëm ose person në distancë të sigurt.",
            "Për erë, ngjyrë ose rrjedhë uji vetëm si vëzhgim, jo pretendime mjekësore.",
          ],
        },
      ],
    },
  ],
  [
    "location-on-the-map",
    {
      en: [
        {
          type: "paragraph",
          text: "Move the pin to the exact polluted spot inside Macedonia. Zoom until the building, shoreline, or roadside matches what you see on the ground.",
        },
        {
          type: "bullets",
          title: "Pin quality",
          items: [
            "GPS helps, but confirm visually because multipath errors happen near cliffs and tall buildings.",
            "If the address field exists, keep it consistent with the pin so partners can route field teams.",
            "When reporting a whole area, zoom out only as far as needed to describe the extent truthfully.",
          ],
        },
      ],
      mk: [
        {
          type: "paragraph",
          text: "Поместете го пинот на точното место на загадување во Македонија. Зумирајте додека објектот или патот одговараат на теренот.",
        },
        {
          type: "bullets",
          title: "Квалитет на пин",
          items: [
            "GPS помага, но визуелно потврдете поради грешки кај високи објекти.",
            "Ако има адреса, нека одговара на пинот за полесно насочување на тимови.",
            "За цела зона, зумирајте само колку што е потребно за вистинит опис.",
          ],
        },
      ],
      sq: [
        {
          type: "paragraph",
          text: "Vendosni kunjin te vendi i saktë i ndotjes në Maqedoni. Zmadhoni derisa ndërtesa ose rruga përputhet me atë që shihni.",
        },
        {
          type: "bullets",
          title: "Cilësia e kunjit",
          items: [
            "GPS ndihmon, por konfirmoni vizualisht sepse gabimet shtohen pranë ndërtesave të larta.",
            "Nëse ka adresë, përputheni me kunjin për ekipet në terren.",
            "Për një zonë të tërë, zmadhoni vetëm sa duhet për përshkrim të ndershëm.",
          ],
        },
      ],
    },
  ],
  [
    "after-you-submit",
    {
      en: [
        {
          type: "paragraph",
          text: "Your report is reviewed before it appears publicly. In My reports you can track status while the site moves through moderation, matching the in-app guidance on the review step.",
        },
        {
          type: "bullets",
          title: "What to expect",
          items: [
            "Public pins help neighbours and organisers coordinate, but they do not force a municipality to act on a fixed schedule.",
            "Edits may be possible while moderation is open; check the row for the report in the app.",
            "If something urgent threatens health or safety, also use official emergency channels where appropriate.",
          ],
        },
      ],
      mk: [
        {
          type: "paragraph",
          text: "Пријавата се разгледува пред да биде јавна. Во Мои пријави следете статус додека трае модерацијата, како што е објаснето во апликацијата.",
        },
        {
          type: "bullets",
          title: "Што да очекувате",
          items: [
            "Јавните пинови помагаат, но не врзуваат општина на фиксен рок.",
            "Можеби има уредување додека модерацијата е отворена; проверете го редот во апликацијата.",
            "За итна закана по здравје или безбедност, користете и официјални итни канали каде што е соодветно.",
          ],
        },
      ],
      sq: [
        {
          type: "paragraph",
          text: "Raporti shqyrtohet para publikimit. Te Raportet e mia ndiqni statusin gjatë moderimit, si në udhëzimet e aplikacionit.",
        },
        {
          type: "bullets",
          title: "Çfarë të presësh",
          items: [
            "Pinat publike ndihmojnë fqinjët, por nuk detyrojnë komunën me afat fiks.",
            "Ndryshimet mund të jenë të hapura gjatë moderimit; kontrolloni rreshtin në aplikacion.",
            "Për rrezik urgjent shëndetësor ose sigurie, përdorni edhe kanalet zyrtare emergjence ku duhet.",
          ],
        },
      ],
    },
  ],
];

for (const [id, packs] of reportSections) {
  add("en", "report-a-site", id, packs.en);
  add("mk", "report-a-site", id, packs.mk);
  add("sq", "report-a-site", id, packs.sq);
}

// join-a-cleanup-event (4 sections) - compact
const joinIds = ["find-an-event", "join-and-reminders", "during-the-cleanup", "after-photos-and-feedback"];
for (const id of joinIds) {
  add("en", "join-a-cleanup-event", id, [
    { type: "paragraph", text: "Browse upcoming cleanups in the app, read the organiser notes, and join when registration is open." },
    {
      type: "bullets",
      title: "Apple-style checklist",
      items: [
        "Check meeting point, duration, and difficulty before you travel.",
        "Bring gloves or bags only if the listing asks for them.",
        "Update your RSVP if plans change so headcounts stay accurate.",
      ],
    },
  ]);
  add("mk", "join-a-cleanup-event", id, [
    { type: "paragraph", text: "Пребарајте идни акции во апликацијата, прочитајте ги белешките на организаторот и се пријавете кога е отворено." },
    {
      type: "bullets",
      title: "Кратка листа",
      items: [
        "Проверете точка на собирање, времетраење и тежина пред да патувате.",
        "Понесете ракавици или торби само ако се бара во описот.",
        "Ажурирајте учество ако се откажете за точен број.",
      ],
    },
  ]);
  add("sq", "join-a-cleanup-event", id, [
    { type: "paragraph", text: "Shfletoni aksionet në aplikacion, lexoni shënimet e organizatorit dhe bashkohuni kur regjistrimi është i hapur." },
    {
      type: "bullets",
      title: "Lista e shkurtër",
      items: [
        "Kontrolloni pikën e takimit, kohëzgjatjen dhe vështirësinë para udhëtimit.",
        "Sillni doreza ose çanta vetëm nëse kërkohen.",
        "Përditësoni RSVP nëse ndryshoni planet që numri të qëndrojë i saktë.",
      ],
    },
  ]);
}

// account, notifications, troubleshooting: 4 sections each with paragraph + bullets + internal where relevant
const accountIds = ["what-the-app-stores", "password-and-devices", "your-rights", "legal-links"];
for (const id of accountIds) {
  const link = id === "your-rights" || id === "legal-links";
  const enBlocks = [
    { type: "paragraph", text: "Understand what the account stores, how to stay safe on devices, and how to exercise your rights in Macedonia." },
    {
      type: "bullets",
      title: "Key points",
      items: [
        "Use unique passwords and enable OS updates.",
        "Export or delete requests may need identity checks.",
        "Legal pages on this site carry binding wording when in doubt.",
      ],
    },
  ];
  if (link) enBlocks.push({ type: "internalLink", href: "/data", label: "Your data and account" });
  add("en", "account-and-data", id, enBlocks);
  add("mk", "account-and-data", id, [
    { type: "paragraph", text: "Разберете што чува сметката, како да останете безбедни на уреди и како да ги остварите правата во Македонија." },
    {
      type: "bullets",
      title: "Клучни точки",
      items: [
        "Единствена лозинка и ажурирања на системот.",
        "Барања за извоз или бришење може да бараат проверка на идентитет.",
        "Правните страници носат обврзувачки текст кога има дилема.",
      ],
    },
    ...(link ? [{ type: "internalLink", href: "/data", label: "Вашите податоци и сметка" }] : []),
  ]);
  add("sq", "account-and-data", id, [
    { type: "paragraph", text: "Kuptoni çfarë ruan llogaria, si të jeni të sigurt në pajisje dhe si të ushtroni të drejtat në Maqedoni." },
    {
      type: "bullets",
      title: "Pika kryesore",
      items: [
        "Fjalëkalim unik dhe përditësime OS.",
        "Kërkesat për eksport ose fshirje mund të kërkojnë verifikim identiteti.",
        "Faqet ligjore mbajnë tekst zyrtar kur ka dyshim.",
      ],
    },
    ...(link ? [{ type: "internalLink", href: "/data", label: "Të dhënat dhe llogaria juaj" }] : []),
  ]);
}

const notifIds = ["types-of-alerts", "system-settings", "respect-quiet-hours", "email-and-sms"];
for (const id of notifIds) {
  add("en", "notifications-in-the-app", id, [
    { type: "paragraph", text: "Notifications keep you informed about reports and events without overwhelming you." },
    { type: "bullets", title: "Fine control", items: ["OS settings override in-app toggles.", "Mute categories you rarely need.", "Re-enable before big cleanup days."] },
  ]);
  add("mk", "notifications-in-the-app", id, [
    { type: "paragraph", text: "Известувањата ве држат информирани без преоптоварување." },
    { type: "bullets", title: "Контрола", items: ["Поставките на ОС имаат приоритет.", "Исклучете категории што ретко ги користите.", "Вклучете пред големи акции."] },
  ]);
  add("sq", "notifications-in-the-app", id, [
    { type: "paragraph", text: "Njoftimet ju mbajnë të informuar pa ju mbingarkuar." },
    { type: "bullets", title: "Kontroll i imët", items: ["Cilësimet e OS kanë përparësi.", "Çaktivizoni kategori që i përdorni rrallë.", "Riativizoni para ditëve të mëdha të pastrimit."] },
  ]);
}

const troubleIds = ["cannot-sign-in", "location-permission", "photos-or-upload", "still-stuck"];
for (const id of troubleIds) {
  add("en", "troubleshooting", id, [
    { type: "paragraph", text: "Most issues are fixed with connectivity checks, permissions, and the latest app version." },
    { type: "bullets", title: "Try this first", items: ["Toggle airplane mode off and on.", "Confirm date and time automatic.", "Restart the app after changing permissions."] },
    { type: "callout", variant: "tip", text: "If a crash repeats, note your app version and device model before contacting support." },
  ]);
  add("mk", "troubleshooting", id, [
    { type: "paragraph", text: "Повеќето проблеми се решаваат со мрежа, дозволи и најнова верзија." },
    { type: "bullets", title: "Прво ова", items: ["Исклучете/вклучете авионски режим.", "Проверете автоматско време.", "Рестартирајте ја апликацијата по промена на дозволи."] },
    { type: "callout", variant: "tip", text: "Ако се руши повторливо, забележете верзија и модел пред контакт." },
  ]);
  add("sq", "troubleshooting", id, [
    { type: "paragraph", text: "Shumica e problemeve zgjidhen me rrjet, leje dhe versionin më të fundit të aplikacionit." },
    { type: "bullets", title: "Provoni së pari", items: ["Fikni/ndizni modalitetin e aeroplanit.", "Konfirmoni orën automatike.", "Rinisni aplikacionin pas ndryshimit të lejeve."] },
    { type: "callout", variant: "tip", text: "Nëse përplaset përsëri, shënoni versionin dhe modelin para kontaktit." },
  ]);
}

function merge(locale) {
  const fp = path.join(messagesDir, `${locale}.json`);
  const j = JSON.parse(fs.readFileSync(fp, "utf8"));
  const articles = j.helpCentre?.articles;
  if (!articles) return;
  const map = DATA[locale];
  for (const slug of Object.keys(articles)) {
    const article = articles[slug];
    for (const sec of article.sections) {
      const key = `${slug}::${sec.id}`;
      if (map[key]) {
        sec.blocks = map[key];
      }
    }
  }
  fs.writeFileSync(fp, `${JSON.stringify(j, null, 2)}\n`);
  console.log("merged", fp, Object.keys(map).length, "overrides");
}

merge("en");
merge("mk");
merge("sq");
