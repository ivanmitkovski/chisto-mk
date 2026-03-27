import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_mk.dart';
import 'app_localizations_sq.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('mk'),
    Locale('sq'),
  ];

  /// No description provided for @reportFlowHelpHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the info button for tips on this step.'**
  String get reportFlowHelpHint;

  /// No description provided for @reportHelpContextTitle.
  ///
  /// In en, this message translates to:
  /// **'Context'**
  String get reportHelpContextTitle;

  /// No description provided for @reportStageEvidenceEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Report a pollution site'**
  String get reportStageEvidenceEyebrow;

  /// No description provided for @reportStageEvidenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Evidence'**
  String get reportStageEvidenceTitle;

  /// No description provided for @reportStageEvidenceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Photos and framing'**
  String get reportStageEvidenceSubtitle;

  /// No description provided for @reportStageEvidenceShortLabel.
  ///
  /// In en, this message translates to:
  /// **'Evidence'**
  String get reportStageEvidenceShortLabel;

  /// No description provided for @reportStageEvidencePrimaryAction.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get reportStageEvidencePrimaryAction;

  /// No description provided for @reportStageEvidencePrimaryRequirement.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get reportStageEvidencePrimaryRequirement;

  /// No description provided for @reportStageEvidenceSecondaryRequirement.
  ///
  /// In en, this message translates to:
  /// **'Up to 5'**
  String get reportStageEvidenceSecondaryRequirement;

  /// No description provided for @reportStageEvidenceInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Evidence'**
  String get reportStageEvidenceInfoTitle;

  /// No description provided for @reportHelpEvidenceS0Title.
  ///
  /// In en, this message translates to:
  /// **'What to capture'**
  String get reportHelpEvidenceS0Title;

  /// No description provided for @reportHelpEvidenceS0Body.
  ///
  /// In en, this message translates to:
  /// **'Add up to five photos that show the polluted area clearly. Use a wide shot for context, then closer frames of what matters: waste piles, pipes, stains, debris, or anything that shows the problem.'**
  String get reportHelpEvidenceS0Body;

  /// No description provided for @reportHelpEvidenceS1Title.
  ///
  /// In en, this message translates to:
  /// **'Why it helps'**
  String get reportHelpEvidenceS1Title;

  /// No description provided for @reportHelpEvidenceS1Body.
  ///
  /// In en, this message translates to:
  /// **'Moderators rely on your images to confirm the report and prioritize follow-up. Daylight, a steady hand, and showing the whole site make verification much easier.'**
  String get reportHelpEvidenceS1Body;

  /// No description provided for @reportStageDetailsEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Describe the issue'**
  String get reportStageDetailsEyebrow;

  /// No description provided for @reportStageDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get reportStageDetailsTitle;

  /// No description provided for @reportStageDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Category, headline, and context'**
  String get reportStageDetailsSubtitle;

  /// No description provided for @reportStageDetailsShortLabel.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get reportStageDetailsShortLabel;

  /// No description provided for @reportStageDetailsPrimaryAction.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get reportStageDetailsPrimaryAction;

  /// No description provided for @reportStageDetailsPrimaryRequirement.
  ///
  /// In en, this message translates to:
  /// **'Category & title'**
  String get reportStageDetailsPrimaryRequirement;

  /// No description provided for @reportStageDetailsSecondaryRequirement.
  ///
  /// In en, this message translates to:
  /// **'Details optional'**
  String get reportStageDetailsSecondaryRequirement;

  /// No description provided for @reportStageDetailsInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get reportStageDetailsInfoTitle;

  /// No description provided for @reportHelpDetailsS0Title.
  ///
  /// In en, this message translates to:
  /// **'What to fill in'**
  String get reportHelpDetailsS0Title;

  /// No description provided for @reportHelpDetailsS0Body.
  ///
  /// In en, this message translates to:
  /// **'Choose the category that best matches what you saw. Write a short headline anyone could understand at a glance, like a news title, not an essay.\n\nThen add severity if you’re unsure; use the description for anything that helps someone find or assess the site on the ground: access, timing, smell, color of water, or landmarks. Cleanup effort is optional and only useful if you have a rough sense of scale.'**
  String get reportHelpDetailsS0Body;

  /// No description provided for @reportHelpDetailsS1Title.
  ///
  /// In en, this message translates to:
  /// **'Optional fields'**
  String get reportHelpDetailsS1Title;

  /// No description provided for @reportHelpDetailsS1Body.
  ///
  /// In en, this message translates to:
  /// **'Nothing here blocks submission except category and title. Extra detail is for nuance. Use it when it genuinely helps.'**
  String get reportHelpDetailsS1Body;

  /// No description provided for @reportStageLocationEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Confirm the location'**
  String get reportStageLocationEyebrow;

  /// No description provided for @reportStageLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get reportStageLocationTitle;

  /// No description provided for @reportStageLocationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Map pin'**
  String get reportStageLocationSubtitle;

  /// No description provided for @reportStageLocationShortLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get reportStageLocationShortLabel;

  /// No description provided for @reportStageLocationPrimaryAction.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get reportStageLocationPrimaryAction;

  /// No description provided for @reportStageLocationPrimaryRequirement.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get reportStageLocationPrimaryRequirement;

  /// No description provided for @reportStageLocationSecondaryRequirement.
  ///
  /// In en, this message translates to:
  /// **'In Macedonia'**
  String get reportStageLocationSecondaryRequirement;

  /// No description provided for @reportStageLocationInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get reportStageLocationInfoTitle;

  /// No description provided for @reportHelpLocationS0Title.
  ///
  /// In en, this message translates to:
  /// **'How to place the pin'**
  String get reportHelpLocationS0Title;

  /// No description provided for @reportHelpLocationS0Body.
  ///
  /// In en, this message translates to:
  /// **'Drag the map to the exact spot where the pollution is, not the nearest town unless you’re reporting a whole area. Zoom in until the pin sits on the real site.'**
  String get reportHelpLocationS0Body;

  /// No description provided for @reportHelpLocationS1Title.
  ///
  /// In en, this message translates to:
  /// **'Coverage area'**
  String get reportHelpLocationS1Title;

  /// No description provided for @reportHelpLocationS1Body.
  ///
  /// In en, this message translates to:
  /// **'The pin must be inside Macedonia so your report can be routed and verified correctly. If you’re unsure, place it as accurately as you can.'**
  String get reportHelpLocationS1Body;

  /// No description provided for @reportHelpLocationS2Title.
  ///
  /// In en, this message translates to:
  /// **'Why it matters'**
  String get reportHelpLocationS2Title;

  /// No description provided for @reportHelpLocationS2Body.
  ///
  /// In en, this message translates to:
  /// **'Coordinates tie your photos and description to a real place for field teams and moderators.'**
  String get reportHelpLocationS2Body;

  /// No description provided for @reportStageReviewEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Final review'**
  String get reportStageReviewEyebrow;

  /// No description provided for @reportStageReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get reportStageReviewTitle;

  /// No description provided for @reportStageReviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Before you send'**
  String get reportStageReviewSubtitle;

  /// No description provided for @reportStageReviewShortLabel.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get reportStageReviewShortLabel;

  /// No description provided for @reportStageReviewPrimaryAction.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get reportStageReviewPrimaryAction;

  /// No description provided for @reportStageReviewPrimaryRequirement.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get reportStageReviewPrimaryRequirement;

  /// No description provided for @reportStageReviewInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get reportStageReviewInfoTitle;

  /// No description provided for @reportHelpReviewS0Title.
  ///
  /// In en, this message translates to:
  /// **'Double-check each section'**
  String get reportHelpReviewS0Title;

  /// No description provided for @reportHelpReviewS0Body.
  ///
  /// In en, this message translates to:
  /// **'Tap any row to jump back and edit. When photos, details, and location all match what you saw, you’re ready.'**
  String get reportHelpReviewS0Body;

  /// No description provided for @reportHelpReviewS1Title.
  ///
  /// In en, this message translates to:
  /// **'What happens next'**
  String get reportHelpReviewS1Title;

  /// No description provided for @reportHelpReviewS1Body.
  ///
  /// In en, this message translates to:
  /// **'Your report is reviewed before it appears publicly. In My reports, you can track status; updates appear there as the site moves through moderation.'**
  String get reportHelpReviewS1Body;

  /// No description provided for @newReportTitle.
  ///
  /// In en, this message translates to:
  /// **'New report'**
  String get newReportTitle;

  /// No description provided for @reportReviewBannerCreditsTitle.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get reportReviewBannerCreditsTitle;

  /// No description provided for @reportReviewBannerAfterSubmitTitle.
  ///
  /// In en, this message translates to:
  /// **'After submit'**
  String get reportReviewBannerAfterSubmitTitle;

  /// No description provided for @reportReviewAfterSubmitReady.
  ///
  /// In en, this message translates to:
  /// **'Moderated before public. Status in My reports.'**
  String get reportReviewAfterSubmitReady;

  /// No description provided for @reportReviewAfterSubmitIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Finish steps above.'**
  String get reportReviewAfterSubmitIncomplete;

  /// No description provided for @semanticsClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get semanticsClose;

  /// No description provided for @semanticsAboutStep.
  ///
  /// In en, this message translates to:
  /// **'About {title}'**
  String semanticsAboutStep(String title);

  /// No description provided for @semanticsNextStep.
  ///
  /// In en, this message translates to:
  /// **'Next: {label}'**
  String semanticsNextStep(String label);

  /// No description provided for @reportFlowEvidenceNeedsPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add at least one photo to continue.'**
  String get reportFlowEvidenceNeedsPhoto;

  /// No description provided for @reportFlowLocationOutsideMacedoniaHelper.
  ///
  /// In en, this message translates to:
  /// **'This location is outside Macedonia. Drag the pin into the country, then tap Confirm location.'**
  String get reportFlowLocationOutsideMacedoniaHelper;

  /// No description provided for @reportLocationAdvanceBlockedBanner.
  ///
  /// In en, this message translates to:
  /// **'Place the pin in Macedonia and tap Confirm location.'**
  String get reportLocationAdvanceBlockedBanner;

  /// No description provided for @reviewTapToEdit.
  ///
  /// In en, this message translates to:
  /// **'Tap to edit'**
  String get reviewTapToEdit;

  /// No description provided for @semanticsCurrentReportStep.
  ///
  /// In en, this message translates to:
  /// **'Current step: {label}'**
  String semanticsCurrentReportStep(String label);

  /// No description provided for @errorBannerDraftSavedHint.
  ///
  /// In en, this message translates to:
  /// **'Your draft is saved — you can try again when ready.'**
  String get errorBannerDraftSavedHint;

  /// No description provided for @reportSubmittedTitle.
  ///
  /// In en, this message translates to:
  /// **'Report submitted'**
  String get reportSubmittedTitle;

  /// No description provided for @reportSubmittedSavedAs.
  ///
  /// In en, this message translates to:
  /// **'Saved as report {number}'**
  String reportSubmittedSavedAs(String number);

  /// No description provided for @reportSubmittedBodyWithAddress.
  ///
  /// In en, this message translates to:
  /// **'{category} near {address} is now in the review queue.'**
  String reportSubmittedBodyWithAddress(String category, String address);

  /// No description provided for @reportSubmittedBodyNoAddress.
  ///
  /// In en, this message translates to:
  /// **'{category} is now in the review queue.'**
  String reportSubmittedBodyNoAddress(String category);

  /// No description provided for @reportSubmittedNewSiteBadge.
  ///
  /// In en, this message translates to:
  /// **'New site added to the map'**
  String get reportSubmittedNewSiteBadge;

  /// No description provided for @reportSubmittedPointsEarned.
  ///
  /// In en, this message translates to:
  /// **'+{points} pts earned'**
  String reportSubmittedPointsEarned(int points);

  /// No description provided for @reportSubmittedPointsPending.
  ///
  /// In en, this message translates to:
  /// **'Earn up to {max} pts when approved'**
  String reportSubmittedPointsPending(int max);

  /// No description provided for @reportSubmittedViewThisReport.
  ///
  /// In en, this message translates to:
  /// **'View this report'**
  String get reportSubmittedViewThisReport;

  /// No description provided for @reportSubmittedViewAllReports.
  ///
  /// In en, this message translates to:
  /// **'View all reports'**
  String get reportSubmittedViewAllReports;

  /// No description provided for @reportSubmittedViewInMyReports.
  ///
  /// In en, this message translates to:
  /// **'View in My reports'**
  String get reportSubmittedViewInMyReports;

  /// No description provided for @reportSubmittedReportAnother.
  ///
  /// In en, this message translates to:
  /// **'Report another'**
  String get reportSubmittedReportAnother;

  /// No description provided for @reportSubmittedSemanticsSuccess.
  ///
  /// In en, this message translates to:
  /// **'Report submitted successfully'**
  String get reportSubmittedSemanticsSuccess;

  /// No description provided for @profileAvatarSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get profileAvatarSourceTitle;

  /// No description provided for @profileAvatarSourceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Take a new photo or choose from your library. You can crop it in the next step.'**
  String get profileAvatarSourceSubtitle;

  /// No description provided for @profileAvatarSourceCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get profileAvatarSourceCamera;

  /// No description provided for @profileAvatarSourceCameraHint.
  ///
  /// In en, this message translates to:
  /// **'Front camera works best with good light.'**
  String get profileAvatarSourceCameraHint;

  /// No description provided for @profileAvatarSourcePhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get profileAvatarSourcePhotos;

  /// No description provided for @profileAvatarSourcePhotosHint.
  ///
  /// In en, this message translates to:
  /// **'Pick any image you already have.'**
  String get profileAvatarSourcePhotosHint;

  /// No description provided for @profileAvatarSourceRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove current photo'**
  String get profileAvatarSourceRemove;

  /// No description provided for @profileAvatarSourceRemoveHint.
  ///
  /// In en, this message translates to:
  /// **'Show your initials instead of a picture'**
  String get profileAvatarSourceRemoveHint;

  /// No description provided for @profileAvatarRemoveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove profile photo?'**
  String get profileAvatarRemoveConfirmTitle;

  /// No description provided for @profileAvatarRemoveConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Your picture will be deleted and your initials will be shown instead.'**
  String get profileAvatarRemoveConfirmMessage;

  /// No description provided for @profileAvatarRemoveConfirmCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get profileAvatarRemoveConfirmCancel;

  /// No description provided for @profileAvatarRemoveConfirmRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get profileAvatarRemoveConfirmRemove;

  /// No description provided for @profileAvatarRemovedMessage.
  ///
  /// In en, this message translates to:
  /// **'Profile photo removed'**
  String get profileAvatarRemovedMessage;

  /// No description provided for @profileAvatarRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not remove your photo. Please try again.'**
  String get profileAvatarRemoveFailed;

  /// No description provided for @profileAvatarSourceRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get profileAvatarSourceRecommended;

  /// No description provided for @profileAvatarCropMoveAndScale.
  ///
  /// In en, this message translates to:
  /// **'Move and scale'**
  String get profileAvatarCropMoveAndScale;

  /// No description provided for @profileAvatarCropHint.
  ///
  /// In en, this message translates to:
  /// **'Pinch to zoom · drag to position'**
  String get profileAvatarCropHint;

  /// No description provided for @profileAvatarCropLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading photo…'**
  String get profileAvatarCropLoading;

  /// No description provided for @profileAvatarCropCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get profileAvatarCropCancel;

  /// No description provided for @profileAvatarCropDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get profileAvatarCropDone;

  /// No description provided for @profileAvatarTapToChange.
  ///
  /// In en, this message translates to:
  /// **'Tap to change photo'**
  String get profileAvatarTapToChange;

  /// No description provided for @profileAvatarUploadingCaption.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get profileAvatarUploadingCaption;

  /// No description provided for @profileAvatarCropEditorSemantic.
  ///
  /// In en, this message translates to:
  /// **'Crop your profile photo. Pinch to zoom and drag to position the image.'**
  String get profileAvatarCropEditorSemantic;

  /// No description provided for @profileAvatarCropFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not crop the photo. Please try again.'**
  String get profileAvatarCropFailed;

  /// No description provided for @profileAvatarCameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unable to open the camera right now. Please try again in a moment.'**
  String get profileAvatarCameraUnavailable;

  /// No description provided for @profileAvatarReadPhotoFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read the photo. Please try again.'**
  String get profileAvatarReadPhotoFailed;

  /// No description provided for @profileAvatarProcessPhotoFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not process the photo. Please try again.'**
  String get profileAvatarProcessPhotoFailed;

  /// No description provided for @profileAvatarPeekSemantic.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get profileAvatarPeekSemantic;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'mk', 'sq'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'mk':
      return AppLocalizationsMk();
    case 'sq':
      return AppLocalizationsSq();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
