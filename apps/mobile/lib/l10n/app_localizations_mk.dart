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
  String get resumeDraftTitle => 'Resume draft?';

  @override
  String get resumeDraftBody =>
      'You have an unsaved report. Resume where you left off or start fresh.';

  @override
  String get resumeDraftStartFresh => 'Start fresh';

  @override
  String get resumeDraftResume => 'Resume';

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
  String get reportFlowJourneySeparator => ' → ';

  @override
  String get reportDraftSaved => 'Нацртот е зачуван';

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
}
