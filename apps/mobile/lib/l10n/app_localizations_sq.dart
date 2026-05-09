// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Albanian (`sq`).
class AppLocalizationsSq extends AppLocalizations {
  AppLocalizationsSq([String locale = 'sq']) : super(locale);

  @override
  String get reportFlowHelpHint =>
      'Prekni butonin e informacionit për këshilla për këtë hap.';

  @override
  String reportFlowStepProgressStep(int current) {
    return 'Hapi $current nga 3';
  }

  @override
  String get reportFlowStepProgressReady => 'Gati për dërgim';

  @override
  String get reportFlowStepStatusComplete => 'E plotë';

  @override
  String get reportFlowStepStatusInProgress => 'Në progres';

  @override
  String get reportFlowStepChipPhotos => 'Foto';

  @override
  String get reportFlowStepChipCategory => 'Kategoria';

  @override
  String get reportFlowStepChipLocation => 'Vendi';

  @override
  String get reportHelpContextTitle => 'Konteksti';

  @override
  String get reportStageEvidenceEyebrow => 'Raporto vend të ndotur';

  @override
  String get reportStageEvidenceTitle => 'Provat';

  @override
  String get reportStageEvidenceSubtitle => 'Foto dhe kornizë';

  @override
  String get reportStageEvidenceShortLabel => 'Provat';

  @override
  String get reportStageEvidencePrimaryAction => 'Vazhdo';

  @override
  String get reportStageEvidencePrimaryRequirement => 'Foto';

  @override
  String get reportStageEvidenceSecondaryRequirement => 'Deri në 5';

  @override
  String get reportStageEvidenceInfoTitle => 'Provat';

  @override
  String get reportHelpEvidenceS0Title => 'Çfarë të fotografosh';

  @override
  String get reportHelpEvidenceS0Body =>
      'Shto deri në pesë foto që e tregojnë qartë zonën e ndotur. Fillo me një kornizë të gjerë për kontekst, pastaj më afër: grumbuj plehrash, tuba, njolla, inerte, çdo gjë që tregon problemin.';

  @override
  String get reportHelpEvidenceS1Title => 'Pse ndihmon';

  @override
  String get reportHelpEvidenceS1Body =>
      'Moderatorët mbështeten në imazhet për të konfirmuar raportin dhe për të përparësuar vazhdimin. Dritë e diellit, dorë e qëndrueshme dhe pamje e plotë e vendit e bëjnë verifikimin më të lehtë.';

  @override
  String get reportStageDetailsEyebrow => 'Përshkruaje problemin';

  @override
  String get reportStageDetailsTitle => 'Detajet';

  @override
  String get reportStageDetailsSubtitle => 'Kategori, titull dhe kontekst';

  @override
  String get reportStageDetailsShortLabel => 'Detajet';

  @override
  String get reportStageDetailsPrimaryAction => 'Vazhdo';

  @override
  String get reportStageDetailsPrimaryRequirement => 'Kategori dhe titull';

  @override
  String get reportStageDetailsSecondaryRequirement => 'Detaje opsionale';

  @override
  String get reportStageDetailsInfoTitle => 'Detajet';

  @override
  String get reportHelpDetailsS0Title => 'Çfarë të plotësosh';

  @override
  String get reportHelpDetailsS0Body =>
      'Zgjidh kategorinë që përputhet më së miri me atë që ke parë. Shkruaj një titull të shkurtër që kuptohet menjëherë, si titull lajmi, jo ese.\n\nNëse nuk je i sigurt, shto rëndësinë; në përshkrim vendos çdo gjë që ndihmon në terren: akses, kohë, erë, ngjyra e ujit, pika referimi. Për pastrimin plotëso vetëm nëse ke ide përafërsisht sa është madhësia.';

  @override
  String get reportHelpDetailsS1Title => 'Fusha opsionale';

  @override
  String get reportHelpDetailsS1Body =>
      'Asgjë këtu nuk bllokon dërgimin përveç kategorisë dhe titullit. Detajet ekstra janë për nuancë; përdoji kur vërtet ndihmojnë.';

  @override
  String get reportStageLocationEyebrow => 'Konfirmo vendndodhjen';

  @override
  String get reportStageLocationTitle => 'Vendndodhja';

  @override
  String get reportStageLocationSubtitle => 'Kunji në hartë';

  @override
  String get reportStageLocationShortLabel => 'Vendndodhja';

  @override
  String get reportStageLocationPrimaryAction => 'Vazhdo';

  @override
  String get reportStageLocationPrimaryRequirement => 'Kunji';

  @override
  String get reportStageLocationSecondaryRequirement => 'Brenda Maqedonisë';

  @override
  String get reportStageLocationInfoTitle => 'Vendndodhja';

  @override
  String get reportHelpLocationS0Title => 'Si ta vendosësh kunjin';

  @override
  String get reportHelpLocationS0Body =>
      'Tërhiq hartën te vendi ku është ndotja, jo te qyteti më i afërt përveç nëse raporton një zonë të tërë. Zmadho derisa kunji të bjerë në vendin e vërtetë.';

  @override
  String get reportHelpLocationS1Title => 'Zona e mbulimit';

  @override
  String get reportHelpLocationS1Body =>
      'Kunji duhet të jetë brenda Maqedonisë që raporti të orientohet dhe verifikohet saktë. Nëse nuk je i sigurt, vendose sa më saktë që të mundet.';

  @override
  String get reportHelpLocationS2Title => 'Pse ka rëndësi';

  @override
  String get reportHelpLocationS2Body =>
      'Koordinatat lidhin fotot dhe përshkrimin me një vend real për ekipet në terren dhe moderatorët.';

  @override
  String get reportStageReviewEyebrow => 'Rishikim final';

  @override
  String get reportStageReviewTitle => 'Rishikim';

  @override
  String get reportStageReviewSubtitle => 'Para dërgimit';

  @override
  String get reportStageReviewShortLabel => 'Rishikim';

  @override
  String get reportStageReviewPrimaryAction => 'Dërgo';

  @override
  String get reportStageReviewPrimaryRequirement => 'Gati';

  @override
  String get reportStageReviewInfoTitle => 'Rishikim';

  @override
  String get reportHelpReviewS0Title => 'Kontrollo çdo pjesë';

  @override
  String get reportHelpReviewS0Body =>
      'Prek një rresht për të kthyer pas dhe përpunuar. Kur fotot, detajet dhe vendndodhja përputhen me atë që ke parë, je gati.';

  @override
  String get reportHelpReviewS1Title => 'Çfarë vjen më pas';

  @override
  String get reportHelpReviewS1Body =>
      'Raporti shqyrtohet para se të bëhet publik. Te Raportet e mia ndjek statusin; përditësimet shfaqen ndërsa vendi kalon nëpër moderim.';

  @override
  String get newReportTitle => 'Raport i ri';

  @override
  String get reportReviewBannerCreditsTitle => 'Kredite';

  @override
  String get reportReviewBannerAfterSubmitTitle => 'Pas dërgimit';

  @override
  String get reportReviewAfterSubmitReady =>
      'Moderim para publikimit. Status te Raportet e mia.';

  @override
  String get reportReviewAfterSubmitIncomplete => 'Përfundo hapat më sipër.';

  @override
  String get reportSubmitSentPending => 'Dërguar';

  @override
  String get semanticsClose => 'Mbyll';

  @override
  String get homeShellNavHome => 'Kreu';

  @override
  String get homeShellNavReports => 'Raportet';

  @override
  String get homeShellNavMap => 'Harta';

  @override
  String get homeShellNavEvents => 'Ngjarjet';

  @override
  String semanticsReportPhotoNumber(int number) {
    return 'Foto e raportit $number';
  }

  @override
  String semanticsAboutStep(String title) {
    return 'Rreth $title';
  }

  @override
  String semanticsNextStep(String label) {
    return 'Tjetra: $label';
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
      'Drafti juaj është ruajtur, mund të provoni përsëri kur të jeni gati.';

  @override
  String get reportSubmittedTitle => 'Raporti u dërgua';

  @override
  String reportSubmittedSavedAs(String number) {
    return 'U ruajt si raport $number';
  }

  @override
  String reportSubmittedBodyWithAddress(String category, String address) {
    return '$category pranë $address është në radhë për shqyrtim.';
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
  String get reportSubmittedPointsPending =>
      'Pikët kreditohen pasi moderatorët ta miratojnë raportin.';

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
      'Zmadhoj me dy gishta, zhvendos për pozicion';

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

  @override
  String get profileWeeklyRankingsTitle => 'Renditja javore';

  @override
  String get profileWeeklyRankingsSubtitle =>
      'Raporte, veprime ekologjike e më shumë, këtë javë.';

  @override
  String get profileWeeklyRankingsTopSupporters => 'Më të aktivët këtë javë';

  @override
  String get profileWeeklyRankingsEmptyTitle => 'Ende pa renditje';

  @override
  String get profileWeeklyRankingsEmptySubtitle =>
      'Fitoni pikë këtë javë nga çdo aktivitet që jep pikë për t’u shfaqur këtu.';

  @override
  String get profileWeeklyRankingsRetry => 'Provo përsëri';

  @override
  String profileWeeklyRankingsYouRank(int rank) {
    return 'Këtë javë jeni nr. $rank';
  }

  @override
  String profileWeeklyRankingsPtsThisWeek(int points) {
    return '$points pikë këtë javë';
  }

  @override
  String get profileWeeklyRankingsYouBadge => 'Ju';

  @override
  String get profileWeeklyRankingsScrollToYouHint =>
      'Shkrollo te pozita juaj në listë';

  @override
  String get profileWeeklyRankingsLoadingSemantic =>
      'Po ngarkohet renditja javore';

  @override
  String profileWeeklyRankingsRowSemantic(int rank, String name, int points) {
    return 'Renditja $rank, $name, $points pikë';
  }

  @override
  String profileLevelLine(int level) {
    return 'Niveli $level';
  }

  @override
  String get profileTierLegend => 'Legjenda e Chisto';

  @override
  String profilePtsToNextLevel(int points) {
    return 'Edhe $points pikë deri në nivelin tjetër';
  }

  @override
  String profileLevelXpSegment(int current, int total) {
    return '$current / $total XP';
  }

  @override
  String profileLifetimeXpOnBar(int xp) {
    return '$xp XP gjithë jetës';
  }

  @override
  String profilePointsBalanceShort(int balance) {
    return 'Bilanci $balance';
  }

  @override
  String get profileMyWeeklyRankTitle => 'Renditja ime javore';

  @override
  String profileMyWeeklyRankDetailRanked(int rank, int points) {
    return 'Nr.$rank, $points pikë';
  }

  @override
  String profileMyWeeklyRankDetailPointsOnly(int points) {
    return '$points pikë';
  }

  @override
  String get profileMyWeeklyRankNoPoints => 'Ende pa pikë këtë javë';

  @override
  String get profileViewRankings => 'Shiko renditjen';

  @override
  String get profilePointsHistoryTitle => 'Pikë dhe nivele';

  @override
  String get profilePointsHistorySubtitle =>
      'XP që fitove dhe çdo nivel që zhbllokove.';

  @override
  String get profilePointsHistoryOpenSemantic =>
      'Hap historikun e pikëve dhe niveleve';

  @override
  String get profilePointsHistoryLoadingSemantic =>
      'Po ngarkohen pikët dhe nivelet';

  @override
  String get profileLoadingSemantic => 'Po ngarkohet profili';

  @override
  String get profileErrorSemantic => 'Profili nuk u ngarkua';

  @override
  String get profileLevelCardSemantic =>
      'Niveli dhe pikët. Hap historinë e pikëve';

  @override
  String get profileWeeklyRankCardSemantic => 'Renditja javore. Hap renditjet';

  @override
  String get profilePointsHistoryMilestonesSection => 'Nivel i ri';

  @override
  String get profilePointsHistoryActivitySection => 'Aktivitet';

  @override
  String get profilePointsHistoryDayToday => 'Sot';

  @override
  String get profilePointsHistoryDayYesterday => 'Dje';

  @override
  String get profilePointsHistoryEmpty =>
      'Ende pa pikë. Kur një raport që dërgohet miratohet si i pari në një vend, fiton XP këtu.';

  @override
  String get profilePointsHistoryLevelUpBadge => 'NIVEL I RI';

  @override
  String get profilePointsHistoryLoadMore => 'Duke u ngarkuar…';

  @override
  String get profilePointsHistoryLoadMoreErrorTitle =>
      'Nuk u ngarkuan më shumë aktivitete';

  @override
  String get profilePointsHistoryLoadMoreRetry => 'Provo përsëri';

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
      'Raporti i parë i miratuar në një vend';

  @override
  String get profilePointsReasonEcoApproved => 'Veprim ekologjik i miratuar';

  @override
  String get profilePointsReasonEcoRealized => 'Veprim ekologjik i përfunduar';

  @override
  String get profilePointsReasonOther => 'Përditësim pikësh';

  @override
  String get profilePointsReasonEventOrganizerApproved =>
      'Ngjarja juaj e pastrimit u miratua';

  @override
  String get profilePointsReasonEventJoined =>
      'U bashkove me një ngjarje pastrimi';

  @override
  String get profilePointsReasonEventJoinNoShow =>
      'Bonusi i bashkimit u rregullua — pa regjistrim';

  @override
  String get profilePointsReasonEventCheckIn => 'Regjistrim në ngjarje';

  @override
  String get profilePointsReasonEventCompleted =>
      'Ngjarja e pastrimit u përfundua';

  @override
  String get profilePointsReasonReportApproved => 'Raporti u miratua';

  @override
  String get profilePointsReasonReportApprovalRevoked =>
      'Miratimi i raportit u anulua';

  @override
  String get profilePointsReasonReportSubmitted =>
      'Raporti u dërgua (i vjetër)';

  @override
  String get profileReportCreditsTitle => 'Kreditë e raportimit';

  @override
  String get profileAccountDetailsSection => 'Detajet e llogarisë';

  @override
  String get profileGeneralInfoTile => 'Informacione të përgjithshme';

  @override
  String get profileLanguageTile => 'Gjuha';

  @override
  String get profileLanguageScreenTitle => 'Gjuha e aplikacionit';

  @override
  String get profileLanguageScreenSubtitle =>
      'Zgjidhni një gjuhë ose përdorni atë të pajisjes.';

  @override
  String get profileLanguageChangeFailed =>
      'Nuk mund të përditësohej gjuha. Provo përsëri.';

  @override
  String get profileLanguageSubtitleDevice => 'Sipas pajisjes';

  @override
  String get profileLanguageOptionSystem => 'Përdor gjuhën e pajisjes';

  @override
  String get profileLanguageNameEn => 'English';

  @override
  String get profileLanguageNameMk => 'Македонски';

  @override
  String get profileLanguageNameSq => 'Shqip';

  @override
  String get profilePasswordTile => 'Fjalëkalimi';

  @override
  String get profileSupportSection => 'Mbështetje';

  @override
  String get profileHelpCenterTile => 'Qendra e ndihmës';

  @override
  String get profileAccountSection => 'Llogaria';

  @override
  String get profileSignOutTile => 'Dil';

  @override
  String get profileDeleteAccountTile => 'Fshi llogarinë';

  @override
  String get profileEmailLabel => 'Email';

  @override
  String get profileEmailReadOnlyHint =>
      'Vetëm për lexim. Për ndryshim kontaktoni mbështetjen.';

  @override
  String get profileNoConnectionSnack => 'Nuk ka lidhje';

  @override
  String get profileRefreshFailedSnack =>
      'Nuk e rifreskua profili. Provo përsëri pas pak.';

  @override
  String get profilePasswordScreenTitle => 'Ndrysho fjalëkalimin';

  @override
  String get profilePasswordScreenSubtitle =>
      'Zgjidh një fjalëkalim të fortë dhe unik.';

  @override
  String get profilePasswordCurrentLabel => 'Fjalëkalimi aktual';

  @override
  String get profilePasswordNewLabel => 'Fjalëkalim i ri';

  @override
  String get profilePasswordConfirmLabel => 'Konfirmo fjalëkalimin e ri';

  @override
  String get profilePasswordNewHelper => 'Të paktën 8 karaktere, me një numër.';

  @override
  String get profilePasswordConfirmMismatchHelper =>
      'Duhet të përputhet me fjalëkalimin e ri më sipër.';

  @override
  String get profilePasswordSecurityHint =>
      'Për siguri, mos ripërdor fjalëkalime nga aplikacione të tjera.';

  @override
  String get profilePasswordSubmit => 'Përditëso fjalëkalimin';

  @override
  String get profilePasswordSubmitting => 'Po përditësohet…';

  @override
  String get profilePasswordSuccess => 'Fjalëkalimi u përditësua';

  @override
  String get profilePasswordEnterCurrentWarning =>
      'Shkruaj fjalëkalimin aktual.';

  @override
  String get profilePasswordMismatchError => 'Fjalëkalimet nuk përputhen.';

  @override
  String get profilePasswordSessionExpired => 'Sesioni skadoi. Hyni përsëri.';

  @override
  String get profilePasswordGenericError =>
      'Diçka shkoi keq. Kontrollo lidhjen dhe provo përsëri.';

  @override
  String get profilePasswordCurrentSemantic => 'Fjalëkalimi aktual';

  @override
  String get profilePasswordNewSemantic => 'Fjalëkalim i ri';

  @override
  String get profilePasswordConfirmSemantic => 'Konfirmo fjalëkalimin e ri';

  @override
  String get profilePasswordToggleVisibility => 'Shfaq ose fsheh fjalëkalimin';

  @override
  String get commonCancel => 'Anulo';

  @override
  String get commonContinue => 'Vazhdo';

  @override
  String get commonRetry => 'Provo përsëri';

  @override
  String get commonTryAgain => 'Provo përsëri';

  @override
  String get commonDelete => 'Fshi';

  @override
  String get commonSave => 'Ruaj';

  @override
  String get commonSkip => 'Anashkalo';

  @override
  String get commonBack => 'Kthehu';

  @override
  String get commonClose => 'Mbyll';

  @override
  String get commonGotIt => 'E kuptova';

  @override
  String get commonKeepEditing => 'Vazhdo përpunimin';

  @override
  String get commonDiscard => 'Hedh poshtë';

  @override
  String get profileSignOutDialogTitle => 'Të dalësh?';

  @override
  String get profileSignOutDialogBody =>
      'Mund të hysh përsëri me llogarinë tënde.';

  @override
  String get profileSignOutFailedSnack => 'Nuk mund të dilnim. Provo përsëri.';

  @override
  String get profileDeleteAccountDialogTitle => 'Të fshihet llogaria?';

  @override
  String get profileDeleteAccountDialogBody =>
      'Të gjitha të dhënat do të hiqen përgjithmonë. Ky veprim nuk kthehet mbrapsht.';

  @override
  String get profileDeleteAccountFailedSnack =>
      'Nuk mund të fshihej llogaria. Provo përsëri.';

  @override
  String get profileDeleteAccountTypeConfirmTitle => 'Konfirmo me shkrim';

  @override
  String get profileDeleteAccountTypeConfirmBody =>
      'Shkruaj fjalën më poshtë saktësisht siç shfaqet. Kjo parandalon fshirjet aksidentale.';

  @override
  String get profileDeleteAccountConfirmPhrase => 'FSHI';

  @override
  String get profileDeleteAccountTypeFieldPlaceholder => 'Shkruaj këtu';

  @override
  String get profileDeleteAccountTypeMismatchSnack =>
      'Shkruaj fjalën e konfirmimit saktësisht siç shfaqet.';

  @override
  String get profileHelpCenterOpenFailedSnack => 'Nuk u hap qendra e ndihmës';

  @override
  String get profileGeneralLoadFailedSnack => 'Nuk u ngarkua profili';

  @override
  String get profileGeneralNameRequiredSnack => 'Emri është i detyrueshëm';

  @override
  String get profileGeneralNameTooLongSnack => 'Emri është shumë i gjatë';

  @override
  String get profileGeneralUpdatedSnack => 'Profili u përditësua';

  @override
  String get profileGeneralPictureUpdatedSnack =>
      'Fotoja e profilit u përditësua';

  @override
  String get profileGeneralInfoSubtitle => 'Ndrysho detajet e profilit';

  @override
  String get profileGeneralNameLabel => 'Emri';

  @override
  String get profileGeneralNameHint => 'Emri yt';

  @override
  String get profileGeneralMobileLabel => 'Telefoni celular';

  @override
  String get profileGeneralPhonePlaceholder => '70 123 456';

  @override
  String get profileGeneralLimitsNotice =>
      'Ndryshimet e emrit janë të kufizuara. Ndryshimi i numrit të telefonit kërkon verifikim.';

  @override
  String get profileGeneralUpdateButton => 'Përditëso të dhënat';

  @override
  String get profileGeneralSaving => 'Duke ruajtur…';

  @override
  String get profileGeneralAvatarSemanticUpdating =>
      'Po përditësohet fotoja e profilit';

  @override
  String get profileGeneralAvatarSemanticChange =>
      'Foto profili. Prek dy herë për ta ndryshuar';

  @override
  String get profileGeneralEmptyValue => '—';

  @override
  String get profileGeneralDefaultDisplayName => 'Përdorues';

  @override
  String get reportListFabLabel => 'Raporto ndotje';

  @override
  String get reportListAppBarStartNewReportLabel => 'Raport i ri';

  @override
  String reportListDraftChipLabel(int photoCount, String savedAgo) {
    String _temp0 = intl.Intl.pluralLogic(
      photoCount,
      locale: localeName,
      other: '$photoCount foto',
      one: '1 foto',
      zero: 'pa foto',
    );
    return 'Draft · $_temp0 · $savedAgo';
  }

  @override
  String reportListDraftChipSemantic(int photoCount) {
    String _temp0 = intl.Intl.pluralLogic(
      photoCount,
      locale: localeName,
      other: '$photoCount foto',
      one: '1 foto',
    );
    return 'Draft i ruajtur me $_temp0. Prek dy herë për ta hapur.';
  }

  @override
  String get reportListSearchSemantic => 'Kërko raporte';

  @override
  String get reportAvailabilityCheckFailedSnack =>
      'Nuk mund të kontrollohet disponueshmëria e raportimit tani.';

  @override
  String get reportFinishStepsSnack =>
      'Përfundo hapat që mungojnë para dërgimit.';

  @override
  String get reportSubmittedPartialUploadSnack =>
      'Raporti u dërgua. Fotot nuk u ngarkuan.';

  @override
  String get reportPhotoUploadFailedTitle => 'Ngarkimi i fotove dështoi';

  @override
  String get reportPhotoUploadFailedBody =>
      'Fotot nuk u ngarkuan. Prek Provo përsëri ose Anashkalo për të dërguar pa foto.';

  @override
  String get reportReviewEvidenceTitle => 'Provat';

  @override
  String reportReviewPhotoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count foto',
      one: '$count foto',
    );
    return '$_temp0';
  }

  @override
  String get reportReviewAddPhoto => 'Shto një foto';

  @override
  String get reportReviewCategoryTitle => 'Kategoria';

  @override
  String get reportReviewChooseCategory => 'Zgjidh kategorinë';

  @override
  String get reportReviewTitleLabel => 'Titulli';

  @override
  String get reportReviewAddTitle => 'Shto titull';

  @override
  String get reportReviewSeverityTitle => 'Rëndësia';

  @override
  String get reportReviewLocationTitle => 'Vendndodhja';

  @override
  String get reportReviewPinnedShort => 'Fiksuar';

  @override
  String get reportReviewPinMacedonia => 'Vendose kunjin në Maqedoni';

  @override
  String get reportReviewExtraContextTitle => 'Kontekst shtesë';

  @override
  String get reportReviewCleanupEffortTitle => 'Përpjekja për pastrim';

  @override
  String get reportSelectCategorySemantic => 'Zgjidh kategorinë e raportit';

  @override
  String get reportBackSemantic => 'Kthehu';

  @override
  String get reportPreviousStepSemantic => 'Hapi i mëparshëm';

  @override
  String get reportCleanupEffortChipHint =>
      'Prek dy herë për të vendosur përpjekjen e vlerësuar të pastrimit.';

  @override
  String get reportCleanupEffortOneToTwo => '1–2 persona';

  @override
  String get reportCleanupEffortThreeToFive => '3–5 persona';

  @override
  String get reportCleanupEffortSixToTen => '6–10 persona';

  @override
  String get reportCleanupEffortTenPlus => '10+ persona';

  @override
  String get reportCleanupEffortNotSure => 'Nuk jam i sigurt';

  @override
  String get reportCooldownTitle => 'Pauzë raportimi';

  @override
  String reportCooldownBody(String retry, String hint) {
    return 'Ke përdorur të 10 kreditet e raportit dhe lejen e jashtëzakonshme.\n\nHapja e jashtëzakonshme përsëri pas $retry.\n\n$hint';
  }

  @override
  String get reportCooldownModalIntro =>
      'Ke përdorur të 10 kreditet e raportit dhe lejen e jashtëzakonshme.';

  @override
  String get reportCooldownModalRetryLead =>
      'Hapja e jashtëzakonshme përsëri pas';

  @override
  String get reportCooldownDurationListSeparator => ', ';

  @override
  String reportCooldownDurationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ditë',
      one: '$count ditë',
    );
    return '$_temp0';
  }

  @override
  String reportCooldownDurationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count orë',
      one: '$count orë',
    );
    return '$_temp0';
  }

  @override
  String reportCooldownDurationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minuta',
      one: '$count minutë',
    );
    return '$_temp0';
  }

  @override
  String reportCooldownDurationSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sekonda',
      one: '$count sekondë',
    );
    return '$_temp0';
  }

  @override
  String get reportCooldownRetrySoon => 'së shpejti';

  @override
  String reportCooldownRetrySeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String reportCooldownRetryMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String reportCooldownRetryHoursMinutes(int hours, int minutes) {
    return '$hours orë $minutes min';
  }

  @override
  String get reportCapacityUnlockHint =>
      'Merr më shumë në evente ose veprime ekologjike (deri në 10 raporte).';

  @override
  String reportCapacityPillHealthy(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kredite',
      one: '$count kredit',
    );
    return '$_temp0';
  }

  @override
  String get reportCapacityBannerHealthyTitle => 'Gati';

  @override
  String reportCapacityBannerHealthyBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kredite të disponueshme',
      one: '$count kredit i disponueshëm',
    );
    return '$_temp0';
  }

  @override
  String get reportCapacityReviewHealthy => 'Përdor 1 kredit.';

  @override
  String reportCapacityPillLow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Edhe $count raporte',
      one: 'Edhe $count raport',
    );
    return '$_temp0';
  }

  @override
  String get reportCapacityBannerLowTitle => 'Pak kredite';

  @override
  String reportCapacityBannerLowBody(String hint) {
    return 'Gati mbaruan. $hint';
  }

  @override
  String reportCapacityReviewLow(String hint) {
    return 'Përdor 1 kredit. $hint';
  }

  @override
  String get reportCapacityPillEmergency => 'Raport emergjence';

  @override
  String get reportCapacityBannerEmergencyTitle => 'Raport emergjence';

  @override
  String reportCapacityBannerEmergencyBody(String hint) {
    return 'Ke edhe një. $hint';
  }

  @override
  String reportCapacityReviewEmergency(String hint) {
    return 'Përdor raportin emergjence. $hint';
  }

  @override
  String get reportCapacityPillCooldown => 'Pauzë';

  @override
  String get reportCapacityBannerCooldownTitle => 'Pauzë';

  @override
  String reportCapacityCooldownRetryOnDate(String date) {
    return 'Emergjenca tjetër: $date.';
  }

  @override
  String reportCapacityCooldownTryAgainInAbout(String duration) {
    return 'Provo përsëri pas ~$duration.';
  }

  @override
  String get reportCapacityCooldownStillWaiting =>
      'Raporti emergjence po freskohet.';

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
    return '(edhe $seconds s)';
  }

  @override
  String get feedRetryLoadingMore => 'Provo përsëri të ngarkosh më shumë';

  @override
  String get feedLoadingMoreSemantic =>
      'Po ngarkohen më shumë postime në rrjedhë';

  @override
  String get feedShowAllSites => 'Shfaq të gjitha vendet';

  @override
  String get feedPullToRefreshSemantic => 'Tërhiq për rifreskim';

  @override
  String get feedRefreshingSemantic => 'Po rifreskohet rrjedha';

  @override
  String get feedLoadMoreFailedSnack =>
      'Nuk u ngarkuan më shumë postime. Prek për të provuar përsëri.';

  @override
  String get feedRefreshStaleSnack =>
      'Rifreskimi dështoi. Po shfaqet lista e fundit e ngarkuar.';

  @override
  String get feedScrollToTopSemantic => 'Shkrollo në krye të rrjedhës';

  @override
  String get feedPollutionFeedTitle => 'Rrjedha e ndotjes';

  @override
  String get feedOfflineBanner =>
      'Jeni jashtë linje. Po shfaqet rrjedha e fundit e ngarkuar.';

  @override
  String get feedCaughtUpTitle => 'I keni parë të gjitha';

  @override
  String get feedCaughtUpSubtitle =>
      'Tërhiqni për rifreskim për raporte të reja';

  @override
  String get feedMoreFiltersTooltip => 'Më shumë filtra';

  @override
  String feedFilterSemantic(String name) {
    return 'Filtri $name';
  }

  @override
  String get feedEmptyAllTitle => 'Ende nuk ka vende ndotjeje';

  @override
  String get feedEmptyAllHint =>
      'Tërhiqni për rifreskim ose kontrolloni më vonë';

  @override
  String get feedEmptyUrgentTitle => 'Tani nuk ka vende urgjente';

  @override
  String get feedEmptyUrgentHint =>
      'Shfaq të gjitha ose provoni një filtër tjetër';

  @override
  String get feedEmptyNearbyTitleOnline => 'Nuk u gjetën vende afër';

  @override
  String get feedEmptyNearbyTitleOffline =>
      'Aktivizoni vendndodhjen për vende afër';

  @override
  String get feedEmptyNearbyHintOffline =>
      'Ndizni shërbimet e vendndodhjes dhe lejoni aksesin';

  @override
  String get feedEmptyNearbyHintOnline =>
      'Shfaq të gjitha ose provoni një filtër tjetër';

  @override
  String get feedEmptyMostVotedTitle => 'Ende nuk ka vota për vendet';

  @override
  String get feedEmptyMostVotedHint =>
      'Shfaq të gjitha ose provoni një filtër tjetër';

  @override
  String get feedEmptyRecentTitle => 'Nuk ka raporte të fundit';

  @override
  String get feedEmptyRecentHint =>
      'Shfaq të gjitha ose provoni një filtër tjetër';

  @override
  String get feedEmptySavedTitle => 'Ende nuk keni vende të ruajtura';

  @override
  String get feedEmptySavedHint => 'Ruaj vende nga menuja për t’i gjetur këtu';

  @override
  String get feedFilterAllName => 'Të gjitha';

  @override
  String get feedFilterAllDesc => 'Renditje e balancuar';

  @override
  String get feedFilterUrgentName => 'Urgjente';

  @override
  String get feedFilterUrgentDesc => 'Së pari incidentet me prioritet të lartë';

  @override
  String get feedFilterNearbyName => 'Afër';

  @override
  String get feedFilterNearbyDesc => 'Raportet më afër jush';

  @override
  String get feedFilterMostVotedName => 'Më e mbështetur';

  @override
  String get feedFilterMostVotedDesc => 'Më shumë mbështetje nga komuniteti';

  @override
  String get feedFilterRecentName => 'Të fundit';

  @override
  String get feedFilterRecentDesc => 'Së pari raportet më të reja';

  @override
  String get feedFilterSavedName => 'Të ruajtura';

  @override
  String get feedFilterSavedDesc => 'Vendet që keni ruajtur';

  @override
  String get feedFiltersSheetTitle => 'Filtra të rrjedhës';

  @override
  String get feedFiltersSheetSubtitle =>
      'Zgjidhni si dëshironi të shfletoni raportet';

  @override
  String get commentsFeedHeaderTitle => 'Komentet';

  @override
  String get commentsSortTop => 'Kryesorët';

  @override
  String get commentsSortNew => 'Të rinj';

  @override
  String get commentsEditingBanner => 'Duke përpunuar komentin';

  @override
  String get commentsBodyTooLong =>
      'Komenti është shumë i gjatë (maks. 2000 karaktere).';

  @override
  String get commentsReplyTargetFallback => 'komentin';

  @override
  String get reportIssueSheetTitle => 'Raporto problem';

  @override
  String get reportIssueSubmitting => 'Po dërgohet...';

  @override
  String get reportIssueSubmit => 'Dërgo raportin';

  @override
  String get reportIssueFailedSnack => 'Nuk u dërgua raporti. Provoni përsëri.';

  @override
  String get reportIssueSheetSubtitle =>
      'Na ndihmo të përmirsohemi. Pse po raporton këtë vend?';

  @override
  String get reportIssueDetailsLabel => 'Detaje shtesë (opsionale)';

  @override
  String get reportIssueDetailsHint => 'Përshkruaj problemin…';

  @override
  String get mapResetFiltersSemantic => 'Rivendos filtrat';

  @override
  String get mapOpenMapsFailed => 'Nuk u hap Hartat';

  @override
  String get mapSearchRecentsLabel => 'Të fundit';

  @override
  String get mapSearchClearRecentsButton => 'Pastro';

  @override
  String get mapSearchEmptyTitle => 'Kërko vende ndotjeje';

  @override
  String get mapSearchEmptySubtitle =>
      'Shkruaj titull, kategori ose përshkrim. Ose prek një kërkim të fundit.';

  @override
  String get mapSearchNoResultsTitle => 'Nuk u gjet asgjë';

  @override
  String get mapSearchNoResultsSubtitle =>
      'Provo fjalë të tjera ose pastro filtrat në hartë.';

  @override
  String mapSearchResultsBadge(int count) {
    return '$count rezultate';
  }

  @override
  String get mapSearchRemoteLoading => 'Duke kërkuar të gjitha vendet…';

  @override
  String get mapSearchRemoteError => 'Nuk u krye kërkimi në të gjitha vendet.';

  @override
  String get mapSearchRemoteRetry => 'Provo sërish';

  @override
  String get mapSearchSectionOnMap => 'Në këtë hartë';

  @override
  String get mapSearchSectionEverywhere => 'Më shumë rezultate';

  @override
  String get mapSearchSuggestionsLabel => 'Sugjerime';

  @override
  String get mapUpdatedToast => 'Harta u përditësua';

  @override
  String get mapErrorAutoRetryFootnote =>
      'Do të provojmë sërish për disa sekonda. Mund edhe të prek Try again.';

  @override
  String mapFilteredSitesAnnounce(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vende shfaqen në hartë',
      one: 'Një vend shfaqet në hartë',
    );
    return '$_temp0';
  }

  @override
  String mapClusterExpansionAnnounce(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vende u ndanë në hartë',
      one: 'Një vend u nda në hartë',
    );
    return '$_temp0';
  }

  @override
  String get mapScreenRouteSemantic =>
      'Harta e ndotjes. Prek fijet për detaje të vendit.';

  @override
  String get mapLoadingSemantic => 'Po ngarkohet harta';

  @override
  String get mapSiteNotOnMapSnack => 'Ky vend ende nuk është në hartë.';

  @override
  String get mapOpenLocationFailedSnack =>
      'Nuk mund të hapet kjo vendndodhje në hartë.';

  @override
  String get mapEmptyFiltersLiveRegion =>
      'Asnjë vend nuk përputhet me filtrat aktualë';

  @override
  String get mapEmptyFiltersTitle => 'Asnjë vend nuk përputhet me filtrat';

  @override
  String get mapEmptyFiltersSubtitle =>
      'Provo të ndryshosh filtrat ose të kërkosh.';

  @override
  String get mapDirectionsSheetOpenInMaps => 'Hape në Hartat';

  @override
  String get mapDirectionsSheetViewLocation => 'Shiko vendndodhjen';

  @override
  String get mapDirectionsSheetSubtitleDirections =>
      'Zgjidh aplikacionin për drejtime.';

  @override
  String get mapDirectionsSheetSubtitleViewLocation =>
      'Zgjidh aplikacionin për ta parë në hartë.';

  @override
  String get mapDirectionsAppleMapsTitle => 'Apple Maps';

  @override
  String get mapDirectionsAppleMapsSubtitle =>
      'Hartat e integruara në këtë pajisje.';

  @override
  String get mapDirectionsGoogleMapsTitle => 'Google Maps';

  @override
  String get mapDirectionsGoogleMapsSubtitle =>
      'Në web dhe në aplikacionin Google Maps.';

  @override
  String get mapSemanticCloseActionsMenu => 'Mbyll menunë e veprimeve';

  @override
  String get mapSemanticOpenActionsMenu => 'Hap menunë e veprimeve';

  @override
  String get mapSemanticHideHeatmap => 'Fshih hartën e nxehtësisë';

  @override
  String get mapSemanticShowHeatmap => 'Shfaq hartën e nxehtësisë';

  @override
  String get mapSemanticSwitchToLightMap => 'Kalo në hartë të çelët';

  @override
  String get mapSemanticSwitchToDarkMap => 'Kalo në hartë të errët';

  @override
  String get mapSemanticZoomWholeCountry => 'Zmadho për të parë gjithë vendin';

  @override
  String get mapSemanticUnlockRotation => 'Shkyç rrotullimin e hartës';

  @override
  String get mapSemanticLockRotation => 'Kyç rrotullimin e hartës';

  @override
  String get mapSemanticCenterOnMyLocation =>
      'Qendro hartën te vendndodhja ime';

  @override
  String get mapSemanticSearchSites => 'Kërko vende';

  @override
  String get mapSemanticResetRotationNorth =>
      'Rivendos rrotullimin drejt veriut';

  @override
  String get mapFilterButtonSemanticPrefix => 'Filtro vendet.';

  @override
  String get mapFilterButtonSemanticNoMatch =>
      'Asnjë vend nuk përputhet me filtrat në këtë zonë.';

  @override
  String get mapFilterButtonSemanticNoSites => 'Nuk ka vende në këtë zonë.';

  @override
  String mapFilterButtonSemanticSitesCount(int count) {
    return '$count vende në këtë zonë.';
  }

  @override
  String get mapFilterButtonSemanticSuffix => 'Prek për të hapur filtrat.';

  @override
  String get mapFilterCountNoMatch => 'Asnjë përputhje';

  @override
  String get mapFilterCountNoSites => 'Asnjë vend';

  @override
  String get mapFilterSheetTitle => 'Filtro vendet';

  @override
  String get mapFilterCloseTooltip => 'Mbyll filtrat';

  @override
  String get mapFilterSectionSiteStatus => 'Statusi i vendit';

  @override
  String get mapFilterSectionArea => 'Komunë / zona';

  @override
  String get mapFilterSectionPollutionType => 'Lloji i ndotjes';

  @override
  String get mapFilterSectionVisibility => 'Dukshmëria';

  @override
  String get mapFilterShowArchivedSites => 'Shfaq vendet e arkivuara';

  @override
  String mapFilterShowingLiveRegion(int visible, int total) {
    return '$visible nga $total vende ndotjeje të dukshme në këtë zonë';
  }

  @override
  String mapFilterShowingInline(int visible, int total) {
    return 'Po shfaqen $visible nga $total';
  }

  @override
  String mapFilterPollutionTypeSemantic(String type) {
    return 'Filtro vendet e llojit $type';
  }

  @override
  String get mapFilterPollutionTypeHintOff =>
      'Prek dy herë për të shfaqur këtë lloj';

  @override
  String get mapFilterPollutionTypeHintOn =>
      'Prek dy herë për ta fshehur këtë lloj';

  @override
  String get mapFilterPollutionTypeUnknown => 'Lloj i panjohur';

  @override
  String get mapFilterSiteStatusReported => 'E raportuar';

  @override
  String get mapFilterSiteStatusVerified => 'E verifikuar';

  @override
  String get mapFilterSiteStatusCleanupScheduled => 'Pastrimi i planifikuar';

  @override
  String get mapFilterSiteStatusInProgress => 'Në progres';

  @override
  String get mapFilterSiteStatusCleaned => 'E pastruar';

  @override
  String get mapFilterSiteStatusDisputed => 'E kontestuar';

  @override
  String get mapFilterSiteStatusArchived => 'E arkivuar';

  @override
  String get mapFilterSiteStatusUnknown => 'Status i panjohur';

  @override
  String mapFilterSiteStatusSemantic(String status) {
    return 'Filtro vendet me status $status';
  }

  @override
  String get mapFilterSiteStatusHintOff =>
      'Prek dy herë për ta shfaqur këtë status';

  @override
  String get mapFilterSiteStatusHintOn =>
      'Prek dy herë për ta fshehur këtë status';

  @override
  String get mapGeoWholeCountry => 'E gjithë vendi';

  @override
  String get mapGeoSkopjeWhole => 'Të gjitha komunat e Shkupit';

  @override
  String get mapGeoSkopje => 'Shkupi';

  @override
  String get mapGeoSkopjeCentar => 'Qendra';

  @override
  String get mapGeoSkopjeAerodrom => 'Aerodromi';

  @override
  String get mapGeoSkopjeKarposh => 'Karposhi';

  @override
  String get mapGeoSkopjeChair => 'Çairi';

  @override
  String get mapGeoSkopjeKiselaVoda => 'Kisela Vodë';

  @override
  String get mapGeoSkopjeGaziBaba => 'Gazi Babë';

  @override
  String get mapGeoSkopjeButel => 'Buteli';

  @override
  String get mapGeoSkopjeGjorcePetrov => 'Gjorçe Petrov';

  @override
  String get mapGeoSkopjeSaraj => 'Saraj';

  @override
  String get mapGeoBitola => 'Manastiri';

  @override
  String get mapGeoKumanovo => 'Kumanova';

  @override
  String get mapGeoPrilep => 'Prilepi';

  @override
  String get mapGeoTetovo => 'Tetova';

  @override
  String get mapGeoVeles => 'Velesi';

  @override
  String get mapGeoOhrid => 'Ohri';

  @override
  String get mapGeoStip => 'Shtipi';

  @override
  String get mapGeoGostivar => 'Gostivari';

  @override
  String get mapGeoStrumica => 'Strumica';

  @override
  String get mapGeoKavadarci => 'Kavadari';

  @override
  String get mapGeoKocani => 'Koçani';

  @override
  String get mapGeoStruga => 'Struga';

  @override
  String get mapGeoRadovis => 'Radovishti';

  @override
  String get mapGeoGevgelija => 'Gjevgjelia';

  @override
  String get mapGeoKrivaPalanka => 'Kriva Pallanka';

  @override
  String get mapGeoSvetiNikole => 'Shënti Nikolla';

  @override
  String get mapGeoVinica => 'Vinica';

  @override
  String get mapGeoDelcevo => 'Delçeva';

  @override
  String get mapGeoProbistip => 'Probishtipi';

  @override
  String get mapGeoBerovo => 'Berova';

  @override
  String get mapGeoKratovo => 'Kratova';

  @override
  String get mapGeoKicevo => 'Kicheva';

  @override
  String get mapGeoMakedonskiBrod => 'Brod';

  @override
  String get mapGeoNegotino => 'Negocina';

  @override
  String get mapGeoResen => 'Reseni';

  @override
  String get mapGeoUnknownArea => 'Zona e panjohur';

  @override
  String mapPinPreviewSemantic(String title, String severity) {
    return '$title, $severity. Prek dy herë për parapamje.';
  }

  @override
  String mapClusterSemantic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count vende ndotjeje të grupuara. Prek dy herë për t’i zgjeruar.',
      one: '1 vend ndotjeje i grupuar. Prek dy herë për ta zgjeruar.',
    );
    return '$_temp0';
  }

  @override
  String get mapUserLocationSemantic => 'Vendndodhja juaj aktuale';

  @override
  String get mapPreviewDismissAnnouncement => 'Parapamja e vendit u mbyll.';

  @override
  String mapDistanceMetersAway(int meters) {
    return '$meters m larg';
  }

  @override
  String mapDistanceKilometersAway(String kilometers) {
    return '$kilometers km larg';
  }

  @override
  String mapPreviewSemanticLabel(String title, String distance) {
    return 'Vendi i zgjedhur: $title. $distance. Prek dy herë për detaje. Tërhiq poshtë për ta mbyllur.';
  }

  @override
  String get mapPreviewSemanticHint =>
      'Përdor veprimet për drejtime ose detaje të plota.';

  @override
  String get mapPreviewDirections => 'Drejtime';

  @override
  String get mapPreviewDetails => 'Detaje';

  @override
  String get mapSyncNoticeSemanticRefreshHint =>
      'Prek dy herë për të rifreskuar menjëherë hartën.';

  @override
  String get mapSyncLiveUpdatesDelayed =>
      'Përditësimet në kohë reale u vonuan. Po riprovohet në heshtje…';

  @override
  String get mapSyncConnectionUnstable =>
      'Lidhja është e paqëndrueshme. Po rifreskohet në sfond…';

  @override
  String get mapSyncOfflineSnapshot =>
      'Jashtë linje. Po shfaqet pamja e fundit e ruajtur e hartës.';

  @override
  String get mapSyncOfflineSnapshotJustNow =>
      'Jashtë linje. Po shfaqet pamja e fundit e ruajtur e hartës nga tani.';

  @override
  String mapSyncOfflineSnapshotMinutesAgo(int minutes) {
    return 'Jashtë linje. Po shfaqet pamja e fundit e ruajtur e hartës para $minutes min.';
  }

  @override
  String mapSyncOfflineSnapshotHoursAgo(int hours) {
    return 'Jashtë linje. Po shfaqet pamja e fundit e ruajtur e hartës para $hours orësh.';
  }

  @override
  String get mapSearchLocationUnavailableSnack =>
      'Vendndodhja nuk është e disponueshme për këtë vend.';

  @override
  String get mapSearchFieldSemanticHint =>
      'Shkruaj titull, kategori ose përshkrim';

  @override
  String get mapSearchBarHint => 'Kërko vende…';

  @override
  String get locationRetryAddressSemantic => 'Provo përsëri adresën';

  @override
  String get photoReviewDiscardTitle => 'Të hidhet poshtë kjo foto?';

  @override
  String get photoReviewDiscardBody =>
      'Mund të rifotografosh ose të zgjedhësh një tjetër nga biblioteka.';

  @override
  String get reportPhotoReviewSheetTitle => 'Rishiko provat';

  @override
  String get reportPhotoReviewSheetSubtitle =>
      'Mbaj kornizën më të qartë para se ta shtosh në raport.';

  @override
  String get reportPhotoReviewSemantic =>
      'Rishiko dhe konfirmo foton para se ta shtosh në raport';

  @override
  String get reportPhotoReviewCloseSemantic => 'Mbyll pa shtuar foto';

  @override
  String get reportPhotoReviewRetake => 'Rifoto';

  @override
  String get reportPhotoReviewUsePhoto => 'Përdor këtë foto';

  @override
  String get reportPhotoReviewRetakeSemantic => 'Rifoto';

  @override
  String get reportPhotoReviewUseSemantic => 'Përdor këtë foto';

  @override
  String get reportPhotoReviewPreviewSemantic => 'Parapamje fotoje';

  @override
  String get reportPhotoGridAddShort => 'Shto';

  @override
  String get reportPhotoGridAdd => 'Shto një foto';

  @override
  String get reportPhotoGridSourceHint => 'Kamera ose bibliotekë';

  @override
  String reportPhotoGridAttachedCount(int current, int max) {
    return '$current nga $max foto të bashkangjitura';
  }

  @override
  String get reportPhotoOpenGallerySemantic =>
      'Hap galerinë e fotove të raportit';

  @override
  String get reportPhotoTapToReviewSingle => 'Prek për të shqyrtuar foton';

  @override
  String get reportPhotoTapToReviewMany => 'Prek për të shqyrtuar fotot';

  @override
  String get reportPhotoVerificationHelpPrimarySelected =>
      'Mbaj fotën e parë si pamjen më të qartë të vendit.';

  @override
  String get reportPhotoVerificationHelpPrimaryOther =>
      'Përdor foto shtesë vetëm për detaje, shkallë ose një kënd tjetër të dobishëm.';

  @override
  String get reportPhotoVerificationHelpEmpty =>
      'Fillo me një pamje të qartë të vendit. Shto detaje vetëm nëse ndihmon.';

  @override
  String get reportPhotoStackCaptionSingle =>
      'Një foto e qartë mjafton. Shto një tjetër vetëm nëse ndihmon të shpjegohet vendi.';

  @override
  String reportPhotoStackCaptionMany(int count) {
    return '$count foto të bashkangjitura. Mbaj vetëm kornizat që e bëjnë raportin më të lehtë për t\'u verifikuar.';
  }

  @override
  String reportPhotoSemanticThumbnail(int index, int total) {
    return 'Foto $index nga $total. Prek dy herë për të zgjedhur.';
  }

  @override
  String get reportPhotoSemanticRemove => 'Hiq foton';

  @override
  String get reportPhotoSemanticAddPhoto => 'Shto foto si dëshmi';

  @override
  String reportPhotoSemanticReportPhoto(int index) {
    return 'Foto e raportit $index';
  }

  @override
  String get reportRequirementPhotos => 'Shto të paktën një foto';

  @override
  String get reportRequirementCategory => 'Zgjidh një kategori';

  @override
  String get reportRequirementTitle => 'Shto një titull të shkurtër';

  @override
  String get reportRequirementLocation =>
      'Konfirmo një vendndodhje në Maqedoni';

  @override
  String get reportCooldownUnlockHintDefault =>
      'Bashkohu dhe verifiko pjesëmarrjen, ose krijo një veprim ekologjik për të hapur më shumë raporte.';

  @override
  String get notificationsTitle => 'Njoftimet';

  @override
  String get notificationsMarkAllRead => 'Shëno të gjitha si të lexuara';

  @override
  String get notificationsShowAll => 'Shfaq të gjitha njoftimet';

  @override
  String get notificationsPreferencesTooltip => 'Preferencat e njoftimeve';

  @override
  String get notificationsScrollToTopSemantic => 'Shkrollo njoftimet në krye';

  @override
  String get notificationsRetryLoadingMore =>
      'Provo përsëri të ngarkosh më shumë';

  @override
  String get notificationsMarkAllReadFailed =>
      'Nuk mund të shënohen të gjitha si të lexuara. Provo përsëri.';

  @override
  String get notificationsAllMarkedReadSuccess =>
      'Të gjitha njoftimet u shënuan si të lexuara';

  @override
  String get notificationsSiteUnavailable =>
      'Ky vend nuk është më i disponueshëm.';

  @override
  String get notificationsReadStateUpdateFailed =>
      'Nuk mund të përditësohet statusi i leximit. Provo përsëri.';

  @override
  String get notificationsMarkedUnreadLocal => 'Shënuar si i palexuar (lokal).';

  @override
  String get notificationsArchivedFromView =>
      'Njoftimi u arkivua nga kjo pamje';

  @override
  String get notificationsPrefsLoadFailed =>
      'Nuk u ngarkuan preferencat e njoftimeve.';

  @override
  String get notificationsPreferenceUpdateFailed =>
      'Nuk mund të përditësohet preferenca. Provo përsëri.';

  @override
  String get notificationsPrefsSheetTitle => 'Preferencat e njoftimeve';

  @override
  String get notificationsPrefsSheetSubtitle =>
      'Çaktivizo llojet e njoftimeve që nuk dëshiron të marrësh.';

  @override
  String get notificationsPrefMuted => 'I heshtur';

  @override
  String get notificationsPrefEnabled => 'I aktivizuar';

  @override
  String get notificationsTypeSiteUpdates => 'Përditësime vendesh';

  @override
  String get notificationsTypeReportStatus => 'Status raporti';

  @override
  String get notificationsTypeUpvotes => 'Vota mbështetëse';

  @override
  String get notificationsTypeComments => 'Komente';

  @override
  String get notificationsTypeNearbyReports => 'Raporte afër';

  @override
  String get notificationsTypeCleanupEvents => 'Ngjarje pastrimi';

  @override
  String get notificationsTypeSystem => 'Sistemi';

  @override
  String get notificationsSwipeMarkUnread => 'Shëno si të palexuar';

  @override
  String get notificationsSwipeMarkRead => 'Shëno si të lexuar';

  @override
  String get notificationsSwipeArchive => 'Arkivo';

  @override
  String get notificationsDebugPreviewTriggered =>
      'Parapamje lokale e njoftimit';

  @override
  String get notificationsAllCaughtUp => 'Gjithçka në rregull';

  @override
  String notificationsUnreadUpdatesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count përditësime të palexuara',
      one: '1 përditësim i palexuar',
    );
    return '$_temp0';
  }

  @override
  String get notificationsUnreadBannerOne =>
      '1 njoftim i palexuar kërkon vëmendjen tënde';

  @override
  String notificationsUnreadBannerMany(int count) {
    return '$count njoftime të palexuara kërkojnë vëmendjen tënde';
  }

  @override
  String get notificationsSwipeHint =>
      'Rrëshqit djathtas për lexuar/palexuar · majtas për arkiv';

  @override
  String get notificationsEmptyUnreadTitle => 'Nuk ka njoftime të palexuara';

  @override
  String get notificationsEmptyAllTitle => 'Ende nuk ka njoftime';

  @override
  String get notificationsEmptyUnreadBody =>
      'Je në kohë. Përditësimet e reja do të shfaqen këtu.';

  @override
  String get notificationsEmptyAllBody =>
      'Kur njerëzit reagojnë te vendet dhe veprimet, përditësimet do të shfaqen këtu.';

  @override
  String get notificationsErrorLoadTitle => 'Nuk u ngarkuan njoftimet';

  @override
  String get notificationsErrorLoadFallback =>
      'Kontrollo lidhjen dhe provo përsëri.';

  @override
  String get notificationsErrorNetwork =>
      'Problem rrjeti gjatë ngarkimit të njoftimeve.';

  @override
  String get notificationsErrorGeneric =>
      'Diçka shkoi keq gjatë ngarkimit të njoftimeve.';

  @override
  String get notificationsFilterAll => 'Të gjitha';

  @override
  String get notificationsFilterUnread => 'Të palexuara';

  @override
  String get eventsEventNotFoundTitle => 'Ngjarja nuk u gjet';

  @override
  String get eventsEventNotFoundBody =>
      'Kjo ngjarje nuk është më e disponueshme.';

  @override
  String get eventsDetailBrowseEvents => 'Shfleto ngjarjet';

  @override
  String get eventsDetailCouldNotRefresh =>
      'Nuk u rifreskua. Po shfaqen detajet e ruajtura.';

  @override
  String get eventsDetailRetryRefresh => 'Provo përsëri';

  @override
  String get eventsDetailLocationTitle => 'Vendndodhja';

  @override
  String get eventsDetailCopyAddress => 'Kopjo adresën';

  @override
  String get eventsDetailAddressCopied => 'Adresa u kopjua';

  @override
  String get eventsDetailLocationLongPressHint =>
      'Shtyp gjatë për adresë të plotë dhe veprime';

  @override
  String get eventsDetailCoverImageUnavailable =>
      'Imazhi nuk është i disponueshëm';

  @override
  String get eventsWeatherUnavailableBody =>
      'Parashikimi i motit nuk është i disponueshëm për momentin.';

  @override
  String get eventsWeatherRetry => 'Provo përsëri';

  @override
  String get eventsUnableToStartEventGeneric =>
      'Nuk mund të nisej ngjarja. Kontrollo lidhjen dhe provo përsëri.';

  @override
  String get eventsStartEventTooEarly =>
      'Mund ta nisni këtë veprim ekologjik pasi të arrijë koha e planifikuar e fillimit.';

  @override
  String get eventsJoinNotYetOpen =>
      'Bashkimi hapet kur arrin koha e planifikuar e fillimit.';

  @override
  String get eventsJoinWindowClosed =>
      'Nuk mund të bashkoheni më. Bashkimi mbeti i hapur deri në 15 minuta pas fillimit të planifikuar.';

  @override
  String get errorEventEndAtTooFar =>
      'Fundi i planifikuar nuk mund të jetë kaq larg nga fillimi. Provoni një zgjatje më të shkurtër.';

  @override
  String get errorEventsEndDifferentSkopjeCalendarDay =>
      'Fundi duhet të jetë i njëjtës ditë kalendarike si fillimi (Evropë/Shkup).';

  @override
  String get errorEventsEndAfterSkopjeLocalDay =>
      'Ngjarja duhet të përfundojë deri në 23:59 të ditës së fillimit.';

  @override
  String get eventsAwaitingModerationCta => 'Në pritje të aprovimit';

  @override
  String get eventsModerationBannerTitle => 'Në pritje të aprovimit';

  @override
  String get eventsModerationBannerBody =>
      'Ky veprim është i dukshëm për ju si organizator. Vullnetarët mund të bashkohen pasi moderatorët ta aprovojnë.';

  @override
  String get eventsAttendeeModerationBannerTitle => 'Në pritje të aprovimit';

  @override
  String get eventsAttendeeModerationBannerBody =>
      'Moderatorët po e shqyrtojnë veprimin. Mund ta hapni, por bashkimi hapet vetëm pas aprovimit.';

  @override
  String get eventsDeclinedBannerTitle => 'Nuk u aprovua';

  @override
  String get eventsDeclinedBannerBody =>
      'Kjo ngjarje nuk i plotësoi kriteret. Ndryshoni dhe ridërgoni.';

  @override
  String get eventsDeclinedResubmitCta => 'Ndrysho dhe ridërgo';

  @override
  String get eventsDeclinedDashboardPill => 'Refuzuar';

  @override
  String get eventsPendingDashboardPill => 'Nën shqyrtim';

  @override
  String get eventsEventPendingPublicCta =>
      'Ende nuk është hapur për t\'u bashkuar';

  @override
  String get eventsFeedOfflineStaleBanner =>
      'Po shfaqen ngjarje të ruajtura — rifreskimi dështoi. Tërhiq poshtë për të provuar përsëri.';

  @override
  String get eventsFeedInitialLoadFailed =>
      'Nuk mundëm të ngarkojmë ngjarjet. Kontrollo lidhjen dhe provo përsëri.';

  @override
  String get eventsOrganizerInvalidateQrTitle => 'Anulo kodet e mëparshme QR';

  @override
  String get eventsOrganizerInvalidateQrSubtitle =>
      'Përdore nëse një kod është ndarë ose fotografuar. Kodet e skanuara mbeten të vlefshme deri në skadim; kjo rrotullon sesionin që skanimet e reja të kërkojnë QR të ri.';

  @override
  String get eventsOrganizerQrSessionRotated =>
      'Sesioni QR u përditësua. Trego kodin e ri pjesëmarrësve.';

  @override
  String get eventsOrganizerQrRotateFailed =>
      'Nuk mundëm t\'i anulojmë kodet. Provo përsëri.';

  @override
  String get eventsEditEventTitle => 'Ndrysho ngjarjen';

  @override
  String get eventsEditEventSave => 'Ruaj ndryshimet';

  @override
  String editEventTitleTooLong(int max) {
    return 'Titulli duhet të ketë së shumti $max karaktere.';
  }

  @override
  String editEventDescriptionTooLong(int max) {
    return 'Përshkrimi duhet të ketë së shumti $max karaktere.';
  }

  @override
  String get editEventMaxParticipantsInvalid =>
      'Shkruani një numër të plotë vendesh, ose lëreni bosh për pa kufi.';

  @override
  String editEventMaxParticipantsRange(int min, int max) {
    return 'Madhësia e ekipit duhet të jetë midis $min dhe $max, ose bosh për pa kufi.';
  }

  @override
  String editEventGearLimitReached(int max) {
    return 'Mund të zgjidhni deri në $max artikuj pajisjesh.';
  }

  @override
  String get editEventDiscardTitle => 'Të hidhen ndryshimet?';

  @override
  String get editEventDiscardMessage =>
      'Keni ndryshime të paruajtura. Nëse largoheni tani, do të humbasin.';

  @override
  String get editEventDiscardConfirm => 'Hidhe';

  @override
  String get editEventDiscardKeepEditing => 'Vazhdo redaktimin';

  @override
  String get editEventSchedulePreviewFailed =>
      'Nuk mund të kontrolloheshin përplasjet e orarit. Prapë mund të ruani; serveri do të refuzojë kohët që përputhen.';

  @override
  String get editEventOfflineSave =>
      'Duket se jeni jashtë linje. Lidheni dhe provoni përsëri.';

  @override
  String get editEventHelpTitle => 'Redaktimi i ngjarjes suaj';

  @override
  String get editEventHelpSubtitle => 'Orari, vullnetarët dhe moderimi';

  @override
  String get editEventHelpButtonTooltip => 'Ndihmë';

  @override
  String get editEventDuplicateSubmitTitle => 'Konflikt orari';

  @override
  String editEventDuplicateSubmitBody(String title, String when) {
    return '$title është planifikuar tashmë në $when. Rregulloni kohët dhe provoni përsëri.';
  }

  @override
  String get editEventNoChangesToSave => 'Nuk ka asgjë për të ruajtur.';

  @override
  String get editEventPendingModerationBanner =>
      'Ngjarja ende pret miratimin e moderatorit. Ndryshimet vlejnë për skicën tuaj.';

  @override
  String get eventsEventNotEditable => 'Kjo ngjarje nuk mund të redaktohet më.';

  @override
  String get eventsEventUpdated => 'Ngjarja u përditësua';

  @override
  String get eventsMutationFailedGeneric => 'Diçka shkoi keq. Provo përsëri.';

  @override
  String get eventsScheduleConflictPreviewTitle =>
      'Mund të ketë mbivendosje në orar';

  @override
  String eventsScheduleConflictPreviewBody(String title, String when) {
    return 'Një ngjarje tjetër në këtë vend mund të mbivendoset me kohën tuaj: $title në $when.';
  }

  @override
  String get eventsScheduleConflictContinue => 'Vazhdo gjithsesi';

  @override
  String get eventsScheduleConflictAdjustTime => 'Ndrysho kohën';

  @override
  String eventsDuplicateEventBlocked(String title, String when) {
    return 'Kjo kohë mbivendoset me \"$title\" ($when). Zgjidh një kohë tjetër.';
  }

  @override
  String get eventsManualCheckInAdd => 'Shto';

  @override
  String get eventsManualCheckInTitle => 'Check-in manual';

  @override
  String get eventsCheckInTitle => 'Check-in';

  @override
  String get eventsOrganizerMockAllCheckedIn =>
      'Të gjithë pjesëmarrësit simulues janë regjistruar tashmë.';

  @override
  String get eventsOrganizerAttendeeNamePlaceholder => 'Emri i pjesëmarrësit';

  @override
  String get eventsOrganizerManualCheckInSubtitle =>
      'Kërko vullnetarët që u bashkuan me këtë ngjarje, pastaj regjistroji.';

  @override
  String get eventsOrganizerManualCheckInNoJoiners =>
      'Ende nuk ka vullnetarë të bashkuar me këtë ngjarje.';

  @override
  String get eventsOrganizerManualCheckInSelectParticipant =>
      'Zgjidh një vullnetar nga lista.';

  @override
  String get eventsOrganizerManualCheckInNotParticipant =>
      'Ky person nuk është në listën e pjesëmarrësve.';

  @override
  String get eventsOrganizerEnterNameFirst =>
      'Së pari shkruaj emrin e pjesëmarrësit.';

  @override
  String eventsOrganizerNameAlreadyCheckedIn(String name) {
    return '$name është regjistruar tashmë.';
  }

  @override
  String eventsOrganizerNameAddedByOrganizer(String name) {
    return '$name u shtua nga organizatori.';
  }

  @override
  String eventsOrganizerCouldNotRemoveName(String name) {
    return 'Nuk mund të hiqet $name.';
  }

  @override
  String eventsOrganizerNameRemovedFromCheckIn(String name) {
    return '$name u hoq nga regjistrimi.';
  }

  @override
  String get eventsOrganizerUnableCompleteEvent =>
      'Nuk mund të përfundohet ngjarja.';

  @override
  String get eventsOrganizerEndedTitle => 'Ngjarja përfundoi';

  @override
  String get eventsOrganizerThanksOrganizing => 'Faleminderit për organizimin!';

  @override
  String get eventsOrganizerEndSummaryOneAttendee =>
      '1 pjesëmarrës u regjistrua.';

  @override
  String eventsOrganizerEndSummaryManyAttendees(int count) {
    return '$count pjesëmarrës u regjistruan.';
  }

  @override
  String get eventsOrganizerUploadAfterPhotosHint =>
      'Ngarko fotot \"pas\" nga detaji i ngjarjes.';

  @override
  String get eventsOrganizerCompletionCheckedInNone =>
      'Asnjë pjesëmarrës nuk u regjistrua.';

  @override
  String eventsOrganizerCompletionJoinedLine(int count) {
    return '$count vullnetarë u bashkuan';
  }

  @override
  String eventsOrganizerCompletionJoinedOfCap(int joined, int cap) {
    return '$joined nga $cap vende të mbushura';
  }

  @override
  String get eventsOrganizerCompletionSheetSemantic =>
      'Ngjarja përfundoi. Shiko hapat e ardhshëm.';

  @override
  String get eventsOrganizerCompletionBackToEvent => 'Kthehu te ngjarja';

  @override
  String get eventsOrganizerCompletionAddPhotosNow =>
      'Shto foto pastrimit tani';

  @override
  String get eventsOrganizerCompletionWhatNextIntro =>
      'Përfundo në faqen e ngjarjes: dokumento rezultatet dhe nda ndikimin që patët së bashku.';

  @override
  String get eventsOrganizerCompletionNextStepsHeading => 'HAPAT E ARDHSHËM';

  @override
  String get eventsOrganizerCompletionStepPhotosTitle => 'Shto foto \"pas\"';

  @override
  String get eventsOrganizerCompletionStepPhotosBody =>
      'Trego dallimin që bëtë. Shfaqen në faqen e ngjarjes për të gjithë.';

  @override
  String get eventsOrganizerCompletionStepImpactTitle => 'Regjistro ndikimin';

  @override
  String get eventsOrganizerCompletionStepImpactBody =>
      'Shëno çanta, orë vullnetare dhe vlerësime nga faqja e ngjarjes.';

  @override
  String get eventsOrganizerCompletionStepVisibilityTitle => 'Ndërto besim';

  @override
  String get eventsOrganizerCompletionStepVisibilityBody =>
      'Fotot ndihmojnë moderatorët të verifikojnë pastrimin dhe frymëzojnë veprime të ardhshme.';

  @override
  String get eventsOrganizerCompletionViewReceipt =>
      'Shiko fletëpagesën e ndikimit';

  @override
  String get eventsImpactReceiptScreenTitle => 'Fletëpagesa e ndikimit';

  @override
  String eventsImpactReceiptHeroSemantic(String title) {
    return 'Fletëpagesë ndikimi për $title';
  }

  @override
  String get eventsImpactReceiptMetricCheckIns => 'Regjistrime';

  @override
  String get eventsImpactReceiptMetricParticipants => 'Të regjistruar';

  @override
  String get eventsImpactReceiptMetricBags => 'Çanta (të raportuara)';

  @override
  String get eventsImpactReceiptProofHeading => 'Dëshmi';

  @override
  String get eventsImpactReceiptNoMediaHint =>
      'Shto foto \"pas\" ose dëshmi të strukturuar nga faqja e ngjarjes.';

  @override
  String eventsImpactReceiptAsOf(String timestamp) {
    return 'Përditësuar $timestamp';
  }

  @override
  String get eventsImpactReceiptCompletenessInProgress => 'Në progres';

  @override
  String get eventsImpactReceiptCompletenessFull => 'Regjistrim i plotë';

  @override
  String get eventsImpactReceiptCompletenessPartialAfter =>
      'Mungojnë fotot \"pas\"';

  @override
  String get eventsImpactReceiptCompletenessPartialEvidence =>
      'Mungojnë dëshmitë e strukturuara';

  @override
  String get eventsImpactReceiptCompletenessPartialBoth =>
      'Mungojnë fotot dhe dëshmitë';

  @override
  String get eventsImpactReceiptShare => 'Ndaj';

  @override
  String get eventsImpactReceiptCopyLink => 'Kopjo lidhjen';

  @override
  String get eventsImpactReceiptLinkCopied => 'Lidhja u kopjua';

  @override
  String get eventsImpactReceiptViewCta => 'Fletëpagesa e ndikimit';

  @override
  String get eventsImpactReceiptRetry => 'Provo përsëri';

  @override
  String get eventsImpactReceiptLoadFailed => 'Nuk u ngarkua fletëpagesa.';

  @override
  String eventsImpactReceiptShareSummary(int checkIns, int bags, int joined) {
    return '$checkIns regjistrime · $bags çanta · $joined të regjistruar';
  }

  @override
  String get errorEventsImpactReceiptNotAvailable =>
      'Fletëpagesa e ndikimit ende nuk është e disponueshme për këtë ngjarje.';

  @override
  String get eventsOrganizerDetailPendingAfterPhotosTitle => 'Foto \"pas\"';

  @override
  String get eventsOrganizerDetailPendingAfterPhotosMessage =>
      'Ngarko foto pas pastrimit që vullnetarët dhe moderatorët të shohin rezultatet. Përdor butonin më poshtë.';

  @override
  String get eventsAttendeeCompletedTitle => 'Faleminderit';

  @override
  String get eventsAttendeeCompletedBody =>
      'Ky veprim ekologjik ka përfunduar. Faleminderit që erdhe.';

  @override
  String get eventsAfterPhotosOrganizerEmptyHint =>
      'Ende pa foto \"pas\". Përdor butonin më poshtë për t\'i shtuar.';

  @override
  String get eventsEvidenceScreenSubtitle =>
      'Fotot \"pas\" dokumentojnë rezultatet dhe shfaqen në faqen e ngjarjes.';

  @override
  String eventsEvidencePhotoCountChip(int current, int max) {
    return '$current nga $max foto';
  }

  @override
  String get eventsEvidenceBeforeAfterTabsSemantic => 'Foto para dhe pas';

  @override
  String get eventsEvidenceSavingSemantic => 'Duke ruajtur fotot \"pas\"';

  @override
  String get eventsOrganizerCheckInPausedSnack =>
      'Regjistrimi u ndal përkohësisht.';

  @override
  String get eventsOrganizerCheckInResumedSnack => 'Regjistrimi u rifillua.';

  @override
  String get eventsOrganizerUnableCancelEvent =>
      'Nuk mund të anulohet ngjarja.';

  @override
  String get eventsOrganizerEventCancelledSnack => 'Ngjarja u anulua.';

  @override
  String eventsOrganizerFeedbackCheckedIn(String name) {
    return '$name u regjistrua';
  }

  @override
  String get eventsOrganizerFeedbackInvalidQr => 'Kod QR i pavlefshëm.';

  @override
  String get eventsOrganizerFeedbackWrongEvent => 'QR për ngjarje tjetër.';

  @override
  String get eventsOrganizerFeedbackPaused =>
      'Regjistrimi është ndalur përkohësisht.';

  @override
  String get eventsOrganizerFeedbackQrExpired =>
      'QR skadoi. Gjenero një të ri.';

  @override
  String get eventsOrganizerFeedbackQrReplay =>
      'QR u përdor tashmë. Po rifreskohet…';

  @override
  String eventsOrganizerFeedbackAlreadyCheckedIn(String name) {
    return '$name është regjistruar tashmë.';
  }

  @override
  String get eventsOrganizerQrRefreshHelp =>
      'Pjesëmarrësit duhet gjithmonë të skanojnë QR-në më të re. Kodi rifreskohet automatikisht para se të skadojë.';

  @override
  String get eventsOrganizerHoldPhoneForScan =>
      'Mbaj telefonin që të mund të skanojnë';

  @override
  String get eventsOrganizerPausedLabel => 'Regjistrimi i ndalur';

  @override
  String get eventsOrganizerStatusOpen => 'Hapur';

  @override
  String get eventsOrganizerStatusPaused => 'Ndalur';

  @override
  String eventsOrganizerRefreshInSeconds(int seconds) {
    return 'Rifreskim për $seconds s';
  }

  @override
  String get eventsOrganizerQrRefreshesWhenOpen =>
      'QR rifreskohet automatikisht dhe pas çdo skanimi';

  @override
  String get eventsOrganizerResumeForFreshQr =>
      'Rifillo regjistrimin për një QR të re';

  @override
  String get eventsOrganizerQrLoadFailedGeneric =>
      'Nuk u ngarkua kodi i regjistrimit. Kontrollo lidhjen dhe provo përsëri.';

  @override
  String get eventsOrganizerQrRateLimited =>
      'Shumë përpjekje rifreskimi. Prit pak dhe provo përsëri.';

  @override
  String get eventsOrganizerSessionSetupFailed =>
      'Nuk mund të nisej regjistrimi. Sigurohu që ngjarja është në vazhdim dhe provo përsëri.';

  @override
  String get eventsOrganizerConfirmTitle => 'Konfirmo regjistrimin';

  @override
  String get eventsOrganizerConfirmSubtitle =>
      'Dëshiron të regjistrohet në këtë ngjarje';

  @override
  String get eventsOrganizerConfirmApprove => 'Konfirmo';

  @override
  String get eventsOrganizerConfirmReject => 'Refuzo';

  @override
  String get eventsOrganizerConfirmExpired =>
      'Kjo kërkesë regjistrimi ka skaduar.';

  @override
  String get eventsVolunteerPendingTitle => 'Duke pritur konfirmimin';

  @override
  String get eventsVolunteerPendingSubtitle =>
      'Organizatori duhet të konfirmojë regjistrimin tuaj...';

  @override
  String get eventsVolunteerRejected =>
      'Regjistrimi nuk u konfirmua nga organizatori.';

  @override
  String get eventsVolunteerExpired => 'Kërkesa skadoi. Skanoni përsëri.';

  @override
  String get eventsOrganizerQrRetry => 'Provo përsëri';

  @override
  String get eventsOrganizerQrBrightnessHint =>
      'Këshillë: rrit ndriçimin e ekranit që skanimi të jetë më i lehtë.';

  @override
  String eventsOrganizerQrSemantics(int seconds) {
    return 'Kod QR për regjistrim. Rifreskohet për rreth $seconds sekonda.';
  }

  @override
  String get eventsOrganizerQrEncodeError =>
      'Ky kod nuk mund të vizatohej. Prek provo përsëri.';

  @override
  String get eventsOrganizerFeedbackInvalidQrStrict =>
      'Ky QR nuk vlen për regjistrim.';

  @override
  String get eventsOrganizerFeedbackRequiresJoin =>
      'Bashkohu me ngjarjen në aplikacion para regjistrimit.';

  @override
  String get eventsOrganizerFeedbackCheckInUnavailable =>
      'Regjistrimi nuk është i disponueshëm për këtë ngjarje tani.';

  @override
  String get eventsOrganizerFeedbackRateLimited =>
      'Shumë përpjekje. Prit pak dhe provo përsëri.';

  @override
  String get eventsOrganizerCopyQrText => 'Kopjo tekstin e kodit QR';

  @override
  String get eventsOrganizerQrTextCopied =>
      'Teksti i kodit QR u kopjua — ngjite në mesazh për pjesëmarrësit që nuk mund të skanojnë.';

  @override
  String get eventsOrganizerNoQrToCopy =>
      'Ende nuk ka kod QR aktiv për të kopjuar.';

  @override
  String get eventsOrganizerManualOverride =>
      'Manualisht: shëno pjesëmarrës si i pranishëm';

  @override
  String get eventsOrganizerCheckedInHeading => 'Të regjistruar';

  @override
  String get eventsOrganizerEmptyListTitle =>
      'Ende askush nuk është regjistruar';

  @override
  String get eventsOrganizerEmptyListSubtitle =>
      'Pjesëmarrësit skanojnë QR-në tënde për t\'u regjistruar';

  @override
  String get eventsOrganizerEndEvent => 'Përfundo ngjarjen';

  @override
  String get eventsOrganizerPauseCheckIn => 'Ndalo regjistrimin';

  @override
  String get eventsOrganizerResumeCheckIn => 'Rifillo regjistrimin';

  @override
  String get eventsOrganizerCancelEvent => 'Anulo ngjarjen';

  @override
  String get eventsOrganizerMoreActionsSemantic =>
      'Më shumë veprime për ngjarjen';

  @override
  String get eventsOrganizerMoreSheetTitle => 'Veprimet e ngjarjes';

  @override
  String get eventsOrganizerEndEventConfirmTitle => 'Të përfundohet ngjarja?';

  @override
  String get eventsOrganizerEndEventConfirmMessage =>
      'Regjistrimi do të mbyllet dhe ngjarja do të shënohet si e përfunduar. Mund të ngarkosh foto pas ngjarjes nga detajet e ngjarjes.';

  @override
  String get eventsOrganizerEndEventKeepManaging => 'Vazhdo menaxhimin';

  @override
  String get eventsOrganizerEndEventConfirmAction => 'Përfundo ngjarjen';

  @override
  String get eventsOrganizerCancelEventConfirmTitle => 'Të anulohet ngjarja?';

  @override
  String get eventsOrganizerCancelEventConfirmMessage =>
      'Vullnetarët do ta shohin ngjarjen si të anuluar. Kjo nuk zhbëhet nga aplikacioni.';

  @override
  String get eventsOrganizerCancelEventKeepEvent => 'Mbaje ngjarjen';

  @override
  String get eventsOrganizerCancelEventConfirmAction => 'Anulo ngjarjen';

  @override
  String eventsOrganizerRemoveAttendeeSemantic(String name) {
    return 'Hiq $name nga regjistrimi';
  }

  @override
  String get eventsOrganizerSimulateCheckInDev => 'Simulo regjistrimin (dev)';

  @override
  String get eventsPhotosTitle => 'Foto';

  @override
  String get createEventDefaultDescription =>
      'Aksion pastrimi komunitar i organizuar nga vullnetarët vendas.';

  @override
  String get createEventCategoryTitle => 'Lloji i ngjarjes';

  @override
  String get createEventCategorySubtitle => 'Çfarë lloj aksioni po organizon?';

  @override
  String get createEventGearTitle => 'Mjetet e nevojshme';

  @override
  String get createEventGearSubtitle =>
      'Zgjidh gjithçka që vullnetarët duhet të sjellin.';

  @override
  String createEventGearDoneSelectedCount(int count) {
    return 'U krye ($count të zgjedhura)';
  }

  @override
  String get createEventGearMultiselectTitle => 'Zgjedhje shumëfishe';

  @override
  String get createEventGearMultiselectMessage =>
      'Prek çdo artikull që vullnetarët duhet të sjellin. Mund të zgjedhësh sa të duash.';

  @override
  String get createEventTeamSizeTitle => 'Madhësia e ekipit';

  @override
  String get createEventTeamSizeSubtitle => 'Sa vullnetarë pret?';

  @override
  String get createEventDifficultyTitle => 'Vështirësia';

  @override
  String get createEventDifficultySubtitle =>
      'Vendos pritshmëritë për vullnetarët.';

  @override
  String createEventStepProgress(int step) {
    return 'Hapi $step nga 5';
  }

  @override
  String get createEventEndTimeError =>
      'Koha e mbarimit duhet të jetë pas fillimit.';

  @override
  String createEventScheduleStartInPast(int minutes) {
    return 'Zgjidh një orë fillimi të paktën $minutes minuta nga tani.';
  }

  @override
  String createEventScheduleEndInPast(int minutes) {
    return 'Zgjidh një orë mbarimi të paktën $minutes minuta nga tani.';
  }

  @override
  String get createEventScheduleDateLabel => 'Data e ngjarjes';

  @override
  String get createEventScheduleEndAfterDayError =>
      'Ngjarja duhet të përfundojë deri në 23:59 të së njëjtës dite.';

  @override
  String get createEventFieldType => 'Lloji i ngjarjes';

  @override
  String get createEventPlaceholderType => 'Zgjidh llojin e ngjarjes';

  @override
  String get createEventFieldTeamSize => 'Madhësia e ekipit';

  @override
  String get createEventPlaceholderTeamSize => 'Sa njerëz?';

  @override
  String get createEventFieldDifficulty => 'Vështirësia';

  @override
  String get createEventPlaceholderDifficulty =>
      'Vendos nivelin e vështirësisë';

  @override
  String get createEventSubmitLabel => 'Krijo aksionin ekologjik';

  @override
  String get createEventAppBarTitle => 'Krijo ngjarjen';

  @override
  String get createEventHelpTitle => 'Krijimi i një ngjarjeje';

  @override
  String get createEventHelpSubtitle => 'Udhëzim i shkurtër për organizatorët';

  @override
  String get createEventHelpBulletModeration =>
      'Ngjarjet shqyrtohen që komuniteti të shohë pastrime të sakta dhe të sigurta.';

  @override
  String get createEventHelpBulletVolunteers =>
      'Vullnetarët shohin titullin, orarin, vendin, pajisjet dhe përshkrimin kur ngjarja është aktive.';

  @override
  String get createEventHelpBulletSite =>
      'Zgjidh një vend ndotjeje nga lista ose harta që të dinë të gjithë ku të takohen.';

  @override
  String get createEventHelpBulletSchedule =>
      'Zgjidh datën e ngjarjes, pastaj orët e fillimit dhe mbarimit të asaj dite.';

  @override
  String get createEventHelpBulletSameDay =>
      'Ngjarja duhet të përfundojë të njëjtën ditë kalendarike, së voni deri në 23:59.';

  @override
  String get createEventHelpBulletSubmit =>
      'Kur janë plotësuar fushat e detyrueshme, përdor „Krijo aksionin ekologjik“ për publikim.';

  @override
  String get createEventFieldVolunteerCap => 'Kufiri i vullnetarëve';

  @override
  String get createEventVolunteerCapPlaceholderNoLimit => 'Pa kufi';

  @override
  String createEventVolunteerCapUpTo(int count) {
    return 'Deri në $count vullnetarë';
  }

  @override
  String get createEventVolunteerCapSheetTitle => 'Kufiri i vullnetarëve';

  @override
  String get createEventVolunteerCapSheetSubtitle =>
      'Opsionale. Kufiri është midis 2 dhe 5000.';

  @override
  String get createEventVolunteerCapNoLimit => 'Pa kufi';

  @override
  String get createEventVolunteerCapCustomLabel => 'Numër i personalizuar';

  @override
  String get createEventVolunteerCapCustomHint => 'Numri (2–5000)';

  @override
  String get createEventVolunteerCapApply => 'Apliko';

  @override
  String get createEventVolunteerCapInvalid =>
      'Shkruaj një numër të plotë midis 2 dhe 5000.';

  @override
  String get createEventSitePickerLoading => 'Po ngarkohen vendet…';

  @override
  String get createEventSitePickerOfflineTitle => 'Lista jashtë linje';

  @override
  String get createEventSitePickerOfflineMessage =>
      'Po shfaqen vende të integruara sepse lista e drejtpërdrejtë është bosh ose e padisponueshme.';

  @override
  String get createEventSitePickerLoadFailedTitle => 'Nuk u rifreskua';

  @override
  String get createEventSitePickerLoadFailedMessage =>
      'Mund të zgjedhësh ende nga lista jashtë linje. Provo përsëri për listën e drejtpërdrejtë.';

  @override
  String get createEventSitePickerRetry => 'Provo përsëri';

  @override
  String get createEventDiscardTitle => 'Hidh poshtë ngjarjen?';

  @override
  String get createEventDiscardBody =>
      'Do të humbasësh çfarë ke futur në këtë ekran.';

  @override
  String get createEventDiscardKeepEditing => 'Vazhdo redaktimin';

  @override
  String get createEventLoadingSemantic =>
      'Po ngarkohet forma për krijimin e ngjarjes';

  @override
  String get createEventSectionScheduleCaption => 'Orari';

  @override
  String get createEventSectionDetailsCaption => 'Detajet e ngjarjes';

  @override
  String get createEventCleanupSiteTitle => 'Vendi i pastrimit';

  @override
  String get createEventSelectSiteSemantic => 'Zgjidh vendin e pastrimit';

  @override
  String get createEventChooseSitePlaceholder => 'Zgjidh një vend me ndotje';

  @override
  String get createEventSiteAnchorHint =>
      'Çdo ngjarje duhet lidhur me një vend pastrimi.';

  @override
  String createEventSiteDistanceAway(String distanceKm, String description) {
    return '$distanceKm km larg · $description';
  }

  @override
  String get createEventSiteRequiredError =>
      'Zgjidh vendin para se të krijosh ngjarjen.';

  @override
  String get createEventTitleLabel => 'Titulli i ngjarjes';

  @override
  String createEventTitleCounter(int current, int max) {
    return '$current / $max';
  }

  @override
  String get createEventTitleHint => 'p.sh. Pastrimi i lumit në fundjavë';

  @override
  String get createEventTitleRequired => 'Titulli është i detyrueshëm.';

  @override
  String get createEventTitleMinLength =>
      'Përdorni të paktën 3 karaktere për titullin.';

  @override
  String get createEventSitePickerTabList => 'Lista';

  @override
  String get createEventSitePickerTabMap => 'Harta';

  @override
  String get createEventSitePickerMapEmpty =>
      'Asnjë vend në hartë nuk përputhet me këtë kërkim, ose vendndodhjet ende nuk janë të disponueshme.';

  @override
  String get createEventSitePickerMapSemanticLabel =>
      'Harta e vendeve të ndotjes';

  @override
  String get createEventSitePickerMapHint =>
      'Prek një shënues për të zgjedhur një vend.';

  @override
  String get createEventSiteMapPreviewSemantic =>
      'Hap zgjedhjen e vendit në hartë';

  @override
  String get createEventTypeRequired => 'Zgjidh një lloj ngjarjeje.';

  @override
  String get createEventGearPlaceholderQuestion =>
      'Çfarë duhet të sjellin vullnetarët?';

  @override
  String get createEventGearLabel => 'Mjetet e nevojshme';

  @override
  String get createEventSelectGearSemantic => 'Zgjidh mjetet e nevojshme';

  @override
  String get createEventDescriptionLabel => 'Përshkrimi';

  @override
  String get createEventDescriptionSubtitle =>
      'Opsionale: më shumë kontekst për vullnetarët.';

  @override
  String get createEventDescriptionHint =>
      'Përshkruaj çfarë të presin, pika e takimit, etj.';

  @override
  String get eventsEventNotFoundShort => 'Ngjarja nuk u gjet.';

  @override
  String get eventsBeforeLabel => 'Para';

  @override
  String get eventsAfterLabel => 'Pas';

  @override
  String get eventsDiscardChangesTitle => 'Të hidhen ndryshimet?';

  @override
  String get eventsDiscardChangesBody =>
      'Ke foto të paruajtura. Je i sigurt që do të dalësh?';

  @override
  String get eventsSetCover => 'Vendos si kopertinë';

  @override
  String get eventsViewFullscreen => 'Ekran i plotë';

  @override
  String get eventsAddToCalendar => 'Shto në kalendar';

  @override
  String get eventsParticipantsRecent => 'Së fundmi';

  @override
  String get eventsParticipantsAz => 'A-ZH';

  @override
  String get eventsParticipantsCheckedIn => 'Të regjistruar';

  @override
  String get eventsSaveImpactSummary => 'Ruaj përmbledhjen e ndikimit';

  @override
  String get eventsCheckedInBadge => 'I regjistruar';

  @override
  String eventsCleanupPhotosCount(int count) {
    return '$count foto pastrimi';
  }

  @override
  String get eventsCtaStartEvent => 'Fillo ngjarjen';

  @override
  String get eventsCtaManageCheckIn => 'Menaxho regjistrimin';

  @override
  String get eventsCtaExtendCleanupEnd => 'Zgjat fundin e planifikuar';

  @override
  String get eventsExtendEndSheetTitle => 'Zgjat pastrimin';

  @override
  String eventsExtendEndSheetSubtitle(String time) {
    return 'Fundi aktual i planifikuar është $time.';
  }

  @override
  String eventsExtendEndCurrentChoice(String time) {
    return 'Fund i ri: $time';
  }

  @override
  String get eventsExtendEndPlus15 => '+15 min';

  @override
  String get eventsExtendEndPlus30 => '+30 min';

  @override
  String get eventsExtendEndPlus60 => '+1 orë';

  @override
  String get eventsExtendEndCustomTime => 'Kohë e personalizuar…';

  @override
  String get eventsExtendEndApply => 'Ruaj fundin e ri';

  @override
  String get eventsExtendEndSuccess => 'Fundi i planifikuar u përditësua.';

  @override
  String get eventsExtendEndSameAsCurrent =>
      'Kjo është tashmë fundi i planifikuar.';

  @override
  String get eventsExtendEndInvalidRange =>
      'Ajo kohë fundi nuk është e vlefshme për këtë pastrim.';

  @override
  String get eventsExtendEndTooSoon => 'Zgjidhni një fund pak më larg në kohë.';

  @override
  String get eventsEndSoonBannerTitle => 'Pastrimi po përfundon së shpejti';

  @override
  String get eventsEndSoonBannerBody =>
      'Mund ta zgjatni fundin e planifikuar ose të përfundoni kur të jeni gati.';

  @override
  String get eventsEndSoonBannerExtend => 'Zgjat';

  @override
  String get eventsOrganizerExtendEndSemantic =>
      'Zgjat fundin e planifikuar të pastrimit';

  @override
  String get eventsOrganizerEndSoonNotifyTitle =>
      'Pastrimi po përfundon së shpejti';

  @override
  String get eventsOrganizerEndSoonNotifyBody =>
      'Pastrimi juaj po i afrohet fundit të planifikuar. Prekni për ta shqyrtuar.';

  @override
  String get eventsOrganizerEndSoonNotifyChannelName =>
      'Rikujtues lokalë për organizatorët';

  @override
  String get eventsOrganizerEndSoonNotifyChannelDescription =>
      'Rikujtues lokalë kur pastrimi që drejtoni po i afrohet fundit të planifikuar.';

  @override
  String get eventsCtaEditAfterPhotos => 'Ndrysho fotot pas';

  @override
  String get eventsCtaUploadAfterPhotos => 'Ngarko fotot pas';

  @override
  String get eventsCtaCheckedIn => 'I regjistruar';

  @override
  String get eventsCtaScanToCheckIn => 'Skano për t\'u regjistruar';

  @override
  String get eventsCtaCheckInPaused => 'Regjistrimi u ndal';

  @override
  String get eventsCtaTurnReminderOff => 'Fike rikujtuesin';

  @override
  String get eventsCtaSetReminder => 'Vendos rikujtues';

  @override
  String get eventsCtaLeaveEvent => 'Largohu nga ngjarja';

  @override
  String get eventsCtaJoinEcoAction => 'Bashkohu me aksionin';

  @override
  String get eventsStatusUpcoming => 'Në pritje';

  @override
  String get eventsStatusInProgress => 'Në progres';

  @override
  String get eventsStatusCompleted => 'E përfunduar';

  @override
  String get eventsStatusCancelled => 'E anuluar';

  @override
  String get eventsCardActionsSheetTitle => 'Veprime për ngjarjen';

  @override
  String get eventsCardCopyTitle => 'Kopjo detajet e ngjarjes';

  @override
  String get eventsCardCopySubtitle => 'Titulli, data dhe vendndodhja';

  @override
  String get eventsCardCopiedSnack => 'Detajet u kopjuan.';

  @override
  String get eventsCardShareTitle => 'Ndaj ngjarjen';

  @override
  String get eventsCardShareSubtitle => 'Ndaj me miqtë';

  @override
  String get eventsCardOpenTitle => 'Hap ngjarjen';

  @override
  String get eventsCardOpenSubtitle => 'Shiko detajet e plota';

  @override
  String get eventsCardMoreActionsSemantic => 'Më shumë veprime për ngjarjen';

  @override
  String get eventsCardSoonLabel => 'Së shpejti';

  @override
  String get eventsFeedUpNext => 'Më pas';

  @override
  String get eventsCountdownStarted => 'Filloi';

  @override
  String eventsCountdownDaysHours(int days, int hours) {
    return 'Fillon për ${days}d ${hours}o';
  }

  @override
  String eventsCountdownHoursMinutes(int hours, int minutes) {
    return 'Fillon për ${hours}o ${minutes}m';
  }

  @override
  String eventsCountdownMinutes(int minutes) {
    return 'Fillon për ${minutes}m';
  }

  @override
  String get eventsShareEventTooltip => 'Ndaj ngjarjen';

  @override
  String get eventsAttendeeCheckInSemantic =>
      'Skano për t\'u regjistruar në ngjarje';

  @override
  String get eventsAttendeeAlreadyCheckedInSnack => 'Je regjistruar tashmë.';

  @override
  String get eventsAttendeeCheckInPausedSnack =>
      'Organizatori e ndali regjistrimin për tani.';

  @override
  String get eventsAttendeeCheckInCompleteSnack => 'Regjistrimi u krye.';

  @override
  String get eventsAttendeeBannerTitleCheckedIn => 'Je i regjistruar';

  @override
  String get eventsAttendeeBannerTitleInProgress => 'Ngjarja është në progres';

  @override
  String get eventsAttendeeBannerSubtitleAttendanceConfirmed =>
      'Pjesëmarrja u konfirmua';

  @override
  String eventsAttendeeBannerSubtitleCheckedInAt(String time) {
    return 'Regjistruar në $time';
  }

  @override
  String get eventsAttendeeBannerSubtitleScanQr =>
      'Skano QR-në e organizatorit për t\'u regjistruar';

  @override
  String get eventsAttendeeBannerSubtitlePaused =>
      'Regjistrimi është pezulluar përkohësisht';

  @override
  String get eventsDetailShareSuccess => 'Ngjarja u nda.';

  @override
  String get eventsDetailShareFailed => 'Nuk u hap ndarja. Provo përsëri.';

  @override
  String get eventsDetailCalendarAdded => 'Ngjarja u shtua në kalendar.';

  @override
  String get eventsDetailCalendarFailed =>
      'Nuk u shtua në kalendar. Provo përsëri.';

  @override
  String get eventsDetailRefreshFailed =>
      'Nuk u rifreskua ngjarja. Provo përsëri.';

  @override
  String get eventsDetailCancelledCallout => 'Kjo ngjarje është anuluar.';

  @override
  String get eventsDetailOpenInMaps => 'Hape në Hartat';

  @override
  String eventsDetailCoverSemantic(String title) {
    return 'Imazh kopertine për $title';
  }

  @override
  String get eventsDetailGroupedPanelSemantic =>
      'Vendndodhja, orari dhe detajet';

  @override
  String eventsHeroChatSemantic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bisedë në grup, $count të palexuara',
      one: 'Bisedë në grup, 1 e palexuar',
      zero: 'Bisedë në grup',
    );
    return '$_temp0';
  }

  @override
  String get eventsDetailParticipationSemantic => 'Pjesëmarrja juaj';

  @override
  String get eventsAnalyticsLoadFailed => 'Nuk u ngarkuan analitikat.';

  @override
  String get eventsAnalyticsRetry => 'Riprovo';

  @override
  String get eventsRecurrenceDaily => 'Çdo ditë';

  @override
  String get eventsRecurrenceNavigatePrevious => 'Ngjarja e mëparshme në seri';

  @override
  String get eventsRecurrenceNavigateNext => 'Ngjarja tjetër në seri';

  @override
  String get eventsImpactSummarySaved => 'Përmbledhja e ndikimit u ruajt.';

  @override
  String get eventsImpactSummaryUpdated =>
      'Përmbledhja e ndikimit u përditësua.';

  @override
  String eventsReminderSetSnack(String when) {
    return 'Rikujtuesi u vendos për $when.';
  }

  @override
  String get eventsFeedbackSheetTitle => 'Feedback pas ngjarjes';

  @override
  String get eventsFeedbackHowWasEvent => 'Si shkoi ngjarja?';

  @override
  String get eventsFeedbackBagsCollected => 'Çanta të mbledhura';

  @override
  String eventsFeedbackVolunteerHours(String hours) {
    return 'Orë vullnetarësh: ${hours}o';
  }

  @override
  String get eventsFeedbackNotesHint =>
      'Çfarë funksionoi mirë? Shënime për herën tjetër?';

  @override
  String eventsEvidenceMaxPhotosSnack(int max) {
    return 'Maksimumi $max foto.';
  }

  @override
  String get eventsEvidencePickFailedSnack =>
      'Nuk mund të zgjidhen foto. Kontrollo lejet.';

  @override
  String get eventsEvidenceRemoveAction => 'Hiq';

  @override
  String get eventsEvidenceAppBarTitle => 'Dëshmi pastrimi';

  @override
  String get eventsEvidenceSaving => 'Duke u ruajtur...';

  @override
  String get eventsEvidenceSaveInProgressHint =>
      'Prit derisa të përfundojë ruajtja para se të largohesh nga kjo faqe.';

  @override
  String get eventsEvidenceAfterPhotosSaved => 'Fotot pas u ruajtën.';

  @override
  String get eventsEvidenceSaveSuccessTitle => 'Fotot u ruajtën';

  @override
  String get eventsEvidenceSaveSuccessBody =>
      'Fotot \"pas\" janë në faqen e ngjarjes.';

  @override
  String get eventsEvidenceSaveFailureTitle => 'Nuk mund të ruhen fotot';

  @override
  String eventsEvidenceSaveFailureBody(String message) {
    return '$message';
  }

  @override
  String get eventsEvidenceNoChanges => 'Nuk ka ndryshime për të ruajtur.';

  @override
  String get eventsSiteReferencePhotoTitle => 'Foto referencë e vendit';

  @override
  String get eventsSiteReferencePhotoBody =>
      'Referencë para pastrimit. Përdor skedën Pas për foto të vendit të pastruar.';

  @override
  String get eventsManageCheckInOnlyInProgress =>
      'Regjistrimi ofrohet vetëm gjatë ngjarjes.';

  @override
  String get eventsEventFull => 'Kjo ngjarje është plot.';

  @override
  String get eventsParticipationUpdateFailed =>
      'Nuk mund të përditësojmë pjesëmarrjen. Provo përsëri.';

  @override
  String get eventsJoinedEcoAction => 'U bashkove me këtë aksion ekologjik.';

  @override
  String eventsJoinPointsEarned(int points) {
    return '+$points pikë — mirë se erdhe!';
  }

  @override
  String get eventsLeftEcoAction => 'U largove nga ky aksion ekologjik.';

  @override
  String eventsCheckInPointsEarned(int points) {
    return '+$points pikë — u regjistrove!';
  }

  @override
  String eventsManualCheckInWithPoints(String name, int points) {
    return '$name u regjistrua · +$points pikë për ta';
  }

  @override
  String get eventsJoinFirstForReminders =>
      'Së pari bashkohu me ngjarjen për të vendosur rikujtues.';

  @override
  String get eventsReminderDisabled => 'Rikujtuesi u fik.';

  @override
  String get eventsReminderSheetTitle => 'Zgjidh kohën e rikujtuesit';

  @override
  String eventsReminderSheetSubtitle(String timeRange, String date) {
    return 'Ngjarja fillon në $timeRange më $date.';
  }

  @override
  String get eventsReminderPreset1Day => '1 ditë para';

  @override
  String get eventsReminderPreset3Hours => '3 orë para';

  @override
  String get eventsReminderPreset1Hour => '1 orë para';

  @override
  String get eventsReminderPreset30Mins => '30 minuta para';

  @override
  String get eventsReminderUnavailableSubtitle =>
      'Jo e disponueshme për këtë orar ngjarjeje';

  @override
  String get eventsReminderCustomTitle => 'Datë dhe orë të personalizuara';

  @override
  String get eventsReminderCustomSubtitle =>
      'Zgjidh një moment specifik për rikujtuesin';

  @override
  String get eventsReminderPickTitle => 'Zgjidh rikujtuesin';

  @override
  String get eventsReminderDone => 'Gati';

  @override
  String eventsCardParticipantsMore(int count) {
    return '+$count të tjerë';
  }

  @override
  String eventsCardParticipantsCountMax(int count, int max) {
    return '$count / $max';
  }

  @override
  String eventsCardParticipantsJoined(int count) {
    return '$count të bashkuar';
  }

  @override
  String get eventsDiscoveryThisWeekRetryHint =>
      'Nuk mund të ngarkojmë zgjedhjet e kësaj jave.';

  @override
  String get eventsDiscoveryThisWeekRetry => 'Riprovo';

  @override
  String eventsDetailSemanticsLabel(String title) {
    return 'Detaje ngjarjeje: $title';
  }

  @override
  String eventsCountdownBadgeSemantic(String label) {
    return 'Kohë deri në fillim të ngjarjes: $label';
  }

  @override
  String get eventsEvidenceThumbnailMenuTitle => 'Foto';

  @override
  String get eventsFeedRefreshFailed => 'Nuk mund të rifreskojmë ngjarjet.';

  @override
  String get eventsCreateGenericError =>
      'Nuk mund të krijojmë ngjarjen. Provo përsëri.';

  @override
  String get qrScannerPointCameraHint =>
      'Drejto kamerën te kodi QR i organizatorit';

  @override
  String get qrScannerEnterManually => 'Nuk skanon? Shkruaje kodin manualisht';

  @override
  String get qrScannerRetryCamera => 'Provo përsëri kamerën';

  @override
  String get qrScannerSubmitCode => 'Dërgo kodin';

  @override
  String get qrScannerHintFreshQr =>
      'Nëse organizatori rifreskon QR-në, skano më të renë.';

  @override
  String get qrScannerHintCameraBlocked =>
      'Nëse kamera mbetet e bllokuar, ngjit kodin manualisht ose aktivizo kamerën te Cilësimet.';

  @override
  String get qrScannerGenericEventTitle => 'ky pastrim';

  @override
  String get qrScannerErrorInvalidFormat => 'Format i pavlefshëm i QR.';

  @override
  String get qrScannerErrorInvalidQr => 'Ky QR nuk vlen për regjistrim.';

  @override
  String get qrScannerErrorWrongEvent => 'Ky QR i përket një ngjarje tjetër.';

  @override
  String get qrScannerErrorSessionClosed =>
      'Organizatori e ndali regjistrimin.';

  @override
  String get qrScannerErrorSessionExpired =>
      'QR skadoi. Kërko një kod të ri te organizatori.';

  @override
  String get qrScannerErrorReplayDetected => 'Ky QR është përdorur tashmë.';

  @override
  String get qrScannerErrorAlreadyCheckedIn => 'Je regjistruar tashmë.';

  @override
  String get qrScannerErrorRequiresJoin =>
      'Bashkohu me këtë ngjarje në aplikacion para se të regjistrohesh.';

  @override
  String get qrScannerErrorCheckInUnavailable =>
      'Regjistrimi nuk është i hapur për këtë ngjarje tani.';

  @override
  String get qrScannerErrorRateLimited =>
      'Shumë përpjekje. Prit pak dhe provo përsëri.';

  @override
  String get qrScannerCameraUnavailableFeedback =>
      'Kamera nuk është e disponueshme. Mund të ngjisësh kodin e organizatorit ose të riaktivizosh kamerën te Cilësimet.';

  @override
  String get qrScannerManualEntryTitle => 'Shkruaje kodin manualisht';

  @override
  String get qrScannerPasteOrganizerQrHint =>
      'Ngjit tekstin e QR të organizatorit';

  @override
  String get qrScannerPasteFromClipboardTooltip => 'Ngjit nga clipboard-i';

  @override
  String get qrScannerEnterCodeFirst => 'Së pari shkruaj një kod.';

  @override
  String get qrScannerCheckedInTitle => 'U regjistrove!';

  @override
  String qrScannerWelcomeTo(String eventTitle) {
    return 'Mirë se erdhe te $eventTitle';
  }

  @override
  String qrScannerCheckedInAt(String time) {
    return 'Regjistruar në $time';
  }

  @override
  String get qrScannerDone => 'U krye';

  @override
  String get qrScannerAppBarTitle => 'Skano për t\'u regjistruar';

  @override
  String get qrScannerToggleFlashlightSemantic => 'Ndërro dritën e kamerës';

  @override
  String get qrScannerCameraStarting => 'Po niset kamera…';

  @override
  String get qrScannerCheckingIn => 'Po verifikohet regjistrimi…';

  @override
  String get qrScannerCameraErrorTitle => 'Kamera jo e disponueshme';

  @override
  String get qrScannerManualEntrySubtitle =>
      'Ngjit të gjithë tekstin që ndau organizatori (kopjo nga ekrani ose mesazhi i tyre).';

  @override
  String get qrScannerPasteButton => 'Ngjit';

  @override
  String get siteReportReasonFakeLabel => 'Të dhëna të rreme ose mashtruese';

  @override
  String get siteReportReasonFakeSubtitle =>
      'Informacioni nuk pasqyron realitetin';

  @override
  String get siteReportReasonResolvedLabel => 'Tashmë u zgjidh';

  @override
  String get siteReportReasonResolvedSubtitle =>
      'Problemi u pastrua ose u rregullua';

  @override
  String get siteReportReasonWrongLocationLabel => 'Vendndodhje e gabuar';

  @override
  String get siteReportReasonWrongLocationSubtitle =>
      'Vendi është vendosur gabim në hartë';

  @override
  String get siteReportReasonDuplicateLabel => 'Raport i dyfishtë';

  @override
  String get siteReportReasonDuplicateSubtitle =>
      'I njëjti vend u raportua disa herë';

  @override
  String get siteReportReasonSpamLabel => 'Spam ose abuzim';

  @override
  String get siteReportReasonSpamSubtitle =>
      'Përmbajtje e papërshtatshme ose dashakeqe';

  @override
  String get siteReportReasonOtherLabel => 'Tjetër';

  @override
  String get siteReportReasonOtherSubtitle =>
      'Diçka tjetër nuk është në rregull';

  @override
  String get takeActionDonationOpenFailed => 'Nuk u hap faqja e donacioneve';

  @override
  String get takeActionShareSiteTitle => 'Ndaj vendin';

  @override
  String get takeActionShareSiteSubtitle =>
      'Ndihmo të tjerët ta zbulojnë dhe ta mbështesin';

  @override
  String get takeActionLinkCopied => 'Lidhja u kopjua';

  @override
  String get takeActionSheetTitle => 'Vepro tani';

  @override
  String get takeActionSheetSubtitle => 'Zgjidh si dëshiron të ndihmosh';

  @override
  String get takeActionCreateEcoTitle => 'Krijo aksion eko';

  @override
  String get takeActionCreateEcoSubtitle =>
      'Planifiko një aksion pastrimi në këtë lokacion';

  @override
  String get takeActionJoinTitle => 'Bashkohu në aksion';

  @override
  String get takeActionJoinSubtitle =>
      'Gjej dhe bashkohu aksioneve të ardhshme të pastrimit';

  @override
  String get takeActionShareTitle => 'Ndaj lokacionin';

  @override
  String get takeActionShareSubtitle =>
      'Ndihmo të tjerët ta zbulojnë këtë lokacion';

  @override
  String get shareSheetSemanticDragHandle =>
      'Tërhiq për të ndryshuar madhësinë ose për ta mbyllur';

  @override
  String get shareSheetCopyLinkTitle => 'Kopjo lidhjen';

  @override
  String get shareSheetCopyLinkSubtitle =>
      'Kopjo lidhjen e vendit në clipboard';

  @override
  String get shareSheetCopyLinkSemantic =>
      'Kopjo lidhjen për këtë vend ndotjeje';

  @override
  String get shareSheetSendTitle => 'Dërgo te njerëzit';

  @override
  String get shareSheetSendSubtitle =>
      'Ndaj në mesazhe ose një aplikacion tjetër';

  @override
  String get shareSheetSendSemantic =>
      'Hap fletën e ndarjes për ta dërguar këtë vend';

  @override
  String siteDetailSemanticShareCount(int count) {
    return '$count ndarje në këtë vend';
  }

  @override
  String get siteDetailThankYouReportSnack =>
      'Faleminderit. Raporti yt na ndihmon.';

  @override
  String get siteDetailUpvoteFailedSnack =>
      'Nuk u përditësua vota. Provo përsëri.';

  @override
  String get siteDetailNoUpvotesSnack =>
      'Ende pa vota. Bëhu i pari që e mbështet!';

  @override
  String get siteUpvotersSheetTitle => 'Mbështetësit';

  @override
  String get siteUpvotersSupportingLabel => 'Po e mbështet';

  @override
  String siteUpvotersSupportersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mbështetës',
      one: '1 mbështetës',
    );
    return '$_temp0';
  }

  @override
  String get siteUpvotersLoadFailed => 'Nuk u ngarkuan mbështetësit.';

  @override
  String get siteUpvotersRetry => 'Provo përsëri';

  @override
  String get siteDetailNoVolunteersSnack => 'Ende pa vullnetarë për këtë vend.';

  @override
  String get siteDetailDirectionsUnavailableSnack =>
      'Udhëzimet nuk janë të disponueshme për këtë vend.';

  @override
  String get siteDetailOpenMapsFailedSnack => 'Nuk u hap Hartat';

  @override
  String get siteDetailNoCoReportersSnack =>
      'Ende nuk ka kontribues të tjerë. Bashkëraportuesit shfaqen kur dikush tjetër raporton të njëjtin vend.';

  @override
  String siteStatsCoReportersSemantic(int count) {
    return '$count bashkëraportues për këtë raport';
  }

  @override
  String siteParticipantStatsSemantic(int count) {
    return '$count për kontribues (bashkëraportues ose raporte të përbashkëta të dyfishta)';
  }

  @override
  String get siteMergedDuplicatesModalTitle =>
      'Raporte të dyfishta të bashkuara';

  @override
  String siteMergedDuplicatesModalBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count paraqitje të ngjashme u bashkuan në këtë raport. Kur dikush tjetër raporton të njëjtin vend, shfaqen si bashkëraportues.',
      one:
          'Një paraqitje e ngjashme u bashkua në këtë raport. Kur dikush tjetër raporton të njëjtin vend, shfaqet si bashkëraportues.',
    );
    return '$_temp0';
  }

  @override
  String get siteCardUpvoteFailedSnack =>
      'Nuk u përditësua vota. Provo përsëri.';

  @override
  String get siteCardSavedFailedSnack =>
      'Nuk u përditësua ruajtja. Provo përsëri.';

  @override
  String get siteCardTakeActionSemantic => 'Ndërmerr veprim';

  @override
  String get siteCardFeedOptionsSemantic => 'Opsione të rrjedhës';

  @override
  String get siteCardCommentsLoadFailedSnack => 'Nuk u ngarkuan komentet.';

  @override
  String get siteCardShareTrackFailedSnack => 'Nuk u regjistrua ndarja.';

  @override
  String get siteCardFeedbackSubmitFailedSnack => 'Nuk u dërgua reagimi.';

  @override
  String get siteCardNotRelevantTitle => 'Jo relevante';

  @override
  String get siteCardShowLessTitle => 'Shfaq më pak të tilla';

  @override
  String get siteCardDuplicateTitle => 'Dublikatë';

  @override
  String get siteCardMisleadingTitle => 'Mashtruese';

  @override
  String get siteCardHidePostTitle => 'Fshih këtë postim';

  @override
  String get feedSiteCommentsAppBarFallback => 'Komentet';

  @override
  String get feedSiteNotFoundMessage => 'Ky vend nuk u gjet.';

  @override
  String get feedDisplayNameFallback => 'Ti';

  @override
  String get feedOpenProfileSemantics => 'Hap profilin';

  @override
  String get feedGreetingPrefix => 'Përshëndetje, ';

  @override
  String get feedGreetingFallbackName => 'aty';

  @override
  String get feedHeaderSubtitle => 'Eksploro vendet e ndotjes pranë teje';

  @override
  String get feedNotificationBellAllReadSemantic =>
      'Njoftime, të gjitha të lexuara';

  @override
  String feedNotificationBellUnreadSemantic(int count) {
    return 'Njoftime, $count të palexuara';
  }

  @override
  String get siteDetailTabPollutionSite => 'Vend ndotjeje';

  @override
  String get siteDetailTabCleaningEvents => 'Aksione pastrimi';

  @override
  String get siteDetailInfoCardTitle => 'Nevojitet veprim i komunitetit';

  @override
  String get siteDetailInfoCardBody =>
      'Bashkohu në një pastrim, raporto ndryshime ose shpërndaje që të veprojmë më shpejt.';

  @override
  String get siteDetailReportedByPrefix => 'Raportuar nga ';

  @override
  String get siteDetailCoReportersTitle => 'Bashkë-raportues';

  @override
  String siteDetailCoReportersSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Edhe $count persona e raportuan këtë vend',
      one: 'Edhe 1 person e raportoi këtë vend',
    );
    return '$_temp0';
  }

  @override
  String siteDetailGalleryPhotoSemantic(int index) {
    return 'Foto e vendit të ndotjes $index';
  }

  @override
  String get siteDetailOpenGalleryLabel => 'Hap galerinë e vendit të ndotjes';

  @override
  String get siteDetailGalleryTapToExpand => 'Prek për ta zgjeruar';

  @override
  String get siteDetailGalleryOpenPhoto => 'Hap foton';

  @override
  String get commonNotAvailable => '—';

  @override
  String get commonDistanceMetersUnit => 'm';

  @override
  String get commonDistanceKilometersUnit => 'km';

  @override
  String get siteCommentsEmptyBody =>
      'Ende nuk ka komente.\nBëhu i pari që komenton.';

  @override
  String get feedCommentsLoadMoreFailedSnack =>
      'Nuk u ngarkuan më shumë komente. Provo përsëri.';

  @override
  String get commentsSheetTitle => 'Veprime komenti';

  @override
  String get commentsSheetSubtitle => 'Menaxho këtë koment';

  @override
  String get commentsEditTitle => 'Përpuno komentin';

  @override
  String get commentsEditSubtitle => 'Përditëso tekstin';

  @override
  String get commentsDeleteTitle => 'Fshi komentin';

  @override
  String get commentsDeleteSubtitle => 'Hiqe nga biseda';

  @override
  String get commentsEditFailedSnack => 'Nuk u përpunua komenti.';

  @override
  String get commentsReplyFailedSnack => 'Nuk u dërgua përgjigja.';

  @override
  String get commentsSortFailedSnack =>
      'Nuk mund të ndryshohet rendi i komenteve. Provoni përsëri.';

  @override
  String get commentsDeletedSnack => 'Komenti u fshi.';

  @override
  String get commentsDeleteFailedSnack => 'Nuk u fshi komenti.';

  @override
  String get commentsLikeFailedSnack => 'Nuk u përditësua pëlqimi.';

  @override
  String get commentsCancelEditSemantic =>
      'Anulo përpunimin dhe pastro draftin';

  @override
  String get commentsCancelReplySemantic =>
      'Anulo përgjigjen dhe pastro draftin';

  @override
  String commentsReplyToSemantic(String name) {
    return 'Përgjigju $name';
  }

  @override
  String get commentsReplyButton => 'Përgjigju';

  @override
  String get commentsViewReplies => 'Shiko përgjigjet';

  @override
  String commentsLoadMoreReplies(int count) {
    return 'Ngarko $count të tjera';
  }

  @override
  String get siteEngagementQueuedOfflineSnack =>
      'Lidhja u ndërpre. Do ta provojmë përsëri kur të jeni përsëri në linjë.';

  @override
  String get commentsHideReplies => 'Fshih përgjigjet';

  @override
  String get commentsStatusDeleting => 'Po fshihet…';

  @override
  String get commentsStatusSavingEdits => 'Po ruhen ndryshimet…';

  @override
  String get commentsCommentMetaJustNow => 'Tani';

  @override
  String commentsCommentMetaJustNowWithLikes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tani • $count pëlqime',
      one: 'Tani • 1 pëlqim',
    );
    return '$_temp0';
  }

  @override
  String commentsCommentMetaMinutesAgo(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'para $minutes minuta',
      one: 'para 1 minute',
    );
    return '$_temp0';
  }

  @override
  String commentsCommentMetaMinutesAgoWithLikes(int minutes, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'para $minutes minuta',
      one: 'para 1 minute',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pëlqime',
      one: '1 pëlqim',
    );
    return '$_temp0 • $_temp1';
  }

  @override
  String commentsCommentMetaHoursAgo(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'para $hours orë',
      one: 'para 1 orë',
    );
    return '$_temp0';
  }

  @override
  String commentsCommentMetaHoursAgoWithLikes(int hours, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'para $hours orë',
      one: 'para 1 orë',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pëlqime',
      one: '1 pëlqim',
    );
    return '$_temp0 • $_temp1';
  }

  @override
  String commentsCommentMetaDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'para $days ditë',
      one: 'para 1 ditë',
    );
    return '$_temp0';
  }

  @override
  String commentsCommentMetaDaysAgoWithLikes(int days, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'para $days ditë',
      one: 'para 1 ditë',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pëlqime',
      one: '1 pëlqim',
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
      other: '$count pëlqime',
      one: '1 pëlqim',
    );
    return '$date • $_temp0';
  }

  @override
  String get commentsOptimisticAuthorYou => 'Ju';

  @override
  String commentsReplyingToBanner(String name) {
    return 'Po i përgjigjeni $name';
  }

  @override
  String get commentsSemanticSheetDragHandle =>
      'Ndryshoni madhësinë ose mbyllni komentet';

  @override
  String get commentsPrefetchCouldNotRefreshSnack =>
      'Nuk u rifreskuan komentet. Po shfaqet biseda e fundit e ngarkuar.';

  @override
  String commentsComposerCharsRemaining(int remaining) {
    String _temp0 = intl.Intl.pluralLogic(
      remaining,
      locale: localeName,
      other: 'mbeten $remaining karaktere',
      one: 'mbetet 1 karakter',
    );
    return '$_temp0';
  }

  @override
  String commentsSemanticHideReplies(String name) {
    return 'Fshih përgjigjet për $name';
  }

  @override
  String commentsSemanticViewReplies(String name) {
    return 'Shiko përgjigjet për $name';
  }

  @override
  String get commentsInputHintEdit => 'Përpuno komentin…';

  @override
  String get commentsInputHintAdd => 'Shto një koment…';

  @override
  String get commentsInputHintReply => 'Shkruaj një përgjigje…';

  @override
  String get commentsLikeTooltip => 'Pëlqe komentin';

  @override
  String get commentsUnlikeTooltip => 'Hiq pëlqimin';

  @override
  String get searchModalCancel => 'Anulo';

  @override
  String get searchModalPlaceholder => 'Kërko vendndotje';

  @override
  String get appSmartImageRetry => 'Provo përsëri';

  @override
  String appSmartImageRetryIn(int seconds) {
    return 'Provo përsëri pas $seconds s';
  }

  @override
  String get semanticClose => 'Mbyll';

  @override
  String get pollutionSiteTabTakeAction => 'Ndërmerr veprim';

  @override
  String get reportDescriptionHint => 'Diçka tjetër';

  @override
  String get reportSubmittedFallbackCategory => 'Raport';

  @override
  String get reportSeverityLow => 'E ulët';

  @override
  String get reportSeverityModerate => 'E moderuar';

  @override
  String get reportSeveritySignificant => 'E ndjeshme';

  @override
  String get reportSeverityHigh => 'E lartë';

  @override
  String get reportSeverityCritical => 'Kritike';

  @override
  String get reportDetailViewOnMap => 'Shiko në hartë';

  @override
  String get reportListSearchPlaceholder => 'Kërko raportet e tua';

  @override
  String get reportListSearchHintPrefix =>
      'Kërko sipas titullit, vendndodhjes, kategorisë ose statusit.';

  @override
  String get reportListSearchNoMatches => 'Nuk ka përputhje';

  @override
  String get reportListSearchOneReport => '1 raport';

  @override
  String reportListSearchNReports(int count) {
    return '$count raporte';
  }

  @override
  String get reportListEmptyTitle => 'Ende pa raporte';

  @override
  String get reportListEmptySubtitle =>
      'Raportet e tua do të shfaqen këtu pasi t’i dërgosh.';

  @override
  String get reportStatusUnderReviewShort => 'Në shqyrtim';

  @override
  String get reportStatusApprovedShort => 'Miratuar';

  @override
  String get reportStatusDeclinedShort => 'Refuzuar';

  @override
  String get reportStatusAlreadyReportedShort => 'E raportuar më parë';

  @override
  String get reportListFilterAll => 'Të gjitha';

  @override
  String get reportListOptimisticPill => 'Duke u dërguar…';

  @override
  String get reportListFilterSemanticPrefix => 'Statusi i raportit';

  @override
  String get reportListHeaderTitle => 'Raportet e tua';

  @override
  String reportListHeaderTotalPill(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count raporte gjithsej',
      one: '1 raport gjithsej',
    );
    return '$_temp0';
  }

  @override
  String reportListHeaderUnderReviewPill(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count në shqyrtim',
      one: '1 në shqyrtim',
    );
    return '$_temp0';
  }

  @override
  String reportListHeaderSemanticSummary(int totalReports, int underReview) {
    String _temp0 = intl.Intl.pluralLogic(
      totalReports,
      locale: localeName,
      other: '$totalReports raporte gjithsej',
      one: '1 raport gjithsej',
    );
    String _temp1 = intl.Intl.pluralLogic(
      underReview,
      locale: localeName,
      other: '$underReview aktualisht në shqyrtim',
      one: '1 aktualisht në shqyrtim',
    );
    return '$_temp0. $_temp1.';
  }

  @override
  String get reportListFilteredFooterAll => 'Po shfaqen të gjitha raportet';

  @override
  String reportListFilteredFooterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count raporte',
      one: '1 raport',
    );
    return '$_temp0';
  }

  @override
  String get reportListNoMatchesSearchTitle => 'Nuk u gjetën raporte';

  @override
  String get reportListNoMatchesFilterTitle => 'Nuk ka raporte me këtë filtr';

  @override
  String get reportListNoMatchesHintSearchAndFilter =>
      'Provo një kërkim tjetër ose pastro filtrat për të parë më shumë raporte.';

  @override
  String get reportListNoMatchesHintSearchOnly =>
      'Kontrollo drejtshkrimin ose provo një kërkim më të gjerë.';

  @override
  String get reportListNoMatchesHintFilterOnly =>
      'Provo një filtr tjetër, ose pastroje për të parë të gjitha raportet.';

  @override
  String get reportListClearSearch => 'Pastro kërkimin';

  @override
  String reportListDateWeeksAgo(int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: 'Para $weeks javësh',
      one: 'Para 1 jave',
    );
    return '$_temp0';
  }

  @override
  String get reportDetailOpeningInProgress => 'Po hapet…';

  @override
  String get reportDetailNoPhotos => 'Pa foto';

  @override
  String get reportDetailStatusUnderReviewTitle =>
      'Në shqyrtim nga moderatorët';

  @override
  String get reportDetailStatusUnderReviewBody =>
      'Moderatorët po kontrollojnë provat dhe vendndodhjen para se të vendosin si ta trajtojnë këtë raport.';

  @override
  String get reportDetailStatusApprovedTitle =>
      'Miratuar dhe i lidhur me një vend';

  @override
  String get reportDetailStatusApprovedBody =>
      'Ky raport ndihmoi të konfirmohet një vend publik i ndotur dhe mund të kontribuojë në veprime pastrimi.';

  @override
  String get reportDetailStatusAlreadyReportedTitle =>
      'Tashmë i gjurmuar si vend ekzistues';

  @override
  String get reportDetailStatusAlreadyReportedBody =>
      'Raporti yt përputhet me një vend ekzistues. Provat janë ende të dobishme për të kuptuar problemin.';

  @override
  String get reportDetailStatusOutcomeTitle => 'Rezultati i shqyrtimit';

  @override
  String get reportDetailStatusOutcomeBodyFallback =>
      'Ky raport nuk mund të miratohet në formën e tij aktuale.';

  @override
  String get reportDetailSheetTitle => 'Detajet e raportit';

  @override
  String get reportDetailSheetSubtitle =>
      'Shiko çfarë dërguat dhe si e trajtuan moderatorët këtë raport.';

  @override
  String reportDetailSheetSubtitleWithNumber(String reportNumber) {
    return '$reportNumber · Shiko çfarë dërguat dhe si e trajtuan moderatorët këtë raport.';
  }

  @override
  String get reportDetailPhotoAttachedPill => 'Foto e bashkangjitur';

  @override
  String get reportDetailPointsLabel => 'Pikë';

  @override
  String reportDetailEvidencePhotoSemantic(int index) {
    return 'Foto e provës $index';
  }

  @override
  String get reportDetailEvidenceGalleryOpenSemantic => 'Hap fotot e provës';

  @override
  String get reportDetailEvidenceTapToExpand => 'Prek për zgjerim';

  @override
  String get reportDetailEvidenceOpenPhoto => 'Hap foton';

  @override
  String get reportDetailSiteNotFoundOpeningMaps =>
      'Vendi nuk u gjet. Po hapen hartat.';

  @override
  String get reportDetailSiteNotAvailable => 'Vendi nuk është i disponueshëm.';

  @override
  String get reportDetailCouldNotLoadSite => 'Nuk mund të ngarkohej vendi.';

  @override
  String get reportCardDeclineNoteTitle => 'Shënim shqyrtimi';

  @override
  String reportListFilterChipSemantic(String label, int selected) {
    String _temp0 = intl.Intl.pluralLogic(
      selected,
      locale: localeName,
      other: 'i pa zgjedhur',
      one: 'i zgjedhur',
    );
    return '$label filtri, $_temp0';
  }

  @override
  String reportListFilterChipHint(String label) {
    return 'Prek dy herë për të filtruar raportet sipas $label.';
  }

  @override
  String get reportReviewTitleHint => 'Titull i shkurtër';

  @override
  String get reportFlowCameraUnavailableSnack =>
      'Kamera nuk mund të hapet tani. Provo përsëri pas pak.';

  @override
  String get reportSemanticsLocationPinThenConfirm =>
      'Vendndodhja: vendos pinin, pastaj konfirmo.';

  @override
  String get newReportTooltipAboutStep => 'Rreth këtij hapi';

  @override
  String get newReportTooltipDismiss => 'Mbyll';

  @override
  String get reportFlowSubmitPhaseCreating => 'Po krijohet…';

  @override
  String get reportFlowSubmitPhaseUploading => 'Po ngarkohet…';

  @override
  String get reportFlowSubmitPhaseSubmitting => 'Po dërgohet…';

  @override
  String get reportFormPrimarySemanticsHintSubmit =>
      'Prek dy herë për të dërguar.';

  @override
  String get reportFormPrimarySemanticsHintNext =>
      'Prek dy herë për të kaluar në hapin tjetër.';

  @override
  String reportCardSemanticLabel(
    String category,
    String status,
    String location,
  ) {
    return '$category, $status, $location. Prek për detaje.';
  }

  @override
  String get appSmartImageUnavailable => 'Imazhi nuk është i disponueshëm';

  @override
  String get eventsReminderSectionTitle => 'Kujtues për ngjarjen';

  @override
  String get eventsReminderSectionEnabled => 'Kujtuesi është aktiv';

  @override
  String eventsReminderSectionSetFor(String time) {
    return 'Vendosur për $time';
  }

  @override
  String get eventsReminderSectionDisabled =>
      'Njoftohu para se të fillojë ngjarja';

  @override
  String get eventsReminderSectionDisable => 'Çaktivizo';

  @override
  String get eventsReminderSectionEnable => 'Aktivizo';

  @override
  String get eventsDescriptionTitle => 'Rreth ngjarjes';

  @override
  String get eventsDescriptionShowLess => 'Shfaq më pak';

  @override
  String get eventsDescriptionReadMore => 'Lexo më shumë';

  @override
  String get eventsAfterCleanupTitle => 'Pas pastrimit';

  @override
  String eventsAfterPhotoSemantic(int index, int total) {
    return 'Shfaq foton pas pastrimit $index nga $total';
  }

  @override
  String get eventsFilterAll => 'Të gjitha';

  @override
  String get eventsFilterUpcoming => 'Në pritje';

  @override
  String get eventsFilterNearby => 'Afër';

  @override
  String get eventsFilterPast => 'Të kaluara';

  @override
  String get eventsFilterMyEvents => 'Ngjarjet e mia';

  @override
  String get eventsFilterSemanticPrefix => 'Ngjarje';

  @override
  String get eventsParticipantsTitle => 'Pjesëmarrësit';

  @override
  String eventsParticipantsViewSemantic(int count) {
    return 'Shfaq $count pjesëmarrës';
  }

  @override
  String eventsParticipantsYouAndOthers(int count) {
    return 'Ti dhe edhe $count të tjerë u bashkuat';
  }

  @override
  String eventsParticipantsVolunteersJoined(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vullnetarë u bashkuan',
      one: '1 vullnetar u bashkua',
    );
    return '$_temp0';
  }

  @override
  String eventsParticipantsSpotsLeft(int count) {
    return '$count vende të lira';
  }

  @override
  String eventsParticipantsCheckedInCount(int checkedIn, int total) {
    return '$checkedIn nga $total të regjistruar';
  }

  @override
  String get eventsParticipantsSearchPlaceholder => 'Kërko pjesëmarrës';

  @override
  String get eventsParticipantsNoSearchResults =>
      'Nuk ka përputhje me kërkimin.';

  @override
  String get eventsParticipantsYouOrganizer => 'Ti · Organizator';

  @override
  String get eventsParticipantsOrganizer => 'Organizator';

  @override
  String get eventsParticipantsYou => 'Ti';

  @override
  String get eventsParticipantsLoadFailed =>
      'Nuk u ngarkua lista e pjesëmarrësve. Kontrollo lidhjen dhe provo përsëri.';

  @override
  String get eventsParticipantsRetry => 'Provo përsëri';

  @override
  String get eventsParticipantsViewRosterSemantic =>
      'Shfaq listën e pjesëmarrësve';

  @override
  String get eventsGearSectionTitle => 'Pajisje për t\'u marrë me vete';

  @override
  String get eventsGearNoneNeeded => 'Nuk nevojitet pajisje e veçantë';

  @override
  String get eventsImpactSummaryTitle => 'Përmbledhje e ndikimit';

  @override
  String get eventsImpactSummaryAdd => 'Shto';

  @override
  String get eventsImpactSummaryEdit => 'Ndrysho';

  @override
  String get eventsImpactSummaryEmptyHint =>
      'Shënoni rezultatet dhe mësimet nga pastrimi.';

  @override
  String get eventsLivePulseTitle => 'Ndikimi në kohë reale';

  @override
  String eventsLivePulseVolunteers(int count) {
    return '$count të regjistruar';
  }

  @override
  String eventsLivePulseCheckIns(int count) {
    return '$count check-in';
  }

  @override
  String eventsLivePulseBags(int count, String kg) {
    return '$count thesa · rreth $kg kg';
  }

  @override
  String get eventsEvidenceStripTitle => 'Dëshmi nga fusha';

  @override
  String get eventsEvidenceStripSubtitle =>
      'Foto nga rrjedha e dëshmive të pastrimit.';

  @override
  String get eventsEvidenceStripSemantic =>
      'Foto para, pas dhe nga fusha nga rrjedha e dëshmive';

  @override
  String get eventsEvidenceKindBefore => 'Para';

  @override
  String get eventsEvidenceKindAfter => 'Pas';

  @override
  String get eventsEvidenceKindField => 'Fushë';

  @override
  String eventsEvidenceStripTileSemantic(int index, int total, String kind) {
    return 'Foto $index nga $total, $kind';
  }

  @override
  String get eventsRouteProgressTitle => 'Rruga';

  @override
  String eventsFieldModeRowServerError(String code) {
    return 'Serveri: $code';
  }

  @override
  String get eventsFieldModeTitle => 'Modaliteti fushë';

  @override
  String get eventsFieldModeSync => 'Sinkronizo tani';

  @override
  String get eventsFieldModeEmpty => 'Asgjë në radhë jashtë linje.';

  @override
  String get eventsFieldModeSynced => 'Radha u sinkronizua.';

  @override
  String get eventsFieldModeSyncFailed =>
      'Sinkronizimi dështoi. Provoni përsëri.';

  @override
  String eventsFieldModeSyncPartial(int synced, int failed) {
    return 'U sinkronizuan $synced përditësime. $failed ende janë në radhë jashtë linje.';
  }

  @override
  String eventsFieldModeRowLiveImpactBags(int count) {
    return 'Ndikim në kohë reale · $count thesa';
  }

  @override
  String get eventsFieldModeRowUnknown => 'Ndryshim jashtë linje';

  @override
  String get eventsFieldModeRowStatusPending => 'Në pritje';

  @override
  String get eventsFieldModeRowStatusSyncing => 'Duke u sinkronizuar';

  @override
  String get eventsOfflineWorkHubTitle => 'Punë jashtë linje';

  @override
  String get eventsOfflineWorkHubSemanticSheet =>
      'Përmbledhje e punës jashtë linje dhe veprime sinkronizimi';

  @override
  String get eventsOfflineWorkSubtitle =>
      'Ndryshime në radhë për check-in, përditësime në terren dhe bisedë.';

  @override
  String get eventsOfflineWorkSectionCheckIns => 'Check-in';

  @override
  String get eventsOfflineWorkSectionField => 'Përditësime në terren';

  @override
  String get eventsOfflineWorkSectionChat => 'Bisedë';

  @override
  String eventsOfflineWorkCountPending(int count) {
    return '$count në pritje';
  }

  @override
  String eventsOfflineWorkCountFailed(int count) {
    return '$count kërkojnë vëmendje';
  }

  @override
  String get eventsOfflineWorkSyncNow => 'Sinkronizo tani';

  @override
  String get eventsOfflineWorkOpenFieldQueue => 'Hap radhën e terrenit';

  @override
  String get eventsOfflineWorkOpenChat => 'Hap bisedën e ngjarjes';

  @override
  String get eventsOfflineWorkRetryFailedChat =>
      'Riprovo dërgimin e mesazheve të dështuara';

  @override
  String get eventsOfflineWorkResolveInChat =>
      'Hap bisedën dhe korrigjo ose fshi mesazhin që nuk u dërgua dot.';

  @override
  String get eventsOfflineWorkSyncDone => 'Sinkronizimi përfundoi';

  @override
  String get eventsOfflineWorkSyncing => 'Duke u sinkronizuar…';

  @override
  String get eventsOfflineWorkDrainFailed =>
      'Nuk e përfunduam dot sinkronizimin. Provo përsëri kur të jesh në linjë.';

  @override
  String eventsChatOutboxFull(int max) {
    return 'Shumë mesazhe presin dërgim jashtë linje (limiti $max). Lidhu për t’i dërguar mesazhet në pritje, pastaj provo përsëri.';
  }

  @override
  String get eventsCompletedBagsSectionTitle =>
      'Thesa me mbeturina të mbledhura';

  @override
  String get eventsCompletedBagsSave => 'Ruaj';

  @override
  String get eventsCompletedBagsSaved => 'Numri i thesave u ruajt.';

  @override
  String eventsImpactBadgeRating(int rating) {
    return '$rating★ vlerësim';
  }

  @override
  String eventsImpactBadgeBags(int count) {
    return '$count thesa';
  }

  @override
  String eventsImpactBadgeHours(String hours) {
    return '${hours}orë';
  }

  @override
  String eventsImpactEstimatedLine(String kg, String co2) {
    return '$kg kg hequr · $co2 kg CO2e të shmangura';
  }

  @override
  String eventsLocationSiteSemantic(String distanceKm) {
    return 'Shfaq vendndodhjen e ndotjes, $distanceKm km larg';
  }

  @override
  String eventsLocationDotKm(String distanceKm) {
    return '· $distanceKm km';
  }

  @override
  String get eventsEmptyAllTitle => 'Ende nuk ka ngjarje mjedisore';

  @override
  String get eventsEmptyAllSubtitle =>
      'Bëhu i pari që krijon një! Prek + sipër për të filluar.';

  @override
  String get eventsEmptyUpcomingTitle => 'Nuk ka ngjarje të ardhshme';

  @override
  String get eventsEmptyUpcomingSubtitle =>
      'Krijo një për të mbledhur vullnetarët.';

  @override
  String get eventsEmptyNearbyTitle => 'Nuk ka ngjarje afër';

  @override
  String get eventsEmptyNearbySubtitle =>
      'Provo një filtër tjetër ose krijo një ngjarje në zonën tënde.';

  @override
  String get eventsEmptyPastTitle => 'Nuk ka ngjarje të kaluara';

  @override
  String get eventsEmptyPastSubtitle =>
      'Ngjarjet e përfunduara do të shfaqen këtu.';

  @override
  String get eventsEmptyMyEventsTitle => 'Ende nuk ka ngjarje';

  @override
  String get eventsEmptyMyEventsSubtitle =>
      'Bashkohu ose krijo një ngjarje për ta parë këtu.';

  @override
  String eventsSearchEmptyTitle(String query) {
    return 'Nuk ka rezultate për \"$query\"';
  }

  @override
  String get eventsSearchEmptySubtitle =>
      'Provo një fjalë tjetër kërkimi ose kontrollo drejtshkrimin.';

  @override
  String get eventsSearchEmptyScopeHint =>
      'Rezultatet vijnë nga serveri gjatë shkrimit dhe nga ngjarjet tashmë të ngarkuara në këtë listë.';

  @override
  String get eventsSitePickerTitle => 'Zgjidh vendndodhjen';

  @override
  String get eventsSitePickerSubtitle =>
      'Lidhe këtë ngjarje me një vend pastrimi.';

  @override
  String get eventsSitePickerSearchPlaceholder =>
      'Kërko sipas emrit ose përshkrimit';

  @override
  String eventsSitePickerNoMatch(String query) {
    return 'Nuk ka vende që përputhen me \"$query\"';
  }

  @override
  String eventsSitePickerRowKmDesc(String km, String desc) {
    return '$km km larg · $desc';
  }

  @override
  String get eventsSuccessDialogTitle => 'Ngjarja u krijua';

  @override
  String eventsSuccessDialogBody(String title, String siteName) {
    return '$title në $siteName është gati. Ndaje me komunitetin për të mbledhur vullnetarë.';
  }

  @override
  String get eventsSuccessDialogOpenEvent => 'Hap ngjarjen';

  @override
  String get eventsSuccessDialogViewEvent => 'Shiko ngjarjen';

  @override
  String get eventsSuccessDialogPendingTitle => 'Dërguar për shqyrtim';

  @override
  String eventsSuccessDialogPendingBody(String title, String siteName) {
    return '$title në $siteName u dërgua. Një moderator do ta miratojë ose refuzojë para se të shfaqet publikisht. Mund ta hapësh nga ngjarjet e tua në çdo kohë.';
  }

  @override
  String get eventsTimePickerSelectTime => 'Zgjidh orën';

  @override
  String get eventsTimePickerConfirm => 'Konfirmo';

  @override
  String get eventsTimePickerFrom => 'Nga';

  @override
  String get eventsTimePickerTo => 'Deri';

  @override
  String eventsTimePickerTimeBlockSemantic(String role, String time) {
    return '$role, $time';
  }

  @override
  String eventsFeedbackRatingStars(int rating) {
    return '$rating★';
  }

  @override
  String get eventsFeedRecentSearches => 'Kërkimet e fundit';

  @override
  String get eventsCleanupAfterUploadSemantic => 'Ngarko foto pas pastrimit';

  @override
  String get eventsCleanupAfterViewFullscreenSemantic =>
      'Shfaq foton në ekran të plotë';

  @override
  String get eventsCleanupAfterUploadMoreTitle => 'Ngarko më shumë foto';

  @override
  String eventsCleanupAfterUploadedCount(int count) {
    return '$count të ngarkuara';
  }

  @override
  String eventsCleanupAfterSlotsRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Edhe $count vende të lira',
      one: 'Edhe 1 vend i lirë',
    );
    return '$_temp0';
  }

  @override
  String get eventsCleanupAfterAddMoreSemantic => 'Shto më shumë foto';

  @override
  String get eventsCleanupAfterRemoveSemantic => 'Hiq foton';

  @override
  String get eventsCleanupAfterEmptyTitle => 'Shto foto të vendit të pastruar';

  @override
  String eventsCleanupAfterEmptyMaxPhotos(int max) {
    return 'Deri në $max foto';
  }

  @override
  String get eventsCleanupAfterEmptyTapGallery =>
      'Prek për të zgjedhur nga galeria';

  @override
  String get eventsCleanupEvidencePhotoSemantic => 'Foto e provës së pastrimit';

  @override
  String get eventsDateRelativeEarlierToday => 'Më herët sot';

  @override
  String eventsDateRelativeDaysAgo(int days) {
    return '$days ditë më parë';
  }

  @override
  String get eventsDateRelativeToday => 'Sot';

  @override
  String get eventsDateRelativeTomorrow => 'Nesër';

  @override
  String eventsDateRelativeInDays(int days) {
    return 'Pas $days ditësh';
  }

  @override
  String get eventsDateInfoSheetTitle => 'Data dhe ora';

  @override
  String eventsDateInfoSemantic(String date, String timeRange) {
    return '$date, $timeRange';
  }

  @override
  String get eventsCategorySheetTitle => 'Kategoria';

  @override
  String eventsCategorySemantic(String label) {
    return 'Kategoria e ngjarjes: $label';
  }

  @override
  String get eventsOrganizerSheetTitle => 'Organizatori';

  @override
  String get eventsOrganizerYouOwnThis => 'Kjo është ngjarja jote';

  @override
  String get eventsOrganizerRoleLabel => 'Organizator i ngjarjes';

  @override
  String eventsOrganizerCreatedOn(int day, int month, int year) {
    return 'Ngjarja u krijua më $day/$month/$year';
  }

  @override
  String eventsOrganizerSemantic(String name) {
    return 'Organizatori: $name';
  }

  @override
  String get eventsOrganizedByLabel => 'Organizuar nga';

  @override
  String get eventsFeedSemantic => 'Lista e ngjarjeve';

  @override
  String get eventsFeedTitle => 'Ngjarje';

  @override
  String get eventsFeedCreateSemantic => 'Krijo ngjarje';

  @override
  String get eventsFeedSearchPlaceholder => 'Kërko ngjarje';

  @override
  String get eventsFeedHappeningNow => 'Në zhvillim';

  @override
  String get eventsFeedComingUp => 'Në vijim';

  @override
  String get eventsFeedRecentlyCompleted => 'Përfunduar së fundmi';

  @override
  String get eventsFeedViewListToggle => 'Pamje listë';

  @override
  String get eventsFeedViewCalendarToggle => 'Pamje kalendar';

  @override
  String get eventsCalendarPreviousMonth => 'Muaji i kaluar';

  @override
  String get eventsCalendarNextMonth => 'Muaji tjetër';

  @override
  String eventsCalendarDaySemantic(int day) {
    return 'Dita $day';
  }

  @override
  String get eventsCalendarNoEventsThisDay => 'Nuk ka ngjarje këtë ditë';

  @override
  String get eventsCalendarIncompleteListHint =>
      'Mund të ketë më shumë ngjarje. Ngarko faqen tjetër për këtë muaj.';

  @override
  String get eventsCalendarLoadMoreButton => 'Ngarko më shumë';

  @override
  String eventsCalendarDayA11yOutOfMonth(int day) {
    return 'Dita $day, jo në këtë muaj';
  }

  @override
  String eventsCalendarDayA11y(int day) {
    return 'Dita $day';
  }

  @override
  String eventsCalendarDayA11yHasEvents(int day) {
    return 'Dita $day, ka ngjarje';
  }

  @override
  String eventsCalendarDayA11ySelected(int day) {
    return 'Dita $day, e zgjedhur';
  }

  @override
  String eventsCalendarDayA11ySelectedHasEvents(int day) {
    return 'Dita $day, e zgjedhur, ka ngjarje';
  }

  @override
  String get eventsEmptyActionClearFilters => 'Pastro filtrat';

  @override
  String get eventsEmptyActionCreateEvent => 'Krijo ngjarje';

  @override
  String get eventsSearchEmptyClearSearch => 'Pastro kërkimin';

  @override
  String siteCardPollutionSiteSemantic(String title) {
    return 'Vend i ndotur: $title. Prek për detaje.';
  }

  @override
  String siteCardPhotoSemantic(String title) {
    return 'Foto e $title';
  }

  @override
  String siteCardGalleryPhotoSemantic(int number, String siteTitle) {
    return 'Fotoja $number e $siteTitle';
  }

  @override
  String siteCardSemanticRemoveUpvote(String title) {
    return 'Hiq mbështetjen për $title';
  }

  @override
  String siteCardSemanticUpvote(String title) {
    return 'Mbështet $title';
  }

  @override
  String get siteUpvoteLongPressOpensSupporters =>
      'Shtyp gjatë për listën e mbështetësve';

  @override
  String siteCardSemanticUpvotesOpenSupporters(int count, String title) {
    return '$count mbështetje për $title. Prek për mbështetësit';
  }

  @override
  String siteCardSemanticCommentsOnSite(int count, String title) {
    return '$count komente për $title';
  }

  @override
  String siteCardSemanticSharesOnSite(int count, String title) {
    return '$count ndarje për $title';
  }

  @override
  String siteCardSemanticSaveSite(String title) {
    return 'Ruaj $title dhe merr përditësime';
  }

  @override
  String siteCardSemanticUnsaveSite(String title) {
    return 'Hiq $title nga të ruajturat';
  }

  @override
  String get siteCardSaveUpdatesOnSnack =>
      'Do të marrësh përditësime për këtë vend';

  @override
  String get siteCardSaveRemovedSnack => 'U hoq nga vendet e ruajtura';

  @override
  String get siteCardFeedbackPostHiddenSnack =>
      'Postimi u fsheh nga rrjedha jote';

  @override
  String get siteCardFeedbackThanksSnack => 'Faleminderit për reagimin';

  @override
  String get siteCardFeedOptionsSheetTitle => 'Opsione të rrjedhës';

  @override
  String get siteCardFeedOptionsSheetSubtitle =>
      'Përshtat çfarë dëshiron të shohësh';

  @override
  String get siteCardEngagementSignInRequired =>
      'Hyr për të mbështetur ose ruajtur vende.';

  @override
  String get siteCardEngagementWaitBriefly =>
      'Prit pak para se të provosh përsëri.';

  @override
  String siteCardRateLimitedSnack(int seconds) {
    return 'Shumë veprime. Provo përsëri pas $seconds sekondash.';
  }

  @override
  String get siteDetailSaveAddedSnack => 'Vendi u ruajt në listën tënde.';

  @override
  String get siteDetailSaveRemovedSnack => 'U hoq nga të ruajturat.';

  @override
  String get siteQuickActionSaveSiteLabel => 'Ruaje vendin';

  @override
  String get siteQuickActionSavedLabel => 'E ruajtur';

  @override
  String get siteQuickActionReportIssueLabel => 'Raporto problem';

  @override
  String get siteQuickActionReportedLabel => 'E raportuar';

  @override
  String get siteQuickActionShareLabel => 'Ndaj';

  @override
  String siteCardDistanceMeters(int meters) {
    return '$meters m';
  }

  @override
  String siteCardDistanceKmShort(String km) {
    return '$km km';
  }

  @override
  String siteCardDistanceKmWhole(String km) {
    return '$km km';
  }

  @override
  String get eventsFilterSheetTitle => 'Filtro ngjarjet';

  @override
  String get eventsFilterSheetCategory => 'Kategoria';

  @override
  String get eventsFilterSheetStatus => 'Statusi';

  @override
  String get eventsFilterSheetDateRange => 'Periudha e datës';

  @override
  String get eventsFilterSheetDateFrom => 'Nga';

  @override
  String get eventsFilterSheetDateTo => 'Deri';

  @override
  String get eventsFilterSheetShowResults => 'Shfaq rezultatet';

  @override
  String get eventsFilterSheetClearAll => 'Fshi të gjitha';

  @override
  String eventsFilterSheetActiveCount(int count) {
    return '$count aktive';
  }

  @override
  String get eventsOrganizerDashboardTitle => 'Ngjarjet e mia';

  @override
  String get eventsOrganizerDashboardEmpty =>
      'Nuk keni organizuar asnjë ngjarje ende.';

  @override
  String get eventsOrganizerDashboardEmptyAction => 'Krijo ngjarjen e parë';

  @override
  String get eventsOrganizerDashboardSectionUpcoming => 'Të ardhshme';

  @override
  String get eventsOrganizerDashboardSectionInProgress => 'Në progres';

  @override
  String get eventsOrganizerDashboardSectionCompleted => 'Të përfunduara';

  @override
  String get eventsOrganizerDashboardSectionCancelled => 'Të anuluara';

  @override
  String eventsOrganizerDashboardParticipants(int count, String max) {
    return '$count/$max pjesëmarrës';
  }

  @override
  String eventsOrganizerDashboardParticipantsUnlimited(int count) {
    return '$count pjesëmarrës';
  }

  @override
  String get eventsOrganizerDashboardEvidenceAction => 'Provat';

  @override
  String get eventsAnalyticsTitle => 'Analitika';

  @override
  String get eventsAnalyticsAttendanceRate => 'Shkalla e prezencës';

  @override
  String get eventsAnalyticsJoiners => 'Pjesëmarrësit me kalimin e kohës';

  @override
  String get eventsAnalyticsCheckInsByHour => 'Regjistrimet sipas orës';

  @override
  String get eventsAnalyticsNoData => 'Nuk ka të dhëna ende';

  @override
  String get eventsAnalyticsRefresh => 'Rifresko analitikën';

  @override
  String eventsAnalyticsCheckedInRatio(int checkedInCount, int totalJoiners) {
    return '$checkedInCount nga $totalJoiners u regjistruan';
  }

  @override
  String get eventsAnalyticsJoinersEmpty =>
      'Asnjëri nuk është bashkuar ende me këtë ngjarje.';

  @override
  String get eventsAnalyticsCheckInsEmpty =>
      'Ende nuk ka regjistrime. Orët janë në UTC.';

  @override
  String eventsAnalyticsPeakCheckInsUtc(String hour) {
    return 'Piku: $hour UTC';
  }

  @override
  String eventsAnalyticsSemanticsJoinCurve(
    int fromCount,
    int toCount,
    int steps,
  ) {
    return 'Trendi i bashkimeve nga $fromCount në $toCount pjesëmarrës, $steps pika të dhënash.';
  }

  @override
  String eventsAnalyticsSemanticsCheckInHeatmap(int peakCount, String hour) {
    return 'Regjistrimet sipas orës në UTC. Piku $peakCount në $hour.';
  }

  @override
  String get eventsAnalyticsSemanticsCheckInNoData =>
      'Regjistrimet sipas orës në UTC. Nuk ka regjistrime.';

  @override
  String get eventsOfflineSyncQueued =>
      'Ruajtur. Do të sinkronizohet kur të lidheni.';

  @override
  String get eventsOfflineSyncFailed =>
      'Sinkronizimi dështoi. Do të provohet automatikisht.';

  @override
  String get eventsWeatherForecast => 'Parashikimi i motit';

  @override
  String get eventsWeatherLoadFailed => 'Moti nuk është i disponueshëm';

  @override
  String eventsWeatherPrecipitationMm(String amount) {
    return '$amount mm reshje';
  }

  @override
  String get eventsWeatherNoPrecipitation => 'Pa reshje të matshme';

  @override
  String eventsWeatherPrecipChance(int percent) {
    return '$percent% mundësi reshjeje';
  }

  @override
  String get eventsWeatherIndicativeNote =>
      'Parashikim orientues nga Open-Meteo; kushtet reale mund të ndryshojnë.';

  @override
  String get eventsWeatherIndicativeInfoTitle => 'Rreth parashikimit';

  @override
  String get eventsWeatherIndicativeInfoSemantic =>
      'Informacion mbi burimin e parashikimit të motit';

  @override
  String get eventsRecurrenceNone => 'Nuk përsëritet';

  @override
  String get eventsRecurrenceWeekly => 'Çdo javë';

  @override
  String get eventsRecurrenceBiweekly => 'Çdo 2 javë';

  @override
  String get eventsRecurrenceMonthly => 'Çdo muaj';

  @override
  String eventsRecurrenceOccurrences(int count) {
    return '$count ndodhje';
  }

  @override
  String get eventsRecurrencePartOfSeries => 'Pjesë e serisë';

  @override
  String eventsRecurrenceSeriesLabel(int index, int total) {
    return 'Ngjarje $index nga $total';
  }

  @override
  String get eventsRecurrenceDone => 'Në rregull';

  @override
  String get eventsCategoryGeneralCleanup => 'Pastrim i përgjithshëm';

  @override
  String get eventsCategoryGeneralCleanupDescription =>
      'Mbledhje mbeturinash, fshesë dhe rikthim i zonës në rregull.';

  @override
  String get eventsCategoryRiverAndLake => 'Pastrim lumenjsh dhe liqenesh';

  @override
  String get eventsCategoryRiverAndLakeDescription =>
      'Heqje mbeturinash nga uji, brigjet dhe kanalet.';

  @override
  String get eventsCategoryTreeAndGreen => 'Mbjellje pemësh dhe gjelbërim';

  @override
  String get eventsCategoryTreeAndGreenDescription =>
      'Mbjellje pemësh, rikthim hapësirash të gjelbra dhe kopshte.';

  @override
  String get eventsCategoryRecyclingDrive => 'Fushatë riciklimi';

  @override
  String get eventsCategoryRecyclingDriveDescription =>
      'Ndaj, mblidh dhe transporto riciklim në përpunim.';

  @override
  String get eventsCategoryHazardousRemoval =>
      'Heqje mbeturinash të rrezikshme';

  @override
  String get eventsCategoryHazardousRemovalDescription =>
      'Mbledhje e sigurt e kimikateve, gomave, baterive ose azbestit.';

  @override
  String get eventsCategoryAwarenessAndEducation => 'Ndërgjegjësim dhe edukim';

  @override
  String get eventsCategoryAwarenessAndEducationDescription =>
      'Seminare, biseda ose angazhim komuniteti për praktika ekologjike.';

  @override
  String get eventsCategoryOther => 'Tjetër';

  @override
  String get eventsCategoryOtherDescription =>
      'Ngjarje e personalizuar që nuk përputhet me kategoritë e mësipërme.';

  @override
  String get eventsGearTrashBags => 'Thesa mbeturinash';

  @override
  String get eventsGearGloves => 'Doreza';

  @override
  String get eventsGearRakes => 'Kratre dhe lopata';

  @override
  String get eventsGearWheelbarrow => 'Karrocë';

  @override
  String get eventsGearWaterBoots => 'Çizme uji';

  @override
  String get eventsGearSafetyVest => 'Jelek reflektues';

  @override
  String get eventsGearFirstAid => 'Kit i ndihmës së parë';

  @override
  String get eventsGearSunscreen => 'Krem dielli dhe ujë';

  @override
  String get eventsScaleSmall => 'E vogël (1–5 vetë)';

  @override
  String get eventsScaleSmallDescription =>
      'Pastrim i shpejtë në një vend, një ose dy thesa.';

  @override
  String get eventsScaleMedium => 'E mesme (6–15 vetë)';

  @override
  String get eventsScaleMediumDescription =>
      'Përpjekje gjysmë-ditore, disa zona.';

  @override
  String get eventsScaleLarge => 'E madhe (16–40 vetë)';

  @override
  String get eventsScaleLargeDescription =>
      'Grup i organizuar, mbeturina të rënda.';

  @override
  String get eventsScaleMassive => 'Masive (40+ vetë)';

  @override
  String get eventsScaleMassiveDescription =>
      'Aksion në shkallë qyteti ose shumë vendndodhje.';

  @override
  String get eventsDifficultyEasy => 'E lehtë';

  @override
  String get eventsDifficultyEasyDescription =>
      'Terren i sheshtë, pak mbeturina, miqësore për familje.';

  @override
  String get eventsDifficultyModerate => 'E mesme';

  @override
  String get eventsDifficultyModerateDescription =>
      'Terren i përzier ose objekte të mëdha, pak më shumë përpjekje.';

  @override
  String get eventsDifficultyHard => 'E vështirë';

  @override
  String get eventsDifficultyHardDescription =>
      'Përrua të pjerrëta, mbeturina të rënda ose materiale të rrezikshme.';

  @override
  String get eventsSiteCoercedDescription => 'Vend i pastrimit komunitar';

  @override
  String get homeSiteCleaningEmptyTitle => 'Ende nuk ka ngjarje pastrimi';

  @override
  String get homeSiteCleaningEmptyBody =>
      'Jini i pari që organizoni një veprim ekologjik dhe mblidhni vullnetarë për këtë vend.';

  @override
  String get homeSiteCleaningTapToCreate => 'Prekni për të krijuar';

  @override
  String get homeSiteCleaningCtaCreateFirst => 'Krijo veprim ekologjik';

  @override
  String get homeSiteCleaningCtaScheduleAnother =>
      'Planifiko një veprim tjetër';

  @override
  String homeSiteCleaningVolunteersJoined(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vullnetarë u bashkuan',
      one: '1 vullnetar u bashkua',
    );
    return '$_temp0';
  }

  @override
  String get homeSiteCleaningOrganizerHint =>
      'Ju e organizoni këtë veprim. Ngarkoni foto \"pas\" sapo të përfundojë.';

  @override
  String get homeSiteCleaningVolunteerHint =>
      'Bashkohuni me veprimin për të ndihmuar në pastrimin e këtij vendi.';

  @override
  String get homeSiteCleaningJoinAction => 'Bashkohu';

  @override
  String get homeSiteCleaningEventUnavailable =>
      'Detajet e ngjarjes nuk janë të disponueshme për momentin.';

  @override
  String get homeSiteCleaningListLoadError =>
      'Nuk u ngarkuan ngjarjet. Kontrollo lidhjen dhe provo përsëri.';

  @override
  String get homeSiteCleaningRetry => 'Riprovo';

  @override
  String get homeSiteCleaningLoadingSemantic =>
      'Po ngarkohen veprimet ekologjike.';

  @override
  String get eventsDistanceLessThan100m => '<100 m';

  @override
  String eventsDistanceMeters(int meters) {
    return '$meters m';
  }

  @override
  String eventsDistanceKilometers(String km) {
    return '$km km';
  }

  @override
  String get errorUserNetwork => 'Kontrolloni lidhjen dhe provoni përsëri.';

  @override
  String get errorUserTimeout => 'Zgjati shumë. Provoni përsëri.';

  @override
  String get errorUserUnauthorized => 'Hyni përsëri për të vazhduar.';

  @override
  String get errorUserForbidden => 'Nuk keni leje për këtë veprim.';

  @override
  String get errorUserNotFound => 'Nuk e gjetëm.';

  @override
  String get errorUserServer =>
      'Shërbimi është i ngarkuar. Provoni së shpejti.';

  @override
  String get errorUserTooManyRequests => 'Shumë përpjekje. Prisni pak.';

  @override
  String get errorUserUnknown => 'Diçka shkoi keq. Provoni përsëri.';

  @override
  String get eventsFilterSheetSemantic => 'Filtro ngjarjet';

  @override
  String get eventChatTitle => 'Biseda';

  @override
  String get eventChatRowTitle => 'Bisedë në grup';

  @override
  String get eventChatInputHint => 'Mesazh';

  @override
  String get eventChatSend => 'Dërgo';

  @override
  String get eventChatEmptyTitle => 'Filloni bisedën';

  @override
  String get eventChatEmptyBody =>
      'Koordinohuni me vullnetarët e tjerë para dhe gjatë ngjarjes.';

  @override
  String get eventChatMessageRemoved => 'Ky mesazh u hoq';

  @override
  String get eventChatNewMessages => 'Mesazhe të reja';

  @override
  String get eventChatToday => 'Sot';

  @override
  String get eventChatYesterday => 'Dje';

  @override
  String get eventChatReply => 'Përgjigju';

  @override
  String get eventChatDelete => 'Fshi';

  @override
  String get eventChatLoadError => 'Nuk u ngarkuan mesazhet';

  @override
  String get eventChatSendFailed =>
      'Mesazhi nuk u dërgua. Prekni për të riprovuar.';

  @override
  String get eventChatOpenMapsFailed =>
      'Nuk mund të hapja Hartat. Provo përsëri.';

  @override
  String get eventChatAttachPhotoLibrary => 'Biblioteka e fotove';

  @override
  String get eventChatAttachCamera => 'Kamera';

  @override
  String get eventChatAttachVideo => 'Video';

  @override
  String get eventChatAttachDocument => 'Dokument';

  @override
  String get eventChatAttachAudio => 'Audio';

  @override
  String get eventChatVoiceDiscard => 'Hidh regjistrimin';

  @override
  String get eventChatVoiceSend => 'Dërgo mesazh zanor';

  @override
  String get eventChatVoicePreviewHint => 'Parapamje zanore';

  @override
  String get eventChatAttachLocation => 'Ndaj vendndodhjen';

  @override
  String get eventChatSendLocation => 'Dërgo vendndodhjen';

  @override
  String get eventChatSending => 'Po dërgohet…';

  @override
  String eventChatReplyingTo(String name) {
    return 'Duke iu përgjigjur $name';
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
  String get eventChatInputSemantics => 'Mesazh në bisedë';

  @override
  String get eventChatMessagesListSemantics => 'Lista e mesazheve';

  @override
  String get eventChatAttachmentsNeedNetwork =>
      'Fotot, video, skedarët dhe zëri kërkojnë lidhje me internetin.';

  @override
  String get eventChatPushChannelName => 'Bisedë e ngjarjes';

  @override
  String get eventChatEdited => '(e redaktuar)';

  @override
  String get eventChatEditMessage => 'Redakto';

  @override
  String get eventChatEditing => 'Duke redaktuar mesazhin';

  @override
  String get eventChatEditHint => 'Redaktoni mesazhin tuaj';

  @override
  String get eventChatSaveEdit => 'Ruaj';

  @override
  String get eventChatPinMessage => 'Fikso';

  @override
  String get eventChatUnpinMessage => 'Hiq fiksimin';

  @override
  String eventChatPinnedBy(String name) {
    return 'Fiksuar nga $name';
  }

  @override
  String get eventChatPinnedMessagesTitle => 'Mesazhe të fiksuar';

  @override
  String get eventChatPinnedBarHint => 'Fiksuar';

  @override
  String get eventChatNoPinnedMessages => 'Nuk ka mesazhe të fiksuar';

  @override
  String get eventChatMuted => 'Njoftimet janë çaktivizuar';

  @override
  String get eventChatUnmuted => 'Njoftimet janë aktivizuar';

  @override
  String get eventChatCopied => 'Mesazhi u kopjua';

  @override
  String get eventChatReconnecting => 'Duke u rilidhur…';

  @override
  String get eventChatConnected => 'I lidhur';

  @override
  String get eventChatSearchHint => 'Kërko mesazhe';

  @override
  String get eventChatSearchNoResults => 'Nuk ka mesazhe që përputhen';

  @override
  String get eventChatSearchAction => 'Kërko';

  @override
  String get eventChatSearchFailed =>
      'Kërkimi dështoi. Kontrollo lidhjen dhe provo përsëri.';

  @override
  String get eventChatSearchMinChars =>
      'Shkruaj të paktën 2 karaktere për të kërkuar.';

  @override
  String get eventChatSearchIncludingLocalMatches =>
      'Përfshin mesazhe të ngarkuara në këtë pajisje.';

  @override
  String get eventChatSearchLoadMore => 'Ngarko më shumë rezultate';

  @override
  String eventChatParticipantsCount(int count) {
    return '$count pjesëmarrës';
  }

  @override
  String get eventChatParticipantsSheetTitle => 'Persona në këtë bisedë';

  @override
  String eventChatParticipantsTitleSemantic(String eventTitle, int count) {
    return '$eventTitle, $count pjesëmarrës';
  }

  @override
  String get eventChatParticipantsLoadError => 'Nuk u ngarkuan pjesëmarrësit.';

  @override
  String get eventChatParticipantsYouBadge => 'Ju';

  @override
  String get eventChatParticipantsEmpty =>
      'Ende nuk ka pjesëmarrës të ngarkuar.';

  @override
  String eventChatSystemUserJoined(String name) {
    return '$name u bashkua me ngjarjen';
  }

  @override
  String eventChatSystemUserLeft(String name) {
    return '$name e la ngjarjen';
  }

  @override
  String get eventChatSystemEventUpdated => 'Detajet e ngjarjes u përditësuan';

  @override
  String get eventChatSwipeReplySemantic =>
      'Rrëshqit për t’iu përgjigjur mesazhit';

  @override
  String get eventChatVoiceLevelSemantic => 'Niveli i zërit';

  @override
  String get eventChatMessageOptions => 'Opsionet e mesazhit';

  @override
  String get eventChatTypingUnknownParticipant => 'Dikush';

  @override
  String get eventChatCopy => 'Kopjo';

  @override
  String get eventChatUnpinConfirm => 'Mesazhi u hoq nga fiksimet';

  @override
  String get eventChatMaxPinnedReached =>
      'U arrit numri maksimal i mesazheve të fiksuar';

  @override
  String get eventChatMessageNotInView =>
      'Ky mesazh nuk është ngarkuar. Rrëshqitni lart për mesazhe më të vjetra.';

  @override
  String get eventChatMuteNotifications => 'Çaktivizo njoftimet';

  @override
  String get eventChatUnmuteNotifications => 'Aktivizo njoftimet';

  @override
  String eventChatSeenBy(String names) {
    return 'Parë nga $names';
  }

  @override
  String eventChatSeenByTruncated(String names, int count) {
    return 'Parë nga $names +$count';
  }

  @override
  String eventChatTypingOne(String name) {
    return '$name po shkruan…';
  }

  @override
  String eventChatTypingTwo(String first, String second) {
    return '$first dhe $second po shkruajnë…';
  }

  @override
  String eventChatTypingMany(String name, int count) {
    return '$name dhe $count të tjerë po shkruajnë…';
  }

  @override
  String get eventChatImageViewerTitle => 'Foto';

  @override
  String eventChatImageViewerPage(int current, int total) {
    return '$current nga $total';
  }

  @override
  String get eventChatVideoViewerTitle => 'Video';

  @override
  String get eventChatOpenFile => 'Hap skedarin';

  @override
  String get eventChatDownloadFailed => 'Shkarkimi i skedarit dështoi';

  @override
  String get eventChatPdfOpenFailed => 'Nuk mund të hapet PDF-ja';

  @override
  String get eventChatShareFile => 'Ndaj';

  @override
  String get eventChatLocationMapTitle => 'Vendndodhja';

  @override
  String get eventChatCopyCoordinates => 'Kopjo koordinatat';

  @override
  String get eventChatDirections => 'Drejtime';

  @override
  String get eventChatAudioExpandedTitle => 'Mesazh zanor';

  @override
  String get eventChatHoldToRecord => 'Mbaj shtypur për të regjistruar';

  @override
  String get eventChatReleaseToSend => 'Lësho për të dërguar';

  @override
  String get eventChatSlideToCancel => 'Tërhiqe majtas për të anuluar';

  @override
  String get eventChatReleaseToCancel => 'Lësho për të anuluar';

  @override
  String get eventChatRecording => 'Duke regjistruar…';

  @override
  String get eventChatMicPermissionDenied =>
      'Nevojitet qasja në mikrofon për mesazhet zanore.';

  @override
  String get reportEntryLabelGuided => 'Raport i udhëhequr';

  @override
  String get reportEntryLabelCamera => 'Raport nga kamera';

  @override
  String get reportEntryHintCamera =>
      'Nëse fillon me një foto të drejtpërdrejtë, moderimi zakonisht është më i shpejtë sepse prova është tashmë e bashkangjitur.';

  @override
  String get homeReportingCapacityCheckFailed =>
      'Nuk mund të kontrollohet disponueshmëria e raportimit tani.';

  @override
  String get homeCameraOpenFailed =>
      'Kamera nuk mund të hapet. Provo përsëri pas një çasti.';

  @override
  String get mapTabPlaceholderHint =>
      'Hap këtë skedë për të ngarkuar hartën live dhe vendet e ndotjes afër.';

  @override
  String get reportCategoryPickerTitle => 'Zgjidh kategorinë';

  @override
  String get reportCategoryPickerSubtitle =>
      'Zgjidh përputhjen më të afërt me problemin që raporton.';

  @override
  String get reportCategoryPickerBannerTitle => 'Zgjidh përputhjen më të afërt';

  @override
  String get reportCategoryPickerBannerBody =>
      'Zgjidh kategorinë që moderatorët duhet ta verifikojnë së pari. Nuk duhet të jetë perfekte.';

  @override
  String get reportCategoryIllegalLandfillTitle => 'Deponi e paligjshme';

  @override
  String get reportCategoryIllegalLandfillDescription =>
      'Mbeturina të hedhura, grumbuj mbeturinash ose vende informale hedhjeje.';

  @override
  String get reportCategoryWaterPollutionTitle => 'Ndotje e ujit';

  @override
  String get reportCategoryWaterPollutionDescription =>
      'Lumenj, liqene, kanalizime të kontaminuara ose shkarkim ujërash të ndotura.';

  @override
  String get reportCategoryAirPollutionTitle => 'Ndotje e ajrit';

  @override
  String get reportCategoryAirPollutionDescription =>
      'Tym, pluhur, djegie mbeturinash ose emetime që dëmtojnë cilësinë e ajrit.';

  @override
  String get reportCategoryIndustrialWasteTitle => 'Mbeturina industriale';

  @override
  String get reportCategoryIndustrialWasteDescription =>
      'Inerte ndërtimi, mbeturina fabrike ose materiale të rrezikshme.';

  @override
  String get reportCategoryOtherTitle => 'Tjetër';

  @override
  String get reportCategoryOtherDescription =>
      'Kur problemi nuk përputhet qartë me kategoritë më sipër.';

  @override
  String get unknownRouteTitle => 'Faqja nuk u gjet';

  @override
  String get unknownRouteMessage =>
      'Lidhja mund të jetë e vjetër ose e pasaktë.';

  @override
  String get unknownRouteContinueButton => 'Vazhdo te aplikacioni';

  @override
  String unknownRouteDebugRoute(String routeName) {
    return 'Debug: emri i rrugës ishte \"$routeName\".';
  }

  @override
  String get chatShareLocation => 'Ndaj vendndodhjen';

  @override
  String get chatSharedLocation => 'Vendndodhje e ndarë';

  @override
  String get organizerToolkitTitle => 'Bëhu organizator';

  @override
  String get organizerToolkitPage1Title => 'Planifiko përpara';

  @override
  String get organizerToolkitPage1Body =>
      'Vlerësoni vendin për rreziqe, përgatitni pajisjet e sigurisë dhe informoni ekipin para se të vijnë vullnetarët.';

  @override
  String get organizerToolkitPage2Title => 'Moderimi ndërton besim';

  @override
  String get organizerToolkitPage2Body =>
      'Pasi të krijoni një ngjarje, moderatorët e shqyrtojnë. Pas aprovimit, vullnetarët mund ta shohin dhe të bashkohen.';

  @override
  String get organizerToolkitPage3Title => 'Verifikoni pjesëmarrjen';

  @override
  String get organizerToolkitPage3Body =>
      'Përdorni check-in me QR në aplikacion që çdo vullnetar të marrë pikët e merituara.';

  @override
  String get organizerToolkitPage4Title => 'Moti dhe siguria';

  @override
  String get organizerToolkitPage4Body =>
      'Nëse kushtet bëhen të pasigurta, ndaloni ose shtyni. Njoftoni menjëherë vullnetarët e regjistruar në aplikacion që askush të mos udhëtojë për një fillim të anuluar.';

  @override
  String get organizerToolkitPage5Title => 'Mbeturinat dhe hedhja';

  @override
  String get organizerToolkitPage5Body =>
      'Ndani riciklimin kur është e mundur, paketoni me siguri sende të mprehta dhe çojini mbeturinat në pika të autorizuara. Lëreni vendin më pastër se sa e gjetët.';

  @override
  String get organizerToolkitPage6Title => 'Përfshini të gjithë';

  @override
  String get organizerToolkitPage6Body =>
      'Ofroni role të qarta, ritëm të qëndrueshëm dhe durim. Një briefing mirëpritës i ndihmon vullnetarët e rinj të ndihen të sigurt.';

  @override
  String get organizerToolkitPage7Title => 'Privatësia në chat';

  @override
  String get organizerToolkitPage7Body =>
      'Mbajini numrat e telefonit dhe adresat jashtë bisedës publike të ngjarjes. Përdorni mesazhet në aplikacion që ekipi të mbetet i informuar pa ndarë tepër.';

  @override
  String get organizerToolkitPage8Title => 'Dëshmi dhe ndikim i ndershëm';

  @override
  String get organizerToolkitPage8Body =>
      'Fotot pas dhe numri i qeseve duhet të pasqyrojnë atë që ndodhi vërtet. Raportimi i saktë ndërton besim te vullnetarët, moderatorët dhe komuniteti.';

  @override
  String get organizerToolkitContinue => 'Vazhdo';

  @override
  String get organizerToolkitStartQuiz => 'Zgjidh kuizin';

  @override
  String get organizerQuizTitle => 'Kontroll i shpejtë i njohurive';

  @override
  String get organizerQuizLoadFailed => 'Nuk u ngarkua kuizi. Provo përsëri.';

  @override
  String get organizerQuizLoadInvalidResponse =>
      'Të dhënat e kuizit nga serveri ishin të paplota. Provo përsëri.';

  @override
  String get organizerQuizRetryLoad => 'Provo përsëri';

  @override
  String get organizerQuizSubmitFailed =>
      'Nuk u dorëzuan përgjigjet. Provo përsëri.';

  @override
  String organizerQuizOptionSemantic(int index, int total, String optionText) {
    return 'Pyetja $index nga $total: $optionText';
  }

  @override
  String get organizerQuizSubmit => 'Dorëzo përgjigjet';

  @override
  String get organizerQuizPassedTitle => 'Jeni certifikuar!';

  @override
  String get organizerQuizPassedBody =>
      'Tani mund të krijoni ngjarje pastrimi. Vullnetarët po presin.';

  @override
  String get organizerQuizFailedTitle => 'Jo plotësisht';

  @override
  String organizerQuizFailedBody(int correct, int total) {
    return 'Rishikoni tutorialin dhe provoni përsëri. Keni $correct nga $total të sakta.';
  }

  @override
  String get organizerQuizRetry => 'Provo përsëri';

  @override
  String get organizerQuizCreateEvent => 'Krijo ngjarjen e parë';

  @override
  String get organizerCertifiedBadge => 'Organizator i certifikuar';

  @override
  String get errorOrganizerQuizSessionExpired =>
      'Sesioni i kuizit skadoi. Ngarkoni një kuiz të ri dhe provoni përsëri.';

  @override
  String get errorOrganizerQuizSessionInvalid =>
      'Ky sesion kuizi nuk është i vlefshëm. Ngarkoni kuizin përsëri.';

  @override
  String get errorOrganizerQuizAnswersMismatch =>
      'Përgjigjet nuk përputhen me kuizin që filluat. Ngarkoni kuizin përsëri.';

  @override
  String get errorOrganizerQuizInvalid =>
      'Disa përgjigje nuk janë të vlefshme për këtë kuiz. Ngarkoni kuizin përsëri.';

  @override
  String get errorOrganizerCertificationAlreadyDone =>
      'Jeni tashmë organizator i certifikuar. Nuk duhet të rifilloni kuizin.';

  @override
  String get reportsSseReconnectBanner =>
      'Duke u rilidhur për përditësime të drejtpërdrejta…';

  @override
  String get reportsSseReconnectAction => 'Rilidh';

  @override
  String get reportsListMergedToast =>
      'Ky raport u bashkua dhe u hoq nga lista jote.';

  @override
  String get reportDraftResumeTitle => 'Të vazhdosh me skicën?';

  @override
  String reportDraftResumeBody(
    int photoCount,
    String titlePreview,
    String savedAt,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      photoCount,
      locale: localeName,
      other: 'U ruajtën $photoCount foto.',
      one: 'U ruajt 1 foto.',
      zero: 'Ende nuk ka foto të ruajtura.',
    );
    return '$_temp0\n\nTitulli: \"$titlePreview\"\n\nRuajtur së fundmi: $savedAt.';
  }

  @override
  String get reportDraftResumeContinue => 'Vazhdo';

  @override
  String get reportDraftResumeDiscard => 'Hidh skicën';

  @override
  String get reportDraftSavedJustNow => 'U ruajt tani';

  @override
  String reportDraftSavedMinutesAgo(int minutes) {
    return 'U ruajt para $minutes min';
  }

  @override
  String reportDraftSavedHoursAgo(int hours) {
    return 'U ruajt para $hours orësh';
  }

  @override
  String reportDraftPhotosLost(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count foto të bashkëngjitura mungonin dhe u hoqën nga skica.',
      one: '1 foto e bashkëngjitur mungonte dhe u hoq nga skica.',
    );
    return '$_temp0';
  }

  @override
  String get reportDraftDiscardConfirmTitle => 'Të hidhet skica?';

  @override
  String get reportDraftDiscardConfirmBody =>
      'Teksti dhe fotot e ruajtura për këtë raport do të fshihen nga ky pajisje.';

  @override
  String get reportDraftCentralFabSheetTitle => 'Ke një draft të ruajtur';

  @override
  String reportDraftCentralFabSubtitle(int photoCount, String savedAgo) {
    String _temp0 = intl.Intl.pluralLogic(
      photoCount,
      locale: localeName,
      other: '$photoCount foto',
      one: '1 foto',
      zero: 'Pa foto',
    );
    return '$_temp0 · $savedAgo';
  }

  @override
  String get reportDraftCentralFabContinue => 'Vazhdo draftin';

  @override
  String get reportDraftCentralFabTakeNewPhoto => 'Foto e re';

  @override
  String get reportDraftCentralFabCancel => 'Anulo';

  @override
  String get reportDraftIncomingPhotoTitle =>
      'Vazhdo draftin apo përdor këtë foto?';

  @override
  String reportDraftIncomingPhotoBody(int photoCount, String savedAgo) {
    String _temp0 = intl.Intl.pluralLogic(
      photoCount,
      locale: localeName,
      other: '$photoCount foto',
      one: '1 foto',
      zero: 'pa foto',
    );
    return 'Ke një draft të ruajtur ($_temp0). $savedAgo';
  }

  @override
  String get reportDraftIncomingPhotoContinue => 'Vazhdo draftin';

  @override
  String get reportDraftIncomingPhotoReplace => 'Zëvendëso draftin';

  @override
  String get reportDraftIncomingPhotoAdd => 'Shto në draft';

  @override
  String get savedMapAreasTitle => 'Zonat e ruajtura të hartës';

  @override
  String get savedMapAreasPlaceholder =>
      'Rajonet offline dhe shkarkimet në sfond do të shfaqen këtu.';

  @override
  String get mapWhatsNewTitle => 'Përditësime të hartës';

  @override
  String get mapWhatsNewBody =>
      'Parapërgatitje më e zgjuar, grupe më të qëndrueshme dhe rrjedha më e sigurt e hartës.';
}
