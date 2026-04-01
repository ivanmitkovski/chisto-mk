// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Albanian (`sq`).
class AppLocalizationsSq extends AppLocalizations {
  AppLocalizationsSq([String locale = 'sq']) : super(locale);

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
      'Shtoni të paktën një foto për të vazhduar.';

  @override
  String get reportFlowLocationOutsideMacedoniaHelper =>
      'Ky vend është jashtë Maqedonisë. Tërhiqni kunjin brenda vendit, pastaj prekni Konfirmo vendndodhjen.';

  @override
  String get reportLocationAdvanceBlockedBanner =>
      'Vendosni kunjin në Maqedoni dhe prekni Konfirmo vendndodhjen.';

  @override
  String get reviewTapToEdit => 'Prek për të përpunuar';

  @override
  String semanticsCurrentReportStep(String label) {
    return 'Hapi aktual: $label';
  }

  @override
  String get errorBannerDraftSavedHint =>
      'Drafti juaj është ruajtur — mund të provoni përsëri kur të jeni gati.';

  @override
  String get reportSubmittedTitle => 'Raporti u dërgua';

  @override
  String reportSubmittedSavedAs(String number) {
    return 'U ruajt si raport $number';
  }

  @override
  String reportSubmittedBodyWithAddress(String category, String address) {
    return '$category near $address është në radhë për shqyrtim.';
  }

  @override
  String reportSubmittedBodyNoAddress(String category) {
    return '$category është në radhë për shqyrtim.';
  }

  @override
  String get reportSubmittedNewSiteBadge => 'Vend i ri u shtua në hartë';

  @override
  String reportSubmittedPointsEarned(int points) {
    return '+$points pikë';
  }

  @override
  String reportSubmittedPointsPending(int max) {
    return 'Deri në $max pikë kur të miratohet';
  }

  @override
  String get reportSubmittedViewThisReport => 'Shiko këtë raport';

  @override
  String get reportSubmittedViewAllReports => 'Shiko të gjitha raportet';

  @override
  String get reportSubmittedViewInMyReports => 'Shiko te Raportet e mia';

  @override
  String get reportSubmittedReportAnother => 'Raport tjetër';

  @override
  String get reportSubmittedSemanticsSuccess => 'Raporti u dërgua me sukses';

  @override
  String get profileAvatarSourceTitle => 'Foto e profilit';

  @override
  String get profileAvatarSourceSubtitle =>
      'Bëni një foto të re ose zgjidhni nga biblioteka juaj. Më pas mund ta përshtatni kadrimin.';

  @override
  String get profileAvatarSourceCamera => 'Kamera';

  @override
  String get profileAvatarSourceCameraHint =>
      'Kamera e përparme me dritë të mirë funksionon më mirë.';

  @override
  String get profileAvatarSourcePhotos => 'Fotografi';

  @override
  String get profileAvatarSourcePhotosHint =>
      'Zgjidhni çdo imazh që keni ruajtur.';

  @override
  String get profileAvatarSourceRemove => 'Hiq foton aktuale';

  @override
  String get profileAvatarSourceRemoveHint =>
      'Shfaq inicialët në vend të fotos';

  @override
  String get profileAvatarRemoveConfirmTitle => 'Të hiqet fotoja e profilit?';

  @override
  String get profileAvatarRemoveConfirmMessage =>
      'Fotoja do të fshihet dhe do të shfaqen inicialët tuaj.';

  @override
  String get profileAvatarRemoveConfirmCancel => 'Anulo';

  @override
  String get profileAvatarRemoveConfirmRemove => 'Hiq';

  @override
  String get profileAvatarRemovedMessage => 'Fotoja e profilit u hoq';

  @override
  String get profileAvatarRemoveFailed => 'Nuk hoqej fotoja. Provoni përsëri.';

  @override
  String get profileAvatarSourceRecommended => 'E rekomanduar';

  @override
  String get profileAvatarCropMoveAndScale => 'Lëviz dhe shkallëzo';

  @override
  String get profileAvatarCropHint =>
      'Zmadhoj me dy gishta · zhvendos për pozicion';

  @override
  String get profileAvatarCropLoading => 'Po ngarkohet fotoja…';

  @override
  String get profileAvatarCropCancel => 'Anulo';

  @override
  String get profileAvatarCropDone => 'Bërë';

  @override
  String get profileAvatarTapToChange => 'Prek për të ndryshuar foton';

  @override
  String get profileAvatarUploadingCaption => 'Duke ngarkuar…';

  @override
  String get profileAvatarCropEditorSemantic =>
      'Prisni foton e profilit. Zoom me dy gishta dhe zhvendoseni imazhin.';

  @override
  String get profileAvatarCropFailed => 'Nuk u prit fotoja. Provoni përsëri.';

  @override
  String get profileAvatarCameraUnavailable =>
      'Kamera nuk hapet tani. Provoni përsëri pas pak.';

  @override
  String get profileAvatarReadPhotoFailed =>
      'Nuk lexohej fotoja. Provoni përsëri.';

  @override
  String get profileAvatarProcessPhotoFailed =>
      'Nuk përpunohej fotoja. Provoni përsëri.';

  @override
  String get profileAvatarPeekSemantic => 'Foto e profilit';

  @override
  String get errorBannerDismiss => 'Mbyll';

  @override
  String get errorBannerTryAgain => 'Provo përsëri';

  @override
  String get authSemanticGoBack => 'Kthehu';

  @override
  String get authLoading => 'Duke u ngarkuar';

  @override
  String get authSignInTitle => 'Hyr';

  @override
  String get authSignInSubtitle =>
      'Mirë se erdhe përsëri. Plotëso të dhënat për të vazhduar.';

  @override
  String get authFieldPhone => 'Numri i telefonit';

  @override
  String get authFieldPhoneHint => '70 123 456';

  @override
  String get authFieldPassword => 'Fjalëkalimi';

  @override
  String get authFieldPasswordHint => 'Shkruaj fjalëkalimin';

  @override
  String get authRememberMe => 'Më mbaj mend';

  @override
  String get authForgotPassword => 'Harrove fjalëkalimin?';

  @override
  String get authSignInCta => 'Hyr';

  @override
  String get authValidationCheckPhonePassword =>
      'Kontrollo numrin e telefonit dhe fjalëkalimin.';

  @override
  String get authSignUpPrompt => 'Nuk ke llogari? ';

  @override
  String get authSignUpLink => 'Regjistrohu';

  @override
  String get authSignUpTitle => 'Regjistrohu';

  @override
  String get authSignUpSubtitle => 'Mirë se erdhe! Plotëso të dhënat e tua';

  @override
  String get authFieldFullName => 'Emri i plotë';

  @override
  String get authFieldFullNameHint => 'Emër Mbiemër';

  @override
  String get authFieldEmail => 'Email';

  @override
  String get authFieldEmailHint => 'përdorues@chisto.mk';

  @override
  String get authFieldPhoneNumber => 'Numri i telefonit';

  @override
  String get authPasswordRequirementsHint =>
      'Të paktën 8 karaktere, me shkronja dhe numra';

  @override
  String get authTermsPrefix => 'Duke u regjistruar pranon ';

  @override
  String get authTermsLink => 'kushtet';

  @override
  String get authValidationCheckFields =>
      'Kontrollo fushat e theksuara më sipër.';

  @override
  String get authSignUpCta => 'Regjistrohu';

  @override
  String get authSignInPrompt => 'Ke tashmë llogari? ';

  @override
  String get authSignInLink => 'Hyr';

  @override
  String authValidationFieldRequired(String fieldName) {
    return '$fieldName është i detyrueshëm';
  }

  @override
  String get authValidationPhoneRequired =>
      'Numri i telefonit është i detyrueshëm';

  @override
  String get authValidationPhoneDigits => 'Shkruaj numër telefoni me 8 shifra';

  @override
  String get authValidationEmailRequired => 'Email-i është i detyrueshëm';

  @override
  String get authValidationEmailInvalid => 'Shkruaj një email të vlefshëm';

  @override
  String get authValidationPasswordRequired =>
      'Fjalëkalimi është i detyrueshëm';

  @override
  String get authValidationPasswordMinLength =>
      'Fjalëkalimi duhet të ketë të paktën 8 karaktere';

  @override
  String get authValidationPasswordNeedNumber =>
      'Fjalëkalimi duhet të përmbajë të paktën një numër';

  @override
  String get authValidationPasswordNeedLetter =>
      'Fjalëkalimi duhet të përmbajë të paktën një shkronjë';

  @override
  String get authValidationConfirmPasswordRequired => 'Konfirmo fjalëkalimin';

  @override
  String get authValidationConfirmPasswordMismatch =>
      'Fjalëkalimet nuk përputhen';

  @override
  String get authErrorInvalidCredentials =>
      'Numër telefoni ose fjalëkalim i gabuar.';

  @override
  String get authErrorAccountSuspended => 'Kjo llogari nuk është aktive.';

  @override
  String get authErrorPhoneNotRegistered =>
      'Nuk u gjet llogari për këtë numër.';

  @override
  String get authErrorEmailRegistered => 'Ky email është tashmë i regjistruar.';

  @override
  String get authErrorPhoneRegistered =>
      'Ky numër telefoni është tashmë i regjistruar.';

  @override
  String get authErrorOtpNotFound => 'Nuk u dërgua kod. Kërko një të ri.';

  @override
  String get authErrorOtpExpired => 'Ky kod ka skaduar. Kërko një të ri.';

  @override
  String get authErrorOtpInvalid => 'Kod i pavlefshëm. Provo përsëri.';

  @override
  String get authErrorOtpMaxAttempts =>
      'Shumë kode të gabuara. Kërko një kod të ri.';

  @override
  String get authErrorCurrentPasswordInvalid =>
      'Fjalëkalimi aktual është i pasaktë.';

  @override
  String get authErrorTooManyAttempts =>
      'Shumë përpjekje të dështuara. Provo më vonë.';

  @override
  String get authErrorRateLimited =>
      'Shumë kërkesa. Prit pak dhe provo përsëri.';

  @override
  String get authErrorUserNotFound =>
      'Nuk gjetëm llogari për këtë numër. Kontrollo dhe provo përsëri.';

  @override
  String get authOtpTitle => 'Shkruaj kodin';

  @override
  String authOtpSubtitle(String phone) {
    return 'Dërguam një kod me 4 shifra te $phone';
  }

  @override
  String get authOtpContinue => 'Vazhdo';

  @override
  String get authOtpResendPrefix => 'Nuk e morët kodin? ';

  @override
  String get authOtpResendAction => 'Dërgo përsëri';

  @override
  String authOtpResendCountdown(int seconds) {
    return 'Ridërgo pas $seconds s';
  }

  @override
  String authOtpResentMessage(String phone) {
    return 'Dërguam një kod të ri te $phone.';
  }

  @override
  String get authForgotPasswordTitle => 'Rivendos fjalëkalimin';

  @override
  String get authForgotPasswordSubtitle =>
      'Shkruaj numrin e telefonit dhe do të të dërgojmë një kod';

  @override
  String get authForgotPasswordSendCode => 'Dërgo kodin';

  @override
  String get authForgotPasswordRequestSemantic => 'Dërgo kod për rivendosje';

  @override
  String get authForgotPasswordOtpTitle => 'Shkruaj kodin';

  @override
  String authForgotPasswordOtpSubtitle(String phone) {
    return 'Dërguam një kod me 4 shifra te $phone';
  }

  @override
  String get authNewPasswordTitle => 'Fjalëkalim i ri';

  @override
  String get authNewPasswordSubtitle =>
      'Shkruaj një fjalëkalim të ri për llogarinë';

  @override
  String get authFieldNewPassword => 'Fjalëkalim i ri';

  @override
  String get authFieldNewPasswordHint => 'Të paktën 8 karaktere';

  @override
  String get authFieldConfirmPassword => 'Konfirmo fjalëkalimin';

  @override
  String get authFieldConfirmPasswordHint => 'Rishkruaj fjalëkalimin';

  @override
  String get authResetPasswordCta => 'Rivendos fjalëkalimin';

  @override
  String get authPasswordResetSuccessTitle => 'Fjalëkalimi u rivendos';

  @override
  String get authPasswordResetSuccessBody =>
      'Fjalëkalimi u ndryshua me sukses. Tani mund të hysh me fjalëkalimin e ri.';

  @override
  String get authBackToSignIn => 'Kthehu te hyrja';

  @override
  String get authOnboardingWelcomeTo => 'Mirë se vini në';

  @override
  String get authOnboardingBrandName => 'Chisto.mk';

  @override
  String get authOnboardingWelcomeDescription => 'Shih. Raporto. Pastro.';

  @override
  String get authOnboardingWelcomeSupporting =>
      'Një qytet më i pastër fillon me një prekje.';

  @override
  String get authOnboardingSlide2Title => 'Raporto në sekonda';

  @override
  String get authOnboardingSlide2Description =>
      'Ndaj një raport me vendndodhje me pak prekje.';

  @override
  String get authOnboardingSlide2Supporting =>
      'Rrjedhë e shpejtë, përditësime të qarta.';

  @override
  String get authOnboardingSlide3Title => 'Bashkohu në pastrime';

  @override
  String get authOnboardingSlide3Description =>
      'Ndiq progresin dhe ndikimin në komunitet.';

  @override
  String get authOnboardingSlide3Supporting =>
      'Së bashku i mbajmë lagjet të gjelbra.';

  @override
  String get authOnboardingContinue => 'Vazhdo';

  @override
  String get authOnboardingGetStarted => 'Fillo';

  @override
  String get authLocationTitle => 'Zgjidh vendndodhjen';

  @override
  String get authLocationSubtitle =>
      'E përdorim për të treguar pastrime dhe raporte afër teje.';

  @override
  String get authLocationMapPlaceholder =>
      'Përdor vendndodhjen aktuale për të përditësuar zonën';

  @override
  String get authLocationDetecting => 'Po zgjidhhet vendndodhja…';

  @override
  String get authLocationContinue => 'Vazhdo';

  @override
  String get authLocationUseCurrent => 'Përdor vendndodhjen aktuale';

  @override
  String get authLocationUseDifferent => 'Përdor vendndodhje tjetër';

  @override
  String get authLocationPrivacyNote =>
      'Vendndodhjen e përdorim vetëm për përmbajtje afër. Nuk të ndjekim në sfond.';

  @override
  String get authLocationServicesDisabled =>
      'Shërbimet e vendndodhjes janë të fikura. Aktivizoji te Cilësimet.';

  @override
  String get authLocationPermissionDenied =>
      'Leja për vendndodhje u refuzua. Mund ta aktivizosh te Cilësimet.';

  @override
  String get authLocationPermissionForever =>
      'Leja është refuzuar përgjithmonë. Po hapen Cilësimet…';

  @override
  String get authLocationMacedoniaOnly =>
      'Momentalisht mbështetemi vetëm për vendndodhje në Maqedoni.';

  @override
  String get authLocationResolveFailed =>
      'Nuk mund të përcaktohej vendndodhja. Provo përsëri.';

  @override
  String get authOtpCodeSemantic => 'Kod verifikimi';

  @override
  String authOtpDigitSemantic(int index, int total) {
    return 'Shifra $index nga $total';
  }
}
