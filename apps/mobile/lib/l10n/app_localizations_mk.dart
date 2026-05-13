// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Macedonian (`mk`).
class AppLocalizationsMk extends AppLocalizations {
  AppLocalizationsMk([String locale = 'mk']) : super(locale);

  @override
  String get reportFlowHelpHint =>
      'Допрете на иконата за информации за совети за овој чекор.';

  @override
  String reportFlowStepProgressStep(int current) {
    return 'Чекор $current/3';
  }

  @override
  String get reportFlowStepProgressReady => 'Спремно за испраќање';

  @override
  String get reportFlowStepStatusComplete => 'Готово';

  @override
  String get reportFlowStepStatusInProgress => 'Во тек';

  @override
  String get reportFlowStepChipPhotos => 'Фото';

  @override
  String get reportFlowStepChipCategory => 'Кат.';

  @override
  String get reportFlowStepChipLocation => 'Лок.';

  @override
  String get reportHelpContextTitle => 'Контекст';

  @override
  String get reportStageEvidenceEyebrow => 'Пријавете загадено место';

  @override
  String get reportStageEvidenceTitle => 'Докази';

  @override
  String get reportStageEvidenceSubtitle => 'Фотографии и кадрирање';

  @override
  String get reportStageEvidenceShortLabel => 'Докази';

  @override
  String get reportStageEvidencePrimaryAction => 'Следно';

  @override
  String get reportStageEvidencePrimaryRequirement => 'Фото';

  @override
  String get reportStageEvidenceSecondaryRequirement => 'До 5';

  @override
  String get reportStageEvidenceInfoTitle => 'Докази';

  @override
  String get reportHelpEvidenceS0Title => 'Што да снимите';

  @override
  String get reportHelpEvidenceS0Body =>
      'Додајте до пет фотографии што јасно ја покажуваат загадената зона. Почнете со поширок кадар за контекст, потоа поблиску: купови отпад, цевки, дамки, шут, се што покажува проблемот.';

  @override
  String get reportHelpEvidenceS1Title => 'Зошто помага';

  @override
  String get reportHelpEvidenceS1Body =>
      'Модераторите се потпираат на сликите за да потврдат пријава и да приоритизираат следен чекор. Подобра дневна светлина, стабилна рака и цела локација го олеснуваат проверувањето.';

  @override
  String get reportStageDetailsEyebrow => 'Опишете го проблемот';

  @override
  String get reportStageDetailsTitle => 'Детали';

  @override
  String get reportStageDetailsSubtitle => 'Категорија, наслов и контекст';

  @override
  String get reportStageDetailsShortLabel => 'Детали';

  @override
  String get reportStageDetailsPrimaryAction => 'Следно';

  @override
  String get reportStageDetailsPrimaryRequirement => 'Категорија и наслов';

  @override
  String get reportStageDetailsSecondaryRequirement => 'Детали опционално';

  @override
  String get reportStageDetailsInfoTitle => 'Детали';

  @override
  String get reportHelpDetailsS0Title => 'Што да пополните';

  @override
  String get reportHelpDetailsS0Body =>
      'Одберете категорија што најдобро одговара на она што го видовте. Краток наслов што кој било би го разбрал на прв поглед, како наслов на вест, не есеј.\n\nАко не сте сигурни, додадете сериозност; во описот ставете сè што им помага на терен да ја најдат или оценат локацијата: пристап, време, мирис, боја на водата, ориентири. За чистење пополнете само ако имате приближна претстава за обем.';

  @override
  String get reportHelpDetailsS1Title => 'Опционални полиња';

  @override
  String get reportHelpDetailsS1Body =>
      'Ништо не го блокира испраќањето освен категорија и наслов. Дополнителни детали се за нијанси; користете ги кога вистински помагаат.';

  @override
  String get reportStageLocationEyebrow => 'Потврдете ја локацијата';

  @override
  String get reportStageLocationTitle => 'Локација';

  @override
  String get reportStageLocationSubtitle => 'Игла на карта';

  @override
  String get reportStageLocationShortLabel => 'Локација';

  @override
  String get reportStageLocationPrimaryAction => 'Следно';

  @override
  String get reportStageLocationPrimaryRequirement => 'Игла';

  @override
  String get reportStageLocationSecondaryRequirement => 'Во Македонија';

  @override
  String get reportStageLocationInfoTitle => 'Локација';

  @override
  String get reportHelpLocationS0Title => 'Како да ја поставите иглата';

  @override
  String get reportHelpLocationS0Body =>
      'Поместете ја картата точно каде е загадувањето, не на најблиското село освен ако пријавувате цела зона. Зумирајте додека иглата не стои на вистинското место.';

  @override
  String get reportHelpLocationS1Title => 'Покриеност';

  @override
  String get reportHelpLocationS1Body =>
      'Иглата мора да биде во Македонија за пријавата да се насочи и верифицира. Ако не сте сигурни, поставете ја што е можно попрецизно.';

  @override
  String get reportHelpLocationS2Title => 'Зошто е важно';

  @override
  String get reportHelpLocationS2Body =>
      'Координатите ги поврзуваат фотографиите и описот со вистинско место за тимови на терен и модератори.';

  @override
  String get reportStageReviewEyebrow => 'Финален преглед';

  @override
  String get reportStageReviewTitle => 'Преглед';

  @override
  String get reportStageReviewSubtitle => 'Пред испраќање';

  @override
  String get reportStageReviewShortLabel => 'Преглед';

  @override
  String get reportStageReviewPrimaryAction => 'Испрати';

  @override
  String get reportStageReviewPrimaryRequirement => 'Подготвено';

  @override
  String get reportStageReviewInfoTitle => 'Преглед';

  @override
  String get reportHelpReviewS0Title => 'Проверете секој дел';

  @override
  String get reportHelpReviewS0Body =>
      'Допрете ред за враќање и уредување. Кога фото, детали и локација одговараат на она што го видовте, може да испратите.';

  @override
  String get reportHelpReviewS1Title => 'Што следи';

  @override
  String get reportHelpReviewS1Body =>
      'Пријавата се разгледува пред да биде јавна. Во Мои пријави следите статус; обновувањата се појавуваат додека локацијата поминува низ модерација.';

  @override
  String get newReportTitle => 'Нова пријава';

  @override
  String get reportReviewBannerCreditsTitle => 'Кредити';

  @override
  String get reportReviewBannerAfterSubmitTitle => 'По испраќање';

  @override
  String get reportReviewAfterSubmitReady =>
      'Модерација пред јавност. Статус во Мои пријави.';

  @override
  String get reportReviewAfterSubmitIncomplete =>
      'Довршете ги чекорите погоре.';

  @override
  String get reportSubmitSentPending => 'Испратено';

  @override
  String get semanticsClose => 'Затвори';

  @override
  String get homeShellNavHome => 'Почетна';

  @override
  String get homeShellNavReports => 'Пријави';

  @override
  String get homeShellNavMap => 'Мапа';

  @override
  String get homeShellNavEvents => 'Настани';

  @override
  String semanticsReportPhotoNumber(int number) {
    return 'Фотографија од пријавата $number';
  }

  @override
  String semanticsAboutStep(String title) {
    return 'За $title';
  }

  @override
  String semanticsNextStep(String label) {
    return 'Следно: $label';
  }

  @override
  String get reportFlowEvidenceNeedsPhoto =>
      'Додајте барем една фотографија за да продолжите.';

  @override
  String get reportFlowLocationOutsideMacedoniaHelper =>
      'Оваа локација е надвор од Македонија. Потегнете ја иглата во земјата, потоа допрете Потврди локација.';

  @override
  String get reportLocationAdvanceBlockedBanner =>
      'Поставете ја иглата во Македонија и допрете Потврди локација.';

  @override
  String get reviewTapToEdit => 'Допри за уредување';

  @override
  String semanticsCurrentReportStep(String label) {
    return 'Тековен чекор: $label';
  }

  @override
  String get errorBannerDraftSavedHint =>
      'Нацртот е зачуван, обидете се повторно кога ќе бидете подготвени.';

  @override
  String get reportSubmittedTitle => 'Пријавата е испратена';

  @override
  String reportSubmittedSavedAs(String number) {
    return 'Зачувано како пријава $number';
  }

  @override
  String reportSubmittedBodyWithAddress(String category, String address) {
    return '$category во близина на $address е во редот за проверка.';
  }

  @override
  String reportSubmittedBodyNoAddress(String category) {
    return '$category е во редот за проверка.';
  }

  @override
  String get reportSubmittedNewSiteBadge =>
      'Нова локација е додадена на мапата';

  @override
  String reportSubmittedPointsEarned(int points) {
    return '+$points поени';
  }

  @override
  String get reportSubmittedPointsPending =>
      'Поените се доделуваат откако модераторите ќе ја одобрат пријавата.';

  @override
  String get reportSubmittedViewThisReport => 'Погледни ја пријавата';

  @override
  String get reportSubmittedViewAllReports => 'Погледни ги сите пријави';

  @override
  String get reportSubmittedViewInMyReports => 'Погледни во Мои пријави';

  @override
  String get reportSubmittedReportAnother => 'Нова пријава';

  @override
  String get reportSubmittedSemanticsSuccess => 'Пријавата е успешно испратена';

  @override
  String get profileAvatarSourceTitle => 'Профилна фотографија';

  @override
  String get profileAvatarSourceSubtitle =>
      'Направете нова фотографија или одберете од вашата библиотека. Во следниот чекор можете да ја исечете.';

  @override
  String get profileAvatarSourceCamera => 'Камера';

  @override
  String get profileAvatarSourceCameraHint =>
      'Предната камера е најдобра со добра светлина.';

  @override
  String get profileAvatarSourcePhotos => 'Фотографии';

  @override
  String get profileAvatarSourcePhotosHint =>
      'Одберете слика што веќе ја имате.';

  @override
  String get profileAvatarSourceRemove => 'Отстрани ја фотографијата';

  @override
  String get profileAvatarSourceRemoveHint => 'Прикажи иницијали наместо слика';

  @override
  String get profileAvatarRemoveConfirmTitle =>
      'Да се отстрани профилната фотографија?';

  @override
  String get profileAvatarRemoveConfirmMessage =>
      'Фотографијата ќе биде избришана и ќе се прикажат вашите иницијали.';

  @override
  String get profileAvatarRemoveConfirmCancel => 'Откажи';

  @override
  String get profileAvatarRemoveConfirmRemove => 'Отстрани';

  @override
  String get profileAvatarRemovedMessage =>
      'Профилната фотографија е отстранета';

  @override
  String get profileAvatarRemoveFailed =>
      'Не можеше да се отстрани фотографијата. Обидете се повторно.';

  @override
  String get profileAvatarSourceRecommended => 'Препорачано';

  @override
  String get profileAvatarCropMoveAndScale => 'Помести и размери';

  @override
  String get profileAvatarCropHint =>
      'Зближете со стискање, повлечете за позиција';

  @override
  String get profileAvatarCropLoading => 'Се вчитува фотографијата…';

  @override
  String get profileAvatarCropCancel => 'Откажи';

  @override
  String get profileAvatarCropDone => 'Готово';

  @override
  String get profileAvatarTapToChange => 'Допрете за да ја смените сликата';

  @override
  String get profileAvatarUploadingCaption => 'Се испраќа…';

  @override
  String get profileAvatarCropEditorSemantic =>
      'Исечете ја профилната фотографија. Зближете со стискање и повлечете за да ја позиционирате сликата.';

  @override
  String get profileAvatarCropFailed =>
      'Не можеше да се исече фотографијата. Обидете се повторно.';

  @override
  String get profileAvatarCameraUnavailable =>
      'Камерата не е достапна сега. Обидете се повторно за момент.';

  @override
  String get profileAvatarReadPhotoFailed =>
      'Не можеше да се прочита фотографијата. Обидете се повторно.';

  @override
  String get profileAvatarProcessPhotoFailed =>
      'Не можеше да се обработи фотографијата. Обидете се повторно.';

  @override
  String get profileAvatarPeekSemantic => 'Профилна фотографија';

  @override
  String get errorBannerDismiss => 'Отфрли';

  @override
  String get errorBannerTryAgain => 'Обиди се повторно';

  @override
  String get authSemanticGoBack => 'Назад';

  @override
  String get authLoading => 'Се вчитува';

  @override
  String get authSignInTitle => 'Најава';

  @override
  String get authSignInSubtitle =>
      'Добредојдовте повторно. Внесете ги податоците за да продолжите.';

  @override
  String get authFieldPhone => 'Телефонски број';

  @override
  String get authFieldPhoneHint => '70 123 456';

  @override
  String get authFieldPassword => 'Лозинка';

  @override
  String get authFieldPasswordHint => 'Внесете ја лозинката';

  @override
  String get authRememberMe => 'Запомни ме';

  @override
  String get authForgotPassword => 'Заборавена лозинка?';

  @override
  String get authSignInCta => 'Најави се';

  @override
  String get authValidationCheckPhonePassword =>
      'Проверете го телефонот и лозинката.';

  @override
  String get authSignUpPrompt => 'Немате сметка? ';

  @override
  String get authSignUpLink => 'Регистрирај се';

  @override
  String get authSignUpTitle => 'Регистрација';

  @override
  String get authSignUpSubtitle => 'Добредојдовте! Внесете ги вашите податоци';

  @override
  String get authFieldFullName => 'Име и презиме';

  @override
  String get authFieldFullNameHint => 'Име Презиме';

  @override
  String get authFieldEmail => 'Е-пошта';

  @override
  String get authFieldEmailHint => 'korisnik@chisto.mk';

  @override
  String get authFieldPhoneNumber => 'Телефонски број';

  @override
  String get authPasswordRequirementsHint =>
      'Најмалку 8 знаци, со букви и бројки';

  @override
  String get authTermsPrefix => 'Со регистрација се согласувате со ';

  @override
  String get authTermsLink => 'условите';

  @override
  String get authValidationCheckFields => 'Проверете ги полињата погоре.';

  @override
  String get authSignUpCta => 'Регистрирај се';

  @override
  String get authSignInPrompt => 'Веќе имате сметка? ';

  @override
  String get authSignInLink => 'Најави се';

  @override
  String authValidationFieldRequired(String fieldName) {
    return '$fieldName е задолжително';
  }

  @override
  String get authValidationPhoneRequired => 'Телефонскиот број е задолжителен';

  @override
  String get authValidationPhoneDigits => 'Внесете 8-цифрен телефонски број';

  @override
  String get authValidationEmailRequired => 'Е-поштата е задолжителна';

  @override
  String get authValidationEmailInvalid => 'Внесете валидна е-пошта';

  @override
  String get authValidationPasswordRequired => 'Лозинката е задолжителна';

  @override
  String get authValidationPasswordMinLength =>
      'Лозинката мора да има најмалку 8 знаци';

  @override
  String get authValidationPasswordNeedNumber =>
      'Лозинката мора да содржи барем една бројка';

  @override
  String get authValidationPasswordNeedLetter =>
      'Лозинката мора да содржи барем една буква';

  @override
  String get authValidationConfirmPasswordRequired => 'Потврдете ја лозинката';

  @override
  String get authValidationConfirmPasswordMismatch =>
      'Лозинките не се совпаѓаат';

  @override
  String get authErrorInvalidCredentials => 'Погрешен телефон или лозинка.';

  @override
  String get authErrorAccountSuspended => 'Оваа сметка не е активна.';

  @override
  String get authErrorPhoneNotRegistered =>
      'Нема сметка за овој телефонски број.';

  @override
  String get authErrorEmailRegistered => 'Оваа е-пошта е веќе регистрирана.';

  @override
  String get authErrorPhoneRegistered =>
      'Овој телефонски број е веќе регистриран.';

  @override
  String get authErrorOtpNotFound => 'Нема испратен код. Побарајте нов.';

  @override
  String get authErrorOtpExpired => 'Кодот е истечен. Побарајте нов.';

  @override
  String get authErrorOtpInvalid => 'Невалиден код. Обидете се повторно.';

  @override
  String get authErrorOtpMaxAttempts =>
      'Премногу погрешни обиди. Побарајте нов код.';

  @override
  String get authErrorCurrentPasswordInvalid =>
      'Моменталната лозинка е неточна.';

  @override
  String get authErrorTooManyAttempts =>
      'Премногу неуспешни обиди. Обидете се подоцна.';

  @override
  String get authErrorRateLimited =>
      'Премногу барања. Почекајте малку и обидете се повторно.';

  @override
  String get authErrorUserNotFound =>
      'Не најдовме сметка за овој број. Проверете и обидете се повторно.';

  @override
  String get authOtpTitle => 'Внесете код';

  @override
  String authOtpSubtitle(String phone) {
    return 'Испративме 4-цифрен код на $phone';
  }

  @override
  String get authOtpContinue => 'Продолжи';

  @override
  String get authOtpResendPrefix => 'Не добивте код? ';

  @override
  String get authOtpResendAction => 'Испрати повторно';

  @override
  String authOtpResendCountdown(int seconds) {
    return 'Повторно испраќање за $seconds с';
  }

  @override
  String authOtpResentMessage(String phone) {
    return 'Испративме нов код на $phone.';
  }

  @override
  String get authForgotPasswordTitle => 'Ресетирај лозинка';

  @override
  String get authForgotPasswordSubtitle =>
      'Внесете го телефонот и ќе ви испратиме код за нова лозинка';

  @override
  String get authForgotPasswordSendCode => 'Испрати код';

  @override
  String get authForgotPasswordRequestSemantic => 'Испрати код за ресет';

  @override
  String get authForgotPasswordOtpTitle => 'Внесете код';

  @override
  String authForgotPasswordOtpSubtitle(String phone) {
    return 'Испративме 4-цифрен код на $phone';
  }

  @override
  String get authNewPasswordTitle => 'Нова лозинка';

  @override
  String get authNewPasswordSubtitle => 'Внесете нова лозинка за вашата сметка';

  @override
  String get authFieldNewPassword => 'Нова лозинка';

  @override
  String get authFieldNewPasswordHint => 'Најмалку 8 знаци';

  @override
  String get authFieldConfirmPassword => 'Потврди лозинка';

  @override
  String get authFieldConfirmPasswordHint => 'Повторно внесете ја лозинката';

  @override
  String get authResetPasswordCta => 'Ресетирај лозинка';

  @override
  String get authPasswordResetSuccessTitle => 'Лозинката е сменета';

  @override
  String get authPasswordResetSuccessBody =>
      'Лозинката е успешно ресетирана. Сега можете да се најавите со новата лозинка.';

  @override
  String get authBackToSignIn => 'Назад на најава';

  @override
  String get authOnboardingWelcomeTo => 'Добредојдовте на';

  @override
  String get authOnboardingBrandName => 'Chisto.mk';

  @override
  String get authOnboardingWelcomeDescription => 'Види. Пријави. Исчисти.';

  @override
  String get authOnboardingWelcomeSupporting => 'Почнува со едно допирање.';

  @override
  String get authOnboardingSlide2Title => 'Пријавете за секунди';

  @override
  String get authOnboardingSlide2Description =>
      'Споделете пријава со локација со неколку допирања.';

  @override
  String get authOnboardingSlide2Supporting =>
      'Брз тек, јасни ажурирања на статусот.';

  @override
  String get authOnboardingSlide3Title => 'Придружете се на акции';

  @override
  String get authOnboardingSlide3Description =>
      'Следете напредок и влијание во заедницата.';

  @override
  String get authOnboardingSlide3Supporting =>
      'Заедно ги чуваме квартовите зелени.';

  @override
  String get authOnboardingContinue => 'Продолжи';

  @override
  String get authOnboardingGetStarted => 'Започни';

  @override
  String get authLocationTitle => 'Одберете локација';

  @override
  String get authLocationSubtitle =>
      'Ја користиме за да ви покажеме акции и пријави во близина.';

  @override
  String get authLocationMapPlaceholder =>
      'Користете ја моменталната локација за да ја ажурирате областа';

  @override
  String get authLocationDetecting => 'Се детектира локација…';

  @override
  String get authLocationContinue => 'Продолжи';

  @override
  String get authLocationUseCurrent => 'Користи моментална локација';

  @override
  String get authLocationUseDifferent => 'Друга локација';

  @override
  String get authLocationPrivacyNote =>
      'Локацијата ја користиме само за содржина во близина. Не ве следиме во позадина.';

  @override
  String get authLocationServicesDisabled =>
      'Локациските услуги се исклучени. Вклучете ги во Поставки.';

  @override
  String get authLocationPermissionDenied =>
      'Дозволата за локација е одбиена. Можете да ја вклучите во Поставки.';

  @override
  String get authLocationPermissionForever =>
      'Дозволата е трајно одбиена. Се отвораат Поставки…';

  @override
  String get authLocationMacedoniaOnly =>
      'Моментално поддржуваме само локации во Македонија.';

  @override
  String get authLocationResolveFailed =>
      'Не можевме да ја одредиме локацијата. Обидете се повторно.';

  @override
  String get authOtpCodeSemantic => 'Код за потврда';

  @override
  String authOtpDigitSemantic(int index, int total) {
    return 'Цифра $index од $total';
  }

  @override
  String get profileWeeklyRankingsTitle => 'Неделна ранг-листа';

  @override
  String get profileWeeklyRankingsSubtitle =>
      'Пријави, еко-акции и повеќе, оваа недела.';

  @override
  String get profileWeeklyRankingsTopSupporters => 'Најактивни оваа недела';

  @override
  String get profileWeeklyRankingsEmptyTitle => 'Сè уште нема ранг-листа';

  @override
  String get profileWeeklyRankingsEmptySubtitle =>
      'Освојте поени оваа недела од која било активност што носи поени за да се појавите тука.';

  @override
  String get profileWeeklyRankingsRetry => 'Обиди се повторно';

  @override
  String profileWeeklyRankingsYouRank(int rank) {
    return 'Оваа недела сте бр. $rank';
  }

  @override
  String profileWeeklyRankingsPtsThisWeek(int points) {
    return '$points поени оваа недела';
  }

  @override
  String get profileWeeklyRankingsYouBadge => 'Вие';

  @override
  String get profileWeeklyRankingsScrollToYouHint =>
      'Скролувај до вашата позиција на листата';

  @override
  String get profileWeeklyRankingsLoadingSemantic =>
      'Се вчитува неделната ранг-листа';

  @override
  String profileWeeklyRankingsRowSemantic(int rank, String name, int points) {
    return 'Место $rank, $name, $points поени';
  }

  @override
  String profileLevelLine(int level) {
    return 'Ниво $level';
  }

  @override
  String get profileTierLegend => 'Легенда на Chisto';

  @override
  String profilePtsToNextLevel(int points) {
    return 'Уште $points поени до следно ниво';
  }

  @override
  String profileLevelXpSegment(int current, int total) {
    return '$current / $total XP';
  }

  @override
  String profileLifetimeXpOnBar(int xp) {
    return '$xp животни XP';
  }

  @override
  String profilePointsBalanceShort(int balance) {
    return 'Салдо $balance';
  }

  @override
  String get profileMyWeeklyRankTitle => 'Мојот неделен ранг';

  @override
  String profileMyWeeklyRankDetailRanked(int rank, int points) {
    return 'бр.$rank, $points поени';
  }

  @override
  String profileMyWeeklyRankDetailPointsOnly(int points) {
    return '$points поени';
  }

  @override
  String get profileMyWeeklyRankNoPoints => 'Сè уште нема поени оваа недела';

  @override
  String get profileViewRankings => 'Види ранг-листа';

  @override
  String get profilePointsHistoryTitle => 'Поени и нивоа';

  @override
  String get profilePointsHistorySubtitle =>
      'Освоени XP и секое отклучено ниво.';

  @override
  String get profilePointsHistoryOpenSemantic =>
      'Отвори историја на поени и нивоа';

  @override
  String get profilePointsHistoryLoadingSemantic =>
      'Се вчитуваат поените и нивоата';

  @override
  String get profileLoadingSemantic => 'Се вчитува профилот';

  @override
  String get profileErrorSemantic => 'Профилот не можеше да се вчита';

  @override
  String get profileLevelCardSemantic =>
      'Ниво и поени. Отвора историја на поени';

  @override
  String get profileWeeklyRankCardSemantic =>
      'Неделен пласман. Отвора рангирања';

  @override
  String get profilePointsHistoryMilestonesSection => 'Ново ниво';

  @override
  String get profilePointsHistoryActivitySection => 'Активност';

  @override
  String get profilePointsHistoryDayToday => 'Денес';

  @override
  String get profilePointsHistoryDayYesterday => 'Вчера';

  @override
  String get profilePointsHistoryEmpty =>
      'Сè уште нема поени. Кога пријавата што ја испрати ќе биде одобрена како прва на локацијата, тука ќе се појави XP.';

  @override
  String get profilePointsHistoryLevelUpBadge => 'НОВО НИВО';

  @override
  String get profilePointsHistoryLoadMore => 'Се вчитува…';

  @override
  String get profilePointsHistoryLoadMoreErrorTitle =>
      'Не можеше да се вчита повеќе активност';

  @override
  String get profilePointsHistoryLoadMoreRetry => 'Обиди се повторно';

  @override
  String profilePointsActivityRowSemantic(
    String reason,
    String time,
    String delta,
  ) {
    return '$reason. $time. $delta';
  }

  @override
  String profilePointsDeltaPositive(int points) {
    return '+$points XP';
  }

  @override
  String profilePointsDeltaNegative(int points) {
    return '$points XP';
  }

  @override
  String get profilePointsReasonFirstReport =>
      'Прва одобрена пријава на локација';

  @override
  String get profilePointsReasonEcoApproved => 'Одобрена еко-акција';

  @override
  String get profilePointsReasonEcoRealized => 'Завршена еко-акција';

  @override
  String get profilePointsReasonOther => 'Промена на поени';

  @override
  String get profilePointsReasonEventOrganizerApproved =>
      'Вашиот настан за чистење е одобрен';

  @override
  String get profilePointsReasonEventJoined =>
      'Се придруживте на настан за чистење';

  @override
  String get profilePointsReasonEventJoinNoShow =>
      'Прилагодување на бонус — без проверка';

  @override
  String get profilePointsReasonEventCheckIn => 'Регистрација на настан';

  @override
  String get profilePointsReasonEventCompleted => 'Завршен настан за чистење';

  @override
  String get profilePointsReasonReportApproved => 'Одобрена пријава';

  @override
  String get profilePointsReasonReportApprovalRevoked =>
      'Поништена одобреност на пријава';

  @override
  String get profilePointsReasonReportSubmitted =>
      'Испратена пријава (застарено)';

  @override
  String get profileReportCreditsTitle => 'Кредити за пријави';

  @override
  String get profileAccountDetailsSection => 'Детали за сметката';

  @override
  String get profileGeneralInfoTile => 'Општи информации';

  @override
  String get profileLanguageTile => 'Јазик';

  @override
  String get profileLanguageScreenTitle => 'Јазик на апликацијата';

  @override
  String get profileLanguageScreenSubtitle =>
      'Изберете јазик или следете го уредот.';

  @override
  String get profileLanguageChangeFailed =>
      'Не можевме да го зачуваме јазикот. Обидете се повторно.';

  @override
  String get profileLanguageSubtitleDevice => 'Поставки на уредот';

  @override
  String get profileLanguageOptionSystem => 'Следи јазик на уредот';

  @override
  String get profileLanguageNameEn => 'English';

  @override
  String get profileLanguageNameMk => 'Македонски';

  @override
  String get profileLanguageNameSq => 'Shqip';

  @override
  String get profilePasswordTile => 'Лозинка';

  @override
  String get profileSupportSection => 'Поддршка';

  @override
  String get profileHelpCenterTile => 'Центар за помош';

  @override
  String get profileAccountSection => 'Сметка';

  @override
  String get profileSignOutTile => 'Одјави се';

  @override
  String get profileDeleteAccountTile => 'Избриши сметка';

  @override
  String get profileEmailLabel => 'Е-пошта';

  @override
  String get profileEmailReadOnlyHint =>
      'Само за читање. За промена контактирајте поддршка.';

  @override
  String get profileNoConnectionSnack => 'Нема врска';

  @override
  String get profileRefreshFailedSnack =>
      'Не можевме да го освежиме профилот. Обидете се повторно за момент.';

  @override
  String get profilePasswordScreenTitle => 'Промени лозинка';

  @override
  String get profilePasswordScreenSubtitle =>
      'Одберете силна, уникатна лозинка.';

  @override
  String get profilePasswordCurrentLabel => 'Моментална лозинка';

  @override
  String get profilePasswordNewLabel => 'Нова лозинка';

  @override
  String get profilePasswordConfirmLabel => 'Потврди нова лозинка';

  @override
  String get profilePasswordNewHelper => 'Најмалку 8 знаци, со бројка.';

  @override
  String get profilePasswordConfirmMismatchHelper =>
      'Мора да се совпаѓа со новата лозинка погоре.';

  @override
  String get profilePasswordSecurityHint =>
      'Од безбедносни причини не ја користете истата лозинка како на други апликации.';

  @override
  String get profilePasswordSubmit => 'Ажурирај лозинка';

  @override
  String get profilePasswordSubmitting => 'Се ажурира…';

  @override
  String get profilePasswordSuccess => 'Лозинката е ажурирана';

  @override
  String get profilePasswordEnterCurrentWarning =>
      'Внесете ја моменталната лозинка.';

  @override
  String get profilePasswordMismatchError => 'Лозинките не се совпаѓаат.';

  @override
  String get profilePasswordSessionExpired =>
      'Сесијата истече. Најавете се повторно.';

  @override
  String get profilePasswordGenericError =>
      'Нешто не е во ред. Проверете ја врската и обидете се повторно.';

  @override
  String get profilePasswordCurrentSemantic => 'Моментална лозинка';

  @override
  String get profilePasswordNewSemantic => 'Нова лозинка';

  @override
  String get profilePasswordConfirmSemantic => 'Потврда на нова лозинка';

  @override
  String get profilePasswordToggleVisibility => 'Прикажи или сокриј лозинка';

  @override
  String get commonCancel => 'Откажи';

  @override
  String get commonContinue => 'Продолжи';

  @override
  String get commonRetry => 'Обиди повторно';

  @override
  String get commonTryAgain => 'Обиди се повторно';

  @override
  String get commonDelete => 'Избриши';

  @override
  String get commonSave => 'Зачувај';

  @override
  String get commonSkip => 'Прескокни';

  @override
  String get commonBack => 'Назад';

  @override
  String get commonClose => 'Затвори';

  @override
  String get commonGotIt => 'Разбрано';

  @override
  String get commonKeepEditing => 'Продолжи со уредување';

  @override
  String get commonDiscard => 'Отфрли';

  @override
  String get profileSignOutDialogTitle => 'Да се одјавите?';

  @override
  String get profileSignOutDialogBody =>
      'Можете повторно да се најавите со вашата сметка.';

  @override
  String get profileSignOutFailedSnack =>
      'Не можевме да ве одјавиме. Обидете се повторно.';

  @override
  String get profileDeleteAccountDialogTitle => 'Да се избрише сметката?';

  @override
  String get profileDeleteAccountDialogBody =>
      'Сите податоци трајно ќе бидат избришани. Ова не може да се врати.';

  @override
  String get profileDeleteAccountFailedSnack =>
      'Не можевме да ја избришеме сметката. Обидете се повторно.';

  @override
  String get profileDeleteAccountTypeConfirmTitle => 'Потврда со внес';

  @override
  String get profileDeleteAccountTypeConfirmBody =>
      'Напишете го зборот подолу точно како што е прикажан. Ова спречува случајно бришење.';

  @override
  String get profileDeleteAccountConfirmPhrase => 'ИЗБРИШИ';

  @override
  String get profileDeleteAccountTypeFieldPlaceholder => 'Напишете овде';

  @override
  String get profileDeleteAccountTypeMismatchSnack =>
      'Напишете го зборот за потврда точно како што е прикажан.';

  @override
  String get profileHelpCenterOpenFailedSnack =>
      'Не можеше да се отвори центарот за помош';

  @override
  String get profileGeneralLoadFailedSnack => 'Не можеше да се вчита профилот';

  @override
  String get profileGeneralNameRequiredSnack => 'Името е задолжително';

  @override
  String get profileGeneralNameTooLongSnack => 'Името е предолго';

  @override
  String get profileGeneralUpdatedSnack => 'Профилот е ажуриран';

  @override
  String get profileGeneralPictureUpdatedSnack =>
      'Профилната слика е ажурирана';

  @override
  String get profileGeneralInfoSubtitle => 'Уредете ги податоците за профилот';

  @override
  String get profileGeneralNameLabel => 'Име';

  @override
  String get profileGeneralNameHint => 'Вашето име';

  @override
  String get profileGeneralMobileLabel => 'Мобилен телефон';

  @override
  String get profileGeneralPhonePlaceholder => '70 123 456';

  @override
  String get profileGeneralLimitsNotice =>
      'Промените на името се ограничени. Промената на телефонот бара верификација.';

  @override
  String get profileGeneralUpdateButton => 'Ажурирај податоци';

  @override
  String get profileGeneralSaving => 'Зачувување…';

  @override
  String get profileGeneralAvatarSemanticUpdating =>
      'Се ажурира профилната фотографија';

  @override
  String get profileGeneralAvatarSemanticChange =>
      'Профилна фотографија. Двоен допир за промена';

  @override
  String get profileGeneralEmptyValue => '—';

  @override
  String get profileGeneralDefaultDisplayName => 'Корисник';

  @override
  String get reportListFabLabel => 'Пријави загадување';

  @override
  String get reportListAppBarStartNewReportLabel => 'Нов извештај';

  @override
  String reportListDraftChipLabel(int photoCount, String savedAgo) {
    String _temp0 = intl.Intl.pluralLogic(
      photoCount,
      locale: localeName,
      other: '$photoCount фотографии',
      one: '1 фотографија',
      zero: 'нема фотографии',
    );
    return 'Нацрт · $_temp0 · $savedAgo';
  }

  @override
  String reportListDraftChipSemantic(int photoCount) {
    String _temp0 = intl.Intl.pluralLogic(
      photoCount,
      locale: localeName,
      other: '$photoCount фотографии',
      one: '1 фотографија',
    );
    return 'Зачуван нацрт со $_temp0. Допри двапати за да отвориш.';
  }

  @override
  String get reportListSearchSemantic => 'Пребарај пријави';

  @override
  String get reportAvailabilityCheckFailedSnack =>
      'Моментално не може да се провери достапноста за пријавување.';

  @override
  String get reportFinishStepsSnack =>
      'Довршете ги недостасувачките чекори пред испраќање.';

  @override
  String get reportSubmittedPartialUploadSnack =>
      'Пријавата е испратена. Фотографиите не се прикачени.';

  @override
  String get reportPhotoUploadFailedTitle =>
      'Неуспешно прикачување на фотографии';

  @override
  String get reportPhotoUploadFailedBody =>
      'Фотографиите не можеа да се прикачат. Допрете Обиди повторно или Прескокни за да испратите без фотографии.';

  @override
  String get reportReviewEvidenceTitle => 'Докази';

  @override
  String reportReviewPhotoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count фотографии',
      one: '$count фотографија',
    );
    return '$_temp0';
  }

  @override
  String get reportReviewAddPhoto => 'Додај фотографија';

  @override
  String get reportReviewCategoryTitle => 'Категорија';

  @override
  String get reportReviewChooseCategory => 'Одбери категорија';

  @override
  String get reportReviewTitleLabel => 'Наслов';

  @override
  String get reportReviewAddTitle => 'Додај наслов';

  @override
  String get reportReviewSeverityTitle => 'Сериозност';

  @override
  String get reportReviewLocationTitle => 'Локација';

  @override
  String get reportReviewPinnedShort => 'Закачено';

  @override
  String get reportReviewPinMacedonia => 'Закачи во Македонија';

  @override
  String get reportReviewExtraContextTitle => 'Дополнителен контекст';

  @override
  String get reportReviewCleanupEffortTitle => 'Проценка за чистење';

  @override
  String get reportSelectCategorySemantic => 'Одбери категорија на пријава';

  @override
  String get reportBackSemantic => 'Назад';

  @override
  String get reportPreviousStepSemantic => 'Претходен чекор';

  @override
  String get reportCleanupEffortChipHint =>
      'Двојно допирање за проценка на напор за чистење.';

  @override
  String get reportCleanupEffortOneToTwo => '1–2 лица';

  @override
  String get reportCleanupEffortThreeToFive => '3–5 лица';

  @override
  String get reportCleanupEffortSixToTen => '6–10 лица';

  @override
  String get reportCleanupEffortTenPlus => '10+ лица';

  @override
  String get reportCleanupEffortNotSure => 'Не сум сигурен/а';

  @override
  String get reportCooldownTitle => 'Пауза за пријавување';

  @override
  String reportCooldownBody(String retry, String hint) {
    return 'Ги искористивте сите 10 кредити за пријави и вонредното олеснување.\n\nВонредното отклучување повторно за $retry.\n\n$hint';
  }

  @override
  String get reportCooldownModalIntro =>
      'Ги искористивте сите 10 кредити за пријави и вонредното олеснување.';

  @override
  String get reportCooldownModalRetryLead =>
      'Вонредното отклучување повторно за';

  @override
  String get reportCooldownDurationListSeparator => ', ';

  @override
  String reportCooldownDurationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дена',
      one: '$count ден',
    );
    return '$_temp0';
  }

  @override
  String reportCooldownDurationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count часа',
      one: '$count час',
    );
    return '$_temp0';
  }

  @override
  String reportCooldownDurationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count минути',
      one: '$count минута',
    );
    return '$_temp0';
  }

  @override
  String reportCooldownDurationSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count секунди',
      one: '$count секунда',
    );
    return '$_temp0';
  }

  @override
  String get reportCooldownRetrySoon => 'наскоро';

  @override
  String reportCooldownRetrySeconds(int seconds) {
    return '$seconds с';
  }

  @override
  String reportCooldownRetryMinutes(int minutes) {
    return '$minutes мин';
  }

  @override
  String reportCooldownRetryHoursMinutes(int hours, int minutes) {
    return '$hours ч $minutes мин';
  }

  @override
  String get reportCapacityUnlockHint =>
      'На настани или еколошки акции за повеќе пријави (до 10).';

  @override
  String reportCapacityPillHealthy(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count кредити',
      one: '$count кредит',
    );
    return '$_temp0';
  }

  @override
  String get reportCapacityBannerHealthyTitle => 'Сè во ред';

  @override
  String reportCapacityBannerHealthyBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count кредити достапни',
      one: '$count кредит достапен',
    );
    return '$_temp0';
  }

  @override
  String get reportCapacityReviewHealthy => 'Користи 1 кредит.';

  @override
  String reportCapacityPillLow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Уште $count пријави',
      one: 'Уште $count пријава',
    );
    return '$_temp0';
  }

  @override
  String get reportCapacityBannerLowTitle => 'Малку кредити';

  @override
  String reportCapacityBannerLowBody(String hint) {
    return 'Скоро празно. $hint';
  }

  @override
  String reportCapacityReviewLow(String hint) {
    return 'Користи 1 кредит. $hint';
  }

  @override
  String get reportCapacityPillEmergency => 'Вонредна пријава';

  @override
  String get reportCapacityBannerEmergencyTitle => 'Вонредна пријава';

  @override
  String reportCapacityBannerEmergencyBody(String hint) {
    return 'Имате уште една. $hint';
  }

  @override
  String reportCapacityReviewEmergency(String hint) {
    return 'Ја користи вонредната пријава. $hint';
  }

  @override
  String get reportCapacityPillCooldown => 'Пауза';

  @override
  String get reportCapacityBannerCooldownTitle => 'Пауза';

  @override
  String reportCapacityCooldownRetryOnDate(String date) {
    return 'Следна вонредна: $date.';
  }

  @override
  String reportCapacityCooldownTryAgainInAbout(String duration) {
    return 'Повторно за ~$duration.';
  }

  @override
  String get reportCapacityCooldownStillWaiting => 'Вонредната се лади.';

  @override
  String reportCapacityBannerCooldownBody(String retryLine, String hint) {
    return '$retryLine $hint';
  }

  @override
  String reportCapacityReviewCooldown(String retryLine, String hint) {
    return '$retryLine $hint';
  }

  @override
  String reportCapacitySecondsRemaining(int seconds) {
    return '(уште $seconds с)';
  }

  @override
  String get feedRetryLoadingMore => 'Обиди повторно да вчиташ повеќе';

  @override
  String get feedLoadingMoreSemantic => 'Се вчитуваат повеќе објави во фидот';

  @override
  String get feedShowAllSites => 'Прикажи ги сите локации';

  @override
  String get feedPullToRefreshSemantic => 'Повлечи за освежување';

  @override
  String get feedRefreshingSemantic => 'Се освежува фидот';

  @override
  String get feedLoadMoreFailedSnack =>
      'Не можеше да се вчитаат повеќе објави. Допрете за обид.';

  @override
  String get feedRefreshStaleSnack =>
      'Не можеше да се освежи листата. Се прикажува последно вчитаната.';

  @override
  String get feedScrollToTopSemantic => 'Скролувај на врв на фидот';

  @override
  String get feedPollutionFeedTitle => 'Фид на загадување';

  @override
  String get feedOfflineBanner =>
      'Нема интернет. Се прикажува последниот вчитан фид.';

  @override
  String get feedCaughtUpTitle => 'Сè е видено';

  @override
  String get feedCaughtUpSubtitle => 'Повлечи за освежување за нови пријави';

  @override
  String get feedMoreFiltersTooltip => 'Повеќе филтри';

  @override
  String feedFilterSemantic(String name) {
    return 'Филтер $name';
  }

  @override
  String get feedEmptyAllTitle => 'Сè уште нема локации за загадување';

  @override
  String get feedEmptyAllHint => 'Повлечи за освежување или провери подоцна';

  @override
  String get feedEmptyUrgentTitle => 'Моментално нема итни локации';

  @override
  String get feedEmptyUrgentHint => 'Прикажи ги сите или пробај друг филтер';

  @override
  String get feedEmptyNearbyTitleOnline => 'Нема локации во близина';

  @override
  String get feedEmptyNearbyTitleOffline =>
      'Вклучи локација за локации во близина';

  @override
  String get feedEmptyNearbyHintOffline =>
      'Вклучи услуги за локација и дозволи пристап';

  @override
  String get feedEmptyNearbyHintOnline =>
      'Прикажи ги сите или пробај друг филтер';

  @override
  String get feedEmptyMostVotedTitle => 'Сè уште нема гласови за локации';

  @override
  String get feedEmptyMostVotedHint => 'Прикажи ги сите или пробај друг филтер';

  @override
  String get feedEmptyRecentTitle => 'Нема неодамнешни пријави';

  @override
  String get feedEmptyRecentHint => 'Прикажи ги сите или пробај друг филтер';

  @override
  String get feedEmptySavedTitle => 'Сè уште немаш зачувани локации';

  @override
  String get feedEmptySavedHint =>
      'Зачувај локации од менито за да ги најдеш тука';

  @override
  String get feedFilterAllName => 'Сите';

  @override
  String get feedFilterAllDesc => 'Избалансиран фид';

  @override
  String get feedFilterUrgentName => 'Итно';

  @override
  String get feedFilterUrgentDesc => 'Најважните инциденти први';

  @override
  String get feedFilterNearbyName => 'Во близина';

  @override
  String get feedFilterNearbyDesc => 'Најблиски пријави околу тебе';

  @override
  String get feedFilterMostVotedName => 'Најподдржани';

  @override
  String get feedFilterMostVotedDesc => 'Најмногу поддршка од заедницата';

  @override
  String get feedFilterRecentName => 'Неодамнешни';

  @override
  String get feedFilterRecentDesc => 'Најнови пријави први';

  @override
  String get feedFilterSavedName => 'Зачувани';

  @override
  String get feedFilterSavedDesc => 'Локации што си ги зачувал';

  @override
  String get feedFiltersSheetTitle => 'Филтри на фидот';

  @override
  String get feedFiltersSheetSubtitle =>
      'Избери како сакаш да прелистуваш пријави';

  @override
  String get commentsFeedHeaderTitle => 'Коментари';

  @override
  String get commentsSortTop => 'Најдобри';

  @override
  String get commentsSortNew => 'Најнови';

  @override
  String get commentsEditingBanner => 'Уредување на коментар';

  @override
  String get commentsBodyTooLong =>
      'Коментарот е предолг (максимум 2000 знаци).';

  @override
  String get commentsReplyTargetFallback => 'коментар';

  @override
  String get reportIssueSheetTitle => 'Пријави проблем';

  @override
  String get reportIssueSubmitting => 'Се испраќа...';

  @override
  String get reportIssueSubmit => 'Испрати пријава';

  @override
  String get reportIssueFailedSnack =>
      'Не можеше да се испрати пријавата. Обиди се повторно.';

  @override
  String get reportIssueSheetSubtitle =>
      'Помогни ни да се подобриме. Зошто ја пријавуваш оваа локација?';

  @override
  String get reportIssueDetailsLabel => 'Дополнителни детали (незадолжително)';

  @override
  String get reportIssueDetailsHint => 'Опиши го проблемот…';

  @override
  String get mapResetFiltersSemantic => 'Ресетирај филтри';

  @override
  String get mapOpenMapsFailed => 'Не можеше да се отвори Maps';

  @override
  String get mapSearchRecentsLabel => 'Неодамна';

  @override
  String get mapSearchClearRecentsButton => 'Исчисти';

  @override
  String get mapSearchEmptyTitle => 'Пребарај загадени места';

  @override
  String get mapSearchEmptySubtitle =>
      'Внеси наслов, категорија или опис. Или избери неодамнешно пребарување.';

  @override
  String get mapSearchNoResultsTitle => 'Нема совпаѓања';

  @override
  String get mapSearchNoResultsSubtitle =>
      'Обиди се со други зборови или ресетирај филтри на мапата.';

  @override
  String mapSearchResultsBadge(int count) {
    return '$count резултати';
  }

  @override
  String get mapSearchRemoteLoading => 'Се пребаруваат сите места…';

  @override
  String get mapSearchRemoteError => 'Не можеше да се пребараат сите места.';

  @override
  String get mapSearchRemoteRetry => 'Обиди се повторно';

  @override
  String get mapSearchSectionOnMap => 'На оваа мапа';

  @override
  String get mapSearchSectionEverywhere => 'Повеќе резултати';

  @override
  String get mapSearchSuggestionsLabel => 'Предлози';

  @override
  String get mapUpdatedToast => 'Мапата е ажурирана';

  @override
  String get mapErrorAutoRetryFootnote =>
      'Ќе обидеме повторно за неколку секунди. Исто така можете да притиснете Обиди се повторно.';

  @override
  String mapFilteredSitesAnnounce(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count места се прикажуваат на мапата',
      one: 'Едно место се прикажува на мапата',
    );
    return '$_temp0';
  }

  @override
  String mapClusterExpansionAnnounce(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count места се одделени на мапата',
      one: 'Едно место е одделено на мапата',
    );
    return '$_temp0';
  }

  @override
  String get mapScreenRouteSemantic =>
      'Мапа на загадување. Допрете ги игличките за преглед на местата.';

  @override
  String get mapLoadingSemantic => 'Се вчитува мапата';

  @override
  String get mapSiteNotOnMapSnack =>
      'Ова место сè уште не е достапно на мапата.';

  @override
  String get mapOpenLocationFailedSnack =>
      'Не можеше да се отвори оваа локација на мапата.';

  @override
  String get mapEmptyFiltersLiveRegion =>
      'Нема места што одговараат на тековните филтри';

  @override
  String get mapEmptyFiltersTitle => 'Нема места што одговараат на филтрите';

  @override
  String get mapEmptyFiltersSubtitle =>
      'Прилагодете ги филтрите или пребарајте.';

  @override
  String get mapDirectionsSheetOpenInMaps => 'Отвори во Maps';

  @override
  String get mapDirectionsSheetViewLocation => 'Погледни локација';

  @override
  String get mapDirectionsSheetSubtitleDirections =>
      'Изберете апликација за навигација.';

  @override
  String get mapDirectionsSheetSubtitleViewLocation =>
      'Изберете апликација за приказ на мапа.';

  @override
  String get mapDirectionsAppleMapsTitle => 'Apple Maps';

  @override
  String get mapDirectionsAppleMapsSubtitle => 'Вградени мапи на уредот.';

  @override
  String get mapDirectionsGoogleMapsTitle => 'Google Maps';

  @override
  String get mapDirectionsGoogleMapsSubtitle => 'Веб и апликација Google Maps.';

  @override
  String get mapSemanticCloseActionsMenu => 'Затвори мени со акции';

  @override
  String get mapSemanticOpenActionsMenu => 'Отвори мени со акции';

  @override
  String get mapSemanticHideHeatmap => 'Сокриј топлотна мапа';

  @override
  String get mapSemanticShowHeatmap => 'Прикажи топлотна мапа';

  @override
  String get mapSemanticSwitchToLightMap => 'Префрли на светла мапа';

  @override
  String get mapSemanticSwitchToDarkMap => 'Префрли на темна мапа';

  @override
  String get mapSemanticZoomWholeCountry =>
      'Зумирај за да се прикаже целата држава';

  @override
  String get mapSemanticUnlockRotation => 'Отклучи ротација на мапата';

  @override
  String get mapSemanticLockRotation => 'Заклучи ротација на мапата';

  @override
  String get mapSemanticCenterOnMyLocation =>
      'Центрирај мапа на мојата локација';

  @override
  String get mapSemanticSearchSites => 'Пребарај места';

  @override
  String get mapSemanticResetRotationNorth => 'Ресетирај ротација кон север';

  @override
  String get mapFilterButtonSemanticPrefix => 'Филтрирај места.';

  @override
  String get mapFilterButtonSemanticNoMatch =>
      'Нема места што одговараат на филтрите во ова подрачје.';

  @override
  String get mapFilterButtonSemanticNoSites => 'Нема места во ова подрачје.';

  @override
  String mapFilterButtonSemanticSitesCount(int count) {
    return '$count места во ова подрачје.';
  }

  @override
  String get mapFilterButtonSemanticSuffix =>
      'Допрете за да ги отворите филтрите.';

  @override
  String get mapFilterCountNoMatch => 'Нема совпаѓање';

  @override
  String get mapFilterCountNoSites => 'Нема места';

  @override
  String get mapFilterSheetTitle => 'Филтрирај места';

  @override
  String get mapFilterCloseTooltip => 'Затвори филтри';

  @override
  String get mapFilterSectionSiteStatus => 'Статус на место';

  @override
  String get mapFilterSectionArea => 'Општина / подрачје';

  @override
  String get mapFilterSectionPollutionType => 'Тип на загадување';

  @override
  String get mapFilterSectionVisibility => 'Видливост';

  @override
  String get mapFilterShowArchivedSites => 'Прикажи архивирани места';

  @override
  String mapFilterShowingLiveRegion(int visible, int total) {
    return '$visible од $total загадени места видливи во ова подрачје';
  }

  @override
  String mapFilterShowingInline(int visible, int total) {
    return 'Се прикажуваат $visible од $total';
  }

  @override
  String mapFilterPollutionTypeSemantic(String type) {
    return 'Филтер за места од тип $type';
  }

  @override
  String get mapFilterPollutionTypeHintOff =>
      'Допрете двапати за да го прикажете овој тип';

  @override
  String get mapFilterPollutionTypeHintOn =>
      'Допрете двапати за да го сокриете овој тип';

  @override
  String get mapFilterPollutionTypeUnknown => 'Непознат тип';

  @override
  String get mapFilterSiteStatusReported => 'Пријавено';

  @override
  String get mapFilterSiteStatusVerified => 'Потврдено';

  @override
  String get mapFilterSiteStatusCleanupScheduled => 'Закажано чистење';

  @override
  String get mapFilterSiteStatusInProgress => 'Во тек';

  @override
  String get mapFilterSiteStatusCleaned => 'Исчистено';

  @override
  String get mapFilterSiteStatusDisputed => 'Оспорено';

  @override
  String get mapFilterSiteStatusArchived => 'Архивирано';

  @override
  String get mapFilterSiteStatusUnknown => 'Непознат статус';

  @override
  String mapFilterSiteStatusSemantic(String status) {
    return 'Филтер за статус $status';
  }

  @override
  String get mapFilterSiteStatusHintOff =>
      'Допрете двапати за да го прикажете овој статус';

  @override
  String get mapFilterSiteStatusHintOn =>
      'Допрете двапати за да го сокриете овој статус';

  @override
  String get mapGeoWholeCountry => 'Цела држава';

  @override
  String get mapGeoSkopjeWhole => 'Цело Скопје';

  @override
  String get mapGeoSkopje => 'Скопје';

  @override
  String get mapGeoSkopjeCentar => 'Центар';

  @override
  String get mapGeoSkopjeAerodrom => 'Аеродром';

  @override
  String get mapGeoSkopjeKarposh => 'Карпош';

  @override
  String get mapGeoSkopjeChair => 'Чаир';

  @override
  String get mapGeoSkopjeKiselaVoda => 'Кисела Вода';

  @override
  String get mapGeoSkopjeGaziBaba => 'Гази Баба';

  @override
  String get mapGeoSkopjeButel => 'Бутел';

  @override
  String get mapGeoSkopjeGjorcePetrov => 'Ѓорче Петров';

  @override
  String get mapGeoSkopjeSaraj => 'Сарај';

  @override
  String get mapGeoBitola => 'Битола';

  @override
  String get mapGeoKumanovo => 'Куманово';

  @override
  String get mapGeoPrilep => 'Прилеп';

  @override
  String get mapGeoTetovo => 'Тетово';

  @override
  String get mapGeoVeles => 'Велес';

  @override
  String get mapGeoOhrid => 'Охрид';

  @override
  String get mapGeoStip => 'Штип';

  @override
  String get mapGeoGostivar => 'Гостивар';

  @override
  String get mapGeoStrumica => 'Струмица';

  @override
  String get mapGeoKavadarci => 'Кавадарци';

  @override
  String get mapGeoKocani => 'Кочани';

  @override
  String get mapGeoStruga => 'Струга';

  @override
  String get mapGeoRadovis => 'Радовиш';

  @override
  String get mapGeoGevgelija => 'Гевгелија';

  @override
  String get mapGeoKrivaPalanka => 'Крива Паланка';

  @override
  String get mapGeoSvetiNikole => 'Свети Николе';

  @override
  String get mapGeoVinica => 'Виница';

  @override
  String get mapGeoDelcevo => 'Делчево';

  @override
  String get mapGeoProbistip => 'Пробиштип';

  @override
  String get mapGeoBerovo => 'Берово';

  @override
  String get mapGeoKratovo => 'Кратово';

  @override
  String get mapGeoKicevo => 'Кичево';

  @override
  String get mapGeoMakedonskiBrod => 'Македонски Брод';

  @override
  String get mapGeoNegotino => 'Неготино';

  @override
  String get mapGeoResen => 'Ресен';

  @override
  String get mapGeoUnknownArea => 'Непознато подрачје';

  @override
  String mapPinPreviewSemantic(String title, String severity) {
    return '$title, $severity. Допрете двапати за преглед.';
  }

  @override
  String mapClusterSemantic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count загадени места во група. Допрете двапати за проширување.',
      one: '1 загадено место во група. Допрете двапати за проширување.',
    );
    return '$_temp0';
  }

  @override
  String get mapUserLocationSemantic => 'Вашата тековна локација';

  @override
  String get mapPreviewDismissAnnouncement =>
      'Прегледот на местото е затворен.';

  @override
  String mapDistanceMetersAway(int meters) {
    return '$meters м оддалеченост';
  }

  @override
  String mapDistanceKilometersAway(String kilometers) {
    return '$kilometers км оддалеченост';
  }

  @override
  String mapPreviewSemanticLabel(String title, String distance) {
    return 'Избрано место: $title. $distance. Допрете двапати за детали. Повлечете надолу за затворање.';
  }

  @override
  String get mapPreviewSemanticHint =>
      'Користете ги копчињата за насоки или целосни детали.';

  @override
  String get mapPreviewDirections => 'Насоки';

  @override
  String get mapPreviewDetails => 'Детали';

  @override
  String get mapSyncNoticeSemanticRefreshHint =>
      'Допрете двапати за веднаш освежување на мапата.';

  @override
  String get mapSyncLiveUpdatesDelayed =>
      'Живите ажурирања се забавени. Тивко повторно се обидуваме…';

  @override
  String get mapSyncConnectionUnstable =>
      'Врската е нестабилна. Освежувањето работи во позадина…';

  @override
  String get mapSyncOfflineSnapshot =>
      'Офлајн. Се прикажува последниот зачуван преглед на мапата.';

  @override
  String get mapSyncOfflineSnapshotJustNow =>
      'Офлајн. Се прикажува последниот зачуван преглед на мапата од сега.';

  @override
  String mapSyncOfflineSnapshotMinutesAgo(int minutes) {
    return 'Офлајн. Се прикажува последниот зачуван преглед на мапата пред $minutes мин.';
  }

  @override
  String mapSyncOfflineSnapshotHoursAgo(int hours) {
    return 'Офлајн. Се прикажува последниот зачуван преглед на мапата пред $hours ч.';
  }

  @override
  String get mapSearchLocationUnavailableSnack =>
      'Локацијата не е достапна за ова место.';

  @override
  String get mapSearchFieldSemanticHint =>
      'Внесете наслов, категорија или опис';

  @override
  String get mapSearchBarHint => 'Пребарај места…';

  @override
  String get locationRetryAddressSemantic => 'Обиди повторно за адреса';

  @override
  String get photoReviewDiscardTitle => 'Да се отфрли оваа фотографија?';

  @override
  String get photoReviewDiscardBody =>
      'Можете повторно да снимите или да одберете друга од библиотеката.';

  @override
  String get reportPhotoReviewSheetTitle => 'Преглед на докази';

  @override
  String get reportPhotoReviewSheetSubtitle =>
      'Задржете го најјасниот кадар пред да го додадете во пријавата.';

  @override
  String get reportPhotoReviewSemantic =>
      'Преглед и потврда на фотографија пред додавање во пријавата';

  @override
  String get reportPhotoReviewCloseSemantic =>
      'Затвори без додавање фотографија';

  @override
  String get reportPhotoReviewRetake => 'Сними повторно';

  @override
  String get reportPhotoReviewUsePhoto => 'Потврди фотографија';

  @override
  String get reportPhotoReviewRetakeSemantic => 'Сними повторно';

  @override
  String get reportPhotoReviewUseSemantic => 'Користи ја оваа фотографија';

  @override
  String get reportPhotoReviewPreviewSemantic => 'Преглед на фотографија';

  @override
  String get reportPhotoGridAddShort => 'Додај';

  @override
  String get reportPhotoGridAdd => 'Додај фотографија';

  @override
  String get reportPhotoGridSourceHint => 'Камера или библиотека';

  @override
  String reportPhotoGridAttachedCount(int current, int max) {
    return '$current од $max прикачени фотографии';
  }

  @override
  String get reportPhotoOpenGallerySemantic =>
      'Отвори галерија со фотографии од пријавата';

  @override
  String get reportPhotoTapToReviewSingle =>
      'Допри за преглед на фотографијата';

  @override
  String get reportPhotoTapToReviewMany => 'Допри за преглед на фотографиите';

  @override
  String get reportPhotoVerificationHelpPrimarySelected =>
      'Задржете ја првата фотографија како најјасен преглед на местото.';

  @override
  String get reportPhotoVerificationHelpPrimaryOther =>
      'Користете дополнителни фотографии само за детали, размер или друг корисен агол.';

  @override
  String get reportPhotoVerificationHelpEmpty =>
      'Почнете со еден јасен преглед на местото. Додавајте детали само ако помага.';

  @override
  String get reportPhotoStackCaptionSingle =>
      'Една јасна фотографија е доволна. Додајте друга само ако помага да се објасни местото.';

  @override
  String reportPhotoStackCaptionMany(int count) {
    return '$count прикачени фотографии. Задржете ги само кадрите што ја олеснуваат верификацијата на пријавата.';
  }

  @override
  String reportPhotoSemanticThumbnail(int index, int total) {
    return 'Фотографија $index од $total. Двоен допир за избор.';
  }

  @override
  String get reportPhotoSemanticRemove => 'Отстрани фотографија';

  @override
  String get reportPhotoSemanticAddPhoto => 'Додај фотографија како доказ';

  @override
  String reportPhotoSemanticReportPhoto(int index) {
    return 'Фотографија од пријавата $index';
  }

  @override
  String get reportRequirementPhotos => 'Додајте барем една фотографија';

  @override
  String get reportRequirementCategory => 'Изберете категорија';

  @override
  String get reportRequirementTitle => 'Додајте краток наслов';

  @override
  String get reportRequirementLocation => 'Потврдете локација во Македонија';

  @override
  String get reportCooldownUnlockHintDefault =>
      'Придружете се и потврдете присуство или креирајте еко-акција за да отклучите повеќе пријави.';

  @override
  String get notificationsTitle => 'Известувања';

  @override
  String get notificationsMarkAllRead => 'Означи сè прочитано';

  @override
  String get notificationsShowAll => 'Прикажи ги сите известувања';

  @override
  String get notificationsPreferencesTooltip => 'Поставки за известувања';

  @override
  String get notificationsScrollToTopSemantic =>
      'Скролувај на врв на известувањата';

  @override
  String get notificationsRetryLoadingMore => 'Обиди повторно да вчиташ повеќе';

  @override
  String get notificationsMarkAllReadFailed =>
      'Не можеше да се означат сите како прочитани. Обидете се повторно.';

  @override
  String get notificationsAllMarkedReadSuccess =>
      'Сите известувања се означени како прочитани';

  @override
  String get notificationsSiteUnavailable =>
      'Оваа локација повеќе не е достапна.';

  @override
  String get notificationsReadStateUpdateFailed =>
      'Не можеше да се ажурира статусот. Обидете се повторно.';

  @override
  String get notificationsMarkedUnreadLocal =>
      'Означено како непрочитано (локално).';

  @override
  String get notificationsArchiveFailed =>
      'Не може да се архивира известувањето. Обидете се повторно.';

  @override
  String get notificationsArchivedFromView => 'Известувањето е архивирано';

  @override
  String get notificationsPrefsLoadFailed =>
      'Не можеа да се вчитаат поставките за известувања.';

  @override
  String get notificationsPreferenceUpdateFailed =>
      'Не можеше да се ажурира поставката. Обидете се повторно.';

  @override
  String get notificationsPrefsSheetTitle => 'Поставки за известувања';

  @override
  String get notificationsPrefsSheetSubtitle =>
      'Исклучете ги типовите известувања што не сакате да ги примате.';

  @override
  String get notificationsPrefMuted => 'Исклучено';

  @override
  String get notificationsPrefEnabled => 'Вклучено';

  @override
  String notificationsPrefSnoozedUntil(String time) {
    return 'Одложено до $time';
  }

  @override
  String get notificationsSnoozeTitle => 'Времетраење на одлагање';

  @override
  String get notificationsSnooze1h => '1 час';

  @override
  String get notificationsSnooze4h => '4 часа';

  @override
  String get notificationsSnooze8h => '8 часа';

  @override
  String get notificationsSnooze24h => '24 часа';

  @override
  String get notificationsSnooze1w => '1 седмица';

  @override
  String get notificationsSnoozePermanent => 'Додека не го вклучам';

  @override
  String get notificationsPauseAll => 'Паузирај ги сите известувања';

  @override
  String get notificationsTypeSiteUpdates => 'Ажурирања за локации';

  @override
  String get notificationsTypeReportStatus => 'Статус на пријава';

  @override
  String get notificationsTypeUpvotes => 'Поддршки';

  @override
  String get notificationsTypeComments => 'Коментари';

  @override
  String get notificationsTypeNearbyReports => 'Пријави во близина';

  @override
  String get notificationsTypeCleanupEvents => 'Акции за чистење';

  @override
  String get notificationsTypeSystem => 'Системски';

  @override
  String get notificationsSwipeMarkUnread => 'Означи непрочитано';

  @override
  String get notificationsSwipeMarkRead => 'Означи прочитано';

  @override
  String get notificationsSwipeArchive => 'Архивирај';

  @override
  String get notificationsDebugPreviewTriggered =>
      'Локален преглед на известување';

  @override
  String get notificationsAllCaughtUp => 'Сè е ажурирано';

  @override
  String notificationsUnreadUpdatesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count непрочитани ажурирања',
      one: '1 непрочитано ажурирање',
    );
    return '$_temp0';
  }

  @override
  String get notificationsUnreadBannerOne => 'Имате 1 непрочитано известување';

  @override
  String notificationsUnreadBannerMany(int count) {
    return 'Имате $count непрочитани известувања';
  }

  @override
  String get notificationsSwipeHint =>
      'Повлечи десно за прочитано/непрочитано · лево за архива';

  @override
  String get notificationsEmptyUnreadTitle => 'Нема непрочитани известувања';

  @override
  String get notificationsEmptyAllTitle => 'Сè уште нема известувања';

  @override
  String get notificationsEmptyUnreadBody =>
      'Сè е ажурирано. Новите ажурирања ќе се појават тука.';

  @override
  String get notificationsEmptyAllBody =>
      'Кога некој ќе реагира на локации и акции, ажурирањата ќе се појават тука.';

  @override
  String get notificationsErrorLoadTitle =>
      'Не можеа да се вчитаат известувањата';

  @override
  String get notificationsErrorLoadFallback =>
      'Проверете ја врската и обидете се повторно.';

  @override
  String get notificationsErrorNetwork =>
      'Проблем со мрежата при вчитување на известувања.';

  @override
  String get notificationsErrorGeneric =>
      'Нешто тргна наопаку при вчитување на известувања.';

  @override
  String get notificationsFilterAll => 'Сите';

  @override
  String get notificationsFilterUnread => 'Непрочитани';

  @override
  String get eventsEventNotFoundTitle => 'Настанот не е пронајден';

  @override
  String get eventsEventNotFoundBody => 'Овој настан повеќе не е достапен.';

  @override
  String get eventsDetailBrowseEvents => 'Прегледај настани';

  @override
  String get eventsDetailCouldNotRefresh =>
      'Не можеше освежување. Се прикажуваат зачувани детали.';

  @override
  String get eventsDetailRetryRefresh => 'Обиди се повторно';

  @override
  String get eventsDetailLocationTitle => 'Локација';

  @override
  String get eventsDetailCopyAddress => 'Копирај адреса';

  @override
  String get eventsDetailAddressCopied => 'Адресата е копирана';

  @override
  String get eventsDetailLocationLongPressHint =>
      'Долг притисок за целосна адреса и акции';

  @override
  String get eventsDetailCoverImageUnavailable => 'Сликата не е достапна';

  @override
  String get eventsWeatherUnavailableBody =>
      'Прогнозата моментално не е достапна.';

  @override
  String get eventsWeatherRetry => 'Обиди се повторно';

  @override
  String get eventsUnableToStartEventGeneric =>
      'Не можевме да го започнеме настанот. Проверете ја врската и обидете се повторно.';

  @override
  String get eventsStartEventTooEarly =>
      'Можете да го започнете ова еко дејство откако ќе настапи закажаното време на почеток.';

  @override
  String get eventsJoinNotYetOpen =>
      'Приклучувањето се отвора кога ќе настапи закажаното време на почеток.';

  @override
  String get eventsJoinWindowClosed =>
      'Не можете повеќе да се придружите. Приклучувањето беше отворено до 15 минути по закажаниот почеток.';

  @override
  String get errorEventEndAtTooFar =>
      'Планираниот крај не може да биде толку далеку од почетокот. Обидете се со пократко продолжување.';

  @override
  String get errorEventsEndDifferentSkopjeCalendarDay =>
      'Крајот мора да биде истиот календарски ден како почетокот (Европа/Скопје).';

  @override
  String get errorEventsEndAfterSkopjeLocalDay =>
      'Настанот мора да заврши до 23:59 на денот на почетокот.';

  @override
  String get eventsAwaitingModerationCta => 'Чека одобрување';

  @override
  String get eventsModerationBannerTitle => 'Чека одобрување';

  @override
  String get eventsModerationBannerBody =>
      'Оваа акција е видлива за вас како организатор. Волонтерите ќе можат да се придружат откако модераторите ќе ја одобрат.';

  @override
  String get eventsAttendeeModerationBannerTitle => 'Чека одобрување';

  @override
  String get eventsAttendeeModerationBannerBody =>
      'Модераторите ја разгледуваат акцијата. Можете да ја отворите, но придружувањето се отвора откако ќе биде одобрена.';

  @override
  String get eventsDeclinedBannerTitle => 'Не е одобрен';

  @override
  String get eventsDeclinedBannerBody =>
      'Настанот не ги исполни критериумите. Уредете и поднесете повторно.';

  @override
  String get eventsDeclinedResubmitCta => 'Уреди и поднеси';

  @override
  String get eventsDeclinedDashboardPill => 'Одбиен';

  @override
  String get eventsPendingDashboardPill => 'На преглед';

  @override
  String get eventsEventPendingPublicCta =>
      'Сè уште не е отворено за придружување';

  @override
  String get eventsFeedOfflineStaleBanner =>
      'Прикажани се зачувани настани — освежувањето не успеа. Повлечете надолу за повторен обид.';

  @override
  String get eventsFeedInitialLoadFailed =>
      'Не можевме да ги вчитаме настаните. Проверете ја врската и обидете се повторно.';

  @override
  String get eventsOrganizerInvalidateQrTitle =>
      'Инвалидирај претходни QR кодови';

  @override
  String get eventsOrganizerInvalidateQrSubtitle =>
      'Користете ако кодот бил споделен или фотографиран. Веќе скенираните кодови важат до истек; ова ја ротира сесијата за нови скенирања.';

  @override
  String get eventsOrganizerQrSessionRotated =>
      'QR сесијата е обновена. Покажете му го новиот код на учесниците.';

  @override
  String get eventsOrganizerQrRotateFailed =>
      'Не можевме да ги инвалидираме кодовите. Обидете се повторно.';

  @override
  String get eventsEditEventTitle => 'Уреди настан';

  @override
  String get eventsEditEventSave => 'Зачувај промени';

  @override
  String editEventTitleTooLong(int max) {
    return 'Насловот смее да има најмногу $max знаци.';
  }

  @override
  String editEventDescriptionTooLong(int max) {
    return 'Описот смее да има најмногу $max знаци.';
  }

  @override
  String get editEventMaxParticipantsInvalid =>
      'Внесете цел број места или оставете празно за без ограничување.';

  @override
  String editEventMaxParticipantsRange(int min, int max) {
    return 'Големината на тимот мора да биде помеѓу $min и $max, или празно за без ограничување.';
  }

  @override
  String editEventGearLimitReached(int max) {
    return 'Можете да изберете најмногу $max ставки опрема.';
  }

  @override
  String get editEventDiscardTitle => 'Да се отфрлат промените?';

  @override
  String get editEventDiscardMessage =>
      'Имате незачувани промени. Ако заминете сега, ќе се изгубат.';

  @override
  String get editEventDiscardConfirm => 'Отфрли';

  @override
  String get editEventDiscardKeepEditing => 'Продолжи со уредување';

  @override
  String get editEventSchedulePreviewFailed =>
      'Не можеше да се провери распоредот. Сè уште можете да зачувате; серверот ќе ги одбие преклопувањата.';

  @override
  String get editEventOfflineSave =>
      'Изгледа дека сте офлајн. Поврзете се и обидете повторно.';

  @override
  String get editEventHelpTitle => 'Уредување на настан';

  @override
  String get editEventHelpSubtitle => 'Распоред, волонтери и модерација';

  @override
  String get editEventHelpButtonTooltip => 'Помош';

  @override
  String get editEventDuplicateSubmitTitle => 'Конфликт во распоредот';

  @override
  String editEventDuplicateSubmitBody(String title, String when) {
    return '$title веќе е закажан во $when. Прилагодете ги времињата и обидете се повторно.';
  }

  @override
  String get editEventNoChangesToSave => 'Нема што да се зачува.';

  @override
  String get editEventPendingModerationBanner =>
      'Настанот сè уште чека одобрување од модератор. Промените важат за вашата нацрт-верзија.';

  @override
  String get eventsEventNotEditable =>
      'Овој настан повеќе не може да се уредува.';

  @override
  String get eventsEventUpdated => 'Настанот е ажуриран';

  @override
  String get eventsMutationFailedGeneric =>
      'Нешто не е во ред. Обидете се повторно.';

  @override
  String get eventsScheduleConflictPreviewTitle => 'Можен преклоп на термин';

  @override
  String eventsScheduleConflictPreviewBody(String title, String when) {
    return 'Друг настан на ова место може да се преклопува со вашиот термин: $title во $when.';
  }

  @override
  String get eventsScheduleConflictContinue => 'Сепак продолжи';

  @override
  String get eventsScheduleConflictAdjustTime => 'Промени време';

  @override
  String eventsDuplicateEventBlocked(String title, String when) {
    return 'Овој термин се преклопува со „$title“ ($when). Изберете друго време.';
  }

  @override
  String get eventsManualCheckInAdd => 'Додај';

  @override
  String get eventsManualCheckInTitle => 'Рачен check-in';

  @override
  String get eventsCheckInTitle => 'Check-in';

  @override
  String get eventsOrganizerMockAllCheckedIn =>
      'Сите пробни учесници веќе се пријавени.';

  @override
  String get eventsOrganizerAttendeeNamePlaceholder => 'Име на учесник';

  @override
  String get eventsOrganizerManualCheckInSubtitle =>
      'Пребарајте волонтери што се пријавиле на настанот, потоа ги пријавете.';

  @override
  String get eventsOrganizerManualCheckInNoJoiners =>
      'Сè уште нема пријавени волонтери на овој настан.';

  @override
  String get eventsOrganizerManualCheckInSelectParticipant =>
      'Изберете волонтер од листата.';

  @override
  String get eventsOrganizerManualCheckInNotParticipant =>
      'Оваа личност не е на листата на учесници.';

  @override
  String get eventsOrganizerEnterNameFirst =>
      'Прво внесете го името на учесникот.';

  @override
  String eventsOrganizerNameAlreadyCheckedIn(String name) {
    return '$name веќе е пријавен/а.';
  }

  @override
  String eventsOrganizerNameAddedByOrganizer(String name) {
    return '$name е додаден/а од организаторот.';
  }

  @override
  String eventsOrganizerCouldNotRemoveName(String name) {
    return 'Не можеше да се отстрани $name.';
  }

  @override
  String eventsOrganizerNameRemovedFromCheckIn(String name) {
    return '$name е отстранет/а од пријавата.';
  }

  @override
  String get eventsOrganizerUnableCompleteEvent =>
      'Не можеше да се заврши настанот.';

  @override
  String get eventsOrganizerEndedTitle => 'Настанот заврши';

  @override
  String get eventsOrganizerThanksOrganizing =>
      'Ви благодариме за организацијата!';

  @override
  String get eventsOrganizerEndSummaryOneAttendee => '1 учесник се пријави.';

  @override
  String eventsOrganizerEndSummaryManyAttendees(int count) {
    return '$count учесници се пријавија.';
  }

  @override
  String get eventsOrganizerUploadAfterPhotosHint =>
      'Поставете ги фотографиите „потоа“ од деталите за настанот.';

  @override
  String get eventsOrganizerCompletionCheckedInNone => 'Никој не се чекирал.';

  @override
  String eventsOrganizerCompletionJoinedLine(int count) {
    return '$count доброволци се пријавиле';
  }

  @override
  String eventsOrganizerCompletionJoinedOfCap(int joined, int cap) {
    return '$joined од $cap места се пополнети';
  }

  @override
  String get eventsOrganizerCompletionSheetSemantic =>
      'Настанот е завршен. Прегледајте ги следните чекори.';

  @override
  String get eventsOrganizerCompletionBackToEvent => 'Назад кон настанот';

  @override
  String get eventsOrganizerCompletionAddPhotosNow => 'Додај фотографии сега';

  @override
  String get eventsOrganizerCompletionWhatNextIntro =>
      'Завршете на страницата на настанот: документирајте резултати и споделете го влијанието.';

  @override
  String get eventsOrganizerCompletionNextStepsHeading => 'СЛЕДНИ ЧЕКОРИ';

  @override
  String get eventsOrganizerCompletionStepPhotosTitle =>
      'Додајте фотографии „потоа“';

  @override
  String get eventsOrganizerCompletionStepPhotosBody =>
      'Покажете ја разликата. Тие се гледаат на страницата на настанот за сите.';

  @override
  String get eventsOrganizerCompletionStepImpactTitle =>
      'Запишете го влијанието';

  @override
  String get eventsOrganizerCompletionStepImpactBody =>
      'Забележете торби, волонтерски часови и проценки од страницата на настанот.';

  @override
  String get eventsOrganizerCompletionStepVisibilityTitle =>
      'Изградете доверба';

  @override
  String get eventsOrganizerCompletionStepVisibilityBody =>
      'Фотографиите им помагаат на модераторите и инспирираат идни акции.';

  @override
  String get eventsOrganizerCompletionViewReceipt =>
      'Погледни потврда за влијание';

  @override
  String get eventsImpactReceiptScreenTitle => 'Потврда за влијание';

  @override
  String eventsImpactReceiptHeroSemantic(String title) {
    return 'Потврда за влијание за $title';
  }

  @override
  String get eventsImpactReceiptMetricCheckIns => 'Пријави присуство';

  @override
  String get eventsImpactReceiptMetricParticipants => 'Пријавени';

  @override
  String get eventsImpactReceiptMetricBags => 'Торби (пријавено)';

  @override
  String get eventsImpactReceiptProofHeading => 'Доказ';

  @override
  String get eventsImpactReceiptNoMediaHint =>
      'Додајте фотографии „потоа“ или структурирани докази од страницата на настанот.';

  @override
  String eventsImpactReceiptAsOf(String timestamp) {
    return 'Ажурирано $timestamp';
  }

  @override
  String get eventsImpactReceiptCompletenessInProgress => 'Во тек';

  @override
  String get eventsImpactReceiptCompletenessFull => 'Целосен запис';

  @override
  String get eventsImpactReceiptCompletenessPartialAfter =>
      'Недостасуваат фотографии „потоа“';

  @override
  String get eventsImpactReceiptCompletenessPartialEvidence =>
      'Недостасува структуриран доказ';

  @override
  String get eventsImpactReceiptCompletenessPartialBoth =>
      'Недостасуваат фотографии и доказ';

  @override
  String get eventsImpactReceiptShare => 'Сподели';

  @override
  String get eventsImpactReceiptCopyLink => 'Копирај врска';

  @override
  String get eventsImpactReceiptLinkCopied => 'Врската е копирана';

  @override
  String get eventsImpactReceiptViewCta => 'Потврда за влијание';

  @override
  String get eventsImpactReceiptRetry => 'Обиди се повторно';

  @override
  String get eventsImpactReceiptLoadFailed => 'Не може да се вчита потврдата.';

  @override
  String eventsImpactReceiptShareSummary(int checkIns, int bags, int joined) {
    return '$checkIns пријави · $bags торби · $joined пријавени';
  }

  @override
  String get errorEventsImpactReceiptNotAvailable =>
      'Потврдата за влијание сè уште не е достапна за овој настан.';

  @override
  String get eventsOrganizerDetailPendingAfterPhotosTitle =>
      'Фотографии „потоа“';

  @override
  String get eventsOrganizerDetailPendingAfterPhotosMessage =>
      'Поставете фотографии по чистењето за да ги видат доброволците и модераторите. Користете го копчето подолу.';

  @override
  String get eventsAttendeeCompletedTitle => 'Ви благодариме';

  @override
  String get eventsAttendeeCompletedBody =>
      'Оваа еко-акција е завршена. Ви благодариме што дојдовте.';

  @override
  String get eventsAfterPhotosOrganizerEmptyHint =>
      'Сè уште нема фотографии „потоа“. Користете го копчето подолу за да додадете.';

  @override
  String get eventsEvidenceScreenSubtitle =>
      'Фотографиите „потоа“ го документираат резултатот и се појавуваат на страницата на настанот.';

  @override
  String eventsEvidencePhotoCountChip(int current, int max) {
    return '$current од $max фотографии';
  }

  @override
  String get eventsEvidenceBeforeAfterTabsSemantic => 'Фотографии пред и потоа';

  @override
  String get eventsEvidenceSavingSemantic =>
      'Се зачувуваат фотографиите „потоа“';

  @override
  String get eventsOrganizerCheckInPausedSnack => 'Пријавата е паузирана.';

  @override
  String get eventsOrganizerCheckInResumedSnack =>
      'Пријавата е активна повторно.';

  @override
  String get eventsOrganizerUnableCancelEvent =>
      'Не можеше да се откаже настанот.';

  @override
  String get eventsOrganizerEventCancelledSnack => 'Настанот е откажан.';

  @override
  String eventsOrganizerFeedbackCheckedIn(String name) {
    return '$name се пријави';
  }

  @override
  String get eventsOrganizerFeedbackInvalidQr => 'Невалиден QR-код.';

  @override
  String get eventsOrganizerFeedbackWrongEvent => 'Погрешен QR за настанот.';

  @override
  String get eventsOrganizerFeedbackPaused =>
      'Пријавата моментално е паузирана.';

  @override
  String get eventsOrganizerFeedbackQrExpired =>
      'QR-кодот истече. Генерирајте нов.';

  @override
  String get eventsOrganizerFeedbackQrReplay =>
      'QR-кодот веќе е искористен. Се освежува…';

  @override
  String eventsOrganizerFeedbackAlreadyCheckedIn(String name) {
    return '$name веќе е пријавен/а.';
  }

  @override
  String get eventsOrganizerQrRefreshHelp =>
      'Учесниците секогаш треба да го скенираат најновиот QR. Кодот се освежува автоматски пред да истече.';

  @override
  String get eventsOrganizerHoldPhoneForScan =>
      'Држете го телефонот за да можат да скенираат';

  @override
  String get eventsOrganizerPausedLabel => 'Пријавата е паузирана';

  @override
  String get eventsOrganizerStatusOpen => 'Отворено';

  @override
  String get eventsOrganizerStatusPaused => 'Паузирано';

  @override
  String eventsOrganizerRefreshInSeconds(int seconds) {
    return 'Освежување за $seconds с';
  }

  @override
  String get eventsOrganizerQrRefreshesWhenOpen =>
      'QR се освежува автоматски и по секое скенирање';

  @override
  String get eventsOrganizerResumeForFreshQr =>
      'Продолжете со пријава за нов QR';

  @override
  String get eventsOrganizerQrLoadFailedGeneric =>
      'Не можеше да се вчита код за пријава. Проверете ја врската и обидете се повторно.';

  @override
  String get eventsOrganizerQrRateLimited =>
      'Премногу обиди за освежување. Почекајте малку и обидете се повторно.';

  @override
  String get eventsOrganizerSessionSetupFailed =>
      'Не можевме да започнеме евиденција. Потврдете дека настанот е во тек и обидете се повторно.';

  @override
  String get eventsOrganizerConfirmTitle => 'Потврди пријавување';

  @override
  String get eventsOrganizerConfirmSubtitle =>
      'Сака да се пријави на овој настан';

  @override
  String get eventsOrganizerConfirmApprove => 'Потврди';

  @override
  String get eventsOrganizerConfirmReject => 'Одбиј';

  @override
  String get eventsOrganizerConfirmExpired =>
      'Ова барање за пријавување е истечено.';

  @override
  String get eventsVolunteerPendingTitle => 'Се чека потврда';

  @override
  String get eventsVolunteerPendingSubtitle =>
      'Организаторот треба да го потврди вашето пријавување...';

  @override
  String get eventsVolunteerRejected =>
      'Пријавувањето не беше потврдено од организаторот.';

  @override
  String get eventsVolunteerExpired =>
      'Барањето е истечено. Скенирајте повторно.';

  @override
  String get eventsOrganizerQrRetry => 'Обиди повторно';

  @override
  String get eventsOrganizerQrBrightnessHint =>
      'Совет: зголемете ја осветленоста на екранот за полесно скенирање.';

  @override
  String eventsOrganizerQrSemantics(int seconds) {
    return 'QR-код за пријава. Се освежува за околу $seconds секунди.';
  }

  @override
  String get eventsOrganizerQrEncodeError =>
      'Кодот не можеше да се прикаже. Допрете обиди повторно.';

  @override
  String get eventsOrganizerFeedbackInvalidQrStrict =>
      'Тој QR не важи за пријава.';

  @override
  String get eventsOrganizerFeedbackRequiresJoin =>
      'Прво се пријавете на настанот во апликацијата.';

  @override
  String get eventsOrganizerFeedbackCheckInUnavailable =>
      'Пријавата моментално не е достапна за овој настан.';

  @override
  String get eventsOrganizerFeedbackRateLimited =>
      'Премногу обиди. Почекајте кратко и обидете се повторно.';

  @override
  String get eventsOrganizerCopyQrText => 'Копирај QR код текст';

  @override
  String get eventsOrganizerQrTextCopied =>
      'QR код текстот е копиран — залепете го во порака до учесниците кои не можат да скенираат.';

  @override
  String get eventsOrganizerNoQrToCopy =>
      'Сè уште нема активен QR код за копирање.';

  @override
  String get eventsOrganizerManualOverride =>
      'Рачно: означи учесник како присутен';

  @override
  String get eventsOrganizerCheckedInHeading => 'Пријавени';

  @override
  String get eventsOrganizerEmptyListTitle => 'Сè уште никој не се пријавил';

  @override
  String get eventsOrganizerEmptyListSubtitle =>
      'Учесниците го скенираат вашиот QR за пријава';

  @override
  String get eventsOrganizerEndEvent => 'Заврши настан';

  @override
  String get eventsOrganizerPauseCheckIn => 'Паузирај пријава';

  @override
  String get eventsOrganizerResumeCheckIn => 'Продолжи пријава';

  @override
  String get eventsOrganizerCancelEvent => 'Откажи настан';

  @override
  String get eventsOrganizerMoreActionsSemantic => 'Повеќе акции за настанот';

  @override
  String get eventsOrganizerMoreSheetTitle => 'Акции за настанот';

  @override
  String get eventsOrganizerEndEventConfirmTitle => 'Да се заврши настанот?';

  @override
  String get eventsOrganizerEndEventConfirmMessage =>
      'Пријавата ќе се затвори и настанот ќе биде означен како завршен. Подоцна можеш да прикачиш фотографии од деталите за настанот.';

  @override
  String get eventsOrganizerEndEventKeepManaging => 'Продолжи со управување';

  @override
  String get eventsOrganizerEndEventConfirmAction => 'Заврши настан';

  @override
  String get eventsOrganizerCancelEventConfirmTitle => 'Да се откаже настанот?';

  @override
  String get eventsOrganizerCancelEventConfirmMessage =>
      'Волонтерите ќе го видат настанот како откажан. Ова не може да се врати од апликацијата.';

  @override
  String get eventsOrganizerCancelEventKeepEvent => 'Задржи настан';

  @override
  String get eventsOrganizerCancelEventConfirmAction => 'Откажи настан';

  @override
  String eventsOrganizerRemoveAttendeeSemantic(String name) {
    return 'Отстрани го $name од пријавата';
  }

  @override
  String get eventsOrganizerSimulateCheckInDev => 'Симулирај check-in (dev)';

  @override
  String get eventsPhotosTitle => 'Фотографии';

  @override
  String get createEventDefaultDescription =>
      'Заедничка акција за чистење организирана од локални волонтери.';

  @override
  String get createEventCategoryTitle => 'Тип на настан';

  @override
  String get createEventCategorySubtitle => 'Каква акција организирате?';

  @override
  String get createEventGearTitle => 'Потребна опрема';

  @override
  String get createEventGearSubtitle =>
      'Изберете што волонтерите треба да понесат.';

  @override
  String createEventGearDoneSelectedCount(int count) {
    return 'Готово ($count избрани)';
  }

  @override
  String get createEventGearMultiselectTitle => 'Повеќекратен избор';

  @override
  String get createEventGearMultiselectMessage =>
      'Допрете ги ставките што волонтерите треба да понесат. Може да изберете повеќе.';

  @override
  String get createEventTeamSizeTitle => 'Големина на тим';

  @override
  String get createEventTeamSizeSubtitle => 'Колку волонтери очекувате?';

  @override
  String get createEventDifficultyTitle => 'Тешкотија';

  @override
  String get createEventDifficultySubtitle =>
      'Поставете очекувања за волонтерите.';

  @override
  String createEventStepProgress(int step) {
    return 'Чекор $step од 5';
  }

  @override
  String get createEventEndTimeError =>
      'Крајот мора да биде подоцна од почетокот.';

  @override
  String createEventScheduleStartInPast(int minutes) {
    return 'Изберете почеток најмалку $minutes минути од сега.';
  }

  @override
  String createEventScheduleEndInPast(int minutes) {
    return 'Изберете крај најмалку $minutes минути од сега.';
  }

  @override
  String get createEventScheduleDateLabel => 'Датум на настанот';

  @override
  String get createEventScheduleEndAfterDayError =>
      'Настанот мора да заврши до 23:59 истиот ден.';

  @override
  String get createEventFieldType => 'Тип на настан';

  @override
  String get createEventPlaceholderType => 'Изберете тип';

  @override
  String get createEventFieldTeamSize => 'Големина на тим';

  @override
  String get createEventPlaceholderTeamSize => 'Колку луѓе?';

  @override
  String get createEventFieldDifficulty => 'Тешкотија';

  @override
  String get createEventPlaceholderDifficulty => 'Поставете ниво на тешкотија';

  @override
  String get createEventSubmitLabel => 'Креирај еко-акција';

  @override
  String get createEventAppBarTitle => 'Креирај настан';

  @override
  String get createEventHelpTitle => 'Креирање настан';

  @override
  String get createEventHelpSubtitle => 'Краток водич за организатори';

  @override
  String get createEventHelpBulletModeration =>
      'Настаните се проверуваат за точни и безбедни акции за заедницата.';

  @override
  String get createEventHelpBulletVolunteers =>
      'Доброволците гледаат наслов, распоред, локација, опрема и опис кога настанот е објавен.';

  @override
  String get createEventHelpBulletSite =>
      'Изберете локација од листата или мапата за да знаат сите каде да се сретнат.';

  @override
  String get createEventHelpBulletSchedule =>
      'Изберете датум на настанот, па почетно и крајно време истиот ден.';

  @override
  String get createEventHelpBulletSameDay =>
      'Настанот мора да заврши истиот календарски ден, најдоцна до 23:59.';

  @override
  String get createEventHelpBulletSubmit =>
      'Кога се пополнети задолжителните полиња, користете „Креирај еко-акција“ за објавување.';

  @override
  String get createEventFieldVolunteerCap => 'Лимит на доброволци';

  @override
  String get createEventVolunteerCapPlaceholderNoLimit => 'Без лимит';

  @override
  String createEventVolunteerCapUpTo(int count) {
    return 'До $count доброволци';
  }

  @override
  String get createEventVolunteerCapSheetTitle => 'Лимит на доброволци';

  @override
  String get createEventVolunteerCapSheetSubtitle =>
      'Изборно. Лимитот е помеѓу 2 и 5000.';

  @override
  String get createEventVolunteerCapNoLimit => 'Без лимит';

  @override
  String get createEventVolunteerCapCustomLabel => 'Сопствен број';

  @override
  String get createEventVolunteerCapCustomHint => 'Број (2–5000)';

  @override
  String get createEventVolunteerCapApply => 'Примени';

  @override
  String get createEventVolunteerCapInvalid =>
      'Внесете цел број помеѓу 2 и 5000.';

  @override
  String get createEventSitePickerLoading => 'Се вчитуваат локации…';

  @override
  String get createEventSitePickerOfflineTitle => 'Офлајн листа';

  @override
  String get createEventSitePickerOfflineMessage =>
      'Се прикажуваат вградени локации бидејќи живата листа е празна или недостапна.';

  @override
  String get createEventSitePickerLoadFailedTitle => 'Не можеше освежување';

  @override
  String get createEventSitePickerLoadFailedMessage =>
      'Сè уште можете да изберете од офлајн листата. Обидете се повторно за жива листа.';

  @override
  String get createEventSitePickerRetry => 'Обиди се повторно';

  @override
  String get createEventDiscardTitle => 'Отфрли настан?';

  @override
  String get createEventDiscardBody =>
      'Ќе ги изгубите внесените податоци на овој екран.';

  @override
  String get createEventDiscardKeepEditing => 'Продолжи уредување';

  @override
  String get createEventLoadingSemantic =>
      'Се вчитува формата за креирање настан';

  @override
  String get createEventSectionScheduleCaption => 'Распоред';

  @override
  String get createEventSectionDetailsCaption => 'Детали за настанот';

  @override
  String get createEventCleanupSiteTitle => 'Локација за чистење';

  @override
  String get createEventSelectSiteSemantic => 'Избери локација за чистење';

  @override
  String get createEventChooseSitePlaceholder =>
      'Изберете локација со загадување';

  @override
  String get createEventSiteAnchorHint =>
      'Секој настан треба да биде врзан за една локација за чистење.';

  @override
  String createEventSiteDistanceAway(String distanceKm, String description) {
    return '$distanceKm км надалеку · $description';
  }

  @override
  String get createEventSiteRequiredError =>
      'Изберете локација пред да креирате настан.';

  @override
  String get createEventTitleLabel => 'Наслов на настанот';

  @override
  String createEventTitleCounter(int current, int max) {
    return '$current / $max';
  }

  @override
  String get createEventTitleHint => 'напр. Чистење на реката за викенд';

  @override
  String get createEventTitleRequired => 'Насловот е задолжителен.';

  @override
  String get createEventTitleMinLength =>
      'Користете најмалку 3 знаци за насловот.';

  @override
  String get createEventSitePickerTabList => 'Листа';

  @override
  String get createEventSitePickerTabMap => 'Мапа';

  @override
  String get createEventSitePickerMapEmpty =>
      'Нема локации на мапата за ова пребарување или координатите сè уште не се достапни.';

  @override
  String get createEventSitePickerMapSemanticLabel =>
      'Мапа на локации со загадување';

  @override
  String get createEventSitePickerMapHint =>
      'Допрете пин за да изберете локација.';

  @override
  String get createEventSiteMapPreviewSemantic =>
      'Отвори избор на локација на мапа';

  @override
  String get createEventTypeRequired => 'Изберете тип на настан.';

  @override
  String get createEventGearPlaceholderQuestion =>
      'Што треба да понесат волонтерите?';

  @override
  String get createEventGearLabel => 'Потребна опрема';

  @override
  String get createEventSelectGearSemantic => 'Избери потребна опрема';

  @override
  String get createEventDescriptionLabel => 'Опис';

  @override
  String get createEventDescriptionSubtitle =>
      'Незадолжително: повеќе контекст за волонтерите.';

  @override
  String get createEventDescriptionHint =>
      'Опишете што да очекуваат, место на собирање итн.';

  @override
  String get eventsEventNotFoundShort => 'Настанот не е пронајден.';

  @override
  String get eventsBeforeLabel => 'Пред';

  @override
  String get eventsAfterLabel => 'Потоа';

  @override
  String get eventsDiscardChangesTitle => 'Да се отфрлат промените?';

  @override
  String get eventsDiscardChangesBody =>
      'Имате незачувани фотографии. Дали сигурно сакате да излезете?';

  @override
  String get eventsSetCover => 'Постави како насловна';

  @override
  String get eventsViewFullscreen => 'Цел екран';

  @override
  String get eventsAddToCalendar => 'Додај во календар';

  @override
  String get eventsParticipantsRecent => 'Неодамнешни';

  @override
  String get eventsParticipantsAz => 'А-Ш';

  @override
  String get eventsParticipantsCheckedIn => 'Пријавени';

  @override
  String get eventsSaveImpactSummary => 'Зачувај преглед на ефект';

  @override
  String get eventsCheckedInBadge => 'Пријавен/а';

  @override
  String eventsCleanupPhotosCount(int count) {
    return '$count фотографии од чистење';
  }

  @override
  String get eventsCtaStartEvent => 'Започни настан';

  @override
  String get eventsCtaManageCheckIn => 'Управувај со пријава';

  @override
  String get eventsCtaExtendCleanupEnd => 'Продолжи планиран крај';

  @override
  String get eventsExtendEndSheetTitle => 'Продолжи чистење';

  @override
  String eventsExtendEndSheetSubtitle(String time) {
    return 'Моментално планиран крај е $time.';
  }

  @override
  String eventsExtendEndCurrentChoice(String time) {
    return 'Нов крај: $time';
  }

  @override
  String get eventsExtendEndPlus15 => '+15 мин';

  @override
  String get eventsExtendEndPlus30 => '+30 мин';

  @override
  String get eventsExtendEndPlus60 => '+1 час';

  @override
  String get eventsExtendEndCustomTime => 'Сопствено време…';

  @override
  String get eventsExtendEndApply => 'Зачувај нов крај';

  @override
  String get eventsExtendEndSuccess => 'Планираниот крај е ажуриран.';

  @override
  String get eventsExtendEndSameAsCurrent => 'Тоа веќе е планираниот крај.';

  @override
  String get eventsExtendEndInvalidRange =>
      'Тоа време на крај не е валидно за ова чистење.';

  @override
  String get eventsExtendEndTooSoon => 'Изберете крај малку подалеку напред.';

  @override
  String get eventsEndSoonBannerTitle => 'Чистењето наскоро завршува';

  @override
  String get eventsEndSoonBannerBody =>
      'Можете да го продолжите планираниот крај или да завршите кога сте подготвени.';

  @override
  String get eventsEndSoonBannerExtend => 'Продолжи';

  @override
  String get eventsOrganizerExtendEndSemantic =>
      'Продолжи го планираниот крај на чистењето';

  @override
  String get eventsOrganizerEndSoonNotifyTitle => 'Чистењето наскоро завршува';

  @override
  String get eventsOrganizerEndSoonNotifyBody =>
      'Вашето чистење се приближува до планираниот крај. Допрете за преглед.';

  @override
  String get eventsOrganizerEndSoonNotifyChannelName =>
      'Локални потсетници за организатори';

  @override
  String get eventsOrganizerEndSoonNotifyChannelDescription =>
      'Локални потсетници кога чистењето што го водите се приближува до планираниот крај.';

  @override
  String get eventsCtaEditAfterPhotos => 'Уреди фотографии потоа';

  @override
  String get eventsCtaUploadAfterPhotos => 'Прикачи фотографии потоа';

  @override
  String get eventsCtaCheckedIn => 'Пријавени';

  @override
  String get eventsCtaScanToCheckIn => 'Скенирај за пријава';

  @override
  String get eventsCtaCheckInPaused => 'Пријавата е паузирана';

  @override
  String get eventsCtaTurnReminderOff => 'Исклучи потсетник';

  @override
  String get eventsCtaSetReminder => 'Постави потсетник';

  @override
  String get eventsCtaLeaveEvent => 'Напушти настан';

  @override
  String get eventsCtaJoinEcoAction => 'Придружи се на акцијата';

  @override
  String get eventsStatusUpcoming => 'Претстоен';

  @override
  String get eventsStatusInProgress => 'Во тек';

  @override
  String get eventsStatusCompleted => 'Завршен';

  @override
  String get eventsStatusCancelled => 'Откажан';

  @override
  String get eventsCardActionsSheetTitle => 'Акции за настанот';

  @override
  String get eventsCardCopyTitle => 'Копирај детали за настанот';

  @override
  String get eventsCardCopySubtitle => 'Наслов, датум и локација';

  @override
  String get eventsCardCopiedSnack => 'Деталите се копирани.';

  @override
  String get eventsCardShareTitle => 'Сподели настан';

  @override
  String get eventsCardShareSubtitle => 'Сподели со пријатели';

  @override
  String get eventsCardOpenTitle => 'Отвори настан';

  @override
  String get eventsCardOpenSubtitle => 'Целосни детали';

  @override
  String get eventsCardMoreActionsSemantic => 'Повеќе акции за настанот';

  @override
  String get eventsCardSoonLabel => 'Наскоро';

  @override
  String get eventsFeedUpNext => 'Следно';

  @override
  String get eventsCountdownStarted => 'Започна';

  @override
  String eventsCountdownDaysHours(int days, int hours) {
    return 'Почнува за $daysд $hoursч';
  }

  @override
  String eventsCountdownHoursMinutes(int hours, int minutes) {
    return 'Почнува за $hoursч $minutesм';
  }

  @override
  String eventsCountdownMinutes(int minutes) {
    return 'Почнува за $minutesм';
  }

  @override
  String get eventsShareEventTooltip => 'Сподели настан';

  @override
  String get eventsAttendeeCheckInSemantic => 'Скенирај за пријава на настанот';

  @override
  String get eventsAttendeeAlreadyCheckedInSnack => 'Веќе сте пријавени.';

  @override
  String get eventsAttendeeCheckInPausedSnack =>
      'Организаторот ја паузираше пријавата.';

  @override
  String get eventsAttendeeCheckInCompleteSnack => 'Пријавата е завршена.';

  @override
  String get eventsAttendeeBannerTitleCheckedIn => 'Пријавени сте';

  @override
  String get eventsAttendeeBannerTitleInProgress => 'Настанот е во тек';

  @override
  String get eventsAttendeeBannerSubtitleAttendanceConfirmed =>
      'Присуството е потврдено';

  @override
  String eventsAttendeeBannerSubtitleCheckedInAt(String time) {
    return 'Пријавени во $time';
  }

  @override
  String get eventsAttendeeBannerSubtitleScanQr =>
      'Скенирајте го QR-кодот на организаторот';

  @override
  String get eventsAttendeeBannerSubtitlePaused =>
      'Пријавата е привремено паузирана';

  @override
  String get eventsDetailShareSuccess => 'Настанот е споделен.';

  @override
  String get eventsDetailShareFailed =>
      'Не можеше да се отвори споделувањето. Обидете се повторно.';

  @override
  String get eventsDetailCalendarAdded => 'Настанот е додаден во календарот.';

  @override
  String get eventsDetailCalendarFailed =>
      'Не можеше да се додаде во календарот. Обидете се повторно.';

  @override
  String get eventsDetailRefreshFailed =>
      'Не можеше да се освежи настанот. Обидете се повторно.';

  @override
  String get eventsDetailCancelledCallout => 'Овој настан е откажан.';

  @override
  String get eventsDetailOpenInMaps => 'Отвори во Maps';

  @override
  String eventsDetailCoverSemantic(String title) {
    return 'Насловна слика за $title';
  }

  @override
  String get eventsDetailGroupedPanelSemantic => 'Локација, распоред и детали';

  @override
  String eventsHeroChatSemantic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Групен разговор, $count непрочитани',
      one: 'Групен разговор, 1 непрочитана',
      zero: 'Групен разговор',
    );
    return '$_temp0';
  }

  @override
  String get eventsDetailParticipationSemantic => 'Ваше учество';

  @override
  String get eventsAnalyticsLoadFailed =>
      'Не можеше да се вчитаат аналитиките.';

  @override
  String get eventsAnalyticsRetry => 'Обиди се повторно';

  @override
  String get eventsRecurrenceDaily => 'Секој ден';

  @override
  String get eventsRecurrenceNavigatePrevious => 'Претходен настан во серијата';

  @override
  String get eventsRecurrenceNavigateNext => 'Следен настан во серијата';

  @override
  String get eventsImpactSummarySaved => 'Резимето на влијание е зачувано.';

  @override
  String get eventsImpactSummaryUpdated => 'Резимето на влијание е ажурирано.';

  @override
  String eventsReminderSetSnack(String when) {
    return 'Потсетникот е поставен за $when.';
  }

  @override
  String get eventsFeedbackSheetTitle => 'Повратна информација по настанот';

  @override
  String get eventsFeedbackHowWasEvent => 'Како помина настанот?';

  @override
  String get eventsFeedbackBagsCollected => 'Собрани ќесиња';

  @override
  String eventsFeedbackVolunteerHours(String hours) {
    return 'Волонтерски часови: $hoursч';
  }

  @override
  String get eventsFeedbackNotesHint =>
      'Што добро помина? Белешки за следниот пат?';

  @override
  String eventsEvidenceMaxPhotosSnack(int max) {
    return 'Максимум $max фотографии.';
  }

  @override
  String get eventsEvidencePickFailedSnack =>
      'Не можеше да се изберат фотографии. Проверете дозволи.';

  @override
  String get eventsEvidenceRemoveAction => 'Отстрани';

  @override
  String get eventsEvidenceAppBarTitle => 'Докази од чистење';

  @override
  String get eventsEvidenceSaving => 'Се зачувува...';

  @override
  String get eventsEvidenceSaveInProgressHint =>
      'Почекајте додека не заврши зачувувањето пред да ја напуштите оваа страница.';

  @override
  String get eventsEvidenceAfterPhotosSaved =>
      'Фотографиите потоа се зачувани.';

  @override
  String get eventsEvidenceSaveSuccessTitle => 'Фотографиите се зачувани';

  @override
  String get eventsEvidenceSaveSuccessBody =>
      'Фотографиите „потоа“ се на страницата на настанот.';

  @override
  String get eventsEvidenceSaveFailureTitle =>
      'Не може да се зачуваат фотографиите';

  @override
  String eventsEvidenceSaveFailureBody(String message) {
    return '$message';
  }

  @override
  String get eventsEvidenceNoChanges => 'Нема промени за зачувување.';

  @override
  String get eventsSiteReferencePhotoTitle =>
      'Референтна фотографија од локацијата';

  @override
  String get eventsSiteReferencePhotoBody =>
      'Референца пред чистење. Користете јазичето Потоа за фотографии од исчистената локација.';

  @override
  String get eventsManageCheckInOnlyInProgress =>
      'Пријавата е достапна само додека настанот е во тек.';

  @override
  String get eventsEventFull => 'Овој настан е полн.';

  @override
  String get eventsParticipationUpdateFailed =>
      'Не можевме да ја ажурираме учеството. Обидете се повторно.';

  @override
  String get eventsJoinedEcoAction => 'Се придруживте на оваа еколошка акција.';

  @override
  String eventsJoinPointsEarned(int points) {
    return '+$points поени — добредојдовте!';
  }

  @override
  String get eventsLeftEcoAction => 'Се одјавивте од оваа еколошка акција.';

  @override
  String eventsCheckInPointsEarned(int points) {
    return '+$points поени — регистрирани сте!';
  }

  @override
  String eventsManualCheckInWithPoints(String name, int points) {
    return '$name е регистриран/а · +$points поени за нив';
  }

  @override
  String get eventsJoinFirstForReminders =>
      'Прво се придружете на настанот за да поставите потсетници.';

  @override
  String get eventsReminderDisabled => 'Потсетникот е исклучен.';

  @override
  String get eventsReminderSheetTitle => 'Изберете време за потсетник';

  @override
  String eventsReminderSheetSubtitle(String timeRange, String date) {
    return 'Настанот почнува во $timeRange на $date.';
  }

  @override
  String get eventsReminderPreset1Day => '1 ден пред';

  @override
  String get eventsReminderPreset3Hours => '3 часа пред';

  @override
  String get eventsReminderPreset1Hour => '1 час пред';

  @override
  String get eventsReminderPreset30Mins => '30 минути пред';

  @override
  String get eventsReminderUnavailableSubtitle =>
      'Недостапно за ова време на настанот';

  @override
  String get eventsReminderCustomTitle => 'Сопствен датум и време';

  @override
  String get eventsReminderCustomSubtitle =>
      'Изберете точен момент за потсетник';

  @override
  String get eventsReminderPickTitle => 'Изберете потсетник';

  @override
  String get eventsReminderDone => 'Готово';

  @override
  String eventsCardParticipantsMore(int count) {
    return '+$count повеќе';
  }

  @override
  String eventsCardParticipantsCountMax(int count, int max) {
    return '$count / $max';
  }

  @override
  String eventsCardParticipantsJoined(int count) {
    return '$count пријавени';
  }

  @override
  String get eventsDiscoveryThisWeekRetryHint =>
      'Не можевме да го вчитаме изборот за оваа недела.';

  @override
  String get eventsDiscoveryThisWeekRetry => 'Обиди повторно';

  @override
  String eventsDetailSemanticsLabel(String title) {
    return 'Детали за настан: $title';
  }

  @override
  String eventsCountdownBadgeSemantic(String label) {
    return 'Време до почеток на настанот: $label';
  }

  @override
  String get eventsEvidenceThumbnailMenuTitle => 'Фотографија';

  @override
  String get eventsFeedRefreshFailed => 'Не можевме да ги освежиме настаните.';

  @override
  String get eventsCreateGenericError =>
      'Не можевме да креираме настан. Обидете се повторно.';

  @override
  String get qrScannerPointCameraHint =>
      'Насочете ја камерата кон живиот QR код на организаторот';

  @override
  String get qrScannerEnterManually => 'Не скенира? Внесете го кодот рачно';

  @override
  String get qrScannerRetryCamera => 'Обиди повторно со камерата';

  @override
  String get qrScannerSubmitCode => 'Испрати код';

  @override
  String get qrScannerHintFreshQr =>
      'Ако организаторот го освежи QR-кодот, скенирајте го најновиот.';

  @override
  String get qrScannerHintCameraBlocked =>
      'Ако пристапот до камерата е блокиран, внесете го кодот рачно или овозможете камера во Поставки.';

  @override
  String get qrScannerGenericEventTitle => 'оваа акција за чистење';

  @override
  String get qrScannerErrorInvalidFormat => 'Невалиден формат на QR.';

  @override
  String get qrScannerErrorInvalidQr => 'Овој QR не важи за пријава.';

  @override
  String get qrScannerErrorWrongEvent => 'Овој QR е за друг настан.';

  @override
  String get qrScannerErrorSessionClosed =>
      'Организаторот ја паузираше пријавата.';

  @override
  String get qrScannerErrorSessionExpired =>
      'QR-кодот истече. Побарајте нов од организаторот.';

  @override
  String get qrScannerErrorReplayDetected => 'Овој QR веќе беше искористен.';

  @override
  String get qrScannerErrorAlreadyCheckedIn => 'Веќе сте пријавени.';

  @override
  String get qrScannerErrorRequiresJoin =>
      'Прво се пријавете на настанот во апликацијата.';

  @override
  String get qrScannerErrorCheckInUnavailable =>
      'Пријавата не е отворена за овој настан во моментов.';

  @override
  String get qrScannerErrorRateLimited =>
      'Премногу обиди. Почекајте малку и обидете се повторно.';

  @override
  String get qrScannerCameraUnavailableFeedback =>
      'Камерата е недостапна. Можете да го внесете кодот од организаторот или повторно да овозможите камера во Поставки.';

  @override
  String get qrScannerManualEntryTitle => 'Внесете го кодот рачно';

  @override
  String get qrScannerPasteOrganizerQrHint =>
      'Залепете го текстот од QR на организаторот';

  @override
  String get qrScannerPasteFromClipboardTooltip =>
      'Залепи од привремена меморија';

  @override
  String get qrScannerEnterCodeFirst => 'Прво внесете код.';

  @override
  String get qrScannerCheckedInTitle => 'Успешно се пријавивте!';

  @override
  String qrScannerWelcomeTo(String eventTitle) {
    return 'Добредојдовте на $eventTitle';
  }

  @override
  String qrScannerCheckedInAt(String time) {
    return 'Пријавени во $time';
  }

  @override
  String get qrScannerDone => 'Готово';

  @override
  String get qrScannerAppBarTitle => 'Скенирај за пријава';

  @override
  String get qrScannerToggleFlashlightSemantic => 'Вклучи или исклучи блиц';

  @override
  String get qrScannerCameraStarting => 'Се стартува камерата…';

  @override
  String get qrScannerCheckingIn => 'Се потврдува пријавата…';

  @override
  String get qrScannerCameraErrorTitle => 'Камерата е недостапна';

  @override
  String get qrScannerManualEntrySubtitle =>
      'Залепете го целиот текст што го сподели организаторот (копирајте од нивниот екран или порака).';

  @override
  String get qrScannerPasteButton => 'Залепи';

  @override
  String get siteReportReasonFakeLabel => 'Лажни или воведувачки податоци';

  @override
  String get siteReportReasonFakeSubtitle =>
      'Информациите не одговараат на реалноста';

  @override
  String get siteReportReasonResolvedLabel => 'Веќе решено';

  @override
  String get siteReportReasonResolvedSubtitle =>
      'Проблемот е исчистен или поправен';

  @override
  String get siteReportReasonWrongLocationLabel => 'Погрешна локација';

  @override
  String get siteReportReasonWrongLocationSubtitle =>
      'Локацијата е погрешно на картата';

  @override
  String get siteReportReasonDuplicateLabel => 'Дупликат пријава';

  @override
  String get siteReportReasonDuplicateSubtitle =>
      'Иста локација пријавена повеќе пати';

  @override
  String get siteReportReasonSpamLabel => 'Спам или злоупотреба';

  @override
  String get siteReportReasonSpamSubtitle => 'Неприфатлива или штетна содржина';

  @override
  String get siteReportReasonOtherLabel => 'Друго';

  @override
  String get siteReportReasonOtherSubtitle => 'Нешто друго не е во ред';

  @override
  String get takeActionDonationOpenFailed =>
      'Не можеше да се отвори страницата за донации';

  @override
  String get takeActionShareSiteTitle => 'Сподели локација';

  @override
  String get takeActionShareSiteSubtitle =>
      'Помогни други да ја откријат и поддржат';

  @override
  String get takeActionLinkCopied => 'Линкот е копиран';

  @override
  String get takeActionSheetTitle => 'Преземи акција';

  @override
  String get takeActionSheetSubtitle => 'Избери како сакаш да помогнеш';

  @override
  String get takeActionCreateEcoTitle => 'Креирај еко акција';

  @override
  String get takeActionCreateEcoSubtitle =>
      'Закажи акција за чистење на оваа локација';

  @override
  String get takeActionJoinTitle => 'Приклучи се';

  @override
  String get takeActionJoinSubtitle =>
      'Пронајди и приклучи се на претстојни чистења';

  @override
  String get takeActionShareTitle => 'Сподели ја локацијата';

  @override
  String get takeActionShareSubtitle =>
      'Помогни и други да ја откријат оваа локација';

  @override
  String get shareSheetSemanticDragHandle =>
      'Влечи за да го промениш големината или да го затвориш';

  @override
  String get shareSheetCopyLinkTitle => 'Копирај линк';

  @override
  String get shareSheetCopyLinkSubtitle =>
      'Копирај го линкот до локацијата во клипборд';

  @override
  String get shareSheetCopyLinkSemantic =>
      'Копирај линк до оваа локација со загадување';

  @override
  String get shareSheetSendTitle => 'Испрати на луѓе';

  @override
  String get shareSheetSendSubtitle => 'Сподели во пораки или друга апликација';

  @override
  String get shareSheetSendSemantic =>
      'Отвори листа за споделување за да ја испратиш оваа локација';

  @override
  String siteDetailSemanticShareCount(int count) {
    return '$count споделувања на оваа локација';
  }

  @override
  String get siteDetailThankYouReportSnack =>
      'Ви благодариме. Вашата пријава ни помага.';

  @override
  String get siteDetailUpvoteFailedSnack =>
      'Не можеше да се ажурира поддршката. Обидете се повторно.';

  @override
  String get siteDetailNoUpvotesSnack => 'Сè уште нема поддршка. Бидете први!';

  @override
  String get siteUpvotersSheetTitle => 'Поддржувачи';

  @override
  String get siteUpvotersSupportingLabel => 'Поддржува';

  @override
  String siteUpvotersSupportersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count поддржувачи',
      one: '1 поддржувач',
    );
    return '$_temp0';
  }

  @override
  String get siteUpvotersLoadFailed => 'Не успеа вчитувањето на поддржувачите.';

  @override
  String get siteUpvotersRetry => 'Обиди се повторно';

  @override
  String get siteDetailNoVolunteersSnack =>
      'Сè уште нема волонтери за оваа локација.';

  @override
  String get siteDetailDirectionsUnavailableSnack =>
      'Насоки не се достапни за оваа локација.';

  @override
  String get siteDetailOpenMapsFailedSnack => 'Не можеше да се отвори Maps';

  @override
  String get siteDetailNoCoReportersSnack =>
      'Сè уште нема други учесници. Заеднички известувачи се појавуваат кога некој друг ќе пријави исто место.';

  @override
  String siteStatsCoReportersSemantic(int count) {
    return '$count заеднички известувачи на оваа пријава';
  }

  @override
  String siteParticipantStatsSemantic(int count) {
    return '$count учесници (заеднички известувачи или споени дупликати)';
  }

  @override
  String get siteMergedDuplicatesModalTitle => 'Споени дупликат-пријави';

  @override
  String siteMergedDuplicatesModalBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count слични пријави се споени во оваа. Кога некој друг ќе пријави исто место, се појавува како заеднички известувач.',
      one:
          'Една слична пријава е споена во оваа. Кога некој друг ќе пријави исто место, се појавува како заеднички известувач.',
    );
    return '$_temp0';
  }

  @override
  String get siteCardUpvoteFailedSnack =>
      'Не можеше да се ажурира поддршката. Обидете се повторно.';

  @override
  String get siteCardSavedFailedSnack =>
      'Не можеше да се ажурира зачуваното. Обидете се повторно.';

  @override
  String get siteCardTakeActionSemantic => 'Преземи акција';

  @override
  String get siteCardFeedOptionsSemantic => 'Опции на фидот';

  @override
  String get siteCardCommentsLoadFailedSnack =>
      'Не можеше да се вчитаат коментарите.';

  @override
  String get siteCardShareTrackFailedSnack =>
      'Не можеше да се забележи споделувањето.';

  @override
  String get siteCardFeedbackSubmitFailedSnack =>
      'Не можеше да се испрати повратната информација.';

  @override
  String get siteCardNotRelevantTitle => 'Не е релевантно';

  @override
  String get siteCardShowLessTitle => 'Покажи помалку вакви';

  @override
  String get siteCardDuplicateTitle => 'Дупликат';

  @override
  String get siteCardMisleadingTitle => 'Воведувачки';

  @override
  String get siteCardHidePostTitle => 'Сокриј ја објавата';

  @override
  String get feedSiteCommentsAppBarFallback => 'Коментари';

  @override
  String get feedSiteNotFoundMessage => 'Ова место не е пронајдено.';

  @override
  String get feedDisplayNameFallback => 'Ти';

  @override
  String get feedOpenProfileSemantics => 'Отвори профил';

  @override
  String get feedGreetingPrefix => 'Здраво, ';

  @override
  String get feedGreetingFallbackName => 'таму';

  @override
  String get feedHeaderSubtitle => 'Истражи локации со загадување во близина';

  @override
  String get feedNotificationBellAllReadSemantic =>
      'Известувања, сè е прочитано';

  @override
  String feedNotificationBellUnreadSemantic(int count) {
    return 'Известувања, $count непрочитани';
  }

  @override
  String get siteDetailTabPollutionSite => 'Локација со загадување';

  @override
  String get siteDetailTabCleaningEvents => 'Акции за чистење';

  @override
  String get siteDetailInfoCardTitle => 'Потребна е акција од заедницата';

  @override
  String get siteDetailInfoCardBody =>
      'Приклучи се на чистење, пријави промени или сподели за да реагираме побрзо.';

  @override
  String get siteDetailReportedByPrefix => 'Пријавено од ';

  @override
  String get siteDetailCoReportersTitle => 'Ко-пријавувачи';

  @override
  String siteDetailCoReportersSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Уште $count лица го пријавија ова место',
      one: 'Уште 1 лице го пријави ова место',
    );
    return '$_temp0';
  }

  @override
  String siteDetailGalleryPhotoSemantic(int index) {
    return 'Фотографија од локацијата $index';
  }

  @override
  String get siteDetailOpenGalleryLabel => 'Отвори галерија за локацијата';

  @override
  String get siteDetailGalleryTapToExpand => 'Допрете за проширување';

  @override
  String get siteDetailGalleryOpenPhoto => 'Отвори фотографија';

  @override
  String get commonNotAvailable => '—';

  @override
  String get commonDistanceMetersUnit => 'м';

  @override
  String get commonDistanceKilometersUnit => 'км';

  @override
  String get siteCommentsEmptyBody =>
      'Сè уште нема коментари.\nБиди прв/а што ќе коментира.';

  @override
  String get feedCommentsLoadMoreFailedSnack =>
      'Не можеше да се вчитаат повеќе коментари. Обиди се повторно.';

  @override
  String get commentsSheetTitle => 'Акции за коментар';

  @override
  String get commentsSheetSubtitle => 'Управувај со коментарот';

  @override
  String get commentsEditTitle => 'Уреди коментар';

  @override
  String get commentsEditSubtitle => 'Ажурирај го текстот';

  @override
  String get commentsDeleteTitle => 'Избриши коментар';

  @override
  String get commentsDeleteSubtitle => 'Отстрани го од нишката';

  @override
  String get commentsEditFailedSnack => 'Не можеше да се уреди коментарот.';

  @override
  String get commentsReplyFailedSnack => 'Не можеше да се испрати одговорот.';

  @override
  String get commentsSortFailedSnack =>
      'Не можеше да се смени редоследот на коментарите. Обидете се повторно.';

  @override
  String get commentsDeletedSnack => 'Коментарот е избришан.';

  @override
  String get commentsDeleteFailedSnack => 'Не можеше да се избрише коментарот.';

  @override
  String get commentsLikeFailedSnack => 'Не можеше да се ажурира допаѓањето.';

  @override
  String get commentsCancelEditSemantic => 'Откажи уредување и исчисти нацрт';

  @override
  String get commentsCancelReplySemantic => 'Откажи одговор и исчисти нацрт';

  @override
  String commentsReplyToSemantic(String name) {
    return 'Одговори на $name';
  }

  @override
  String get commentsReplyButton => 'Одговори';

  @override
  String get commentsViewReplies => 'Види одговори';

  @override
  String commentsLoadMoreReplies(int count) {
    return 'Вчитај уште $count';
  }

  @override
  String get siteEngagementQueuedOfflineSnack =>
      'Врската прекина. Ќе пробаме повторно кога повторно ќе бидете онлајн.';

  @override
  String get commentsHideReplies => 'Сокриј одговори';

  @override
  String get commentsStatusDeleting => 'Се брише…';

  @override
  String get commentsStatusSavingEdits => 'Се зачувуваат измените…';

  @override
  String get commentsCommentMetaJustNow => 'Штотуку';

  @override
  String commentsCommentMetaJustNowWithLikes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Штотуку • $count допаѓања',
      one: 'Штотуку • 1 допаѓање',
    );
    return '$_temp0';
  }

  @override
  String commentsCommentMetaMinutesAgo(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'пред $minutes минути',
      one: 'пред 1 минута',
    );
    return '$_temp0';
  }

  @override
  String commentsCommentMetaMinutesAgoWithLikes(int minutes, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'пред $minutes минути',
      one: 'пред 1 минута',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count допаѓања',
      one: '1 допаѓање',
    );
    return '$_temp0 • $_temp1';
  }

  @override
  String commentsCommentMetaHoursAgo(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'пред $hours часа',
      one: 'пред 1 час',
    );
    return '$_temp0';
  }

  @override
  String commentsCommentMetaHoursAgoWithLikes(int hours, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'пред $hours часа',
      one: 'пред 1 час',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count допаѓања',
      one: '1 допаѓање',
    );
    return '$_temp0 • $_temp1';
  }

  @override
  String commentsCommentMetaDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'пред $days дена',
      one: 'пред 1 ден',
    );
    return '$_temp0';
  }

  @override
  String commentsCommentMetaDaysAgoWithLikes(int days, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'пред $days дена',
      one: 'пред 1 ден',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count допаѓања',
      one: '1 допаѓање',
    );
    return '$_temp0 • $_temp1';
  }

  @override
  String commentsCommentMetaDate(String date) {
    return '$date';
  }

  @override
  String commentsCommentMetaDateWithLikes(String date, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count допаѓања',
      one: '1 допаѓање',
    );
    return '$date • $_temp0';
  }

  @override
  String get commentsOptimisticAuthorYou => 'Вие';

  @override
  String commentsReplyingToBanner(String name) {
    return 'Одговарате на $name';
  }

  @override
  String get commentsSemanticSheetDragHandle =>
      'Променете ја големината или затворете ги коментарите';

  @override
  String get commentsPrefetchCouldNotRefreshSnack =>
      'Не можевме да ги освежиме коментарите. Се прикажува последниот вчитан разговор.';

  @override
  String commentsComposerCharsRemaining(int remaining) {
    String _temp0 = intl.Intl.pluralLogic(
      remaining,
      locale: localeName,
      other: 'остануваат $remaining знаци',
      one: 'останува 1 знак',
    );
    return '$_temp0';
  }

  @override
  String commentsSemanticHideReplies(String name) {
    return 'Сокриј ги одговорите за $name';
  }

  @override
  String commentsSemanticViewReplies(String name) {
    return 'Види ги одговорите за $name';
  }

  @override
  String get commentsInputHintEdit => 'Уреди го коментарот…';

  @override
  String get commentsInputHintAdd => 'Додај коментар…';

  @override
  String get commentsInputHintReply => 'Напиши одговор…';

  @override
  String get commentsLikeTooltip => 'Допаѓање на коментар';

  @override
  String get commentsUnlikeTooltip => 'Отстрани допаѓање';

  @override
  String get searchModalCancel => 'Откажи';

  @override
  String get searchModalPlaceholder => 'Пребарај загадени локации';

  @override
  String get appSmartImageRetry => 'Обиди повторно';

  @override
  String appSmartImageRetryIn(int seconds) {
    return 'Обид повторно за $seconds с';
  }

  @override
  String get semanticClose => 'Затвори';

  @override
  String get pollutionSiteTabTakeAction => 'Преземи акција';

  @override
  String get reportDescriptionHint => 'Нешто друго';

  @override
  String get reportSubmittedFallbackCategory => 'Пријава';

  @override
  String get reportSeverityLow => 'Ниска';

  @override
  String get reportSeverityModerate => 'Умерена';

  @override
  String get reportSeveritySignificant => 'Значајна';

  @override
  String get reportSeverityHigh => 'Висока';

  @override
  String get reportSeverityCritical => 'Критична';

  @override
  String get reportDetailViewOnMap => 'Поглед на мапа';

  @override
  String get reportListSearchPlaceholder => 'Пребарај пријави';

  @override
  String get reportListSearchHintPrefix =>
      'Пребарување по наслов, локација, категорија или статус.';

  @override
  String get reportListSearchNoMatches => 'Нема совпаѓања';

  @override
  String get reportListSearchOneReport => '1 пријава';

  @override
  String reportListSearchNReports(int count) {
    return '$count пријави';
  }

  @override
  String get reportListEmptyTitle => 'Сè уште нема пријави';

  @override
  String get reportListEmptySubtitle =>
      'Вашите пријави ќе се појават тука откако ќе ги испратите.';

  @override
  String get reportStatusUnderReviewShort => 'На преглед';

  @override
  String get reportStatusApprovedShort => 'Одобрено';

  @override
  String get reportStatusDeclinedShort => 'Одбиено';

  @override
  String get reportStatusAlreadyReportedShort => 'Веќе пријавено';

  @override
  String get reportListFilterAll => 'Сите';

  @override
  String get reportListOptimisticPill => 'Се испраќа…';

  @override
  String get reportListFilterSemanticPrefix => 'Статус на пријава';

  @override
  String get reportListHeaderTitle => 'Вашите пријави';

  @override
  String reportListHeaderTotalPill(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count пријави вкупно',
      one: '1 пријава вкупно',
    );
    return '$_temp0';
  }

  @override
  String reportListHeaderUnderReviewPill(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count на преглед',
      one: '1 на преглед',
    );
    return '$_temp0';
  }

  @override
  String reportListHeaderSemanticSummary(int totalReports, int underReview) {
    String _temp0 = intl.Intl.pluralLogic(
      totalReports,
      locale: localeName,
      other: '$totalReports пријави вкупно',
      one: '1 пријава вкупно',
    );
    String _temp1 = intl.Intl.pluralLogic(
      underReview,
      locale: localeName,
      other: '$underReview моментално на преглед',
      one: '1 моментално на преглед',
    );
    return '$_temp0. $_temp1.';
  }

  @override
  String get reportListFilteredFooterAll => 'Сите пријави се прикажани';

  @override
  String reportListFilteredFooterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count пријави',
      one: '1 пријава',
    );
    return '$_temp0';
  }

  @override
  String get reportListNoMatchesSearchTitle => 'Нема пронајдени пријави';

  @override
  String get reportListNoMatchesFilterTitle => 'Нема пријави за овој филтер';

  @override
  String get reportListNoMatchesHintSearchAndFilter =>
      'Обидете се со друго пребарување или исчистете ги филтрите за да видите повеќе пријави.';

  @override
  String get reportListNoMatchesHintSearchOnly =>
      'Проверете го правописот или обидете се со пошироко пребарување.';

  @override
  String get reportListNoMatchesHintFilterOnly =>
      'Обидете се со друг филтер или исчистете го за да ги видите сите пријави.';

  @override
  String get reportListClearSearch => 'Исчисти пребарување';

  @override
  String reportListDateWeeksAgo(int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: 'Пред $weeks недели',
      one: 'Пред 1 недела',
    );
    return '$_temp0';
  }

  @override
  String get reportDetailOpeningInProgress => 'Се отвора…';

  @override
  String get reportDetailNoPhotos => 'Нема фотографии';

  @override
  String get reportDetailStatusUnderReviewTitle =>
      'На преглед кај модераторите';

  @override
  String get reportDetailStatusUnderReviewBody =>
      'Модераторите ги проверуваат вашите докази и локацијата пред да одлучат како да постапат со пријавата.';

  @override
  String get reportDetailStatusApprovedTitle =>
      'Одобрено и поврзано со локација';

  @override
  String get reportDetailStatusApprovedBody =>
      'Оваа пријава помогна да се потврди јавно загадување и може да придонесе кон акции за чистење.';

  @override
  String get reportDetailStatusAlreadyReportedTitle =>
      'Веќе е забележана како постоечка локација';

  @override
  String get reportDetailStatusAlreadyReportedBody =>
      'Вашата пријава се совпаѓа со постоечка локација. Доказите сè уште се корисни за подобро разбирање на проблемот.';

  @override
  String get reportDetailStatusOutcomeTitle => 'Исход од прегледот';

  @override
  String get reportDetailStatusOutcomeBodyFallback =>
      'Оваа пријава не можеше да се одобри во сегашната форма.';

  @override
  String get reportDetailSheetTitle => 'Детали за пријавата';

  @override
  String get reportDetailSheetSubtitle =>
      'Погледнете што испративте и како модераторите ја обработија пријавата.';

  @override
  String reportDetailSheetSubtitleWithNumber(String reportNumber) {
    return '$reportNumber · Погледнете што испративте и како модераторите ја обработија пријавата.';
  }

  @override
  String get reportDetailPhotoAttachedPill => 'Фотографија приложена';

  @override
  String get reportDetailPointsLabel => 'Поени';

  @override
  String reportDetailEvidencePhotoSemantic(int index) {
    return 'Фотографија од доказ $index';
  }

  @override
  String get reportDetailEvidenceGalleryOpenSemantic =>
      'Отвори ги фотографиите од доказот';

  @override
  String get reportDetailEvidenceTapToExpand => 'Допри за проширување';

  @override
  String get reportDetailEvidenceOpenPhoto => 'Отвори фотографија';

  @override
  String get reportDetailSiteNotFoundOpeningMaps =>
      'Локацијата не е пронајдена. Се отвораат мапите.';

  @override
  String get reportDetailSiteNotAvailable => 'Локацијата не е достапна.';

  @override
  String get reportDetailCouldNotLoadSite =>
      'Не можевме да ја вчитаме локацијата.';

  @override
  String get reportCardDeclineNoteTitle => 'Забелешка од прегледот';

  @override
  String reportListFilterChipSemantic(String label, int selected) {
    String _temp0 = intl.Intl.pluralLogic(
      selected,
      locale: localeName,
      other: 'не е избран',
      one: 'избран',
    );
    return '$label филтер, $_temp0';
  }

  @override
  String reportListFilterChipHint(String label) {
    return 'Двојно допри за да ги филтрираш пријавите по $label.';
  }

  @override
  String get reportReviewTitleHint => 'Краток наслов';

  @override
  String get reportFlowCameraUnavailableSnack =>
      'Камерата не може да се отвори сега. Обиди се повторно за момент.';

  @override
  String get reportSemanticsLocationPinThenConfirm =>
      'Локација: закачи пин, потоа потврди.';

  @override
  String get newReportTooltipAboutStep => 'За овој чекор';

  @override
  String get newReportTooltipDismiss => 'Отфрли';

  @override
  String get reportFlowSubmitPhaseCreating => 'Се создава…';

  @override
  String get reportFlowSubmitPhaseUploading => 'Се прикачува…';

  @override
  String get reportFlowSubmitPhaseSubmitting => 'Се испраќа…';

  @override
  String get reportFormPrimarySemanticsHintSubmit =>
      'Допри двапати за да испратиш.';

  @override
  String get reportFormPrimarySemanticsHintNext =>
      'Допри двапати за да одиш на следниот чекор.';

  @override
  String reportCardSemanticLabel(
    String category,
    String status,
    String location,
  ) {
    return '$category, $status, $location. Допри за детали.';
  }

  @override
  String get appSmartImageUnavailable => 'Сликата не е достапна';

  @override
  String get eventsReminderSectionTitle => 'Потсетник за настан';

  @override
  String get eventsReminderSectionEnabled => 'Потсетникот е вклучен';

  @override
  String eventsReminderSectionSetFor(String time) {
    return 'Поставен за $time';
  }

  @override
  String get eventsReminderSectionDisabled =>
      'Добијте известување пред почетокот';

  @override
  String get eventsReminderSectionDisable => 'Исклучи';

  @override
  String get eventsReminderSectionEnable => 'Вклучи';

  @override
  String get eventsDescriptionTitle => 'За настанот';

  @override
  String get eventsDescriptionShowLess => 'Прикажи помалку';

  @override
  String get eventsDescriptionReadMore => 'Прочитај повеќе';

  @override
  String get eventsAfterCleanupTitle => 'По чистењето';

  @override
  String eventsAfterPhotoSemantic(int index, int total) {
    return 'Прикажи фотографија по чистење $index од $total';
  }

  @override
  String get eventsFilterAll => 'Сите';

  @override
  String get eventsFilterUpcoming => 'Претстојни';

  @override
  String get eventsFilterNearby => 'Во близина';

  @override
  String get eventsFilterPast => 'Поминати';

  @override
  String get eventsFilterMyEvents => 'Мои настани';

  @override
  String get eventsFilterSemanticPrefix => 'Настани';

  @override
  String get eventsParticipantsTitle => 'Учесници';

  @override
  String eventsParticipantsViewSemantic(int count) {
    return 'Прикажи $count учесници';
  }

  @override
  String eventsParticipantsYouAndOthers(int count) {
    return 'Вие и уште $count се приклучивте';
  }

  @override
  String eventsParticipantsVolunteersJoined(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count волонтери се приклучија',
      one: '1 волонтер се приклучи',
    );
    return '$_temp0';
  }

  @override
  String eventsParticipantsSpotsLeft(int count) {
    return 'Останати места: $count';
  }

  @override
  String eventsParticipantsCheckedInCount(int checkedIn, int total) {
    return '$checkedIn од $total се пријавени';
  }

  @override
  String get eventsParticipantsSearchPlaceholder => 'Пребарај учесник';

  @override
  String get eventsParticipantsNoSearchResults =>
      'Нема совпаѓања за пребарувањето.';

  @override
  String get eventsParticipantsYouOrganizer => 'Вие · Организатор';

  @override
  String get eventsParticipantsOrganizer => 'Организатор';

  @override
  String get eventsParticipantsYou => 'Вие';

  @override
  String get eventsParticipantsLoadFailed =>
      'Не можевме да ја вчитаме листата. Проверете ја врската и обидете се повторно.';

  @override
  String get eventsParticipantsRetry => 'Обиди се повторно';

  @override
  String get eventsParticipantsViewRosterSemantic =>
      'Погледни ја листата на учесници';

  @override
  String get eventsGearSectionTitle => 'Опрема за понесување';

  @override
  String get eventsGearNoneNeeded => 'Нема потреба за посебна опрема';

  @override
  String get eventsImpactSummaryTitle => 'Преглед на ефект';

  @override
  String get eventsImpactSummaryAdd => 'Додај';

  @override
  String get eventsImpactSummaryEdit => 'Уреди';

  @override
  String get eventsImpactSummaryEmptyHint =>
      'Забележете резултати и поуки од чистењето.';

  @override
  String get eventsLivePulseTitle => 'Влијание во живо';

  @override
  String eventsLivePulseVolunteers(int count) {
    return '$count пријавени';
  }

  @override
  String eventsLivePulseCheckIns(int count) {
    return '$count check-in';
  }

  @override
  String eventsLivePulseBags(int count, String kg) {
    return '$count ќесиња · прибл. $kg kg';
  }

  @override
  String get eventsEvidenceStripTitle => 'Доказ од терен';

  @override
  String get eventsEvidenceStripSubtitle =>
      'Фотографии од евиденцијата за чистење.';

  @override
  String get eventsEvidenceStripSemantic =>
      'Фотографии пред, потоа и од терен од евиденцијата';

  @override
  String get eventsEvidenceKindBefore => 'Пред';

  @override
  String get eventsEvidenceKindAfter => 'Потоа';

  @override
  String get eventsEvidenceKindField => 'Терен';

  @override
  String eventsEvidenceStripTileSemantic(int index, int total, String kind) {
    return 'Фотографија $index од $total, $kind';
  }

  @override
  String get eventsRouteProgressTitle => 'Рута';

  @override
  String eventsFieldModeRowServerError(String code) {
    return 'Сервер: $code';
  }

  @override
  String get eventsFieldModeTitle => 'Теренски режим';

  @override
  String get eventsFieldModeSync => 'Синхронизирај';

  @override
  String get eventsFieldModeEmpty => 'Нема редица офлајн.';

  @override
  String get eventsFieldModeSynced => 'Редицата е синхронизирана.';

  @override
  String get eventsFieldModeSyncFailed =>
      'Не успеа синхронизација. Обидете се повторно.';

  @override
  String eventsFieldModeSyncPartial(int synced, int failed) {
    return 'Синхронизирани се $synced промени. $failed сè уште се во офлајн редицата.';
  }

  @override
  String eventsFieldModeRowLiveImpactBags(int count) {
    return 'Влијание во живо · $count ќесии';
  }

  @override
  String get eventsFieldModeRowUnknown => 'Офлајн промена';

  @override
  String get eventsFieldModeRowStatusPending => 'Чека';

  @override
  String get eventsFieldModeRowStatusSyncing => 'Се синхронизира';

  @override
  String get eventsOfflineWorkHubTitle => 'Офлајн работа';

  @override
  String get eventsOfflineWorkHubSemanticSheet =>
      'Преглед на офлајн работа и синхронизација';

  @override
  String get eventsOfflineWorkSubtitle =>
      'Редици за проверки на локација, теренски промени и разговор.';

  @override
  String get eventsOfflineWorkSectionCheckIns => 'Проверки на локација';

  @override
  String get eventsOfflineWorkSectionField => 'Теренски промени';

  @override
  String get eventsOfflineWorkSectionChat => 'Разговор';

  @override
  String eventsOfflineWorkCountPending(int count) {
    return '$count на чекање';
  }

  @override
  String eventsOfflineWorkCountFailed(int count) {
    return '$count бараат внимание';
  }

  @override
  String get eventsOfflineWorkSyncNow => 'Синхронизирај сега';

  @override
  String get eventsOfflineWorkOpenFieldQueue => 'Отвори ја теренската редица';

  @override
  String get eventsOfflineWorkOpenChat => 'Отвори разговор на настанот';

  @override
  String get eventsOfflineWorkRetryFailedChat =>
      'Обиди се повторно со неиспратени пораки';

  @override
  String get eventsOfflineWorkResolveInChat =>
      'Отворете го разговорот и поправете или избришете ја пораката што не можеше да се испрати.';

  @override
  String get eventsOfflineWorkSyncDone => 'Синхронизацијата заврши';

  @override
  String get eventsOfflineWorkSyncing => 'Се синхронизира…';

  @override
  String get eventsOfflineWorkDrainFailed =>
      'Не можевме да ја завршиме синхронизацијата. Обидете се повторно кога сте онлајн.';

  @override
  String eventsChatOutboxFull(int max) {
    return 'Премногу пораки чекаат офлајн (лимит $max). Поврзете се за да ги испратите, па обидете се повторно.';
  }

  @override
  String get eventsCompletedBagsSectionTitle => 'Собрани ќесии со отпад';

  @override
  String get eventsCompletedBagsSave => 'Зачувај';

  @override
  String get eventsCompletedBagsSaved => 'Бројот на ќесии е зачуван.';

  @override
  String eventsImpactBadgeRating(int rating) {
    return '$rating★ оценка';
  }

  @override
  String eventsImpactBadgeBags(int count) {
    return '$count ќесии';
  }

  @override
  String eventsImpactBadgeHours(String hours) {
    return '$hoursч';
  }

  @override
  String eventsImpactEstimatedLine(String kg, String co2) {
    return '$kg kg отстрането · $co2 kg CO2e избегнато';
  }

  @override
  String eventsLocationSiteSemantic(String distanceKm) {
    return 'Погледни ја локацијата на загадување, на $distanceKm км';
  }

  @override
  String eventsLocationDotKm(String distanceKm) {
    return '· $distanceKm км';
  }

  @override
  String get eventsEmptyAllTitle => 'Сè уште нема еко настани';

  @override
  String get eventsEmptyAllSubtitle =>
      'Бидете први што ќе создадат! Допрете + погоре за да почнете.';

  @override
  String get eventsEmptyUpcomingTitle => 'Нема претстојни настани';

  @override
  String get eventsEmptyUpcomingSubtitle =>
      'Создадете еден за да ги соберете волонтерите.';

  @override
  String get eventsEmptyNearbyTitle => 'Нема настани во близина';

  @override
  String get eventsEmptyNearbySubtitle =>
      'Обидете се со друг филтер или создадете настан во вашата област.';

  @override
  String get eventsEmptyPastTitle => 'Нема минати настани';

  @override
  String get eventsEmptyPastSubtitle =>
      'Завршените настани ќе се појават тука.';

  @override
  String get eventsEmptyMyEventsTitle => 'Сè уште нема настани';

  @override
  String get eventsEmptyMyEventsSubtitle =>
      'Придружете се или создадете настан за да го видите тука.';

  @override
  String eventsSearchEmptyTitle(String query) {
    return 'Нема резултати за „$query“';
  }

  @override
  String get eventsSearchEmptySubtitle =>
      'Обидете се со друг термин или проверете го правописот.';

  @override
  String get eventsSearchEmptyScopeHint =>
      'Резултатите доаѓаат од серверот додека пишувате и од настаните веќе вчитани во оваа листа.';

  @override
  String get eventsSitePickerTitle => 'Изберете локација';

  @override
  String get eventsSitePickerSubtitle =>
      'Поврзете го настанот со една локација за чистење.';

  @override
  String get eventsSitePickerSearchPlaceholder => 'Пребарај по име или опис';

  @override
  String eventsSitePickerNoMatch(String query) {
    return 'Нема локации што одговараат на „$query“';
  }

  @override
  String eventsSitePickerRowKmDesc(String km, String desc) {
    return '$km км далеку · $desc';
  }

  @override
  String get eventsSuccessDialogTitle => 'Настанот е создаден';

  @override
  String eventsSuccessDialogBody(String title, String siteName) {
    return '„$title“ на $siteName е подготвен. Споделете со заедницата за да се приклучат волонтери.';
  }

  @override
  String get eventsSuccessDialogOpenEvent => 'Отвори настан';

  @override
  String get eventsSuccessDialogViewEvent => 'Погледни настан';

  @override
  String get eventsSuccessDialogPendingTitle => 'Испратено за проверка';

  @override
  String eventsSuccessDialogPendingBody(String title, String siteName) {
    return '„$title“ на $siteName е испратен. Модератор ќе го одобри или одбие пред да се појави јавно. Можеш да го отвориш од твоите настани во секое време.';
  }

  @override
  String get eventsTimePickerSelectTime => 'Изберете време';

  @override
  String get eventsTimePickerConfirm => 'Потврди';

  @override
  String get eventsTimePickerFrom => 'Од';

  @override
  String get eventsTimePickerTo => 'До';

  @override
  String eventsTimePickerTimeBlockSemantic(String role, String time) {
    return '$role, $time';
  }

  @override
  String eventsFeedbackRatingStars(int rating) {
    return '$rating★';
  }

  @override
  String get eventsFeedRecentSearches => 'Неодамнешни пребарувања';

  @override
  String get eventsCleanupAfterUploadSemantic =>
      'Прикачи фотографии по чистењето';

  @override
  String get eventsCleanupAfterViewFullscreenSemantic =>
      'Погледни ја фотографијата на цел екран';

  @override
  String get eventsCleanupAfterUploadMoreTitle => 'Прикачи уште фотографии';

  @override
  String eventsCleanupAfterUploadedCount(int count) {
    return '$count прикачени';
  }

  @override
  String eventsCleanupAfterSlotsRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Уште $count слободни места',
      one: 'Уште 1 слободно место',
    );
    return '$_temp0';
  }

  @override
  String get eventsCleanupAfterAddMoreSemantic => 'Додај уште фотографии';

  @override
  String get eventsCleanupAfterRemoveSemantic => 'Отстрани фотографија';

  @override
  String get eventsCleanupAfterEmptyTitle =>
      'Додајте фотографии од исчистената локација';

  @override
  String eventsCleanupAfterEmptyMaxPhotos(int max) {
    return 'До $max фотографии';
  }

  @override
  String get eventsCleanupAfterEmptyTapGallery =>
      'Допрете за избор од галерија';

  @override
  String get eventsCleanupEvidencePhotoSemantic =>
      'Фотографија од доказ за чистење';

  @override
  String get eventsDateRelativeEarlierToday => 'Порано денес';

  @override
  String eventsDateRelativeDaysAgo(int days) {
    return 'Пред $days дена';
  }

  @override
  String get eventsDateRelativeToday => 'Денес';

  @override
  String get eventsDateRelativeTomorrow => 'Утре';

  @override
  String eventsDateRelativeInDays(int days) {
    return 'За $days дена';
  }

  @override
  String get eventsDateInfoSheetTitle => 'Датум и време';

  @override
  String eventsDateInfoSemantic(String date, String timeRange) {
    return '$date, $timeRange';
  }

  @override
  String get eventsCategorySheetTitle => 'Категорија';

  @override
  String eventsCategorySemantic(String label) {
    return 'Категорија на настан: $label';
  }

  @override
  String get eventsOrganizerSheetTitle => 'Организатор';

  @override
  String get eventsOrganizerYouOwnThis => 'Ова е ваш настан';

  @override
  String get eventsOrganizerRoleLabel => 'Организатор на настан';

  @override
  String eventsOrganizerCreatedOn(int day, int month, int year) {
    return 'Настанот е креиран на $day/$month/$year';
  }

  @override
  String eventsOrganizerSemantic(String name) {
    return 'Организатор: $name';
  }

  @override
  String get eventsOrganizedByLabel => 'Организирано од';

  @override
  String get eventsFeedSemantic => 'Листа на настани';

  @override
  String get eventsFeedLoadingSemantic => 'Се вчитуваат настаните';

  @override
  String get eventsFeedTitle => 'Еко-настани';

  @override
  String get eventsFeedCreateSemantic => 'Креирај настан';

  @override
  String get eventsFeedSearchPlaceholder => 'Пребарај настани';

  @override
  String get eventsFeedHappeningNow => 'Во тек';

  @override
  String get eventsFeedComingUp => 'Следуваат';

  @override
  String get eventsFeedRecentlyCompleted => 'Неодамна завршени';

  @override
  String get eventsFeedViewListToggle => 'Листа';

  @override
  String get eventsFeedViewCalendarToggle => 'Календар';

  @override
  String get eventsCalendarPreviousMonth => 'Претходен месец';

  @override
  String get eventsCalendarNextMonth => 'Следен месец';

  @override
  String eventsCalendarDaySemantic(int day) {
    return 'Ден $day';
  }

  @override
  String get eventsCalendarNoEventsThisDay => 'Нема настани за овој ден';

  @override
  String get eventsCalendarIncompleteListHint =>
      'Можеби има повеќе настани. Вчитајте наредна страница за овој месец.';

  @override
  String get eventsCalendarLoadMoreButton => 'Вчитај повеќе';

  @override
  String eventsCalendarDayA11yOutOfMonth(int day) {
    return 'Ден $day, не е од овој месец';
  }

  @override
  String eventsCalendarDayA11y(int day) {
    return 'Ден $day';
  }

  @override
  String eventsCalendarDayA11yHasEvents(int day) {
    return 'Ден $day, има настани';
  }

  @override
  String eventsCalendarDayA11ySelected(int day) {
    return 'Ден $day, избрано';
  }

  @override
  String eventsCalendarDayA11ySelectedHasEvents(int day) {
    return 'Ден $day, избрано, има настани';
  }

  @override
  String get eventsEmptyActionClearFilters => 'Исчисти филтри';

  @override
  String get eventsEmptyActionCreateEvent => 'Креирај настан';

  @override
  String get eventsSearchEmptyClearSearch => 'Исчисти пребарување';

  @override
  String siteCardPollutionSiteSemantic(String title) {
    return 'Загадено место: $title. Допри за детали.';
  }

  @override
  String siteCardPhotoSemantic(String title) {
    return 'Фотографија на $title';
  }

  @override
  String siteCardGalleryPhotoSemantic(int number, String siteTitle) {
    return 'Фотографија $number од $siteTitle';
  }

  @override
  String siteCardSemanticRemoveUpvote(String title) {
    return 'Отстрани поддршка за $title';
  }

  @override
  String siteCardSemanticUpvote(String title) {
    return 'Поддржи $title';
  }

  @override
  String get siteUpvoteLongPressOpensSupporters =>
      'Долго притисни за листа на поддржувачи';

  @override
  String siteCardSemanticUpvotesOpenSupporters(int count, String title) {
    return '$count поддршки на $title. Допри за поддржувачи';
  }

  @override
  String siteCardSemanticCommentsOnSite(int count, String title) {
    return '$count коментари на $title';
  }

  @override
  String siteCardSemanticSharesOnSite(int count, String title) {
    return '$count споделувања на $title';
  }

  @override
  String siteCardSemanticSaveSite(String title) {
    return 'Зачувај $title и добивај ажурирања';
  }

  @override
  String siteCardSemanticUnsaveSite(String title) {
    return 'Отстрани $title од зачувани';
  }

  @override
  String get siteCardSaveUpdatesOnSnack =>
      'Ќе добиваш ажурирања за оваа локација';

  @override
  String get siteCardSaveRemovedSnack => 'Отстрането од зачуваните локации';

  @override
  String get siteCardFeedbackPostHiddenSnack =>
      'Објавата е сокриена од твојот фид';

  @override
  String get siteCardFeedbackThanksSnack =>
      'Ти благодариме за повратната информација';

  @override
  String get siteCardFeedOptionsSheetTitle => 'Опции на фидот';

  @override
  String get siteCardFeedOptionsSheetSubtitle =>
      'Прилагоди што сакаш да гледаш';

  @override
  String get siteCardEngagementSignInRequired =>
      'Најави се за да поддржуваш или зачувуваш локации.';

  @override
  String get siteCardEngagementWaitBriefly =>
      'Почекај малку пред повторен обид.';

  @override
  String siteCardRateLimitedSnack(int seconds) {
    return 'Премногу акции. Обиди се повторно за $seconds секунди.';
  }

  @override
  String get siteDetailSaveAddedSnack => 'Локацијата е зачувана.';

  @override
  String get siteDetailSaveRemovedSnack => 'Отстранета од зачуваните.';

  @override
  String get siteQuickActionSaveSiteLabel => 'Зачувај локација';

  @override
  String get siteQuickActionSavedLabel => 'Зачувано';

  @override
  String get siteQuickActionReportIssueLabel => 'Пријави проблем';

  @override
  String get siteQuickActionReportedLabel => 'Пријавено';

  @override
  String get siteQuickActionShareLabel => 'Сподели';

  @override
  String siteCardDistanceMeters(int meters) {
    return '$meters м';
  }

  @override
  String siteCardDistanceKmShort(String km) {
    return '$km км';
  }

  @override
  String siteCardDistanceKmWhole(String km) {
    return '$km км';
  }

  @override
  String get eventsFilterSheetTitle => 'Филтрирај настани';

  @override
  String get eventsFilterSheetCategory => 'Категорија';

  @override
  String get eventsFilterSheetStatus => 'Статус';

  @override
  String get eventsFilterSheetDateRange => 'Период на датум';

  @override
  String get eventsFilterSheetDateFrom => 'Од';

  @override
  String get eventsFilterSheetDateTo => 'До';

  @override
  String get eventsFilterSheetShowResults => 'Прикажи резултати';

  @override
  String get eventsFilterSheetClearAll => 'Исчисти сè';

  @override
  String eventsFilterSheetActiveCount(int count) {
    return '$count активни';
  }

  @override
  String get eventsOrganizerDashboardTitle => 'Мои настани';

  @override
  String get eventsOrganizerDashboardEmpty =>
      'Сè уште не сте организирале настани.';

  @override
  String get eventsOrganizerDashboardEmptyAction => 'Создај прв настан';

  @override
  String get eventsOrganizerDashboardSectionUpcoming => 'Претстојни';

  @override
  String get eventsOrganizerDashboardSectionInProgress => 'Во тек';

  @override
  String get eventsOrganizerDashboardSectionCompleted => 'Завршени';

  @override
  String get eventsOrganizerDashboardSectionCancelled => 'Откажани';

  @override
  String eventsOrganizerDashboardParticipants(int count, String max) {
    return '$count/$max учесници';
  }

  @override
  String eventsOrganizerDashboardParticipantsUnlimited(int count) {
    return '$count учесници';
  }

  @override
  String get eventsOrganizerDashboardEvidenceAction => 'Докази';

  @override
  String get eventsAnalyticsTitle => 'Аналитика';

  @override
  String get eventsAnalyticsAttendanceRate => 'Стапка на присуство';

  @override
  String get eventsAnalyticsJoiners => 'Приклучени со текот на времето';

  @override
  String get eventsAnalyticsCheckInsByHour => 'Пријави по час';

  @override
  String get eventsAnalyticsNoData => 'Сè уште нема податоци';

  @override
  String get eventsAnalyticsRefresh => 'Освежи аналитика';

  @override
  String eventsAnalyticsCheckedInRatio(int checkedInCount, int totalJoiners) {
    return '$checkedInCount од $totalJoiners се пријавија';
  }

  @override
  String get eventsAnalyticsJoinersEmpty =>
      'Сè уште никој не се приклучил на настанот.';

  @override
  String get eventsAnalyticsCheckInsEmpty =>
      'Сè уште нема пријави. Часовите се во UTC.';

  @override
  String eventsAnalyticsPeakCheckInsUtc(String hour) {
    return 'Врв: $hour UTC';
  }

  @override
  String eventsAnalyticsSemanticsJoinCurve(
    int fromCount,
    int toCount,
    int steps,
  ) {
    return 'Тренд на приклучувања од $fromCount до $toCount учесници, $steps точки.';
  }

  @override
  String eventsAnalyticsSemanticsCheckInHeatmap(int peakCount, String hour) {
    return 'Пријави по час во UTC. Врв $peakCount во $hour.';
  }

  @override
  String get eventsAnalyticsSemanticsCheckInNoData =>
      'Пријави по час во UTC. Нема записани пријави.';

  @override
  String get eventsOfflineSyncQueued =>
      'Зачувано. Ќе се синхронизира кога ќе се поврзете.';

  @override
  String get eventsOfflineSyncFailed =>
      'Синхронизацијата не успеа. Ќе се обиде повторно.';

  @override
  String get eventsWeatherForecast => 'Прогноза за времето';

  @override
  String get eventsWeatherLoadFailed => 'Времето не е достапно';

  @override
  String eventsWeatherPrecipitationMm(String amount) {
    return '$amount мм врнежи';
  }

  @override
  String get eventsWeatherNoPrecipitation => 'Без значителни врнежи';

  @override
  String eventsWeatherPrecipChance(int percent) {
    return '$percent% веројатност за врнежи';
  }

  @override
  String get eventsWeatherIndicativeNote =>
      'Индикативна прогноза од Open-Meteo; вистинските услови може да се разликуваат.';

  @override
  String get eventsWeatherIndicativeInfoTitle => 'За оваа прогноза';

  @override
  String get eventsWeatherIndicativeInfoSemantic =>
      'Информации за изворот на временската прогноза';

  @override
  String get eventsRecurrenceNone => 'Не се повторува';

  @override
  String get eventsRecurrenceWeekly => 'Секоја недела';

  @override
  String get eventsRecurrenceBiweekly => 'На секои 2 недели';

  @override
  String get eventsRecurrenceMonthly => 'Секој месец';

  @override
  String eventsRecurrenceOccurrences(int count) {
    return '$count повторувања';
  }

  @override
  String get eventsRecurrencePartOfSeries => 'Дел од серија';

  @override
  String eventsRecurrenceSeriesLabel(int index, int total) {
    return 'Настан $index од $total';
  }

  @override
  String get eventsRecurrenceDone => 'Готово';

  @override
  String get eventsCategoryGeneralCleanup => 'Општо чистење';

  @override
  String get eventsCategoryGeneralCleanupDescription =>
      'Собирање ѓубре, метење и враќање на подрачјето во ред.';

  @override
  String get eventsCategoryRiverAndLake => 'Чистење на реки и езера';

  @override
  String get eventsCategoryRiverAndLakeDescription =>
      'Отстранување отпад од вода, обали и одводни канали.';

  @override
  String get eventsCategoryTreeAndGreen => 'Садење дрвја и зеленило';

  @override
  String get eventsCategoryTreeAndGreenDescription =>
      'Садење, обновување на зелени површини и градини.';

  @override
  String get eventsCategoryRecyclingDrive => 'Рециклирање';

  @override
  String get eventsCategoryRecyclingDriveDescription =>
      'Сортирање, собирање и транспорт на рециклажа до преработка.';

  @override
  String get eventsCategoryHazardousRemoval => 'Опасен отпад';

  @override
  String get eventsCategoryHazardousRemovalDescription =>
      'Безбедно собирање на хемикалии, гуми, батерии или азбест.';

  @override
  String get eventsCategoryAwarenessAndEducation => 'Свест и едукација';

  @override
  String get eventsCategoryAwarenessAndEducationDescription =>
      'Работилници, предавања или заедничка ангажираност за еколошки практики.';

  @override
  String get eventsCategoryOther => 'Друго';

  @override
  String get eventsCategoryOtherDescription =>
      'Прилагоден настан што не се вклопува во горните категории.';

  @override
  String get eventsGearTrashBags => 'Џувалја за отпад';

  @override
  String get eventsGearGloves => 'Ракавици';

  @override
  String get eventsGearRakes => 'Грабли и лопати';

  @override
  String get eventsGearWheelbarrow => 'Количка';

  @override
  String get eventsGearWaterBoots => 'Чизми за вода';

  @override
  String get eventsGearSafetyVest => 'Рефлектирачки елек';

  @override
  String get eventsGearFirstAid => 'Апчиња за прва помош';

  @override
  String get eventsGearSunscreen => 'Сончев крем и вода';

  @override
  String get eventsScaleSmall => 'Мала (1–5 луѓе)';

  @override
  String get eventsScaleSmallDescription =>
      'Кратко чистење на едно место, една-две торби.';

  @override
  String get eventsScaleMedium => 'Средна (6–15 луѓе)';

  @override
  String get eventsScaleMediumDescription => 'Полудневна акција, повеќе зони.';

  @override
  String get eventsScaleLarge => 'Голема (16–40 луѓе)';

  @override
  String get eventsScaleLargeDescription =>
      'Организирана група, потешок отпад.';

  @override
  String get eventsScaleMassive => 'Масовна (40+ луѓе)';

  @override
  String get eventsScaleMassiveDescription =>
      'Градска или повеќелокациска акција.';

  @override
  String get eventsDifficultyEasy => 'Лесно';

  @override
  String get eventsDifficultyEasyDescription =>
      'Рамен терен, малку отпад, погодно за семејства.';

  @override
  String get eventsDifficultyModerate => 'Умерено';

  @override
  String get eventsDifficultyModerateDescription =>
      'Мешан терен или обемни предмети, повеќе напор.';

  @override
  String get eventsDifficultyHard => 'Тешко';

  @override
  String get eventsDifficultyHardDescription =>
      'Стрмни нагорнини, тежок отпад или опасни материјали.';

  @override
  String get eventsSiteCoercedDescription => 'Заедничка локација за чистење';

  @override
  String get homeSiteCleaningEmptyTitle => 'Сè уште нема настани за чистење';

  @override
  String get homeSiteCleaningEmptyBody =>
      'Бидете први што ќе организираат еколошка акција и ќе соберат волонтери за оваа локација.';

  @override
  String get homeSiteCleaningTapToCreate => 'Допрете за да креирате';

  @override
  String get homeSiteCleaningCtaCreateFirst => 'Креирај еколошка акција';

  @override
  String get homeSiteCleaningCtaScheduleAnother => 'Закажи друга акција';

  @override
  String homeSiteCleaningVolunteersJoined(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count волонтери се приклучија',
      one: '1 волонтер се приклучи',
    );
    return '$_temp0';
  }

  @override
  String get homeSiteCleaningOrganizerHint =>
      'Вие ја организирате оваа акција. Поставете „потоа“ фотографии откако ќе заврши.';

  @override
  String get homeSiteCleaningVolunteerHint =>
      'Приклучете се на акцијата за да помогнете да се исчисти локацијата.';

  @override
  String get homeSiteCleaningJoinAction => 'Приклучи се';

  @override
  String get homeSiteCleaningEventUnavailable =>
      'Деталите за настанот моментално не се достапни.';

  @override
  String get homeSiteCleaningListLoadError =>
      'Не можевме да ги вчитаме настаните. Проверете ја врската и обидете се повторно.';

  @override
  String get homeSiteCleaningRetry => 'Обиди повторно';

  @override
  String get homeSiteCleaningLoadingSemantic => 'Се вчитуваат еко акции.';

  @override
  String get eventsDistanceLessThan100m => '<100 м';

  @override
  String eventsDistanceMeters(int meters) {
    return '$meters м';
  }

  @override
  String eventsDistanceKilometers(String km) {
    return '$km км';
  }

  @override
  String get errorUserNetwork => 'Проверете ја врската и обидете се повторно.';

  @override
  String get errorUserTimeout => 'Побара премногу долго. Обидете се повторно.';

  @override
  String get errorUserUnauthorized => 'Најавете се повторно за да продолжите.';

  @override
  String get errorUserSessionRevoked =>
      'Сесијата повеќе не е важечка. Најавете се повторно.';

  @override
  String get errorUserForbidden => 'Немате дозвола за таа акција.';

  @override
  String get errorUserNotFound => 'Не можевме да го најдеме.';

  @override
  String get errorUserServer => 'Сервисот е зафатен. Обидете се за кратко.';

  @override
  String get errorUserTooManyRequests => 'Премногу обиди. Почекајте малку.';

  @override
  String get errorUserUnknown => 'Нешто тргна наопаку. Обидете се повторно.';

  @override
  String get eventsFilterSheetSemantic => 'Филтрирај настани';

  @override
  String get eventChatTitle => 'Разговор';

  @override
  String get eventChatRowTitle => 'Групен разговор';

  @override
  String get eventChatInputHint => 'Порака';

  @override
  String get eventChatSend => 'Испрати';

  @override
  String get eventChatEmptyTitle => 'Започнете разговор';

  @override
  String get eventChatEmptyBody =>
      'Координирајте со другите волонтери пред и за време на настанот.';

  @override
  String get eventChatEmptySayHello => 'Поздрави се';

  @override
  String get eventChatMessageRemoved => 'Оваа порака е отстранета';

  @override
  String get eventChatNewMessages => 'Нови пораки';

  @override
  String get eventChatToday => 'Денес';

  @override
  String get eventChatYesterday => 'Вчера';

  @override
  String get eventChatReply => 'Одговори';

  @override
  String get eventChatDelete => 'Избриши';

  @override
  String get eventChatLoadError => 'Не можевме да ги вчитаме пораките';

  @override
  String get eventChatSendFailed =>
      'Пораката не е испратена. Допрете за повторен обид.';

  @override
  String get eventChatOpenMapsFailed =>
      'Не можев да го отворам Maps. Обиди се повторно.';

  @override
  String get eventChatAttachPhotoLibrary => 'Фото библиотека';

  @override
  String get eventChatAttachCamera => 'Камера';

  @override
  String get eventChatAttachVideo => 'Видео';

  @override
  String get eventChatAttachDocument => 'Документ';

  @override
  String get eventChatAttachAudio => 'Аудио';

  @override
  String get eventChatVoiceDiscard => 'Отфрли снимка';

  @override
  String get eventChatVoiceSend => 'Испрати гласовна порака';

  @override
  String get eventChatVoicePreviewHint => 'Преглед на глас';

  @override
  String get eventChatAttachLocation => 'Сподели локација';

  @override
  String get eventChatSendLocation => 'Испрати локација';

  @override
  String get eventChatSending => 'Се испраќа…';

  @override
  String eventChatReplyingTo(String name) {
    return 'Одговор на $name';
  }

  @override
  String eventChatCharCountHint(int count) {
    return '$count / 2000';
  }

  @override
  String eventChatSemanticsBubble(String author, String time, String body) {
    return '$author, $time. $body';
  }

  @override
  String get eventChatInputSemantics => 'Порака во разговорот';

  @override
  String get eventChatMessagesListSemantics => 'Листа на пораки';

  @override
  String get eventChatAttachmentsNeedNetwork =>
      'Фотографии, видео, датотеки и гласовни пораки бараат интернет врска.';

  @override
  String get eventChatPushChannelName => 'Разговор на настан';

  @override
  String get eventChatEdited => '(изменето)';

  @override
  String get eventChatEditMessage => 'Уреди';

  @override
  String get eventChatEditing => 'Уредување порака';

  @override
  String get eventChatEditHint => 'Уредете ја вашата порака';

  @override
  String get eventChatSaveEdit => 'Зачувај';

  @override
  String get eventChatPinMessage => 'Закачи';

  @override
  String get eventChatUnpinMessage => 'Откачи';

  @override
  String eventChatPinnedBy(String name) {
    return 'Закачено од $name';
  }

  @override
  String get eventChatPinnedMessagesTitle => 'Закачени пораки';

  @override
  String get eventChatPinnedBarHint => 'Закачено';

  @override
  String get eventChatNoPinnedMessages => 'Нема закачени пораки';

  @override
  String get eventChatMuted => 'Известувањата се исклучени';

  @override
  String get eventChatUnmuted => 'Известувањата се вклучени';

  @override
  String get eventChatCopied => 'Пораката е копирана';

  @override
  String get eventChatReconnecting => 'Повторно поврзување…';

  @override
  String get eventChatConnected => 'Поврзано';

  @override
  String get eventChatSearchHint => 'Пребарај пораки';

  @override
  String get eventChatSearchNoResults => 'Нема совпаѓања за пребарувањето';

  @override
  String get eventChatSearchAction => 'Пребарај';

  @override
  String get eventChatSearchFailed =>
      'Пребарувањето не успеа. Провери ја врската и обиди се повторно.';

  @override
  String get eventChatSearchMinChars => 'Внеси барем 2 знаци за пребарување.';

  @override
  String get eventChatSearchIncludingLocalMatches =>
      'Вклучува пораки вчитани на овој уред.';

  @override
  String get eventChatSearchLoadMore => 'Вчитај повеќе резултати';

  @override
  String eventChatParticipantsCount(int count) {
    return '$count учесници';
  }

  @override
  String get eventChatParticipantsSheetTitle => 'Луѓе во овој разговор';

  @override
  String eventChatParticipantsTitleSemantic(String eventTitle, int count) {
    return '$eventTitle, $count учесници';
  }

  @override
  String get eventChatParticipantsLoadError =>
      'Не можеше да се вчитаат учесниците.';

  @override
  String get eventChatParticipantsYouBadge => 'Вие';

  @override
  String get eventChatParticipantsEmpty => 'Сè уште нема вчитани учесници.';

  @override
  String eventChatSystemUserJoined(String name) {
    return '$name се придружи на настанот';
  }

  @override
  String eventChatSystemUserLeft(String name) {
    return '$name го напушти настанот';
  }

  @override
  String get eventChatSystemEventUpdated => 'Деталите за настанот се ажурирани';

  @override
  String get eventChatSwipeReplySemantic => 'Повлечи за одговор на порака';

  @override
  String get eventChatVoiceLevelSemantic => 'Ниво на глас';

  @override
  String get eventChatMessageOptions => 'Опции за порака';

  @override
  String get eventChatTypingUnknownParticipant => 'Некој';

  @override
  String get eventChatCopy => 'Копирај';

  @override
  String get eventChatUnpinConfirm => 'Пораката е откачена';

  @override
  String get eventChatMaxPinnedReached =>
      'Достигнат е максимумот закачени пораки';

  @override
  String get eventChatMessageNotInView =>
      'Таа порака не е вчитана. Лизгајте нагоре за постари пораки.';

  @override
  String get eventChatMuteNotifications => 'Исклучи известувања';

  @override
  String get eventChatUnmuteNotifications => 'Вклучи известувања';

  @override
  String eventChatSeenBy(String names) {
    return 'Видено од $names';
  }

  @override
  String eventChatSeenByTruncated(String names, int count) {
    return 'Видено од $names +$count';
  }

  @override
  String eventChatTypingOne(String name) {
    return '$name пишува…';
  }

  @override
  String eventChatTypingTwo(String first, String second) {
    return '$first и $second пишуваат…';
  }

  @override
  String eventChatTypingMany(String name, int count) {
    return '$name и уште $count пишуваат…';
  }

  @override
  String get eventChatImageViewerTitle => 'Фотографија';

  @override
  String eventChatImageViewerPage(int current, int total) {
    return '$current од $total';
  }

  @override
  String get eventChatVideoViewerTitle => 'Видео';

  @override
  String get eventChatOpenFile => 'Отвори датотека';

  @override
  String get eventChatDownloadFailed => 'Не можев да ја преземам датотеката';

  @override
  String get eventChatPdfOpenFailed => 'Не можев да го отворам PDF';

  @override
  String get eventChatShareFile => 'Сподели';

  @override
  String get eventChatLocationMapTitle => 'Локација';

  @override
  String get eventChatCopyCoordinates => 'Копирај координати';

  @override
  String get eventChatDirections => 'Насоки';

  @override
  String get eventChatAudioExpandedTitle => 'Гласовна порака';

  @override
  String get eventChatHoldToRecord => 'Држи за снимање';

  @override
  String get eventChatReleaseToSend => 'Пушти за испраќање';

  @override
  String get eventChatSlideToCancel => 'Повлечи лево за откажување';

  @override
  String get eventChatReleaseToCancel => 'Пушти за откажување';

  @override
  String get eventChatRecording => 'Снимање…';

  @override
  String get eventChatMicPermissionDenied =>
      'Потребен е пристап до микрофонот за гласовни пораки.';

  @override
  String get reportEntryLabelGuided => 'Воден извештај';

  @override
  String get reportEntryLabelCamera => 'Извештај од камера';

  @override
  String get reportEntryHintCamera =>
      'Ако почнеш со жива фотографија, модерацијата обично е побрза бидејќи доказот веќе е прикачен.';

  @override
  String get homeReportingCapacityCheckFailed =>
      'Не можевме да ја провериме достапноста за пријавување.';

  @override
  String get homeCameraOpenFailed =>
      'Камерата не може да се отвори. Обиди се повторно за момент.';

  @override
  String get mapTabPlaceholderHint =>
      'Отвори ја оваа картичка за да се вчита живата мапа и локалитетите на загадување.';

  @override
  String get reportCategoryPickerTitle => 'Избери категорија';

  @override
  String get reportCategoryPickerSubtitle =>
      'Избери најблиската опција за проблемот што го пријавуваш.';

  @override
  String get reportCategoryPickerBannerTitle => 'Избери најблиската опција';

  @override
  String get reportCategoryPickerBannerBody =>
      'Избери ја категоријата што модераторите прво треба да ја потврдат. Не мора да биде совршено.';

  @override
  String get reportCategoryIllegalLandfillTitle => 'Незаконска депонија';

  @override
  String get reportCategoryIllegalLandfillDescription =>
      'Фрлен отпад, купишта ѓубре или неформални места за одлагање.';

  @override
  String get reportCategoryWaterPollutionTitle => 'Загадување на вода';

  @override
  String get reportCategoryWaterPollutionDescription =>
      'Загадени реки, езера, одводи или испуштање на отпадни води.';

  @override
  String get reportCategoryAirPollutionTitle => 'Загадување на воздух';

  @override
  String get reportCategoryAirPollutionDescription =>
      'Чад, прашина, пален отпад или емисии што му штетат на воздухот.';

  @override
  String get reportCategoryIndustrialWasteTitle => 'Индустриски отпад';

  @override
  String get reportCategoryIndustrialWasteDescription =>
      'Градежен шут, фабрички отпад или опасни материјали.';

  @override
  String get reportCategoryOtherTitle => 'Друго';

  @override
  String get reportCategoryOtherDescription =>
      'Кога проблемот не се вклопува јасно во категориите погоре.';

  @override
  String get unknownRouteTitle => 'Страницата не е пронајдена';

  @override
  String get unknownRouteMessage => 'Линкот може да е застарен или погрешен.';

  @override
  String get unknownRouteContinueButton => 'Продолжи кон апликацијата';

  @override
  String unknownRouteDebugRoute(String routeName) {
    return 'Дебаг: името на рутата беше „$routeName“.';
  }

  @override
  String get chatShareLocation => 'Сподели локација';

  @override
  String get chatSharedLocation => 'Споделена локација';

  @override
  String get organizerToolkitTitle => 'Стани организатор';

  @override
  String get organizerToolkitPage1Title => 'Планирај однапред';

  @override
  String get organizerToolkitPage1Body =>
      'Проценете ја локацијата за опасности, подгответе безбедносна опрема и брифирајте го тимот пред доаѓањето на доброволците.';

  @override
  String get organizerToolkitPage2Title => 'Модерацијата гради доверба';

  @override
  String get organizerToolkitPage2Body =>
      'Откако ќе креирате настан, модераторите го прегледуваат. По одобрувањето, доброволците можат да го видат и да се приклучат.';

  @override
  String get organizerToolkitPage3Title => 'Потврдете присуство';

  @override
  String get organizerToolkitPage3Body =>
      'Користете го QR чекирањето во апликацијата за секој доброволец да добие заслужени поени.';

  @override
  String get organizerToolkitPage4Title => 'Време и безбедност';

  @override
  String get organizerToolkitPage4Body =>
      'Ако условите станат небезбедни, паузирајте или одложете. Веднаш известете ги регистрираните доброволци во апликацијата за никој да не патува за откажан почеток.';

  @override
  String get organizerToolkitPage5Title => 'Отпад и одлагање';

  @override
  String get organizerToolkitPage5Body =>
      'Сортирајте рециклажа кога е можно, безбедно пакувајте остри предмети и однесете го отпадот на овластени места. Оставете ја локацијата почиста отколку што ја затекнавте.';

  @override
  String get organizerToolkitPage6Title => 'Вклучете ги сите';

  @override
  String get organizerToolkitPage6Body =>
      'Понудете јасни улоги, постојан темпо и трпеливост. Добредојде брифинг им помага на новите доброволци да се чувствуваат сигурно и безбедно.';

  @override
  String get organizerToolkitPage7Title => 'Приватност во чат';

  @override
  String get organizerToolkitPage7Body =>
      'Држете ги личните телефони и адреси надвор од јавниот чат на настанот. Користете пораки во апликацијата за целиот тим да биде известен без преголемо споделување.';

  @override
  String get organizerToolkitPage8Title => 'Докази и чесен ефект';

  @override
  String get organizerToolkitPage8Body =>
      'Фотографиите потоа и бројот на ќесии треба да ја одразуваат вистината. Точно известување гради доверба кај доброволците, модераторите и пошироката заедница.';

  @override
  String get organizerToolkitContinue => 'Продолжи';

  @override
  String get organizerToolkitStartQuiz => 'Реши го квизот';

  @override
  String get organizerQuizTitle => 'Брза проверка на знаење';

  @override
  String get organizerQuizLoadFailed =>
      'Не можеше да се вчита квизот. Обидете се повторно.';

  @override
  String get organizerQuizLoadInvalidResponse =>
      'Податоците за квизот од серверот се нецелосни. Обидете се повторно.';

  @override
  String get organizerQuizRetryLoad => 'Обиди се повторно';

  @override
  String get organizerQuizSubmitFailed =>
      'Не можеше да се поднесат одговорите. Обидете се повторно.';

  @override
  String organizerQuizOptionSemantic(int index, int total, String optionText) {
    return 'Прашање $index од $total: $optionText';
  }

  @override
  String get organizerQuizSubmit => 'Поднеси одговори';

  @override
  String get organizerQuizPassedTitle => 'Сертифициран сте!';

  @override
  String get organizerQuizPassedBody =>
      'Сега можете да креирате настани за чистење. Доброволците чекаат.';

  @override
  String get organizerQuizFailedTitle => 'Не сосема';

  @override
  String organizerQuizFailedBody(int correct, int total) {
    return 'Прегледајте го туториалот и обидете се повторно. Точни $correct од $total.';
  }

  @override
  String get organizerQuizRetry => 'Обидете се повторно';

  @override
  String get organizerQuizCreateEvent => 'Креирај го првиот настан';

  @override
  String get organizerCertifiedBadge => 'Сертифициран организатор';

  @override
  String get errorOrganizerQuizSessionExpired =>
      'Сесијата за квиз истече. Вчитајте нов квиз и обидете се повторно.';

  @override
  String get errorOrganizerQuizSessionInvalid =>
      'Оваа сесија за квиз не е валидна. Вчитајте го квизот повторно.';

  @override
  String get errorOrganizerQuizAnswersMismatch =>
      'Одговорите не се совпаѓаат со квизот што го започнавте. Вчитајте го квизот повторно.';

  @override
  String get errorOrganizerQuizInvalid =>
      'Некои одговори не се валидни за овој квиз. Вчитајте го квизот повторно.';

  @override
  String get errorOrganizerCertificationAlreadyDone =>
      'Веќе сте сертифициран организатор. Не треба повторно да полагате квиз.';

  @override
  String get reportsSseReconnectBanner => 'Повторно поврзување за ажурирања…';

  @override
  String get reportsSseOfflineBanner =>
      'Ажурирањата во живо се исклучени. Повторно поврзете се кога имате мрежа или обидете се повторно.';

  @override
  String get reportsSseReconnectAction => 'Повторно поврзи';

  @override
  String get reportsListMergedToast =>
      'Оваа пријава е споена и отстранета од вашата листа.';

  @override
  String get reportDraftResumeTitle => 'Да продолжите со нацртот?';

  @override
  String reportDraftResumeBody(
    int photoCount,
    String titlePreview,
    String savedAt,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      photoCount,
      locale: localeName,
      other: 'Зачувани се $photoCount фотографии.',
      one: 'Зачувана е 1 фотографија.',
      zero: 'Сè уште нема зачувани фотографии.',
    );
    return '$_temp0\n\nНаслов: \"$titlePreview\"\n\nПоследно зачувано: $savedAt.';
  }

  @override
  String get reportDraftResumeContinue => 'Продолжи';

  @override
  String get reportDraftResumeDiscard => 'Отфрли нацрт';

  @override
  String get reportDraftSavedJustNow => 'Зачувано пред малку';

  @override
  String reportDraftSavedMinutesAgo(int minutes) {
    return 'Зачувано пред $minutes мин';
  }

  @override
  String reportDraftSavedHoursAgo(int hours) {
    return 'Зачувано пред $hours ч';
  }

  @override
  String reportDraftPhotosLost(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count прикачени фотографии недостасуваа и беа отстранети од нацртот.',
      one:
          'Една прикачена фотографија недостасуваше и беше отстранета од нацртот.',
    );
    return '$_temp0';
  }

  @override
  String get reportDraftDiscardConfirmTitle => 'Да се отфрли нацртот?';

  @override
  String get reportDraftDiscardConfirmBody =>
      'Зачуваниот текст и фотографиите за оваа пријава ќе бидат избришани од овој уред.';

  @override
  String get reportDraftCentralFabSheetTitle => 'Имате зачуван нацрт';

  @override
  String reportDraftCentralFabSubtitle(int photoCount, String savedAgo) {
    String _temp0 = intl.Intl.pluralLogic(
      photoCount,
      locale: localeName,
      other: '$photoCount фотографии',
      one: '1 фотографија',
      zero: 'Нема фотографии',
    );
    return '$_temp0 · $savedAgo';
  }

  @override
  String get reportDraftCentralFabContinue => 'Продолжи со нацртот';

  @override
  String get reportDraftCentralFabTakeNewPhoto => 'Нова фотографија';

  @override
  String get reportDraftCentralFabCancel => 'Откажи';

  @override
  String get reportDraftIncomingPhotoTitle =>
      'Продолжи со нацртот или користи ја оваа фотографија?';

  @override
  String reportDraftIncomingPhotoBody(int photoCount, String savedAgo) {
    String _temp0 = intl.Intl.pluralLogic(
      photoCount,
      locale: localeName,
      other: '$photoCount фотографии',
      one: '1 фотографија',
      zero: 'нема фотографии',
    );
    return 'Имате зачуван нацрт ($_temp0). $savedAgo';
  }

  @override
  String get reportDraftIncomingPhotoContinue => 'Продолжи со нацртот';

  @override
  String get reportDraftIncomingPhotoReplace => 'Замени го нацртот';

  @override
  String get reportDraftIncomingPhotoAdd => 'Додај во нацртот';

  @override
  String get savedMapAreasTitle => 'Зачувани области на мапа';

  @override
  String get savedMapAreasPlaceholder =>
      'Офлајн региони и преземања ќе се појават тука.';

  @override
  String get mapWhatsNewTitle => 'Ажурирања на мапата';

  @override
  String get mapWhatsNewBody =>
      'Подобро предвремено вчитување, постојани кластери и побезбедни мапни процеси.';

  @override
  String get pushPermissionRationaleTitle => 'Останете во тек';

  @override
  String get pushPermissionRationaleBody =>
      'Дозволете известувања за потсетници за чистење, ажурирања на настани и пораки во четот. Можете да го промените ова во Поставувања.';

  @override
  String get pushPermissionRationaleAllow => 'Дозволи известувања';

  @override
  String get pushPermissionRationaleNotNow => 'Не сега';

  @override
  String get pushChannelDefaultName => 'Chisto.mk';

  @override
  String get pushChannelDefaultDescription => 'Општи известувања';

  @override
  String get eventChatPushChannelDescription =>
      'Пораки за чистења на кои сте се пријавиле';

  @override
  String get micPermissionRationaleTitle => 'Пристап до микрофон';

  @override
  String get micPermissionRationaleBody =>
      'Гласовните пораки во четот на настанот го користат микрофонот само додека снимате.';

  @override
  String get micPermissionRationaleAllow => 'Дозволи микрофон';

  @override
  String get micPermissionRationaleNotNow => 'Не сега';

  @override
  String get micPermissionOpenSettings => 'Отвори Поставувања';

  @override
  String get photoSourceModalTitle => 'Додај фотографија';

  @override
  String get photoSourceModalSubtitle =>
      'Изберете како да ја додадете првата фотографија.';

  @override
  String get photoSourceModalHint =>
      'Можете да ја прегледате фотографијата пред да се додаде.';

  @override
  String get photoSourceTakePhoto => 'Сликај';

  @override
  String get photoSourceTakePhotoSubtitle => 'Зфатете јасен преглед веднаш.';

  @override
  String get photoSourceBestChoiceBadge => 'Најдобар избор';

  @override
  String get photoSourceChooseFromLibrary => 'Избери од галерија';

  @override
  String get photoSourceChooseFromLibrarySubtitle =>
      'Користете фотографија што веќе ја имате на уредот.';

  @override
  String get photoSourceCloseSemanticLabel => 'Затвори';

  @override
  String get locationPickerStatePermissionNeeded =>
      'Потребна е дозвола за локација';

  @override
  String get locationPickerStateDetectingPosition =>
      'Се открива вашата позиција';

  @override
  String get locationPickerStateCheckingLocation => 'Се проверува локацијата…';

  @override
  String get locationPickerStateCurrentLocationUnavailable =>
      'Моменталната локација е недостапна';

  @override
  String get locationPickerStateReviewDetectedLocation =>
      'Прегледајте ја откриената локација';

  @override
  String get locationPickerStateOutsideMacedonia =>
      'Локацијата е надвор од Македонија';

  @override
  String get locationPickerStatePinNeedsConfirmation => 'Пинот бара потврда';

  @override
  String get locationPickerStateLocationConfirmed => 'Локацијата е потврдена';

  @override
  String get locationPickerStateTapConfirmWhenReady =>
      'Допрете Потврди кога сте подготвени';

  @override
  String locationPickerScreenSemantics(String stateLabel) {
    return 'Избирач на локација. $stateLabel';
  }

  @override
  String get locationPickerMapSemantics =>
      'Мапа. Влечете за да го поместите пинот. Пинот не може да излезе од Македонија.';

  @override
  String get locationPickerHelperReviewGps =>
      'Ја најдовме вашата моментална локација. Прегледајте го пинот, потоа потврдете.';

  @override
  String get locationPickerHelperReadyToSubmit =>
      'Закачената локација е подготвена за испраќање.';

  @override
  String get locationPickerHelperMovePinConfirm =>
      'Поместете го пинот точно на местото, потоа допрете Потврди. Мапата останува во Македонија.';

  @override
  String get locationPickerRetryAddressHint =>
      'Двојно допрете за повторно пребарување на адресата.';

  @override
  String get locationPickerAddressLookupUnavailableBody =>
      'Пребарувањето на адресата е недостапно. Сепак можете да го потврдите пинот.';

  @override
  String get locationPickerBannerPermissionOff =>
      'Пристапот до локација е исклучен. Поместете ја мапата рачно, потоа потврдете го пинот.';

  @override
  String get locationPickerBannerGpsOutsideTitle =>
      'Моменталната локација е надвор од покриеност';

  @override
  String get locationPickerBannerGpsOutsideBody =>
      'GPS е надвор од Македонија. Поместете го пинот рачно или обидете се повторно.';

  @override
  String get locationPickerConfirmSemanticsWhenUnset =>
      'Потврди локација. Поставете го ова место како локација на пријавата';

  @override
  String get locationPickerConfirmSemanticsWhenConfirmed =>
      'Потврди локација. Локацијата е веќе потврдена';

  @override
  String get locationPickerConfirmHintDone =>
      'Локацијата е поставена за оваа пријава.';

  @override
  String get locationPickerConfirmHintPending =>
      'Двојно допрете за да го поставите ова место како локација на пријавата.';

  @override
  String get locationPickerConfirmChecking => 'Се проверува…';

  @override
  String get locationPickerConfirmLocation => 'Потврди локација';

  @override
  String get locationPickerAddressChecking => 'Се проверува адресата…';

  @override
  String locationPickerAddressUnavailableWithCoords(String coords) {
    return 'Адресата е недостапна. Координати: $coords';
  }

  @override
  String locationPickerAddressNear(String address) {
    return 'Околу $address';
  }

  @override
  String get locationPickerAddressPlaceholder => '—';

  @override
  String get locationPickerUseCurrentLocationLabel =>
      'Користи моментална локација.';

  @override
  String get locationPickerUseCurrentLocationHint =>
      'Двојно допрете за да ја центрирате мапата на GPS позицијата ако е во Македонија.';
}
