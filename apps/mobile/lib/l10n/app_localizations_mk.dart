// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Macedonian (`mk`).
class AppLocalizationsMk extends AppLocalizations {
  AppLocalizationsMk([String locale = 'mk']) : super(locale);

  @override
  String get reportFlowHelpHint => 'Tap the info button for tips on this step.';

  @override
  String get reportHelpContextTitle => 'Context';

  @override
  String get reportStageEvidenceEyebrow => 'Report a pollution site';

  @override
  String get reportStageEvidenceTitle => 'Evidence';

  @override
  String get reportStageEvidenceSubtitle => 'Photos and framing';

  @override
  String get reportStageEvidenceShortLabel => 'Evidence';

  @override
  String get reportStageEvidencePrimaryAction => 'Next';

  @override
  String get reportStageEvidencePrimaryRequirement => 'Photo';

  @override
  String get reportStageEvidenceSecondaryRequirement => 'Up to 5';

  @override
  String get reportStageEvidenceInfoTitle => 'Evidence';

  @override
  String get reportHelpEvidenceS0Title => 'What to capture';

  @override
  String get reportHelpEvidenceS0Body =>
      'Add up to five photos that show the polluted area clearly. Use a wide shot for context, then closer frames of what matters: waste piles, pipes, stains, debris, or anything that shows the problem.';

  @override
  String get reportHelpEvidenceS1Title => 'Why it helps';

  @override
  String get reportHelpEvidenceS1Body =>
      'Moderators rely on your images to confirm the report and prioritize follow-up. Daylight, a steady hand, and showing the whole site make verification much easier.';

  @override
  String get reportStageDetailsEyebrow => 'Describe the issue';

  @override
  String get reportStageDetailsTitle => 'Details';

  @override
  String get reportStageDetailsSubtitle => 'Category, headline, and context';

  @override
  String get reportStageDetailsShortLabel => 'Details';

  @override
  String get reportStageDetailsPrimaryAction => 'Next';

  @override
  String get reportStageDetailsPrimaryRequirement => 'Category & title';

  @override
  String get reportStageDetailsSecondaryRequirement => 'Details optional';

  @override
  String get reportStageDetailsInfoTitle => 'Details';

  @override
  String get reportHelpDetailsS0Title => 'What to fill in';

  @override
  String get reportHelpDetailsS0Body =>
      'Choose the category that best matches what you saw. Write a short headline anyone could understand at a glance, like a news title, not an essay.\n\nThen add severity if you’re unsure; use the description for anything that helps someone find or assess the site on the ground: access, timing, smell, color of water, or landmarks. Cleanup effort is optional and only useful if you have a rough sense of scale.';

  @override
  String get reportHelpDetailsS1Title => 'Optional fields';

  @override
  String get reportHelpDetailsS1Body =>
      'Nothing here blocks submission except category and title. Extra detail is for nuance. Use it when it genuinely helps.';

  @override
  String get reportStageLocationEyebrow => 'Confirm the location';

  @override
  String get reportStageLocationTitle => 'Location';

  @override
  String get reportStageLocationSubtitle => 'Map pin';

  @override
  String get reportStageLocationShortLabel => 'Location';

  @override
  String get reportStageLocationPrimaryAction => 'Next';

  @override
  String get reportStageLocationPrimaryRequirement => 'Pin';

  @override
  String get reportStageLocationSecondaryRequirement => 'In Macedonia';

  @override
  String get reportStageLocationInfoTitle => 'Location';

  @override
  String get reportHelpLocationS0Title => 'How to place the pin';

  @override
  String get reportHelpLocationS0Body =>
      'Drag the map to the exact spot where the pollution is, not the nearest town unless you’re reporting a whole area. Zoom in until the pin sits on the real site.';

  @override
  String get reportHelpLocationS1Title => 'Coverage area';

  @override
  String get reportHelpLocationS1Body =>
      'The pin must be inside Macedonia so your report can be routed and verified correctly. If you’re unsure, place it as accurately as you can.';

  @override
  String get reportHelpLocationS2Title => 'Why it matters';

  @override
  String get reportHelpLocationS2Body =>
      'Coordinates tie your photos and description to a real place for field teams and moderators.';

  @override
  String get reportStageReviewEyebrow => 'Final review';

  @override
  String get reportStageReviewTitle => 'Review';

  @override
  String get reportStageReviewSubtitle => 'Before you send';

  @override
  String get reportStageReviewShortLabel => 'Review';

  @override
  String get reportStageReviewPrimaryAction => 'Submit';

  @override
  String get reportStageReviewPrimaryRequirement => 'Ready';

  @override
  String get reportStageReviewInfoTitle => 'Review';

  @override
  String get reportHelpReviewS0Title => 'Double-check each section';

  @override
  String get reportHelpReviewS0Body =>
      'Tap any row to jump back and edit. When photos, details, and location all match what you saw, you’re ready.';

  @override
  String get reportHelpReviewS1Title => 'What happens next';

  @override
  String get reportHelpReviewS1Body =>
      'Your report is reviewed before it appears publicly. In My reports, you can track status; updates appear there as the site moves through moderation.';

  @override
  String get newReportTitle => 'New report';

  @override
  String get reportReviewBannerCreditsTitle => 'Credits';

  @override
  String get reportReviewBannerAfterSubmitTitle => 'After submit';

  @override
  String get reportReviewAfterSubmitReady =>
      'Moderated before public. Status in My reports.';

  @override
  String get reportReviewAfterSubmitIncomplete => 'Finish steps above.';

  @override
  String get semanticsClose => 'Close';

  @override
  String semanticsAboutStep(String title) {
    return 'About $title';
  }

  @override
  String semanticsNextStep(String label) {
    return 'Next: $label';
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
      'Нацртот е зачуван — обидете се повторно кога ќе бидете подготвени.';

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
  String reportSubmittedPointsPending(int max) {
    return 'До $max поени кога ќе биде одобрено';
  }

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
      'Зближете со стискање · повлечете за позиција';

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
}
