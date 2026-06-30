import type { PrismaClient } from '../src/prisma-client';
import { paragraphsToBody } from '../src/news/services/news-posts-validation';
import type { NewsTranslations } from '../src/news/types/news.types';

const LAUNCH_SLUG = 'chisto-mk-ios-app-store-launch-2026';

const LAUNCH_TRANSLATIONS: NewsTranslations = {
  en: {
    title:
      'Chisto.mk launches on the App Store, bringing pollution reporting to iPhone users in North Macedonia',
    excerpt:
      "The civic environmental platform went live on Apple's App Store on 23 June, offering free map-based reporting and cleanup events for residents across the country.",
    body: paragraphsToBody([
      'SKOPJE, 23 June 2026. Chisto.mk, the civic environmental platform developed by the Ekohab association, is now available to iPhone users in North Macedonia through the App Store.',
      'The platform lets citizens document pollution sites with photographs, precise location data, and short descriptions. Each report appears on a shared map that residents, volunteers, and organisations can browse without creating an account on the web.',
      'Inside the app, users can filter reports by issue type, follow developments at specific sites, and discover cleanup events published by organisers in the same area. The design links what people see on the ground with coordinated community action.',
      '"Mobile access was the missing piece," a spokesperson for the Chisto.mk team at Ekohab said on Tuesday. "People often notice illegal dumping or smoke while walking home. Now they can file a report in seconds, with evidence visible on the map for everyone to see."',
      'The app is free to download. It is listed on the App Store as Chisto.mk. Users who prefer the website can also open the download section at chisto.mk.',
      'Chisto.mk began as a web-based civic tool for mapping environmental problems across Macedonia. The iPhone release is aimed at on-the-spot reporting when someone is in the field and does not have a laptop at hand.',
      "Tuesday's launch covers iOS only. The team confirmed that an Android version is not part of this release and gave no date for other platforms.",
      'Further announcements will be published on the Chisto.mk news page. Organisations and journalists with questions can reach the team through the contact form at chisto.mk.',
    ]),
  },
  mk: {
    title: 'Chisto.mk на App Store: граѓанско пријавување загадување достапно на iPhone',
    excerpt:
      'На 23 јуни граѓанската еколошка платформа за iPhone се објави на App Store со бесплатно мапско пријавување и акции за чистење низ државата.',
    body: paragraphsToBody([
      'СКОПЈЕ, 23 јуни 2026. Chisto.mk, граѓанската еколошка платформа развиена од здружението Екохаб, од денес е достапна за корисници на iPhone во Северна Македонија преку App Store.',
      'Платформата им овозможува на граѓаните да документираат загадени места со фотографии, прецизна локација и краток опис. Секоја пријава се појавува на заедничка мапа што ја можат да ја прегледуваат жители, волонтери и организации.',
      'Во апликацијата корисниците можат да филтрираат пријави по тип на проблем, да ги следат промените на конкретни локации и да пронајдат акции за чистење објавени од организатори во истата област. Целта е теренското набљудување да се поврзе со координирана заедничка акција.',
      '"Мобилниот пристап беше недостасувачкиот дел," изјави портпарол на тимот на Chisto.mk во Екохаб во вторникот. "Луѓето често забележуваат нелегално депонирање или чад додека одат дома. Сега можат да пријават за неколку секунди, со доказ видлив на мапата за сите."',
      'Апликацијата е бесплатна за преземање. На App Store е објавена под името Chisto.mk. Корисниците што претпочитаат веб-страница можат да ја отворат секцијата за преземање на chisto.mk.',
      'Chisto.mk започна како веб-алатка за мапирање на еколошки проблеми низ Македонија. Верзијата за iPhone е наменета за пријавување на место, кога некој е на терен без лаптоп.',
      'Објавувањето во вторникот опфаќа само iOS. Тимот потврди дека верзија за Android не е дел од оваа објава и не даде датум за други платформи.',
      'Следните соопштенија ќе бидат објавени на страницата за новости на Chisto.mk. Организации и новинари со прашања можат да го контактираат тимот преку контакт-формата на chisto.mk.',
    ]),
  },
  sq: {
    title:
      'Chisto.mk në App Store: raportimi i ndotjes për përdoruesit e iPhone në Maqedoninë e Veriut',
    excerpt:
      'Më 23 qershor platforma qytetare mjedisore për iPhone u publikua në App Store me raportim falas në hartë dhe ngjarje pastrimi në të gjithë vendin.',
    body: paragraphsToBody([
      'SHKUP, 23 qershor 2026. Chisto.mk, platforma qytetare mjedisore e zhvilluar nga shoqata Ekohab, tani është e disponueshme për përdoruesit e iPhone në Maqedoninë e Veriut përmes App Store.',
      'Platforma u lejon qytetarëve të dokumentojnë vende të ndotura me fotografi, vendndodhje të saktë dhe përshkrime të shkurtra. Çdo raport shfaqet në një hartë të përbashkët që banorët, vullnetarët dhe organizatat mund ta shfletojnë.',
      'Brenda aplikacionit, përdoruesit mund të filtrojnë raportet sipas llojit të problemit, të ndjekin zhvillimet në vende specifike dhe të gjejnë ngjarje pastrimi të publikuara nga organizatorët në të njëjtën zonë. Qëllimi është të lidhet vëzhgimi në terren me veprim të koordinuar komunitar.',
      '"Qasja mobile ishte pjesa që mungonte," tha një zëdhënës i ekipit Chisto.mk në Ekohab të martën. "Njerëzit shpesh vërejnë depozitime të paligjshme ose tym ndërsa ecin për në shtëpi. Tani mund të raportojnë për disa sekonda, me prova të dukshme në hartë për të gjithë."',
      'Aplikacioni është falas për shkarkim. Në App Store është listuar si Chisto.mk. Përdoruesit që preferojnë faqen e internetit mund të hapin seksionin e shkarkimit në chisto.mk.',
      'Chisto.mk filloi si mjet qytetar në internet për hartimin e problemeve mjedisore në Maqedoni. Versioni për iPhone synon raportimin në vend, kur dikush është në terren pa laptop.',
      'Lansimi i të martës mbulon vetëm iOS. Ekipi konfirmoi se një version për Android nuk është pjesë e kësaj publikimi dhe nuk dha datë për platforma të tjera.',
      'Njoftimet e ardhshme do të publikohen në faqen e lajmeve të Chisto.mk. Organizatat dhe gazetarët me pyetje mund të kontaktojnë ekipin përmes formularit të kontaktit në chisto.mk.',
    ]),
  },
};

export async function seedNewsLaunchPost(prisma: PrismaClient): Promise<void> {
  const existing = await prisma.newsPost.findUnique({ where: { slug: LAUNCH_SLUG } });
  if (existing) {
    return;
  }

  await prisma.newsPost.create({
    data: {
      slug: LAUNCH_SLUG,
      category: 'RELEASE',
      status: 'PUBLISHED',
      publishedAt: new Date('2026-06-23T06:00:00.000Z'),
      featured: true,
      translations: LAUNCH_TRANSLATIONS,
    },
  });
}
