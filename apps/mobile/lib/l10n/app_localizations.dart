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

  /// No description provided for @reportFlowStepProgressStep.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of 3'**
  String reportFlowStepProgressStep(int current);

  /// No description provided for @reportFlowStepProgressReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to submit'**
  String get reportFlowStepProgressReady;

  /// No description provided for @reportFlowStepStatusComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get reportFlowStepStatusComplete;

  /// No description provided for @reportFlowStepStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get reportFlowStepStatusInProgress;

  /// No description provided for @reportFlowStepChipPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get reportFlowStepChipPhotos;

  /// No description provided for @reportFlowStepChipCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get reportFlowStepChipCategory;

  /// No description provided for @reportFlowStepChipLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get reportFlowStepChipLocation;

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

  /// No description provided for @reportSubmitSentPending.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get reportSubmitSentPending;

  /// No description provided for @semanticsClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get semanticsClose;

  /// No description provided for @homeShellNavHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeShellNavHome;

  /// No description provided for @homeShellNavReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get homeShellNavReports;

  /// No description provided for @homeShellNavMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get homeShellNavMap;

  /// No description provided for @homeShellNavEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get homeShellNavEvents;

  /// No description provided for @semanticsReportPhotoNumber.
  ///
  /// In en, this message translates to:
  /// **'Report photo {number}'**
  String semanticsReportPhotoNumber(int number);

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
  /// **'Your draft is saved, you can try again when ready.'**
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
  /// **'Points are credited after moderators approve your report.'**
  String get reportSubmittedPointsPending;

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
  /// **'Pinch to zoom, drag to position'**
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

  /// No description provided for @errorBannerDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get errorBannerDismiss;

  /// No description provided for @errorBannerTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get errorBannerTryAgain;

  /// No description provided for @authSemanticGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get authSemanticGoBack;

  /// No description provided for @authLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get authLoading;

  /// No description provided for @authSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignInTitle;

  /// No description provided for @authSignInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back. Enter your details to continue.'**
  String get authSignInSubtitle;

  /// No description provided for @authFieldPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get authFieldPhone;

  /// No description provided for @authFieldPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'70 123 456'**
  String get authFieldPhoneHint;

  /// No description provided for @authFieldPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authFieldPassword;

  /// No description provided for @authFieldPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get authFieldPasswordHint;

  /// No description provided for @authRememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get authRememberMe;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// No description provided for @authSignInCta.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignInCta;

  /// No description provided for @authValidationCheckPhonePassword.
  ///
  /// In en, this message translates to:
  /// **'Please check your phone number and password.'**
  String get authValidationCheckPhonePassword;

  /// No description provided for @authSignUpPrompt.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get authSignUpPrompt;

  /// No description provided for @authSignUpLink.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get authSignUpLink;

  /// No description provided for @authSignUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get authSignUpTitle;

  /// No description provided for @authSignUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome! Please enter your details'**
  String get authSignUpSubtitle;

  /// No description provided for @authFieldFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get authFieldFullName;

  /// No description provided for @authFieldFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'John Doe'**
  String get authFieldFullNameHint;

  /// No description provided for @authFieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authFieldEmail;

  /// No description provided for @authFieldEmailHint.
  ///
  /// In en, this message translates to:
  /// **'john@chisto.mk'**
  String get authFieldEmailHint;

  /// No description provided for @authFieldPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get authFieldPhoneNumber;

  /// No description provided for @authPasswordRequirementsHint.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters, with letters and numbers'**
  String get authPasswordRequirementsHint;

  /// No description provided for @authTermsPrefix.
  ///
  /// In en, this message translates to:
  /// **'By signing up you agree to our '**
  String get authTermsPrefix;

  /// No description provided for @authTermsLink.
  ///
  /// In en, this message translates to:
  /// **'terms and conditions'**
  String get authTermsLink;

  /// No description provided for @authValidationCheckFields.
  ///
  /// In en, this message translates to:
  /// **'Please check the highlighted fields above.'**
  String get authValidationCheckFields;

  /// No description provided for @authSignUpCta.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get authSignUpCta;

  /// No description provided for @authSignInPrompt.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get authSignInPrompt;

  /// No description provided for @authSignInLink.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignInLink;

  /// No description provided for @authValidationFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'{fieldName} is required'**
  String authValidationFieldRequired(String fieldName);

  /// No description provided for @authValidationPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get authValidationPhoneRequired;

  /// No description provided for @authValidationPhoneDigits.
  ///
  /// In en, this message translates to:
  /// **'Enter an 8-digit phone number'**
  String get authValidationPhoneDigits;

  /// No description provided for @authValidationEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get authValidationEmailRequired;

  /// No description provided for @authValidationEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get authValidationEmailInvalid;

  /// No description provided for @authValidationPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get authValidationPasswordRequired;

  /// No description provided for @authValidationPasswordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get authValidationPasswordMinLength;

  /// No description provided for @authValidationPasswordNeedNumber.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one number'**
  String get authValidationPasswordNeedNumber;

  /// No description provided for @authValidationPasswordNeedLetter.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one letter'**
  String get authValidationPasswordNeedLetter;

  /// No description provided for @authValidationConfirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get authValidationConfirmPasswordRequired;

  /// No description provided for @authValidationConfirmPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get authValidationConfirmPasswordMismatch;

  /// No description provided for @authErrorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Wrong phone number or password.'**
  String get authErrorInvalidCredentials;

  /// No description provided for @authErrorAccountSuspended.
  ///
  /// In en, this message translates to:
  /// **'This account is not active.'**
  String get authErrorAccountSuspended;

  /// No description provided for @authErrorPhoneNotRegistered.
  ///
  /// In en, this message translates to:
  /// **'No account found for this phone number.'**
  String get authErrorPhoneNotRegistered;

  /// No description provided for @authErrorEmailRegistered.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered.'**
  String get authErrorEmailRegistered;

  /// No description provided for @authErrorPhoneRegistered.
  ///
  /// In en, this message translates to:
  /// **'This phone number is already registered.'**
  String get authErrorPhoneRegistered;

  /// No description provided for @authErrorOtpNotFound.
  ///
  /// In en, this message translates to:
  /// **'No code was sent. Request a new code.'**
  String get authErrorOtpNotFound;

  /// No description provided for @authErrorOtpExpired.
  ///
  /// In en, this message translates to:
  /// **'This code has expired. Request a new code.'**
  String get authErrorOtpExpired;

  /// No description provided for @authErrorOtpInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid code. Please try again.'**
  String get authErrorOtpInvalid;

  /// No description provided for @authErrorOtpMaxAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many wrong codes. Request a new code.'**
  String get authErrorOtpMaxAttempts;

  /// No description provided for @authErrorCurrentPasswordInvalid.
  ///
  /// In en, this message translates to:
  /// **'Current password is incorrect.'**
  String get authErrorCurrentPasswordInvalid;

  /// No description provided for @authErrorTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many failed attempts. Try again later.'**
  String get authErrorTooManyAttempts;

  /// No description provided for @authErrorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please wait a moment and try again.'**
  String get authErrorRateLimited;

  /// No description provided for @authErrorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'We could not find an account for this number. Please check and try again.'**
  String get authErrorUserNotFound;

  /// No description provided for @authOtpTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter code'**
  String get authOtpTitle;

  /// No description provided for @authOtpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We just sent a 4-digit code to {phone}'**
  String authOtpSubtitle(String phone);

  /// No description provided for @authOtpContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get authOtpContinue;

  /// No description provided for @authOtpResendPrefix.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive code? '**
  String get authOtpResendPrefix;

  /// No description provided for @authOtpResendAction.
  ///
  /// In en, this message translates to:
  /// **'Send again'**
  String get authOtpResendAction;

  /// No description provided for @authOtpResendCountdown.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}s'**
  String authOtpResendCountdown(int seconds);

  /// No description provided for @authOtpResentMessage.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a new code to {phone}.'**
  String authOtpResentMessage(String phone);

  /// No description provided for @authForgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get authForgotPasswordTitle;

  /// No description provided for @authForgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number and we\'ll send you a code to reset your password'**
  String get authForgotPasswordSubtitle;

  /// No description provided for @authForgotPasswordSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send reset code'**
  String get authForgotPasswordSendCode;

  /// No description provided for @authForgotPasswordRequestSemantic.
  ///
  /// In en, this message translates to:
  /// **'Send reset code'**
  String get authForgotPasswordRequestSemantic;

  /// No description provided for @authForgotPasswordOtpTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter code'**
  String get authForgotPasswordOtpTitle;

  /// No description provided for @authForgotPasswordOtpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We sent a 4-digit code to {phone}'**
  String authForgotPasswordOtpSubtitle(String phone);

  /// No description provided for @authNewPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Create new password'**
  String get authNewPasswordTitle;

  /// No description provided for @authNewPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter a new password for your account'**
  String get authNewPasswordSubtitle;

  /// No description provided for @authFieldNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get authFieldNewPassword;

  /// No description provided for @authFieldNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get authFieldNewPasswordHint;

  /// No description provided for @authFieldConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authFieldConfirmPassword;

  /// No description provided for @authFieldConfirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get authFieldConfirmPasswordHint;

  /// No description provided for @authResetPasswordCta.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get authResetPasswordCta;

  /// No description provided for @authPasswordResetSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Password reset'**
  String get authPasswordResetSuccessTitle;

  /// No description provided for @authPasswordResetSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'Your password has been reset successfully. You can now sign in with your new password.'**
  String get authPasswordResetSuccessBody;

  /// No description provided for @authBackToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get authBackToSignIn;

  /// No description provided for @authOnboardingWelcomeTo.
  ///
  /// In en, this message translates to:
  /// **'Welcome to'**
  String get authOnboardingWelcomeTo;

  /// No description provided for @authOnboardingBrandName.
  ///
  /// In en, this message translates to:
  /// **'Chisto.mk'**
  String get authOnboardingBrandName;

  /// No description provided for @authOnboardingWelcomeDescription.
  ///
  /// In en, this message translates to:
  /// **'See it. Report it. Clean it.'**
  String get authOnboardingWelcomeDescription;

  /// No description provided for @authOnboardingWelcomeSupporting.
  ///
  /// In en, this message translates to:
  /// **'A cleaner city starts with one tap.'**
  String get authOnboardingWelcomeSupporting;

  /// No description provided for @authOnboardingSlide2Title.
  ///
  /// In en, this message translates to:
  /// **'Report in seconds'**
  String get authOnboardingSlide2Title;

  /// No description provided for @authOnboardingSlide2Description.
  ///
  /// In en, this message translates to:
  /// **'Share a report with location in a few taps.'**
  String get authOnboardingSlide2Description;

  /// No description provided for @authOnboardingSlide2Supporting.
  ///
  /// In en, this message translates to:
  /// **'Fast flow, clear status updates.'**
  String get authOnboardingSlide2Supporting;

  /// No description provided for @authOnboardingSlide3Title.
  ///
  /// In en, this message translates to:
  /// **'Join cleanup events'**
  String get authOnboardingSlide3Title;

  /// No description provided for @authOnboardingSlide3Description.
  ///
  /// In en, this message translates to:
  /// **'Track progress and community impact nearby.'**
  String get authOnboardingSlide3Description;

  /// No description provided for @authOnboardingSlide3Supporting.
  ///
  /// In en, this message translates to:
  /// **'Together we keep neighborhoods green.'**
  String get authOnboardingSlide3Supporting;

  /// No description provided for @authOnboardingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get authOnboardingContinue;

  /// No description provided for @authOnboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get authOnboardingGetStarted;

  /// No description provided for @authLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your location'**
  String get authLocationTitle;

  /// No description provided for @authLocationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We use your location to show cleanups and reports near you.'**
  String get authLocationSubtitle;

  /// No description provided for @authLocationMapPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Use current location to update this area'**
  String get authLocationMapPlaceholder;

  /// No description provided for @authLocationDetecting.
  ///
  /// In en, this message translates to:
  /// **'Detecting location…'**
  String get authLocationDetecting;

  /// No description provided for @authLocationContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get authLocationContinue;

  /// No description provided for @authLocationUseCurrent.
  ///
  /// In en, this message translates to:
  /// **'Use current location'**
  String get authLocationUseCurrent;

  /// No description provided for @authLocationUseDifferent.
  ///
  /// In en, this message translates to:
  /// **'Use a different location'**
  String get authLocationUseDifferent;

  /// No description provided for @authLocationPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'We only use your location to show nearby cleanups. We don\'t track you in the background.'**
  String get authLocationPrivacyNote;

  /// No description provided for @authLocationServicesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled. Please enable them in Settings.'**
  String get authLocationServicesDisabled;

  /// No description provided for @authLocationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied. You can enable it in Settings to use this feature.'**
  String get authLocationPermissionDenied;

  /// No description provided for @authLocationPermissionForever.
  ///
  /// In en, this message translates to:
  /// **'Location permission is permanently denied. Opening Settings…'**
  String get authLocationPermissionForever;

  /// No description provided for @authLocationMacedoniaOnly.
  ///
  /// In en, this message translates to:
  /// **'Currently we only support locations in Macedonia.'**
  String get authLocationMacedoniaOnly;

  /// No description provided for @authLocationResolveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not resolve your location. Please try again.'**
  String get authLocationResolveFailed;

  /// No description provided for @authOtpCodeSemantic.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get authOtpCodeSemantic;

  /// No description provided for @authOtpDigitSemantic.
  ///
  /// In en, this message translates to:
  /// **'Digit {index} of {total}'**
  String authOtpDigitSemantic(int index, int total);

  /// No description provided for @profileWeeklyRankingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly rankings'**
  String get profileWeeklyRankingsTitle;

  /// No description provided for @profileWeeklyRankingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reports, eco-actions & more, this week.'**
  String get profileWeeklyRankingsSubtitle;

  /// No description provided for @profileWeeklyRankingsTopSupporters.
  ///
  /// In en, this message translates to:
  /// **'This week\'s top supporters'**
  String get profileWeeklyRankingsTopSupporters;

  /// No description provided for @profileWeeklyRankingsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No rankings yet'**
  String get profileWeeklyRankingsEmptyTitle;

  /// No description provided for @profileWeeklyRankingsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Earn points this week from any credited activity to show up here.'**
  String get profileWeeklyRankingsEmptySubtitle;

  /// No description provided for @profileWeeklyRankingsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get profileWeeklyRankingsRetry;

  /// No description provided for @profileWeeklyRankingsYouRank.
  ///
  /// In en, this message translates to:
  /// **'You are No. {rank} this week'**
  String profileWeeklyRankingsYouRank(int rank);

  /// No description provided for @profileWeeklyRankingsPtsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'{points} pts this week'**
  String profileWeeklyRankingsPtsThisWeek(int points);

  /// No description provided for @profileWeeklyRankingsYouBadge.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get profileWeeklyRankingsYouBadge;

  /// No description provided for @profileWeeklyRankingsScrollToYouHint.
  ///
  /// In en, this message translates to:
  /// **'Scroll to your position in the list'**
  String get profileWeeklyRankingsScrollToYouHint;

  /// No description provided for @profileWeeklyRankingsLoadingSemantic.
  ///
  /// In en, this message translates to:
  /// **'Loading weekly rankings'**
  String get profileWeeklyRankingsLoadingSemantic;

  /// No description provided for @profileWeeklyRankingsRowSemantic.
  ///
  /// In en, this message translates to:
  /// **'Rank {rank}, {name}, {points} points'**
  String profileWeeklyRankingsRowSemantic(int rank, String name, int points);

  /// No description provided for @profileLevelLine.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String profileLevelLine(int level);

  /// No description provided for @profileTierLegend.
  ///
  /// In en, this message translates to:
  /// **'Chisto Legend'**
  String get profileTierLegend;

  /// No description provided for @profilePtsToNextLevel.
  ///
  /// In en, this message translates to:
  /// **'{points} pts to next level'**
  String profilePtsToNextLevel(int points);

  /// No description provided for @profileLevelXpSegment.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total} XP'**
  String profileLevelXpSegment(int current, int total);

  /// No description provided for @profileLifetimeXpOnBar.
  ///
  /// In en, this message translates to:
  /// **'{xp} lifetime XP'**
  String profileLifetimeXpOnBar(int xp);

  /// No description provided for @profilePointsBalanceShort.
  ///
  /// In en, this message translates to:
  /// **'Balance {balance}'**
  String profilePointsBalanceShort(int balance);

  /// No description provided for @profileMyWeeklyRankTitle.
  ///
  /// In en, this message translates to:
  /// **'My weekly rank'**
  String get profileMyWeeklyRankTitle;

  /// No description provided for @profileMyWeeklyRankDetailRanked.
  ///
  /// In en, this message translates to:
  /// **'#{rank}, {points} pts'**
  String profileMyWeeklyRankDetailRanked(int rank, int points);

  /// No description provided for @profileMyWeeklyRankDetailPointsOnly.
  ///
  /// In en, this message translates to:
  /// **'{points} pts'**
  String profileMyWeeklyRankDetailPointsOnly(int points);

  /// No description provided for @profileMyWeeklyRankNoPoints.
  ///
  /// In en, this message translates to:
  /// **'No points this week yet'**
  String get profileMyWeeklyRankNoPoints;

  /// No description provided for @profileViewRankings.
  ///
  /// In en, this message translates to:
  /// **'View rankings'**
  String get profileViewRankings;

  /// No description provided for @profilePointsHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Points & levels'**
  String get profilePointsHistoryTitle;

  /// No description provided for @profilePointsHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'XP you earned and every level you unlocked.'**
  String get profilePointsHistorySubtitle;

  /// No description provided for @profilePointsHistoryOpenSemantic.
  ///
  /// In en, this message translates to:
  /// **'Open points and level history'**
  String get profilePointsHistoryOpenSemantic;

  /// No description provided for @profilePointsHistoryLoadingSemantic.
  ///
  /// In en, this message translates to:
  /// **'Loading points and levels'**
  String get profilePointsHistoryLoadingSemantic;

  /// No description provided for @profileLoadingSemantic.
  ///
  /// In en, this message translates to:
  /// **'Loading profile'**
  String get profileLoadingSemantic;

  /// No description provided for @profileErrorSemantic.
  ///
  /// In en, this message translates to:
  /// **'Profile failed to load'**
  String get profileErrorSemantic;

  /// No description provided for @profileLevelCardSemantic.
  ///
  /// In en, this message translates to:
  /// **'Level and points. Opens points history'**
  String get profileLevelCardSemantic;

  /// No description provided for @profileWeeklyRankCardSemantic.
  ///
  /// In en, this message translates to:
  /// **'Weekly rank. Opens rankings'**
  String get profileWeeklyRankCardSemantic;

  /// No description provided for @profilePointsHistoryMilestonesSection.
  ///
  /// In en, this message translates to:
  /// **'Level ups'**
  String get profilePointsHistoryMilestonesSection;

  /// No description provided for @profilePointsHistoryActivitySection.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get profilePointsHistoryActivitySection;

  /// No description provided for @profilePointsHistoryDayToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get profilePointsHistoryDayToday;

  /// No description provided for @profilePointsHistoryDayYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get profilePointsHistoryDayYesterday;

  /// No description provided for @profilePointsHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No points yet. When a report you submitted is approved as the first on a site, you earn XP here.'**
  String get profilePointsHistoryEmpty;

  /// No description provided for @profilePointsHistoryLevelUpBadge.
  ///
  /// In en, this message translates to:
  /// **'LEVEL UP'**
  String get profilePointsHistoryLevelUpBadge;

  /// No description provided for @profilePointsHistoryLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get profilePointsHistoryLoadMore;

  /// No description provided for @profilePointsHistoryLoadMoreErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load more activity'**
  String get profilePointsHistoryLoadMoreErrorTitle;

  /// No description provided for @profilePointsHistoryLoadMoreRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get profilePointsHistoryLoadMoreRetry;

  /// No description provided for @profilePointsActivityRowSemantic.
  ///
  /// In en, this message translates to:
  /// **'{reason}. {time}. {delta}'**
  String profilePointsActivityRowSemantic(
    String reason,
    String time,
    String delta,
  );

  /// No description provided for @profilePointsDeltaPositive.
  ///
  /// In en, this message translates to:
  /// **'+{points} XP'**
  String profilePointsDeltaPositive(int points);

  /// No description provided for @profilePointsDeltaNegative.
  ///
  /// In en, this message translates to:
  /// **'{points} XP'**
  String profilePointsDeltaNegative(int points);

  /// No description provided for @profilePointsReasonFirstReport.
  ///
  /// In en, this message translates to:
  /// **'First approved report on a site'**
  String get profilePointsReasonFirstReport;

  /// No description provided for @profilePointsReasonEcoApproved.
  ///
  /// In en, this message translates to:
  /// **'Eco action approved'**
  String get profilePointsReasonEcoApproved;

  /// No description provided for @profilePointsReasonEcoRealized.
  ///
  /// In en, this message translates to:
  /// **'Eco action completed'**
  String get profilePointsReasonEcoRealized;

  /// No description provided for @profilePointsReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Points update'**
  String get profilePointsReasonOther;

  /// No description provided for @profilePointsReasonEventOrganizerApproved.
  ///
  /// In en, this message translates to:
  /// **'Your cleanup event was approved'**
  String get profilePointsReasonEventOrganizerApproved;

  /// No description provided for @profilePointsReasonEventJoined.
  ///
  /// In en, this message translates to:
  /// **'Joined a cleanup event'**
  String get profilePointsReasonEventJoined;

  /// No description provided for @profilePointsReasonEventJoinNoShow.
  ///
  /// In en, this message translates to:
  /// **'Join bonus adjusted — no check-in'**
  String get profilePointsReasonEventJoinNoShow;

  /// No description provided for @profilePointsReasonEventCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Event check-in'**
  String get profilePointsReasonEventCheckIn;

  /// No description provided for @profilePointsReasonEventCompleted.
  ///
  /// In en, this message translates to:
  /// **'Cleanup event completed'**
  String get profilePointsReasonEventCompleted;

  /// No description provided for @profilePointsReasonReportApproved.
  ///
  /// In en, this message translates to:
  /// **'Report approved'**
  String get profilePointsReasonReportApproved;

  /// No description provided for @profilePointsReasonReportApprovalRevoked.
  ///
  /// In en, this message translates to:
  /// **'Report approval reversed'**
  String get profilePointsReasonReportApprovalRevoked;

  /// No description provided for @profilePointsReasonReportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report filed (legacy)'**
  String get profilePointsReasonReportSubmitted;

  /// No description provided for @profileReportCreditsTitle.
  ///
  /// In en, this message translates to:
  /// **'Report credits'**
  String get profileReportCreditsTitle;

  /// No description provided for @profileAccountDetailsSection.
  ///
  /// In en, this message translates to:
  /// **'Account details'**
  String get profileAccountDetailsSection;

  /// No description provided for @profileGeneralInfoTile.
  ///
  /// In en, this message translates to:
  /// **'General info'**
  String get profileGeneralInfoTile;

  /// No description provided for @profileLanguageTile.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguageTile;

  /// No description provided for @profileLanguageScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get profileLanguageScreenTitle;

  /// No description provided for @profileLanguageScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a language or follow your device.'**
  String get profileLanguageScreenSubtitle;

  /// No description provided for @profileLanguageChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update language. Try again.'**
  String get profileLanguageChangeFailed;

  /// No description provided for @profileLanguageSubtitleDevice.
  ///
  /// In en, this message translates to:
  /// **'Device settings'**
  String get profileLanguageSubtitleDevice;

  /// No description provided for @profileLanguageOptionSystem.
  ///
  /// In en, this message translates to:
  /// **'Use device language'**
  String get profileLanguageOptionSystem;

  /// No description provided for @profileLanguageNameEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get profileLanguageNameEn;

  /// No description provided for @profileLanguageNameMk.
  ///
  /// In en, this message translates to:
  /// **'Македонски'**
  String get profileLanguageNameMk;

  /// No description provided for @profileLanguageNameSq.
  ///
  /// In en, this message translates to:
  /// **'Shqip'**
  String get profileLanguageNameSq;

  /// No description provided for @profilePasswordTile.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get profilePasswordTile;

  /// No description provided for @profileSupportSection.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get profileSupportSection;

  /// No description provided for @profileHelpCenterTile.
  ///
  /// In en, this message translates to:
  /// **'Help center'**
  String get profileHelpCenterTile;

  /// No description provided for @profileAccountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileAccountSection;

  /// No description provided for @profileSignOutTile.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get profileSignOutTile;

  /// No description provided for @profileDeleteAccountTile.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get profileDeleteAccountTile;

  /// No description provided for @profileEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmailLabel;

  /// No description provided for @profileEmailReadOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'Read-only. Contact support to change your email.'**
  String get profileEmailReadOnlyHint;

  /// No description provided for @profileNoConnectionSnack.
  ///
  /// In en, this message translates to:
  /// **'No connection'**
  String get profileNoConnectionSnack;

  /// No description provided for @profileRefreshFailedSnack.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t refresh your profile. Try again in a moment.'**
  String get profileRefreshFailedSnack;

  /// No description provided for @profilePasswordScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get profilePasswordScreenTitle;

  /// No description provided for @profilePasswordScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a strong, unique password.'**
  String get profilePasswordScreenSubtitle;

  /// No description provided for @profilePasswordCurrentLabel.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get profilePasswordCurrentLabel;

  /// No description provided for @profilePasswordNewLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get profilePasswordNewLabel;

  /// No description provided for @profilePasswordConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get profilePasswordConfirmLabel;

  /// No description provided for @profilePasswordNewHelper.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters, with a number.'**
  String get profilePasswordNewHelper;

  /// No description provided for @profilePasswordConfirmMismatchHelper.
  ///
  /// In en, this message translates to:
  /// **'Make sure this matches the new password above.'**
  String get profilePasswordConfirmMismatchHelper;

  /// No description provided for @profilePasswordSecurityHint.
  ///
  /// In en, this message translates to:
  /// **'For security, avoid reusing passwords from other apps.'**
  String get profilePasswordSecurityHint;

  /// No description provided for @profilePasswordSubmit.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get profilePasswordSubmit;

  /// No description provided for @profilePasswordSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Updating…'**
  String get profilePasswordSubmitting;

  /// No description provided for @profilePasswordSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get profilePasswordSuccess;

  /// No description provided for @profilePasswordEnterCurrentWarning.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password.'**
  String get profilePasswordEnterCurrentWarning;

  /// No description provided for @profilePasswordMismatchError.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get profilePasswordMismatchError;

  /// No description provided for @profilePasswordSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please sign in again.'**
  String get profilePasswordSessionExpired;

  /// No description provided for @profilePasswordGenericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Check your connection and try again.'**
  String get profilePasswordGenericError;

  /// No description provided for @profilePasswordCurrentSemantic.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get profilePasswordCurrentSemantic;

  /// No description provided for @profilePasswordNewSemantic.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get profilePasswordNewSemantic;

  /// No description provided for @profilePasswordConfirmSemantic.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get profilePasswordConfirmSemantic;

  /// No description provided for @profilePasswordToggleVisibility.
  ///
  /// In en, this message translates to:
  /// **'Show or hide password'**
  String get profilePasswordToggleVisibility;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonTryAgain;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get commonSkip;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get commonGotIt;

  /// No description provided for @commonKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get commonKeepEditing;

  /// No description provided for @commonDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get commonDiscard;

  /// No description provided for @profileSignOutDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get profileSignOutDialogTitle;

  /// No description provided for @profileSignOutDialogBody.
  ///
  /// In en, this message translates to:
  /// **'You can sign back in anytime with your account.'**
  String get profileSignOutDialogBody;

  /// No description provided for @profileSignOutFailedSnack.
  ///
  /// In en, this message translates to:
  /// **'Could not sign out. Try again.'**
  String get profileSignOutFailedSnack;

  /// No description provided for @profileDeleteAccountDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get profileDeleteAccountDialogTitle;

  /// No description provided for @profileDeleteAccountDialogBody.
  ///
  /// In en, this message translates to:
  /// **'All your data will be permanently removed. This action cannot be undone.'**
  String get profileDeleteAccountDialogBody;

  /// No description provided for @profileDeleteAccountFailedSnack.
  ///
  /// In en, this message translates to:
  /// **'Could not delete your account. Try again.'**
  String get profileDeleteAccountFailedSnack;

  /// No description provided for @profileDeleteAccountTypeConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm by typing'**
  String get profileDeleteAccountTypeConfirmTitle;

  /// No description provided for @profileDeleteAccountTypeConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Type the word below exactly as shown. This helps prevent accidental deletion.'**
  String get profileDeleteAccountTypeConfirmBody;

  /// No description provided for @profileDeleteAccountConfirmPhrase.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get profileDeleteAccountConfirmPhrase;

  /// No description provided for @profileDeleteAccountTypeFieldPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Type here'**
  String get profileDeleteAccountTypeFieldPlaceholder;

  /// No description provided for @profileDeleteAccountTypeMismatchSnack.
  ///
  /// In en, this message translates to:
  /// **'Type the confirmation word exactly as shown.'**
  String get profileDeleteAccountTypeMismatchSnack;

  /// No description provided for @profileHelpCenterOpenFailedSnack.
  ///
  /// In en, this message translates to:
  /// **'Could not open help center'**
  String get profileHelpCenterOpenFailedSnack;

  /// No description provided for @profileGeneralLoadFailedSnack.
  ///
  /// In en, this message translates to:
  /// **'Could not load profile'**
  String get profileGeneralLoadFailedSnack;

  /// No description provided for @profileGeneralNameRequiredSnack.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get profileGeneralNameRequiredSnack;

  /// No description provided for @profileGeneralNameTooLongSnack.
  ///
  /// In en, this message translates to:
  /// **'Name is too long'**
  String get profileGeneralNameTooLongSnack;

  /// No description provided for @profileGeneralUpdatedSnack.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileGeneralUpdatedSnack;

  /// No description provided for @profileGeneralPictureUpdatedSnack.
  ///
  /// In en, this message translates to:
  /// **'Profile picture updated'**
  String get profileGeneralPictureUpdatedSnack;

  /// No description provided for @profileGeneralInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Edit your profile details'**
  String get profileGeneralInfoSubtitle;

  /// No description provided for @profileGeneralNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get profileGeneralNameLabel;

  /// No description provided for @profileGeneralNameHint.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get profileGeneralNameHint;

  /// No description provided for @profileGeneralMobileLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile phone'**
  String get profileGeneralMobileLabel;

  /// No description provided for @profileGeneralPhonePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'70 123 456'**
  String get profileGeneralPhonePlaceholder;

  /// No description provided for @profileGeneralLimitsNotice.
  ///
  /// In en, this message translates to:
  /// **'Name changes are limited. Phone number changes require verification.'**
  String get profileGeneralLimitsNotice;

  /// No description provided for @profileGeneralUpdateButton.
  ///
  /// In en, this message translates to:
  /// **'Update info'**
  String get profileGeneralUpdateButton;

  /// No description provided for @profileGeneralSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get profileGeneralSaving;

  /// No description provided for @profileGeneralAvatarSemanticUpdating.
  ///
  /// In en, this message translates to:
  /// **'Updating profile photo'**
  String get profileGeneralAvatarSemanticUpdating;

  /// No description provided for @profileGeneralAvatarSemanticChange.
  ///
  /// In en, this message translates to:
  /// **'Profile photo. Double tap to change'**
  String get profileGeneralAvatarSemanticChange;

  /// No description provided for @profileGeneralEmptyValue.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get profileGeneralEmptyValue;

  /// No description provided for @profileGeneralDefaultDisplayName.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get profileGeneralDefaultDisplayName;

  /// No description provided for @reportListFabLabel.
  ///
  /// In en, this message translates to:
  /// **'Report pollution'**
  String get reportListFabLabel;

  /// No description provided for @reportListAppBarStartNewReportLabel.
  ///
  /// In en, this message translates to:
  /// **'Start a new report'**
  String get reportListAppBarStartNewReportLabel;

  /// No description provided for @reportListDraftChipLabel.
  ///
  /// In en, this message translates to:
  /// **'Draft · {photoCount, plural, =0{no photos} one{1 photo} other{{photoCount} photos}} · {savedAgo}'**
  String reportListDraftChipLabel(int photoCount, String savedAgo);

  /// No description provided for @reportListDraftChipSemantic.
  ///
  /// In en, this message translates to:
  /// **'Saved draft with {photoCount, plural, one{1 photo} other{{photoCount} photos}}. Double tap to open.'**
  String reportListDraftChipSemantic(int photoCount);

  /// No description provided for @reportListSearchSemantic.
  ///
  /// In en, this message translates to:
  /// **'Search reports'**
  String get reportListSearchSemantic;

  /// No description provided for @reportAvailabilityCheckFailedSnack.
  ///
  /// In en, this message translates to:
  /// **'Could not check reporting availability right now.'**
  String get reportAvailabilityCheckFailedSnack;

  /// No description provided for @reportFinishStepsSnack.
  ///
  /// In en, this message translates to:
  /// **'Please finish the missing steps before submitting.'**
  String get reportFinishStepsSnack;

  /// No description provided for @reportSubmittedPartialUploadSnack.
  ///
  /// In en, this message translates to:
  /// **'Report submitted. Photos could not be uploaded.'**
  String get reportSubmittedPartialUploadSnack;

  /// No description provided for @reportPhotoUploadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Photo upload failed'**
  String get reportPhotoUploadFailedTitle;

  /// No description provided for @reportPhotoUploadFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Photos could not be uploaded. Tap Retry to try again, or Skip to submit without photos.'**
  String get reportPhotoUploadFailedBody;

  /// No description provided for @reportReviewEvidenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Evidence'**
  String get reportReviewEvidenceTitle;

  /// No description provided for @reportReviewPhotoCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} photo} other{{count} photos}}'**
  String reportReviewPhotoCount(int count);

  /// No description provided for @reportReviewAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get reportReviewAddPhoto;

  /// No description provided for @reportReviewCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get reportReviewCategoryTitle;

  /// No description provided for @reportReviewChooseCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose category'**
  String get reportReviewChooseCategory;

  /// No description provided for @reportReviewTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get reportReviewTitleLabel;

  /// No description provided for @reportReviewAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add title'**
  String get reportReviewAddTitle;

  /// No description provided for @reportReviewSeverityTitle.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get reportReviewSeverityTitle;

  /// No description provided for @reportReviewLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get reportReviewLocationTitle;

  /// No description provided for @reportReviewPinnedShort.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get reportReviewPinnedShort;

  /// No description provided for @reportReviewPinMacedonia.
  ///
  /// In en, this message translates to:
  /// **'Pin in Macedonia'**
  String get reportReviewPinMacedonia;

  /// No description provided for @reportReviewExtraContextTitle.
  ///
  /// In en, this message translates to:
  /// **'Extra context'**
  String get reportReviewExtraContextTitle;

  /// No description provided for @reportReviewCleanupEffortTitle.
  ///
  /// In en, this message translates to:
  /// **'Cleanup effort'**
  String get reportReviewCleanupEffortTitle;

  /// No description provided for @reportSelectCategorySemantic.
  ///
  /// In en, this message translates to:
  /// **'Select report category'**
  String get reportSelectCategorySemantic;

  /// No description provided for @reportBackSemantic.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get reportBackSemantic;

  /// No description provided for @reportPreviousStepSemantic.
  ///
  /// In en, this message translates to:
  /// **'Previous step'**
  String get reportPreviousStepSemantic;

  /// No description provided for @reportCleanupEffortChipHint.
  ///
  /// In en, this message translates to:
  /// **'Double-tap to set estimated cleanup effort.'**
  String get reportCleanupEffortChipHint;

  /// No description provided for @reportCleanupEffortOneToTwo.
  ///
  /// In en, this message translates to:
  /// **'1–2 people'**
  String get reportCleanupEffortOneToTwo;

  /// No description provided for @reportCleanupEffortThreeToFive.
  ///
  /// In en, this message translates to:
  /// **'3–5 people'**
  String get reportCleanupEffortThreeToFive;

  /// No description provided for @reportCleanupEffortSixToTen.
  ///
  /// In en, this message translates to:
  /// **'6–10 people'**
  String get reportCleanupEffortSixToTen;

  /// No description provided for @reportCleanupEffortTenPlus.
  ///
  /// In en, this message translates to:
  /// **'10+ people'**
  String get reportCleanupEffortTenPlus;

  /// No description provided for @reportCleanupEffortNotSure.
  ///
  /// In en, this message translates to:
  /// **'Not sure'**
  String get reportCleanupEffortNotSure;

  /// No description provided for @reportCooldownTitle.
  ///
  /// In en, this message translates to:
  /// **'Reporting cooldown'**
  String get reportCooldownTitle;

  /// No description provided for @reportCooldownBody.
  ///
  /// In en, this message translates to:
  /// **'You have used all 10 report credits and the emergency allowance.\n\nEmergency unlock retries in {retry}.\n\n{hint}'**
  String reportCooldownBody(String retry, String hint);

  /// No description provided for @reportCooldownModalIntro.
  ///
  /// In en, this message translates to:
  /// **'You have used all 10 report credits and the emergency allowance.'**
  String get reportCooldownModalIntro;

  /// No description provided for @reportCooldownModalRetryLead.
  ///
  /// In en, this message translates to:
  /// **'Emergency unlock retries in'**
  String get reportCooldownModalRetryLead;

  /// No description provided for @reportCooldownDurationListSeparator.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get reportCooldownDurationListSeparator;

  /// No description provided for @reportCooldownDurationDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} day} other{{count} days}}'**
  String reportCooldownDurationDays(int count);

  /// No description provided for @reportCooldownDurationHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} hour} other{{count} hours}}'**
  String reportCooldownDurationHours(int count);

  /// No description provided for @reportCooldownDurationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} minute} other{{count} minutes}}'**
  String reportCooldownDurationMinutes(int count);

  /// No description provided for @reportCooldownDurationSeconds.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} second} other{{count} seconds}}'**
  String reportCooldownDurationSeconds(int count);

  /// No description provided for @reportCooldownRetrySoon.
  ///
  /// In en, this message translates to:
  /// **'soon'**
  String get reportCooldownRetrySoon;

  /// No description provided for @reportCooldownRetrySeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String reportCooldownRetrySeconds(int seconds);

  /// No description provided for @reportCooldownRetryMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String reportCooldownRetryMinutes(int minutes);

  /// No description provided for @reportCooldownRetryHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String reportCooldownRetryHoursMinutes(int hours, int minutes);

  /// No description provided for @reportCapacityUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Join events or eco actions to get more reports (up to 10).'**
  String get reportCapacityUnlockHint;

  /// No description provided for @reportCapacityPillHealthy.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} credit} other{{count} credits}}'**
  String reportCapacityPillHealthy(int count);

  /// No description provided for @reportCapacityBannerHealthyTitle.
  ///
  /// In en, this message translates to:
  /// **'All set'**
  String get reportCapacityBannerHealthyTitle;

  /// No description provided for @reportCapacityBannerHealthyBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} credit available} other{{count} credits available}}'**
  String reportCapacityBannerHealthyBody(int count);

  /// No description provided for @reportCapacityReviewHealthy.
  ///
  /// In en, this message translates to:
  /// **'Uses 1 credit.'**
  String get reportCapacityReviewHealthy;

  /// No description provided for @reportCapacityPillLow.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} report left} other{{count} reports left}}'**
  String reportCapacityPillLow(int count);

  /// No description provided for @reportCapacityBannerLowTitle.
  ///
  /// In en, this message translates to:
  /// **'Almost out'**
  String get reportCapacityBannerLowTitle;

  /// No description provided for @reportCapacityBannerLowBody.
  ///
  /// In en, this message translates to:
  /// **'Low balance. {hint}'**
  String reportCapacityBannerLowBody(String hint);

  /// No description provided for @reportCapacityReviewLow.
  ///
  /// In en, this message translates to:
  /// **'Uses 1 credit. {hint}'**
  String reportCapacityReviewLow(String hint);

  /// No description provided for @reportCapacityPillEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency report'**
  String get reportCapacityPillEmergency;

  /// No description provided for @reportCapacityBannerEmergencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency report'**
  String get reportCapacityBannerEmergencyTitle;

  /// No description provided for @reportCapacityBannerEmergencyBody.
  ///
  /// In en, this message translates to:
  /// **'You have one left. {hint}'**
  String reportCapacityBannerEmergencyBody(String hint);

  /// No description provided for @reportCapacityReviewEmergency.
  ///
  /// In en, this message translates to:
  /// **'Uses your emergency report. {hint}'**
  String reportCapacityReviewEmergency(String hint);

  /// No description provided for @reportCapacityPillCooldown.
  ///
  /// In en, this message translates to:
  /// **'Cooldown active'**
  String get reportCapacityPillCooldown;

  /// No description provided for @reportCapacityBannerCooldownTitle.
  ///
  /// In en, this message translates to:
  /// **'Cooldown'**
  String get reportCapacityBannerCooldownTitle;

  /// No description provided for @reportCapacityCooldownRetryOnDate.
  ///
  /// In en, this message translates to:
  /// **'Next emergency: {date}.'**
  String reportCapacityCooldownRetryOnDate(String date);

  /// No description provided for @reportCapacityCooldownTryAgainInAbout.
  ///
  /// In en, this message translates to:
  /// **'Try again in ~{duration}.'**
  String reportCapacityCooldownTryAgainInAbout(String duration);

  /// No description provided for @reportCapacityCooldownStillWaiting.
  ///
  /// In en, this message translates to:
  /// **'Emergency report cooling down.'**
  String get reportCapacityCooldownStillWaiting;

  /// No description provided for @reportCapacityBannerCooldownBody.
  ///
  /// In en, this message translates to:
  /// **'{retryLine} {hint}'**
  String reportCapacityBannerCooldownBody(String retryLine, String hint);

  /// No description provided for @reportCapacityReviewCooldown.
  ///
  /// In en, this message translates to:
  /// **'{retryLine} {hint}'**
  String reportCapacityReviewCooldown(String retryLine, String hint);

  /// No description provided for @reportCapacitySecondsRemaining.
  ///
  /// In en, this message translates to:
  /// **'({seconds}s remaining)'**
  String reportCapacitySecondsRemaining(int seconds);

  /// No description provided for @feedRetryLoadingMore.
  ///
  /// In en, this message translates to:
  /// **'Retry loading more'**
  String get feedRetryLoadingMore;

  /// No description provided for @feedLoadingMoreSemantic.
  ///
  /// In en, this message translates to:
  /// **'Loading more feed posts'**
  String get feedLoadingMoreSemantic;

  /// No description provided for @feedShowAllSites.
  ///
  /// In en, this message translates to:
  /// **'Show all sites'**
  String get feedShowAllSites;

  /// No description provided for @feedPullToRefreshSemantic.
  ///
  /// In en, this message translates to:
  /// **'Pull to refresh'**
  String get feedPullToRefreshSemantic;

  /// No description provided for @feedRefreshingSemantic.
  ///
  /// In en, this message translates to:
  /// **'Refreshing feed'**
  String get feedRefreshingSemantic;

  /// No description provided for @feedLoadMoreFailedSnack.
  ///
  /// In en, this message translates to:
  /// **'Could not load more posts. Tap retry.'**
  String get feedLoadMoreFailedSnack;

  /// No description provided for @feedRefreshStaleSnack.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh. Showing the last loaded feed.'**
  String get feedRefreshStaleSnack;

  /// No description provided for @feedScrollToTopSemantic.
  ///
  /// In en, this message translates to:
  /// **'Scroll feed to top'**
  String get feedScrollToTopSemantic;

  /// No description provided for @feedPollutionFeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Pollution feed'**
  String get feedPollutionFeedTitle;

  /// No description provided for @feedOfflineBanner.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Showing the last loaded feed.'**
  String get feedOfflineBanner;

  /// No description provided for @feedCaughtUpTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up'**
  String get feedCaughtUpTitle;

  /// No description provided for @feedCaughtUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pull to refresh for new reports'**
  String get feedCaughtUpSubtitle;

  /// No description provided for @feedMoreFiltersTooltip.
  ///
  /// In en, this message translates to:
  /// **'More filters'**
  String get feedMoreFiltersTooltip;

  /// No description provided for @feedFilterSemantic.
  ///
  /// In en, this message translates to:
  /// **'{name} filter'**
  String feedFilterSemantic(String name);

  /// No description provided for @feedEmptyAllTitle.
  ///
  /// In en, this message translates to:
  /// **'No pollution sites yet'**
  String get feedEmptyAllTitle;

  /// No description provided for @feedEmptyAllHint.
  ///
  /// In en, this message translates to:
  /// **'Pull to refresh or check back later'**
  String get feedEmptyAllHint;

  /// No description provided for @feedEmptyUrgentTitle.
  ///
  /// In en, this message translates to:
  /// **'No urgent sites right now'**
  String get feedEmptyUrgentTitle;

  /// No description provided for @feedEmptyUrgentHint.
  ///
  /// In en, this message translates to:
  /// **'Show all sites or try another filter'**
  String get feedEmptyUrgentHint;

  /// No description provided for @feedEmptyNearbyTitleOnline.
  ///
  /// In en, this message translates to:
  /// **'No nearby sites found'**
  String get feedEmptyNearbyTitleOnline;

  /// No description provided for @feedEmptyNearbyTitleOffline.
  ///
  /// In en, this message translates to:
  /// **'Enable location to see nearby sites'**
  String get feedEmptyNearbyTitleOffline;

  /// No description provided for @feedEmptyNearbyHintOffline.
  ///
  /// In en, this message translates to:
  /// **'Turn on location services and allow access'**
  String get feedEmptyNearbyHintOffline;

  /// No description provided for @feedEmptyNearbyHintOnline.
  ///
  /// In en, this message translates to:
  /// **'Show all sites or try another filter'**
  String get feedEmptyNearbyHintOnline;

  /// No description provided for @feedEmptyMostVotedTitle.
  ///
  /// In en, this message translates to:
  /// **'No sites have been voted yet'**
  String get feedEmptyMostVotedTitle;

  /// No description provided for @feedEmptyMostVotedHint.
  ///
  /// In en, this message translates to:
  /// **'Show all sites or try another filter'**
  String get feedEmptyMostVotedHint;

  /// No description provided for @feedEmptyRecentTitle.
  ///
  /// In en, this message translates to:
  /// **'No recent reports'**
  String get feedEmptyRecentTitle;

  /// No description provided for @feedEmptyRecentHint.
  ///
  /// In en, this message translates to:
  /// **'Show all sites or try another filter'**
  String get feedEmptyRecentHint;

  /// No description provided for @feedEmptySavedTitle.
  ///
  /// In en, this message translates to:
  /// **'No saved sites yet'**
  String get feedEmptySavedTitle;

  /// No description provided for @feedEmptySavedHint.
  ///
  /// In en, this message translates to:
  /// **'Save sites from the menu to find them here'**
  String get feedEmptySavedHint;

  /// No description provided for @feedFilterAllName.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get feedFilterAllName;

  /// No description provided for @feedFilterAllDesc.
  ///
  /// In en, this message translates to:
  /// **'Balanced feed ranking'**
  String get feedFilterAllDesc;

  /// No description provided for @feedFilterUrgentName.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get feedFilterUrgentName;

  /// No description provided for @feedFilterUrgentDesc.
  ///
  /// In en, this message translates to:
  /// **'High-priority incidents first'**
  String get feedFilterUrgentDesc;

  /// No description provided for @feedFilterNearbyName.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get feedFilterNearbyName;

  /// No description provided for @feedFilterNearbyDesc.
  ///
  /// In en, this message translates to:
  /// **'Closest reports around you'**
  String get feedFilterNearbyDesc;

  /// No description provided for @feedFilterMostVotedName.
  ///
  /// In en, this message translates to:
  /// **'Top support'**
  String get feedFilterMostVotedName;

  /// No description provided for @feedFilterMostVotedDesc.
  ///
  /// In en, this message translates to:
  /// **'Most community-backed'**
  String get feedFilterMostVotedDesc;

  /// No description provided for @feedFilterRecentName.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get feedFilterRecentName;

  /// No description provided for @feedFilterRecentDesc.
  ///
  /// In en, this message translates to:
  /// **'Newest reports first'**
  String get feedFilterRecentDesc;

  /// No description provided for @feedFilterSavedName.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get feedFilterSavedName;

  /// No description provided for @feedFilterSavedDesc.
  ///
  /// In en, this message translates to:
  /// **'Sites you bookmarked'**
  String get feedFilterSavedDesc;

  /// No description provided for @feedFiltersSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Feed filters'**
  String get feedFiltersSheetTitle;

  /// No description provided for @feedFiltersSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to browse reports'**
  String get feedFiltersSheetSubtitle;

  /// No description provided for @commentsFeedHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get commentsFeedHeaderTitle;

  /// No description provided for @commentsSortTop.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get commentsSortTop;

  /// No description provided for @commentsSortNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get commentsSortNew;

  /// No description provided for @commentsEditingBanner.
  ///
  /// In en, this message translates to:
  /// **'Editing comment'**
  String get commentsEditingBanner;

  /// No description provided for @commentsBodyTooLong.
  ///
  /// In en, this message translates to:
  /// **'Comment is too long (max 2000 characters).'**
  String get commentsBodyTooLong;

  /// No description provided for @commentsReplyTargetFallback.
  ///
  /// In en, this message translates to:
  /// **'comment'**
  String get commentsReplyTargetFallback;

  /// No description provided for @reportIssueSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Report issue'**
  String get reportIssueSheetTitle;

  /// No description provided for @reportIssueSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get reportIssueSubmitting;

  /// No description provided for @reportIssueSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get reportIssueSubmit;

  /// No description provided for @reportIssueFailedSnack.
  ///
  /// In en, this message translates to:
  /// **'Could not send report. Try again.'**
  String get reportIssueFailedSnack;

  /// No description provided for @reportIssueSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Help us improve. Why are you reporting this site?'**
  String get reportIssueSheetSubtitle;

  /// No description provided for @reportIssueDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Additional details (optional)'**
  String get reportIssueDetailsLabel;

  /// No description provided for @reportIssueDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the issue…'**
  String get reportIssueDetailsHint;

  /// No description provided for @mapResetFiltersSemantic.
  ///
  /// In en, this message translates to:
  /// **'Reset filters'**
  String get mapResetFiltersSemantic;

  /// No description provided for @mapOpenMapsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open Maps'**
  String get mapOpenMapsFailed;

  /// No description provided for @mapSearchRecentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get mapSearchRecentsLabel;

  /// No description provided for @mapSearchClearRecentsButton.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get mapSearchClearRecentsButton;

  /// No description provided for @mapSearchEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Search pollution sites'**
  String get mapSearchEmptyTitle;

  /// No description provided for @mapSearchEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Type a title, category, or description. Or tap a recent search below.'**
  String get mapSearchEmptySubtitle;

  /// No description provided for @mapSearchNoResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching sites'**
  String get mapSearchNoResultsTitle;

  /// No description provided for @mapSearchNoResultsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try different words or clear filters on the map.'**
  String get mapSearchNoResultsSubtitle;

  /// No description provided for @mapSearchResultsBadge.
  ///
  /// In en, this message translates to:
  /// **'{count} results'**
  String mapSearchResultsBadge(int count);

  /// No description provided for @mapSearchRemoteLoading.
  ///
  /// In en, this message translates to:
  /// **'Searching all sites…'**
  String get mapSearchRemoteLoading;

  /// No description provided for @mapSearchRemoteError.
  ///
  /// In en, this message translates to:
  /// **'Could not search all sites.'**
  String get mapSearchRemoteError;

  /// No description provided for @mapSearchRemoteRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get mapSearchRemoteRetry;

  /// No description provided for @mapSearchSectionOnMap.
  ///
  /// In en, this message translates to:
  /// **'On this map'**
  String get mapSearchSectionOnMap;

  /// No description provided for @mapSearchSectionEverywhere.
  ///
  /// In en, this message translates to:
  /// **'More results'**
  String get mapSearchSectionEverywhere;

  /// No description provided for @mapSearchSuggestionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get mapSearchSuggestionsLabel;

  /// No description provided for @mapUpdatedToast.
  ///
  /// In en, this message translates to:
  /// **'Map updated'**
  String get mapUpdatedToast;

  /// No description provided for @mapErrorAutoRetryFootnote.
  ///
  /// In en, this message translates to:
  /// **'We’ll retry automatically in a few seconds. You can also tap Try again.'**
  String get mapErrorAutoRetryFootnote;

  /// No description provided for @mapFilteredSitesAnnounce.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{One site shown on the map} other{{count} sites shown on the map}}'**
  String mapFilteredSitesAnnounce(int count);

  /// No description provided for @mapClusterExpansionAnnounce.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{One site separated on the map} other{{count} sites separated on the map}}'**
  String mapClusterExpansionAnnounce(int count);

  /// No description provided for @mapScreenRouteSemantic.
  ///
  /// In en, this message translates to:
  /// **'Pollution map. Tap pins to view site details.'**
  String get mapScreenRouteSemantic;

  /// No description provided for @mapLoadingSemantic.
  ///
  /// In en, this message translates to:
  /// **'Loading map'**
  String get mapLoadingSemantic;

  /// No description provided for @mapSiteNotOnMapSnack.
  ///
  /// In en, this message translates to:
  /// **'This site is not available on the map yet.'**
  String get mapSiteNotOnMapSnack;

  /// No description provided for @mapOpenLocationFailedSnack.
  ///
  /// In en, this message translates to:
  /// **'Could not open this location on the map.'**
  String get mapOpenLocationFailedSnack;

  /// No description provided for @mapEmptyFiltersLiveRegion.
  ///
  /// In en, this message translates to:
  /// **'No sites match your current filters'**
  String get mapEmptyFiltersLiveRegion;

  /// No description provided for @mapEmptyFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'No sites match your filters'**
  String get mapEmptyFiltersTitle;

  /// No description provided for @mapEmptyFiltersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting filters or search.'**
  String get mapEmptyFiltersSubtitle;

  /// No description provided for @mapDirectionsSheetOpenInMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Maps'**
  String get mapDirectionsSheetOpenInMaps;

  /// No description provided for @mapDirectionsSheetViewLocation.
  ///
  /// In en, this message translates to:
  /// **'View location'**
  String get mapDirectionsSheetViewLocation;

  /// No description provided for @mapDirectionsSheetSubtitleDirections.
  ///
  /// In en, this message translates to:
  /// **'Choose which app to get directions.'**
  String get mapDirectionsSheetSubtitleDirections;

  /// No description provided for @mapDirectionsSheetSubtitleViewLocation.
  ///
  /// In en, this message translates to:
  /// **'Choose which app to view this location on a map.'**
  String get mapDirectionsSheetSubtitleViewLocation;

  /// No description provided for @mapDirectionsAppleMapsTitle.
  ///
  /// In en, this message translates to:
  /// **'Apple Maps'**
  String get mapDirectionsAppleMapsTitle;

  /// No description provided for @mapDirectionsAppleMapsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Built-in maps on this device.'**
  String get mapDirectionsAppleMapsSubtitle;

  /// No description provided for @mapDirectionsGoogleMapsTitle.
  ///
  /// In en, this message translates to:
  /// **'Google Maps'**
  String get mapDirectionsGoogleMapsTitle;

  /// No description provided for @mapDirectionsGoogleMapsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Web and Google Maps app.'**
  String get mapDirectionsGoogleMapsSubtitle;

  /// No description provided for @mapSemanticCloseActionsMenu.
  ///
  /// In en, this message translates to:
  /// **'Close actions menu'**
  String get mapSemanticCloseActionsMenu;

  /// No description provided for @mapSemanticOpenActionsMenu.
  ///
  /// In en, this message translates to:
  /// **'Open actions menu'**
  String get mapSemanticOpenActionsMenu;

  /// No description provided for @mapSemanticHideHeatmap.
  ///
  /// In en, this message translates to:
  /// **'Hide heatmap'**
  String get mapSemanticHideHeatmap;

  /// No description provided for @mapSemanticShowHeatmap.
  ///
  /// In en, this message translates to:
  /// **'Show heatmap'**
  String get mapSemanticShowHeatmap;

  /// No description provided for @mapSemanticSwitchToLightMap.
  ///
  /// In en, this message translates to:
  /// **'Switch to light map'**
  String get mapSemanticSwitchToLightMap;

  /// No description provided for @mapSemanticSwitchToDarkMap.
  ///
  /// In en, this message translates to:
  /// **'Switch to dark map'**
  String get mapSemanticSwitchToDarkMap;

  /// No description provided for @mapSemanticZoomWholeCountry.
  ///
  /// In en, this message translates to:
  /// **'Zoom out to show whole country'**
  String get mapSemanticZoomWholeCountry;

  /// No description provided for @mapSemanticUnlockRotation.
  ///
  /// In en, this message translates to:
  /// **'Unlock map rotation'**
  String get mapSemanticUnlockRotation;

  /// No description provided for @mapSemanticLockRotation.
  ///
  /// In en, this message translates to:
  /// **'Lock map rotation'**
  String get mapSemanticLockRotation;

  /// No description provided for @mapSemanticCenterOnMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Center map on my location'**
  String get mapSemanticCenterOnMyLocation;

  /// No description provided for @mapSemanticSearchSites.
  ///
  /// In en, this message translates to:
  /// **'Search sites'**
  String get mapSemanticSearchSites;

  /// No description provided for @mapSemanticResetRotationNorth.
  ///
  /// In en, this message translates to:
  /// **'Reset map rotation to north'**
  String get mapSemanticResetRotationNorth;

  /// No description provided for @mapFilterButtonSemanticPrefix.
  ///
  /// In en, this message translates to:
  /// **'Filter sites.'**
  String get mapFilterButtonSemanticPrefix;

  /// No description provided for @mapFilterButtonSemanticNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No sites match current filters in this area.'**
  String get mapFilterButtonSemanticNoMatch;

  /// No description provided for @mapFilterButtonSemanticNoSites.
  ///
  /// In en, this message translates to:
  /// **'No sites in this area.'**
  String get mapFilterButtonSemanticNoSites;

  /// No description provided for @mapFilterButtonSemanticSitesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} sites in this area.'**
  String mapFilterButtonSemanticSitesCount(int count);

  /// No description provided for @mapFilterButtonSemanticSuffix.
  ///
  /// In en, this message translates to:
  /// **'Tap to open filters.'**
  String get mapFilterButtonSemanticSuffix;

  /// No description provided for @mapFilterCountNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No match'**
  String get mapFilterCountNoMatch;

  /// No description provided for @mapFilterCountNoSites.
  ///
  /// In en, this message translates to:
  /// **'No sites'**
  String get mapFilterCountNoSites;

  /// No description provided for @mapFilterSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter sites'**
  String get mapFilterSheetTitle;

  /// No description provided for @mapFilterCloseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close filters'**
  String get mapFilterCloseTooltip;

  /// No description provided for @mapFilterSectionSiteStatus.
  ///
  /// In en, this message translates to:
  /// **'Site status'**
  String get mapFilterSectionSiteStatus;

  /// No description provided for @mapFilterSectionArea.
  ///
  /// In en, this message translates to:
  /// **'Municipality / area'**
  String get mapFilterSectionArea;

  /// No description provided for @mapFilterSectionPollutionType.
  ///
  /// In en, this message translates to:
  /// **'Pollution type'**
  String get mapFilterSectionPollutionType;

  /// No description provided for @mapFilterSectionVisibility.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get mapFilterSectionVisibility;

  /// No description provided for @mapFilterShowArchivedSites.
  ///
  /// In en, this message translates to:
  /// **'Show archived sites'**
  String get mapFilterShowArchivedSites;

  /// No description provided for @mapFilterShowingLiveRegion.
  ///
  /// In en, this message translates to:
  /// **'{visible} of {total} pollution sites visible in this area'**
  String mapFilterShowingLiveRegion(int visible, int total);

  /// No description provided for @mapFilterShowingInline.
  ///
  /// In en, this message translates to:
  /// **'Showing {visible} of {total}'**
  String mapFilterShowingInline(int visible, int total);

  /// No description provided for @mapFilterPollutionTypeSemantic.
  ///
  /// In en, this message translates to:
  /// **'Filter {type} sites'**
  String mapFilterPollutionTypeSemantic(String type);

  /// No description provided for @mapFilterPollutionTypeHintOff.
  ///
  /// In en, this message translates to:
  /// **'Double tap to show this type'**
  String get mapFilterPollutionTypeHintOff;

  /// No description provided for @mapFilterPollutionTypeHintOn.
  ///
  /// In en, this message translates to:
  /// **'Double tap to hide this type'**
  String get mapFilterPollutionTypeHintOn;

  /// No description provided for @mapFilterPollutionTypeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown type'**
  String get mapFilterPollutionTypeUnknown;

  /// No description provided for @mapFilterSiteStatusReported.
  ///
  /// In en, this message translates to:
  /// **'Reported'**
  String get mapFilterSiteStatusReported;

  /// No description provided for @mapFilterSiteStatusVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get mapFilterSiteStatusVerified;

  /// No description provided for @mapFilterSiteStatusCleanupScheduled.
  ///
  /// In en, this message translates to:
  /// **'Cleanup scheduled'**
  String get mapFilterSiteStatusCleanupScheduled;

  /// No description provided for @mapFilterSiteStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get mapFilterSiteStatusInProgress;

  /// No description provided for @mapFilterSiteStatusCleaned.
  ///
  /// In en, this message translates to:
  /// **'Cleaned'**
  String get mapFilterSiteStatusCleaned;

  /// No description provided for @mapFilterSiteStatusDisputed.
  ///
  /// In en, this message translates to:
  /// **'Disputed'**
  String get mapFilterSiteStatusDisputed;

  /// No description provided for @mapFilterSiteStatusArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get mapFilterSiteStatusArchived;

  /// No description provided for @mapFilterSiteStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown status'**
  String get mapFilterSiteStatusUnknown;

  /// No description provided for @mapFilterSiteStatusSemantic.
  ///
  /// In en, this message translates to:
  /// **'Filter {status} sites'**
  String mapFilterSiteStatusSemantic(String status);

  /// No description provided for @mapFilterSiteStatusHintOff.
  ///
  /// In en, this message translates to:
  /// **'Double tap to show this status'**
  String get mapFilterSiteStatusHintOff;

  /// No description provided for @mapFilterSiteStatusHintOn.
  ///
  /// In en, this message translates to:
  /// **'Double tap to hide this status'**
  String get mapFilterSiteStatusHintOn;

  /// No description provided for @mapGeoWholeCountry.
  ///
  /// In en, this message translates to:
  /// **'Whole country'**
  String get mapGeoWholeCountry;

  /// No description provided for @mapGeoSkopjeWhole.
  ///
  /// In en, this message translates to:
  /// **'All Skopje municipalities'**
  String get mapGeoSkopjeWhole;

  /// No description provided for @mapGeoSkopje.
  ///
  /// In en, this message translates to:
  /// **'Skopje'**
  String get mapGeoSkopje;

  /// No description provided for @mapGeoSkopjeCentar.
  ///
  /// In en, this message translates to:
  /// **'Centar'**
  String get mapGeoSkopjeCentar;

  /// No description provided for @mapGeoSkopjeAerodrom.
  ///
  /// In en, this message translates to:
  /// **'Aerodrom'**
  String get mapGeoSkopjeAerodrom;

  /// No description provided for @mapGeoSkopjeKarposh.
  ///
  /// In en, this message translates to:
  /// **'Karpoš'**
  String get mapGeoSkopjeKarposh;

  /// No description provided for @mapGeoSkopjeChair.
  ///
  /// In en, this message translates to:
  /// **'Čair'**
  String get mapGeoSkopjeChair;

  /// No description provided for @mapGeoSkopjeKiselaVoda.
  ///
  /// In en, this message translates to:
  /// **'Kisela Voda'**
  String get mapGeoSkopjeKiselaVoda;

  /// No description provided for @mapGeoSkopjeGaziBaba.
  ///
  /// In en, this message translates to:
  /// **'Gazi Baba'**
  String get mapGeoSkopjeGaziBaba;

  /// No description provided for @mapGeoSkopjeButel.
  ///
  /// In en, this message translates to:
  /// **'Butel'**
  String get mapGeoSkopjeButel;

  /// No description provided for @mapGeoSkopjeGjorcePetrov.
  ///
  /// In en, this message translates to:
  /// **'Gjorče Petrov'**
  String get mapGeoSkopjeGjorcePetrov;

  /// No description provided for @mapGeoSkopjeSaraj.
  ///
  /// In en, this message translates to:
  /// **'Saraj'**
  String get mapGeoSkopjeSaraj;

  /// No description provided for @mapGeoBitola.
  ///
  /// In en, this message translates to:
  /// **'Bitola'**
  String get mapGeoBitola;

  /// No description provided for @mapGeoKumanovo.
  ///
  /// In en, this message translates to:
  /// **'Kumanovo'**
  String get mapGeoKumanovo;

  /// No description provided for @mapGeoPrilep.
  ///
  /// In en, this message translates to:
  /// **'Prilep'**
  String get mapGeoPrilep;

  /// No description provided for @mapGeoTetovo.
  ///
  /// In en, this message translates to:
  /// **'Tetovo'**
  String get mapGeoTetovo;

  /// No description provided for @mapGeoVeles.
  ///
  /// In en, this message translates to:
  /// **'Veles'**
  String get mapGeoVeles;

  /// No description provided for @mapGeoOhrid.
  ///
  /// In en, this message translates to:
  /// **'Ohrid'**
  String get mapGeoOhrid;

  /// No description provided for @mapGeoStip.
  ///
  /// In en, this message translates to:
  /// **'Štip'**
  String get mapGeoStip;

  /// No description provided for @mapGeoGostivar.
  ///
  /// In en, this message translates to:
  /// **'Gostivar'**
  String get mapGeoGostivar;

  /// No description provided for @mapGeoStrumica.
  ///
  /// In en, this message translates to:
  /// **'Strumica'**
  String get mapGeoStrumica;

  /// No description provided for @mapGeoKavadarci.
  ///
  /// In en, this message translates to:
  /// **'Kavadarci'**
  String get mapGeoKavadarci;

  /// No description provided for @mapGeoKocani.
  ///
  /// In en, this message translates to:
  /// **'Kočani'**
  String get mapGeoKocani;

  /// No description provided for @mapGeoStruga.
  ///
  /// In en, this message translates to:
  /// **'Struga'**
  String get mapGeoStruga;

  /// No description provided for @mapGeoRadovis.
  ///
  /// In en, this message translates to:
  /// **'Radoviš'**
  String get mapGeoRadovis;

  /// No description provided for @mapGeoGevgelija.
  ///
  /// In en, this message translates to:
  /// **'Gevgelija'**
  String get mapGeoGevgelija;

  /// No description provided for @mapGeoKrivaPalanka.
  ///
  /// In en, this message translates to:
  /// **'Kriva Palanka'**
  String get mapGeoKrivaPalanka;

  /// No description provided for @mapGeoSvetiNikole.
  ///
  /// In en, this message translates to:
  /// **'Sveti Nikole'**
  String get mapGeoSvetiNikole;

  /// No description provided for @mapGeoVinica.
  ///
  /// In en, this message translates to:
  /// **'Vinica'**
  String get mapGeoVinica;

  /// No description provided for @mapGeoDelcevo.
  ///
  /// In en, this message translates to:
  /// **'Delčevo'**
  String get mapGeoDelcevo;

  /// No description provided for @mapGeoProbistip.
  ///
  /// In en, this message translates to:
  /// **'Probishtip'**
  String get mapGeoProbistip;

  /// No description provided for @mapGeoBerovo.
  ///
  /// In en, this message translates to:
  /// **'Berovo'**
  String get mapGeoBerovo;

  /// No description provided for @mapGeoKratovo.
  ///
  /// In en, this message translates to:
  /// **'Kratovo'**
  String get mapGeoKratovo;

  /// No description provided for @mapGeoKicevo.
  ///
  /// In en, this message translates to:
  /// **'Kičevo'**
  String get mapGeoKicevo;

  /// No description provided for @mapGeoMakedonskiBrod.
  ///
  /// In en, this message translates to:
  /// **'Makedonski Brod'**
  String get mapGeoMakedonskiBrod;

  /// No description provided for @mapGeoNegotino.
  ///
  /// In en, this message translates to:
  /// **'Negotino'**
  String get mapGeoNegotino;

  /// No description provided for @mapGeoResen.
  ///
  /// In en, this message translates to:
  /// **'Resen'**
  String get mapGeoResen;

  /// No description provided for @mapGeoUnknownArea.
  ///
  /// In en, this message translates to:
  /// **'Unknown area'**
  String get mapGeoUnknownArea;

  /// No description provided for @mapPinPreviewSemantic.
  ///
  /// In en, this message translates to:
  /// **'{title}, {severity}. Double tap to preview.'**
  String mapPinPreviewSemantic(String title, String severity);

  /// No description provided for @mapClusterSemantic.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 pollution site clustered. Double tap to expand.} other{{count} pollution sites clustered. Double tap to expand.}}'**
  String mapClusterSemantic(int count);

  /// No description provided for @mapUserLocationSemantic.
  ///
  /// In en, this message translates to:
  /// **'Your current location'**
  String get mapUserLocationSemantic;

  /// No description provided for @mapPreviewDismissAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Dismissed site preview.'**
  String get mapPreviewDismissAnnouncement;

  /// No description provided for @mapDistanceMetersAway.
  ///
  /// In en, this message translates to:
  /// **'{meters} m away'**
  String mapDistanceMetersAway(int meters);

  /// No description provided for @mapDistanceKilometersAway.
  ///
  /// In en, this message translates to:
  /// **'{kilometers} km away'**
  String mapDistanceKilometersAway(String kilometers);

  /// No description provided for @mapPreviewSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Selected site: {title}. {distance}. Double tap preview for details. Swipe down to dismiss.'**
  String mapPreviewSemanticLabel(String title, String distance);

  /// No description provided for @mapPreviewSemanticHint.
  ///
  /// In en, this message translates to:
  /// **'Use actions for directions or full details.'**
  String get mapPreviewSemanticHint;

  /// No description provided for @mapPreviewDirections.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get mapPreviewDirections;

  /// No description provided for @mapPreviewDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get mapPreviewDetails;

  /// No description provided for @mapSyncNoticeSemanticRefreshHint.
  ///
  /// In en, this message translates to:
  /// **'Double tap to refresh map now.'**
  String get mapSyncNoticeSemanticRefreshHint;

  /// No description provided for @mapSyncLiveUpdatesDelayed.
  ///
  /// In en, this message translates to:
  /// **'Live updates delayed. Retrying quietly…'**
  String get mapSyncLiveUpdatesDelayed;

  /// No description provided for @mapSyncConnectionUnstable.
  ///
  /// In en, this message translates to:
  /// **'Connection unstable. Refreshing in background…'**
  String get mapSyncConnectionUnstable;

  /// No description provided for @mapSyncOfflineSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Offline. Showing your last saved map snapshot.'**
  String get mapSyncOfflineSnapshot;

  /// No description provided for @mapSyncOfflineSnapshotJustNow.
  ///
  /// In en, this message translates to:
  /// **'Offline. Showing your last saved map snapshot from just now.'**
  String get mapSyncOfflineSnapshotJustNow;

  /// No description provided for @mapSyncOfflineSnapshotMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'Offline. Showing your last saved map snapshot from {minutes}m ago.'**
  String mapSyncOfflineSnapshotMinutesAgo(int minutes);

  /// No description provided for @mapSyncOfflineSnapshotHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'Offline. Showing your last saved map snapshot from {hours}h ago.'**
  String mapSyncOfflineSnapshotHoursAgo(int hours);

  /// No description provided for @mapSearchLocationUnavailableSnack.
  ///
  /// In en, this message translates to:
  /// **'Location is unavailable for this site.'**
  String get mapSearchLocationUnavailableSnack;

  /// No description provided for @mapSearchFieldSemanticHint.
  ///
  /// In en, this message translates to:
  /// **'Type a title, category, or description'**
  String get mapSearchFieldSemanticHint;

  /// No description provided for @mapSearchBarHint.
  ///
  /// In en, this message translates to:
  /// **'Search sites…'**
  String get mapSearchBarHint;

  /// No description provided for @locationRetryAddressSemantic.
  ///
  /// In en, this message translates to:
  /// **'Retry address'**
  String get locationRetryAddressSemantic;

  /// No description provided for @photoReviewDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard this photo?'**
  String get photoReviewDiscardTitle;

  /// No description provided for @photoReviewDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'You can retake or choose another from your library.'**
  String get photoReviewDiscardBody;

  /// No description provided for @reportPhotoReviewSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Review evidence'**
  String get reportPhotoReviewSheetTitle;

  /// No description provided for @reportPhotoReviewSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep the clearest frame before adding it to the report.'**
  String get reportPhotoReviewSheetSubtitle;

  /// No description provided for @reportPhotoReviewSemantic.
  ///
  /// In en, this message translates to:
  /// **'Review and confirm photo before adding to report'**
  String get reportPhotoReviewSemantic;

  /// No description provided for @reportPhotoReviewCloseSemantic.
  ///
  /// In en, this message translates to:
  /// **'Close without adding photo'**
  String get reportPhotoReviewCloseSemantic;

  /// No description provided for @reportPhotoReviewRetake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get reportPhotoReviewRetake;

  /// No description provided for @reportPhotoReviewUsePhoto.
  ///
  /// In en, this message translates to:
  /// **'Use this photo'**
  String get reportPhotoReviewUsePhoto;

  /// No description provided for @reportPhotoReviewRetakeSemantic.
  ///
  /// In en, this message translates to:
  /// **'Retake photo'**
  String get reportPhotoReviewRetakeSemantic;

  /// No description provided for @reportPhotoReviewUseSemantic.
  ///
  /// In en, this message translates to:
  /// **'Use this photo'**
  String get reportPhotoReviewUseSemantic;

  /// No description provided for @reportPhotoReviewPreviewSemantic.
  ///
  /// In en, this message translates to:
  /// **'Photo preview'**
  String get reportPhotoReviewPreviewSemantic;

  /// No description provided for @reportPhotoGridAddShort.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get reportPhotoGridAddShort;

  /// No description provided for @reportPhotoGridAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get reportPhotoGridAdd;

  /// No description provided for @reportPhotoGridSourceHint.
  ///
  /// In en, this message translates to:
  /// **'Camera or library'**
  String get reportPhotoGridSourceHint;

  /// No description provided for @reportPhotoGridAttachedCount.
  ///
  /// In en, this message translates to:
  /// **'{current} of {max} photos attached'**
  String reportPhotoGridAttachedCount(int current, int max);

  /// No description provided for @reportPhotoOpenGallerySemantic.
  ///
  /// In en, this message translates to:
  /// **'Open report photo gallery'**
  String get reportPhotoOpenGallerySemantic;

  /// No description provided for @reportPhotoTapToReviewSingle.
  ///
  /// In en, this message translates to:
  /// **'Tap to review photo'**
  String get reportPhotoTapToReviewSingle;

  /// No description provided for @reportPhotoTapToReviewMany.
  ///
  /// In en, this message translates to:
  /// **'Tap to review photos'**
  String get reportPhotoTapToReviewMany;

  /// No description provided for @reportPhotoVerificationHelpPrimarySelected.
  ///
  /// In en, this message translates to:
  /// **'Keep the first photo as the clearest overview of the site.'**
  String get reportPhotoVerificationHelpPrimarySelected;

  /// No description provided for @reportPhotoVerificationHelpPrimaryOther.
  ///
  /// In en, this message translates to:
  /// **'Use extra photos only for details, scale, or another useful angle.'**
  String get reportPhotoVerificationHelpPrimaryOther;

  /// No description provided for @reportPhotoVerificationHelpEmpty.
  ///
  /// In en, this message translates to:
  /// **'Start with one clear overview of the site. Add detail only if it helps.'**
  String get reportPhotoVerificationHelpEmpty;

  /// No description provided for @reportPhotoStackCaptionSingle.
  ///
  /// In en, this message translates to:
  /// **'One clear photo is enough. Add another only if it helps explain the site.'**
  String get reportPhotoStackCaptionSingle;

  /// No description provided for @reportPhotoStackCaptionMany.
  ///
  /// In en, this message translates to:
  /// **'{count} photos attached. Keep only the frames that make the report easier to verify.'**
  String reportPhotoStackCaptionMany(int count);

  /// No description provided for @reportPhotoSemanticThumbnail.
  ///
  /// In en, this message translates to:
  /// **'Photo {index} of {total}. Double-tap to select.'**
  String reportPhotoSemanticThumbnail(int index, int total);

  /// No description provided for @reportPhotoSemanticRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get reportPhotoSemanticRemove;

  /// No description provided for @reportPhotoSemanticAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add evidence photo'**
  String get reportPhotoSemanticAddPhoto;

  /// No description provided for @reportPhotoSemanticReportPhoto.
  ///
  /// In en, this message translates to:
  /// **'Report photo {index}'**
  String reportPhotoSemanticReportPhoto(int index);

  /// No description provided for @reportRequirementPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add at least one photo'**
  String get reportRequirementPhotos;

  /// No description provided for @reportRequirementCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose a category'**
  String get reportRequirementCategory;

  /// No description provided for @reportRequirementTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a short title'**
  String get reportRequirementTitle;

  /// No description provided for @reportRequirementLocation.
  ///
  /// In en, this message translates to:
  /// **'Confirm a location in Macedonia'**
  String get reportRequirementLocation;

  /// No description provided for @reportCooldownUnlockHintDefault.
  ///
  /// In en, this message translates to:
  /// **'Join and verify attendance, or create an eco action to unlock more reports.'**
  String get reportCooldownUnlockHintDefault;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all notifications'**
  String get notificationsShowAll;

  /// No description provided for @notificationsPreferencesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Notification preferences'**
  String get notificationsPreferencesTooltip;

  /// No description provided for @notificationsScrollToTopSemantic.
  ///
  /// In en, this message translates to:
  /// **'Scroll notifications to top'**
  String get notificationsScrollToTopSemantic;

  /// No description provided for @notificationsRetryLoadingMore.
  ///
  /// In en, this message translates to:
  /// **'Retry loading more'**
  String get notificationsRetryLoadingMore;

  /// No description provided for @notificationsMarkAllReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not mark all as read. Please try again.'**
  String get notificationsMarkAllReadFailed;

  /// No description provided for @notificationsAllMarkedReadSuccess.
  ///
  /// In en, this message translates to:
  /// **'All notifications marked as read'**
  String get notificationsAllMarkedReadSuccess;

  /// No description provided for @notificationsSiteUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This site is no longer available.'**
  String get notificationsSiteUnavailable;

  /// No description provided for @notificationsReadStateUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update read state. Please try again.'**
  String get notificationsReadStateUpdateFailed;

  /// No description provided for @notificationsMarkedUnreadLocal.
  ///
  /// In en, this message translates to:
  /// **'Marked as unread (local).'**
  String get notificationsMarkedUnreadLocal;

  /// No description provided for @notificationsArchivedFromView.
  ///
  /// In en, this message translates to:
  /// **'Notification archived from this view'**
  String get notificationsArchivedFromView;

  /// No description provided for @notificationsPrefsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load notification preferences.'**
  String get notificationsPrefsLoadFailed;

  /// No description provided for @notificationsPreferenceUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update preference. Please try again.'**
  String get notificationsPreferenceUpdateFailed;

  /// No description provided for @notificationsPrefsSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification preferences'**
  String get notificationsPrefsSheetTitle;

  /// No description provided for @notificationsPrefsSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Mute notification types you do not want to receive.'**
  String get notificationsPrefsSheetSubtitle;

  /// No description provided for @notificationsPrefMuted.
  ///
  /// In en, this message translates to:
  /// **'Muted'**
  String get notificationsPrefMuted;

  /// No description provided for @notificationsPrefEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get notificationsPrefEnabled;

  /// No description provided for @notificationsTypeSiteUpdates.
  ///
  /// In en, this message translates to:
  /// **'Site updates'**
  String get notificationsTypeSiteUpdates;

  /// No description provided for @notificationsTypeReportStatus.
  ///
  /// In en, this message translates to:
  /// **'Report status'**
  String get notificationsTypeReportStatus;

  /// No description provided for @notificationsTypeUpvotes.
  ///
  /// In en, this message translates to:
  /// **'Upvotes'**
  String get notificationsTypeUpvotes;

  /// No description provided for @notificationsTypeComments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get notificationsTypeComments;

  /// No description provided for @notificationsTypeNearbyReports.
  ///
  /// In en, this message translates to:
  /// **'Nearby reports'**
  String get notificationsTypeNearbyReports;

  /// No description provided for @notificationsTypeCleanupEvents.
  ///
  /// In en, this message translates to:
  /// **'Cleanup events'**
  String get notificationsTypeCleanupEvents;

  /// No description provided for @notificationsTypeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get notificationsTypeSystem;

  /// No description provided for @notificationsSwipeMarkUnread.
  ///
  /// In en, this message translates to:
  /// **'Mark unread'**
  String get notificationsSwipeMarkUnread;

  /// No description provided for @notificationsSwipeMarkRead.
  ///
  /// In en, this message translates to:
  /// **'Mark read'**
  String get notificationsSwipeMarkRead;

  /// No description provided for @notificationsSwipeArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get notificationsSwipeArchive;

  /// No description provided for @notificationsDebugPreviewTriggered.
  ///
  /// In en, this message translates to:
  /// **'Local notification preview triggered'**
  String get notificationsDebugPreviewTriggered;

  /// No description provided for @notificationsAllCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up'**
  String get notificationsAllCaughtUp;

  /// No description provided for @notificationsUnreadUpdatesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unread update} other{{count} unread updates}}'**
  String notificationsUnreadUpdatesCount(int count);

  /// No description provided for @notificationsUnreadBannerOne.
  ///
  /// In en, this message translates to:
  /// **'1 unread notification needs your attention'**
  String get notificationsUnreadBannerOne;

  /// No description provided for @notificationsUnreadBannerMany.
  ///
  /// In en, this message translates to:
  /// **'{count} unread notifications need your attention'**
  String notificationsUnreadBannerMany(int count);

  /// No description provided for @notificationsSwipeHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe right to mark read or unread · left to archive'**
  String get notificationsSwipeHint;

  /// No description provided for @notificationsEmptyUnreadTitle.
  ///
  /// In en, this message translates to:
  /// **'No unread notifications'**
  String get notificationsEmptyUnreadTitle;

  /// No description provided for @notificationsEmptyAllTitle.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notificationsEmptyAllTitle;

  /// No description provided for @notificationsEmptyUnreadBody.
  ///
  /// In en, this message translates to:
  /// **'You are all caught up. New updates will appear here.'**
  String get notificationsEmptyUnreadBody;

  /// No description provided for @notificationsEmptyAllBody.
  ///
  /// In en, this message translates to:
  /// **'When people react to sites and actions, you will see updates here.'**
  String get notificationsEmptyAllBody;

  /// No description provided for @notificationsErrorLoadTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load notifications'**
  String get notificationsErrorLoadTitle;

  /// No description provided for @notificationsErrorLoadFallback.
  ///
  /// In en, this message translates to:
  /// **'Please check your connection and try again.'**
  String get notificationsErrorLoadFallback;

  /// No description provided for @notificationsErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network issue while loading notifications.'**
  String get notificationsErrorNetwork;

  /// No description provided for @notificationsErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while loading notifications.'**
  String get notificationsErrorGeneric;

  /// No description provided for @notificationsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get notificationsFilterAll;

  /// No description provided for @notificationsFilterUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get notificationsFilterUnread;

  /// No description provided for @eventsEventNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Event not found'**
  String get eventsEventNotFoundTitle;

  /// No description provided for @eventsEventNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'This event is no longer available.'**
  String get eventsEventNotFoundBody;

  /// No description provided for @eventsDetailBrowseEvents.
  ///
  /// In en, this message translates to:
  /// **'Browse events'**
  String get eventsDetailBrowseEvents;

  /// No description provided for @eventsDetailCouldNotRefresh.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t refresh. Showing saved details.'**
  String get eventsDetailCouldNotRefresh;

  /// No description provided for @eventsDetailRetryRefresh.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get eventsDetailRetryRefresh;

  /// No description provided for @eventsDetailLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get eventsDetailLocationTitle;

  /// No description provided for @eventsDetailCopyAddress.
  ///
  /// In en, this message translates to:
  /// **'Copy address'**
  String get eventsDetailCopyAddress;

  /// No description provided for @eventsDetailAddressCopied.
  ///
  /// In en, this message translates to:
  /// **'Address copied'**
  String get eventsDetailAddressCopied;

  /// No description provided for @eventsDetailLocationLongPressHint.
  ///
  /// In en, this message translates to:
  /// **'Long-press for full address and actions'**
  String get eventsDetailLocationLongPressHint;

  /// No description provided for @eventsDetailCoverImageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Image unavailable'**
  String get eventsDetailCoverImageUnavailable;

  /// No description provided for @eventsWeatherUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'Forecast isn’t available right now.'**
  String get eventsWeatherUnavailableBody;

  /// No description provided for @eventsWeatherRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get eventsWeatherRetry;

  /// No description provided for @eventsUnableToStartEventGeneric.
  ///
  /// In en, this message translates to:
  /// **'Could not start the event. Check your connection and try again.'**
  String get eventsUnableToStartEventGeneric;

  /// No description provided for @eventsStartEventTooEarly.
  ///
  /// In en, this message translates to:
  /// **'You can start this eco action once the scheduled start time arrives.'**
  String get eventsStartEventTooEarly;

  /// No description provided for @eventsJoinNotYetOpen.
  ///
  /// In en, this message translates to:
  /// **'Joining opens when the scheduled start time arrives.'**
  String get eventsJoinNotYetOpen;

  /// No description provided for @eventsJoinWindowClosed.
  ///
  /// In en, this message translates to:
  /// **'You can no longer join this action. Joining stayed open until 15 minutes after the scheduled start.'**
  String get eventsJoinWindowClosed;

  /// No description provided for @errorEventEndAtTooFar.
  ///
  /// In en, this message translates to:
  /// **'The planned end cannot be that far after the start. Try a shorter extension.'**
  String get errorEventEndAtTooFar;

  /// No description provided for @errorEventsEndDifferentSkopjeCalendarDay.
  ///
  /// In en, this message translates to:
  /// **'The end time must be on the same calendar day as the start (Europe/Skopje).'**
  String get errorEventsEndDifferentSkopjeCalendarDay;

  /// No description provided for @errorEventsEndAfterSkopjeLocalDay.
  ///
  /// In en, this message translates to:
  /// **'The event must end by 23:59 on the start day.'**
  String get errorEventsEndAfterSkopjeLocalDay;

  /// No description provided for @eventsAwaitingModerationCta.
  ///
  /// In en, this message translates to:
  /// **'Awaiting approval'**
  String get eventsAwaitingModerationCta;

  /// No description provided for @eventsModerationBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Awaiting approval'**
  String get eventsModerationBannerTitle;

  /// No description provided for @eventsModerationBannerBody.
  ///
  /// In en, this message translates to:
  /// **'This action is visible to you as the organizer. Volunteers will be able to join after moderators approve it.'**
  String get eventsModerationBannerBody;

  /// No description provided for @eventsAttendeeModerationBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Awaiting approval'**
  String get eventsAttendeeModerationBannerTitle;

  /// No description provided for @eventsAttendeeModerationBannerBody.
  ///
  /// In en, this message translates to:
  /// **'Moderators are reviewing this action. You can open it, but joining opens only after approval.'**
  String get eventsAttendeeModerationBannerBody;

  /// No description provided for @eventsDeclinedBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Not approved'**
  String get eventsDeclinedBannerTitle;

  /// No description provided for @eventsDeclinedBannerBody.
  ///
  /// In en, this message translates to:
  /// **'This event did not meet the criteria. Edit and resubmit to try again.'**
  String get eventsDeclinedBannerBody;

  /// No description provided for @eventsDeclinedResubmitCta.
  ///
  /// In en, this message translates to:
  /// **'Edit & resubmit'**
  String get eventsDeclinedResubmitCta;

  /// No description provided for @eventsDeclinedDashboardPill.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get eventsDeclinedDashboardPill;

  /// No description provided for @eventsPendingDashboardPill.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get eventsPendingDashboardPill;

  /// No description provided for @eventsEventPendingPublicCta.
  ///
  /// In en, this message translates to:
  /// **'Not open for joining yet'**
  String get eventsEventPendingPublicCta;

  /// No description provided for @eventsFeedOfflineStaleBanner.
  ///
  /// In en, this message translates to:
  /// **'Showing saved events — couldn’t refresh. Pull down to retry.'**
  String get eventsFeedOfflineStaleBanner;

  /// No description provided for @eventsFeedInitialLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t load events. Check your connection and try again.'**
  String get eventsFeedInitialLoadFailed;

  /// No description provided for @eventsOrganizerInvalidateQrTitle.
  ///
  /// In en, this message translates to:
  /// **'Invalidate previous QR codes'**
  String get eventsOrganizerInvalidateQrTitle;

  /// No description provided for @eventsOrganizerInvalidateQrSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use if a code was shared or photographed. Already scanned codes stay valid until they expire; this rotates the session so new scans need a fresh QR.'**
  String get eventsOrganizerInvalidateQrSubtitle;

  /// No description provided for @eventsOrganizerQrSessionRotated.
  ///
  /// In en, this message translates to:
  /// **'QR session updated. Show the new code to attendees.'**
  String get eventsOrganizerQrSessionRotated;

  /// No description provided for @eventsOrganizerQrRotateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not invalidate codes. Try again.'**
  String get eventsOrganizerQrRotateFailed;

  /// No description provided for @eventsEditEventTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit event'**
  String get eventsEditEventTitle;

  /// No description provided for @eventsEditEventSave.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get eventsEditEventSave;

  /// No description provided for @editEventTitleTooLong.
  ///
  /// In en, this message translates to:
  /// **'Title must be at most {max} characters.'**
  String editEventTitleTooLong(int max);

  /// No description provided for @editEventDescriptionTooLong.
  ///
  /// In en, this message translates to:
  /// **'Description must be at most {max} characters.'**
  String editEventDescriptionTooLong(int max);

  /// No description provided for @editEventMaxParticipantsInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid whole number of spots, or leave blank for no limit.'**
  String get editEventMaxParticipantsInvalid;

  /// No description provided for @editEventMaxParticipantsRange.
  ///
  /// In en, this message translates to:
  /// **'Team size must be between {min} and {max}, or leave blank for no limit.'**
  String editEventMaxParticipantsRange(int min, int max);

  /// No description provided for @editEventGearLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You can select up to {max} gear items.'**
  String editEventGearLimitReached(int max);

  /// No description provided for @editEventDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get editEventDiscardTitle;

  /// No description provided for @editEventDiscardMessage.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. If you leave now, they will be lost.'**
  String get editEventDiscardMessage;

  /// No description provided for @editEventDiscardConfirm.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get editEventDiscardConfirm;

  /// No description provided for @editEventDiscardKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get editEventDiscardKeepEditing;

  /// No description provided for @editEventSchedulePreviewFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not check for schedule conflicts. You can still save; the server will reject overlapping times.'**
  String get editEventSchedulePreviewFailed;

  /// No description provided for @editEventOfflineSave.
  ///
  /// In en, this message translates to:
  /// **'You appear to be offline. Connect and try again.'**
  String get editEventOfflineSave;

  /// No description provided for @editEventHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Editing your event'**
  String get editEventHelpTitle;

  /// No description provided for @editEventHelpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule, volunteers, and moderation'**
  String get editEventHelpSubtitle;

  /// No description provided for @editEventHelpButtonTooltip.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get editEventHelpButtonTooltip;

  /// No description provided for @editEventDuplicateSubmitTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule conflict'**
  String get editEventDuplicateSubmitTitle;

  /// No description provided for @editEventDuplicateSubmitBody.
  ///
  /// In en, this message translates to:
  /// **'{title} is already scheduled at {when}. Adjust your times and try again.'**
  String editEventDuplicateSubmitBody(String title, String when);

  /// No description provided for @editEventNoChangesToSave.
  ///
  /// In en, this message translates to:
  /// **'Nothing to save.'**
  String get editEventNoChangesToSave;

  /// No description provided for @editEventPendingModerationBanner.
  ///
  /// In en, this message translates to:
  /// **'This event is still awaiting moderator approval. Changes apply to your draft.'**
  String get editEventPendingModerationBanner;

  /// No description provided for @eventsEventNotEditable.
  ///
  /// In en, this message translates to:
  /// **'This event can no longer be edited.'**
  String get eventsEventNotEditable;

  /// No description provided for @eventsEventUpdated.
  ///
  /// In en, this message translates to:
  /// **'Event updated'**
  String get eventsEventUpdated;

  /// No description provided for @eventsMutationFailedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get eventsMutationFailedGeneric;

  /// No description provided for @eventsScheduleConflictPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Possible schedule overlap'**
  String get eventsScheduleConflictPreviewTitle;

  /// No description provided for @eventsScheduleConflictPreviewBody.
  ///
  /// In en, this message translates to:
  /// **'Another event at this site may overlap your time: {title} at {when}.'**
  String eventsScheduleConflictPreviewBody(String title, String when);

  /// No description provided for @eventsScheduleConflictContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue anyway'**
  String get eventsScheduleConflictContinue;

  /// No description provided for @eventsScheduleConflictAdjustTime.
  ///
  /// In en, this message translates to:
  /// **'Change time'**
  String get eventsScheduleConflictAdjustTime;

  /// No description provided for @eventsDuplicateEventBlocked.
  ///
  /// In en, this message translates to:
  /// **'This time overlaps \"{title}\" ({when}). Choose a different time.'**
  String eventsDuplicateEventBlocked(String title, String when);

  /// No description provided for @eventsManualCheckInAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get eventsManualCheckInAdd;

  /// No description provided for @eventsManualCheckInTitle.
  ///
  /// In en, this message translates to:
  /// **'Manual check-in'**
  String get eventsManualCheckInTitle;

  /// No description provided for @eventsCheckInTitle.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get eventsCheckInTitle;

  /// No description provided for @eventsOrganizerMockAllCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'All mock attendees are already checked in.'**
  String get eventsOrganizerMockAllCheckedIn;

  /// No description provided for @eventsOrganizerAttendeeNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Attendee name'**
  String get eventsOrganizerAttendeeNamePlaceholder;

  /// No description provided for @eventsOrganizerManualCheckInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search volunteers who joined this event, then check them in.'**
  String get eventsOrganizerManualCheckInSubtitle;

  /// No description provided for @eventsOrganizerManualCheckInNoJoiners.
  ///
  /// In en, this message translates to:
  /// **'No volunteers have joined this event yet.'**
  String get eventsOrganizerManualCheckInNoJoiners;

  /// No description provided for @eventsOrganizerManualCheckInSelectParticipant.
  ///
  /// In en, this message translates to:
  /// **'Select a volunteer from the list.'**
  String get eventsOrganizerManualCheckInSelectParticipant;

  /// No description provided for @eventsOrganizerManualCheckInNotParticipant.
  ///
  /// In en, this message translates to:
  /// **'This person is not on the participant list.'**
  String get eventsOrganizerManualCheckInNotParticipant;

  /// No description provided for @eventsOrganizerEnterNameFirst.
  ///
  /// In en, this message translates to:
  /// **'Enter attendee name first.'**
  String get eventsOrganizerEnterNameFirst;

  /// No description provided for @eventsOrganizerNameAlreadyCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'{name} is already checked in.'**
  String eventsOrganizerNameAlreadyCheckedIn(String name);

  /// No description provided for @eventsOrganizerNameAddedByOrganizer.
  ///
  /// In en, this message translates to:
  /// **'{name} added by organizer.'**
  String eventsOrganizerNameAddedByOrganizer(String name);

  /// No description provided for @eventsOrganizerCouldNotRemoveName.
  ///
  /// In en, this message translates to:
  /// **'Could not remove {name}.'**
  String eventsOrganizerCouldNotRemoveName(String name);

  /// No description provided for @eventsOrganizerNameRemovedFromCheckIn.
  ///
  /// In en, this message translates to:
  /// **'{name} removed from check-in.'**
  String eventsOrganizerNameRemovedFromCheckIn(String name);

  /// No description provided for @eventsOrganizerUnableCompleteEvent.
  ///
  /// In en, this message translates to:
  /// **'Unable to complete the event.'**
  String get eventsOrganizerUnableCompleteEvent;

  /// No description provided for @eventsOrganizerEndedTitle.
  ///
  /// In en, this message translates to:
  /// **'Event ended'**
  String get eventsOrganizerEndedTitle;

  /// No description provided for @eventsOrganizerThanksOrganizing.
  ///
  /// In en, this message translates to:
  /// **'Thanks for organizing!'**
  String get eventsOrganizerThanksOrganizing;

  /// No description provided for @eventsOrganizerEndSummaryOneAttendee.
  ///
  /// In en, this message translates to:
  /// **'1 attendee checked in.'**
  String get eventsOrganizerEndSummaryOneAttendee;

  /// No description provided for @eventsOrganizerEndSummaryManyAttendees.
  ///
  /// In en, this message translates to:
  /// **'{count} attendees checked in.'**
  String eventsOrganizerEndSummaryManyAttendees(int count);

  /// No description provided for @eventsOrganizerUploadAfterPhotosHint.
  ///
  /// In en, this message translates to:
  /// **'Upload after photos from the event detail.'**
  String get eventsOrganizerUploadAfterPhotosHint;

  /// No description provided for @eventsOrganizerCompletionCheckedInNone.
  ///
  /// In en, this message translates to:
  /// **'No attendees checked in.'**
  String get eventsOrganizerCompletionCheckedInNone;

  /// No description provided for @eventsOrganizerCompletionJoinedLine.
  ///
  /// In en, this message translates to:
  /// **'{count} volunteers joined'**
  String eventsOrganizerCompletionJoinedLine(int count);

  /// No description provided for @eventsOrganizerCompletionJoinedOfCap.
  ///
  /// In en, this message translates to:
  /// **'{joined} of {cap} spots filled'**
  String eventsOrganizerCompletionJoinedOfCap(int joined, int cap);

  /// No description provided for @eventsOrganizerCompletionSheetSemantic.
  ///
  /// In en, this message translates to:
  /// **'Event completed. Review next steps.'**
  String get eventsOrganizerCompletionSheetSemantic;

  /// No description provided for @eventsOrganizerCompletionBackToEvent.
  ///
  /// In en, this message translates to:
  /// **'Back to event'**
  String get eventsOrganizerCompletionBackToEvent;

  /// No description provided for @eventsOrganizerCompletionAddPhotosNow.
  ///
  /// In en, this message translates to:
  /// **'Add cleanup photos now'**
  String get eventsOrganizerCompletionAddPhotosNow;

  /// No description provided for @eventsOrganizerCompletionWhatNextIntro.
  ///
  /// In en, this message translates to:
  /// **'Wrap up on the event page: document results and share the impact you made together.'**
  String get eventsOrganizerCompletionWhatNextIntro;

  /// No description provided for @eventsOrganizerCompletionNextStepsHeading.
  ///
  /// In en, this message translates to:
  /// **'NEXT STEPS'**
  String get eventsOrganizerCompletionNextStepsHeading;

  /// No description provided for @eventsOrganizerCompletionStepPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Add after photos'**
  String get eventsOrganizerCompletionStepPhotosTitle;

  /// No description provided for @eventsOrganizerCompletionStepPhotosBody.
  ///
  /// In en, this message translates to:
  /// **'Show the difference you made. They appear on the event page for everyone.'**
  String get eventsOrganizerCompletionStepPhotosBody;

  /// No description provided for @eventsOrganizerCompletionStepImpactTitle.
  ///
  /// In en, this message translates to:
  /// **'Log your impact'**
  String get eventsOrganizerCompletionStepImpactTitle;

  /// No description provided for @eventsOrganizerCompletionStepImpactBody.
  ///
  /// In en, this message translates to:
  /// **'Record bags collected, time volunteered, and estimates from the event page.'**
  String get eventsOrganizerCompletionStepImpactBody;

  /// No description provided for @eventsOrganizerCompletionStepVisibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Build trust'**
  String get eventsOrganizerCompletionStepVisibilityTitle;

  /// No description provided for @eventsOrganizerCompletionStepVisibilityBody.
  ///
  /// In en, this message translates to:
  /// **'Photos help moderators verify the cleanup and inspire future actions in your community.'**
  String get eventsOrganizerCompletionStepVisibilityBody;

  /// No description provided for @eventsOrganizerCompletionViewReceipt.
  ///
  /// In en, this message translates to:
  /// **'View impact receipt'**
  String get eventsOrganizerCompletionViewReceipt;

  /// No description provided for @eventsImpactReceiptScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Impact receipt'**
  String get eventsImpactReceiptScreenTitle;

  /// No description provided for @eventsImpactReceiptHeroSemantic.
  ///
  /// In en, this message translates to:
  /// **'Impact receipt for {title}'**
  String eventsImpactReceiptHeroSemantic(String title);

  /// No description provided for @eventsImpactReceiptMetricCheckIns.
  ///
  /// In en, this message translates to:
  /// **'Check-ins'**
  String get eventsImpactReceiptMetricCheckIns;

  /// No description provided for @eventsImpactReceiptMetricParticipants.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get eventsImpactReceiptMetricParticipants;

  /// No description provided for @eventsImpactReceiptMetricBags.
  ///
  /// In en, this message translates to:
  /// **'Bags (reported)'**
  String get eventsImpactReceiptMetricBags;

  /// No description provided for @eventsImpactReceiptProofHeading.
  ///
  /// In en, this message translates to:
  /// **'Proof'**
  String get eventsImpactReceiptProofHeading;

  /// No description provided for @eventsImpactReceiptNoMediaHint.
  ///
  /// In en, this message translates to:
  /// **'Add after photos or structured evidence from the event page when you can.'**
  String get eventsImpactReceiptNoMediaHint;

  /// No description provided for @eventsImpactReceiptAsOf.
  ///
  /// In en, this message translates to:
  /// **'Updated {timestamp}'**
  String eventsImpactReceiptAsOf(String timestamp);

  /// No description provided for @eventsImpactReceiptCompletenessInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get eventsImpactReceiptCompletenessInProgress;

  /// No description provided for @eventsImpactReceiptCompletenessFull.
  ///
  /// In en, this message translates to:
  /// **'Complete record'**
  String get eventsImpactReceiptCompletenessFull;

  /// No description provided for @eventsImpactReceiptCompletenessPartialAfter.
  ///
  /// In en, this message translates to:
  /// **'After photos pending'**
  String get eventsImpactReceiptCompletenessPartialAfter;

  /// No description provided for @eventsImpactReceiptCompletenessPartialEvidence.
  ///
  /// In en, this message translates to:
  /// **'Structured evidence pending'**
  String get eventsImpactReceiptCompletenessPartialEvidence;

  /// No description provided for @eventsImpactReceiptCompletenessPartialBoth.
  ///
  /// In en, this message translates to:
  /// **'After photos and evidence pending'**
  String get eventsImpactReceiptCompletenessPartialBoth;

  /// No description provided for @eventsImpactReceiptShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get eventsImpactReceiptShare;

  /// No description provided for @eventsImpactReceiptCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get eventsImpactReceiptCopyLink;

  /// No description provided for @eventsImpactReceiptLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get eventsImpactReceiptLinkCopied;

  /// No description provided for @eventsImpactReceiptViewCta.
  ///
  /// In en, this message translates to:
  /// **'Impact receipt'**
  String get eventsImpactReceiptViewCta;

  /// No description provided for @eventsImpactReceiptRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get eventsImpactReceiptRetry;

  /// No description provided for @eventsImpactReceiptLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load receipt.'**
  String get eventsImpactReceiptLoadFailed;

  /// No description provided for @eventsImpactReceiptShareSummary.
  ///
  /// In en, this message translates to:
  /// **'{checkIns} check-ins · {bags} bags · {joined} joined'**
  String eventsImpactReceiptShareSummary(int checkIns, int bags, int joined);

  /// No description provided for @errorEventsImpactReceiptNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Impact receipt is not available for this event yet.'**
  String get errorEventsImpactReceiptNotAvailable;

  /// No description provided for @eventsOrganizerDetailPendingAfterPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'After photos'**
  String get eventsOrganizerDetailPendingAfterPhotosTitle;

  /// No description provided for @eventsOrganizerDetailPendingAfterPhotosMessage.
  ///
  /// In en, this message translates to:
  /// **'Upload photos after cleanup so volunteers and moderators can see your results. Use the button below when you are ready.'**
  String get eventsOrganizerDetailPendingAfterPhotosMessage;

  /// No description provided for @eventsAttendeeCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Thank you'**
  String get eventsAttendeeCompletedTitle;

  /// No description provided for @eventsAttendeeCompletedBody.
  ///
  /// In en, this message translates to:
  /// **'This eco action is complete. Thanks for showing up for your community.'**
  String get eventsAttendeeCompletedBody;

  /// No description provided for @eventsAfterPhotosOrganizerEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'No after photos yet. Use the button below to add them.'**
  String get eventsAfterPhotosOrganizerEmptyHint;

  /// No description provided for @eventsEvidenceScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'After photos document your results and appear on the event page.'**
  String get eventsEvidenceScreenSubtitle;

  /// No description provided for @eventsEvidencePhotoCountChip.
  ///
  /// In en, this message translates to:
  /// **'{current} of {max} photos'**
  String eventsEvidencePhotoCountChip(int current, int max);

  /// No description provided for @eventsEvidenceBeforeAfterTabsSemantic.
  ///
  /// In en, this message translates to:
  /// **'Before and after photos'**
  String get eventsEvidenceBeforeAfterTabsSemantic;

  /// No description provided for @eventsEvidenceSavingSemantic.
  ///
  /// In en, this message translates to:
  /// **'Saving after photos'**
  String get eventsEvidenceSavingSemantic;

  /// No description provided for @eventsOrganizerCheckInPausedSnack.
  ///
  /// In en, this message translates to:
  /// **'Check-in paused.'**
  String get eventsOrganizerCheckInPausedSnack;

  /// No description provided for @eventsOrganizerCheckInResumedSnack.
  ///
  /// In en, this message translates to:
  /// **'Check-in resumed.'**
  String get eventsOrganizerCheckInResumedSnack;

  /// No description provided for @eventsOrganizerUnableCancelEvent.
  ///
  /// In en, this message translates to:
  /// **'Unable to cancel the event.'**
  String get eventsOrganizerUnableCancelEvent;

  /// No description provided for @eventsOrganizerEventCancelledSnack.
  ///
  /// In en, this message translates to:
  /// **'Event cancelled.'**
  String get eventsOrganizerEventCancelledSnack;

  /// No description provided for @eventsOrganizerFeedbackCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'{name} checked in'**
  String eventsOrganizerFeedbackCheckedIn(String name);

  /// No description provided for @eventsOrganizerFeedbackInvalidQr.
  ///
  /// In en, this message translates to:
  /// **'Invalid QR code.'**
  String get eventsOrganizerFeedbackInvalidQr;

  /// No description provided for @eventsOrganizerFeedbackWrongEvent.
  ///
  /// In en, this message translates to:
  /// **'Wrong event QR.'**
  String get eventsOrganizerFeedbackWrongEvent;

  /// No description provided for @eventsOrganizerFeedbackPaused.
  ///
  /// In en, this message translates to:
  /// **'Check-in is currently paused.'**
  String get eventsOrganizerFeedbackPaused;

  /// No description provided for @eventsOrganizerFeedbackQrExpired.
  ///
  /// In en, this message translates to:
  /// **'QR expired. Generate a new one.'**
  String get eventsOrganizerFeedbackQrExpired;

  /// No description provided for @eventsOrganizerFeedbackQrReplay.
  ///
  /// In en, this message translates to:
  /// **'QR already used. Regenerating...'**
  String get eventsOrganizerFeedbackQrReplay;

  /// No description provided for @eventsOrganizerFeedbackAlreadyCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'{name} is already checked in.'**
  String eventsOrganizerFeedbackAlreadyCheckedIn(String name);

  /// No description provided for @eventsOrganizerQrRefreshHelp.
  ///
  /// In en, this message translates to:
  /// **'Attendees should always scan the newest QR. The code refreshes automatically before it expires.'**
  String get eventsOrganizerQrRefreshHelp;

  /// No description provided for @eventsOrganizerHoldPhoneForScan.
  ///
  /// In en, this message translates to:
  /// **'Hold your phone so attendees can scan'**
  String get eventsOrganizerHoldPhoneForScan;

  /// No description provided for @eventsOrganizerPausedLabel.
  ///
  /// In en, this message translates to:
  /// **'Check-in paused'**
  String get eventsOrganizerPausedLabel;

  /// No description provided for @eventsOrganizerStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get eventsOrganizerStatusOpen;

  /// No description provided for @eventsOrganizerStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get eventsOrganizerStatusPaused;

  /// No description provided for @eventsOrganizerRefreshInSeconds.
  ///
  /// In en, this message translates to:
  /// **'Refresh in {seconds}s'**
  String eventsOrganizerRefreshInSeconds(int seconds);

  /// No description provided for @eventsOrganizerQrRefreshesWhenOpen.
  ///
  /// In en, this message translates to:
  /// **'QR refreshes automatically and after each scan'**
  String get eventsOrganizerQrRefreshesWhenOpen;

  /// No description provided for @eventsOrganizerResumeForFreshQr.
  ///
  /// In en, this message translates to:
  /// **'Resume check-in to issue a fresh QR'**
  String get eventsOrganizerResumeForFreshQr;

  /// No description provided for @eventsOrganizerQrLoadFailedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Could not load a check-in code. Check your connection and try again.'**
  String get eventsOrganizerQrLoadFailedGeneric;

  /// No description provided for @eventsOrganizerQrRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many refresh attempts. Wait a moment and try again.'**
  String get eventsOrganizerQrRateLimited;

  /// No description provided for @eventsOrganizerSessionSetupFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start check-in. Confirm the event is in progress and try again.'**
  String get eventsOrganizerSessionSetupFailed;

  /// No description provided for @eventsOrganizerConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm check-in'**
  String get eventsOrganizerConfirmTitle;

  /// No description provided for @eventsOrganizerConfirmSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Wants to check in to this event'**
  String get eventsOrganizerConfirmSubtitle;

  /// No description provided for @eventsOrganizerConfirmApprove.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get eventsOrganizerConfirmApprove;

  /// No description provided for @eventsOrganizerConfirmReject.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get eventsOrganizerConfirmReject;

  /// No description provided for @eventsOrganizerConfirmExpired.
  ///
  /// In en, this message translates to:
  /// **'This check-in request has expired.'**
  String get eventsOrganizerConfirmExpired;

  /// No description provided for @eventsVolunteerPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for confirmation'**
  String get eventsVolunteerPendingTitle;

  /// No description provided for @eventsVolunteerPendingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The organizer needs to confirm your check-in...'**
  String get eventsVolunteerPendingSubtitle;

  /// No description provided for @eventsVolunteerRejected.
  ///
  /// In en, this message translates to:
  /// **'Check-in was not confirmed by the organizer.'**
  String get eventsVolunteerRejected;

  /// No description provided for @eventsVolunteerExpired.
  ///
  /// In en, this message translates to:
  /// **'Request expired. Please scan again.'**
  String get eventsVolunteerExpired;

  /// No description provided for @eventsOrganizerQrRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get eventsOrganizerQrRetry;

  /// No description provided for @eventsOrganizerQrBrightnessHint.
  ///
  /// In en, this message translates to:
  /// **'Tip: turn up screen brightness so the code is easier to scan.'**
  String get eventsOrganizerQrBrightnessHint;

  /// No description provided for @eventsOrganizerQrSemantics.
  ///
  /// In en, this message translates to:
  /// **'Check-in QR code. Refreshes in about {seconds} seconds.'**
  String eventsOrganizerQrSemantics(int seconds);

  /// No description provided for @eventsOrganizerQrEncodeError.
  ///
  /// In en, this message translates to:
  /// **'This code could not be drawn. Tap try again.'**
  String get eventsOrganizerQrEncodeError;

  /// No description provided for @eventsOrganizerFeedbackInvalidQrStrict.
  ///
  /// In en, this message translates to:
  /// **'That QR is not valid for check-in.'**
  String get eventsOrganizerFeedbackInvalidQrStrict;

  /// No description provided for @eventsOrganizerFeedbackRequiresJoin.
  ///
  /// In en, this message translates to:
  /// **'Join the event in the app before checking in.'**
  String get eventsOrganizerFeedbackRequiresJoin;

  /// No description provided for @eventsOrganizerFeedbackCheckInUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Check-in is not available for this event right now.'**
  String get eventsOrganizerFeedbackCheckInUnavailable;

  /// No description provided for @eventsOrganizerFeedbackRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait briefly and try again.'**
  String get eventsOrganizerFeedbackRateLimited;

  /// No description provided for @eventsOrganizerCopyQrText.
  ///
  /// In en, this message translates to:
  /// **'Copy QR code text'**
  String get eventsOrganizerCopyQrText;

  /// No description provided for @eventsOrganizerQrTextCopied.
  ///
  /// In en, this message translates to:
  /// **'QR code text copied — paste it in a message to attendees who can\'t scan.'**
  String get eventsOrganizerQrTextCopied;

  /// No description provided for @eventsOrganizerNoQrToCopy.
  ///
  /// In en, this message translates to:
  /// **'No active QR code to copy yet.'**
  String get eventsOrganizerNoQrToCopy;

  /// No description provided for @eventsOrganizerManualOverride.
  ///
  /// In en, this message translates to:
  /// **'Manual override: mark attendee present'**
  String get eventsOrganizerManualOverride;

  /// No description provided for @eventsOrganizerCheckedInHeading.
  ///
  /// In en, this message translates to:
  /// **'Checked in'**
  String get eventsOrganizerCheckedInHeading;

  /// No description provided for @eventsOrganizerEmptyListTitle.
  ///
  /// In en, this message translates to:
  /// **'No one checked in yet'**
  String get eventsOrganizerEmptyListTitle;

  /// No description provided for @eventsOrganizerEmptyListSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Attendees scan your QR to check in'**
  String get eventsOrganizerEmptyListSubtitle;

  /// No description provided for @eventsOrganizerEndEvent.
  ///
  /// In en, this message translates to:
  /// **'End event'**
  String get eventsOrganizerEndEvent;

  /// No description provided for @eventsOrganizerPauseCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Pause check-in'**
  String get eventsOrganizerPauseCheckIn;

  /// No description provided for @eventsOrganizerResumeCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Resume check-in'**
  String get eventsOrganizerResumeCheckIn;

  /// No description provided for @eventsOrganizerCancelEvent.
  ///
  /// In en, this message translates to:
  /// **'Cancel event'**
  String get eventsOrganizerCancelEvent;

  /// No description provided for @eventsOrganizerMoreActionsSemantic.
  ///
  /// In en, this message translates to:
  /// **'More event actions'**
  String get eventsOrganizerMoreActionsSemantic;

  /// No description provided for @eventsOrganizerMoreSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Event actions'**
  String get eventsOrganizerMoreSheetTitle;

  /// No description provided for @eventsOrganizerEndEventConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'End this event?'**
  String get eventsOrganizerEndEventConfirmTitle;

  /// No description provided for @eventsOrganizerEndEventConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Check-in will close and the event will be marked completed. You can upload after photos from the event detail.'**
  String get eventsOrganizerEndEventConfirmMessage;

  /// No description provided for @eventsOrganizerEndEventKeepManaging.
  ///
  /// In en, this message translates to:
  /// **'Keep managing'**
  String get eventsOrganizerEndEventKeepManaging;

  /// No description provided for @eventsOrganizerEndEventConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'End event'**
  String get eventsOrganizerEndEventConfirmAction;

  /// No description provided for @eventsOrganizerCancelEventConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this event?'**
  String get eventsOrganizerCancelEventConfirmTitle;

  /// No description provided for @eventsOrganizerCancelEventConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Volunteers will see the event as cancelled. This cannot be undone from the app.'**
  String get eventsOrganizerCancelEventConfirmMessage;

  /// No description provided for @eventsOrganizerCancelEventKeepEvent.
  ///
  /// In en, this message translates to:
  /// **'Keep event'**
  String get eventsOrganizerCancelEventKeepEvent;

  /// No description provided for @eventsOrganizerCancelEventConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel event'**
  String get eventsOrganizerCancelEventConfirmAction;

  /// No description provided for @eventsOrganizerRemoveAttendeeSemantic.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from check-in'**
  String eventsOrganizerRemoveAttendeeSemantic(String name);

  /// No description provided for @eventsOrganizerSimulateCheckInDev.
  ///
  /// In en, this message translates to:
  /// **'Simulate check-in (dev)'**
  String get eventsOrganizerSimulateCheckInDev;

  /// No description provided for @eventsPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get eventsPhotosTitle;

  /// No description provided for @createEventDefaultDescription.
  ///
  /// In en, this message translates to:
  /// **'Community cleanup action organized by local volunteers.'**
  String get createEventDefaultDescription;

  /// No description provided for @createEventCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Event type'**
  String get createEventCategoryTitle;

  /// No description provided for @createEventCategorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'What kind of action are you organizing?'**
  String get createEventCategorySubtitle;

  /// No description provided for @createEventGearTitle.
  ///
  /// In en, this message translates to:
  /// **'Gear needed'**
  String get createEventGearTitle;

  /// No description provided for @createEventGearSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select everything volunteers should bring.'**
  String get createEventGearSubtitle;

  /// No description provided for @createEventGearDoneSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'Done ({count} selected)'**
  String createEventGearDoneSelectedCount(int count);

  /// No description provided for @createEventGearMultiselectTitle.
  ///
  /// In en, this message translates to:
  /// **'Multi-select'**
  String get createEventGearMultiselectTitle;

  /// No description provided for @createEventGearMultiselectMessage.
  ///
  /// In en, this message translates to:
  /// **'Tap each item volunteers should bring. You can select as many as needed.'**
  String get createEventGearMultiselectMessage;

  /// No description provided for @createEventTeamSizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Team size'**
  String get createEventTeamSizeTitle;

  /// No description provided for @createEventTeamSizeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How many volunteers do you expect?'**
  String get createEventTeamSizeSubtitle;

  /// No description provided for @createEventDifficultyTitle.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get createEventDifficultyTitle;

  /// No description provided for @createEventDifficultySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set expectations for volunteers.'**
  String get createEventDifficultySubtitle;

  /// No description provided for @createEventStepProgress.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of 5'**
  String createEventStepProgress(int step);

  /// No description provided for @createEventEndTimeError.
  ///
  /// In en, this message translates to:
  /// **'End time must be later than start time.'**
  String get createEventEndTimeError;

  /// No description provided for @createEventScheduleStartInPast.
  ///
  /// In en, this message translates to:
  /// **'Choose a start time at least {minutes} minutes from now.'**
  String createEventScheduleStartInPast(int minutes);

  /// No description provided for @createEventScheduleEndInPast.
  ///
  /// In en, this message translates to:
  /// **'Choose an end time at least {minutes} minutes from now.'**
  String createEventScheduleEndInPast(int minutes);

  /// No description provided for @createEventScheduleDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Event date'**
  String get createEventScheduleDateLabel;

  /// No description provided for @createEventScheduleEndAfterDayError.
  ///
  /// In en, this message translates to:
  /// **'The event must end by 23:59 on the same day.'**
  String get createEventScheduleEndAfterDayError;

  /// No description provided for @createEventFieldType.
  ///
  /// In en, this message translates to:
  /// **'Event type'**
  String get createEventFieldType;

  /// No description provided for @createEventPlaceholderType.
  ///
  /// In en, this message translates to:
  /// **'Select event type'**
  String get createEventPlaceholderType;

  /// No description provided for @createEventFieldTeamSize.
  ///
  /// In en, this message translates to:
  /// **'Team size'**
  String get createEventFieldTeamSize;

  /// No description provided for @createEventPlaceholderTeamSize.
  ///
  /// In en, this message translates to:
  /// **'How many people?'**
  String get createEventPlaceholderTeamSize;

  /// No description provided for @createEventFieldDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get createEventFieldDifficulty;

  /// No description provided for @createEventPlaceholderDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Set difficulty level'**
  String get createEventPlaceholderDifficulty;

  /// No description provided for @createEventSubmitLabel.
  ///
  /// In en, this message translates to:
  /// **'Create eco action'**
  String get createEventSubmitLabel;

  /// No description provided for @createEventAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Create event'**
  String get createEventAppBarTitle;

  /// No description provided for @createEventHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Creating an event'**
  String get createEventHelpTitle;

  /// No description provided for @createEventHelpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Quick guide for organizers'**
  String get createEventHelpSubtitle;

  /// No description provided for @createEventHelpBulletModeration.
  ///
  /// In en, this message translates to:
  /// **'Events are reviewed so the community sees accurate, safe cleanups.'**
  String get createEventHelpBulletModeration;

  /// No description provided for @createEventHelpBulletVolunteers.
  ///
  /// In en, this message translates to:
  /// **'Volunteers see your title, schedule, site, gear list, and description once the event is live.'**
  String get createEventHelpBulletVolunteers;

  /// No description provided for @createEventHelpBulletSite.
  ///
  /// In en, this message translates to:
  /// **'Pick a pollution site on the list or map so everyone knows where to meet.'**
  String get createEventHelpBulletSite;

  /// No description provided for @createEventHelpBulletSchedule.
  ///
  /// In en, this message translates to:
  /// **'Pick the event date, then start and end times on that same day.'**
  String get createEventHelpBulletSchedule;

  /// No description provided for @createEventHelpBulletSameDay.
  ///
  /// In en, this message translates to:
  /// **'The event must finish on the same calendar day and by 23:59 at the latest.'**
  String get createEventHelpBulletSameDay;

  /// No description provided for @createEventHelpBulletSubmit.
  ///
  /// In en, this message translates to:
  /// **'When everything required is filled in, use Create eco action to publish.'**
  String get createEventHelpBulletSubmit;

  /// No description provided for @createEventFieldVolunteerCap.
  ///
  /// In en, this message translates to:
  /// **'Volunteer cap'**
  String get createEventFieldVolunteerCap;

  /// No description provided for @createEventVolunteerCapPlaceholderNoLimit.
  ///
  /// In en, this message translates to:
  /// **'No limit'**
  String get createEventVolunteerCapPlaceholderNoLimit;

  /// No description provided for @createEventVolunteerCapUpTo.
  ///
  /// In en, this message translates to:
  /// **'Up to {count} volunteers'**
  String createEventVolunteerCapUpTo(int count);

  /// No description provided for @createEventVolunteerCapSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Volunteer cap'**
  String get createEventVolunteerCapSheetTitle;

  /// No description provided for @createEventVolunteerCapSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional. You can cap sign-ups between 2 and 5000.'**
  String get createEventVolunteerCapSheetSubtitle;

  /// No description provided for @createEventVolunteerCapNoLimit.
  ///
  /// In en, this message translates to:
  /// **'No limit'**
  String get createEventVolunteerCapNoLimit;

  /// No description provided for @createEventVolunteerCapCustomLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get createEventVolunteerCapCustomLabel;

  /// No description provided for @createEventVolunteerCapCustomHint.
  ///
  /// In en, this message translates to:
  /// **'Number (2–5000)'**
  String get createEventVolunteerCapCustomHint;

  /// No description provided for @createEventVolunteerCapApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get createEventVolunteerCapApply;

  /// No description provided for @createEventVolunteerCapInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number between 2 and 5000.'**
  String get createEventVolunteerCapInvalid;

  /// No description provided for @createEventSitePickerLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading sites…'**
  String get createEventSitePickerLoading;

  /// No description provided for @createEventSitePickerOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline list'**
  String get createEventSitePickerOfflineTitle;

  /// No description provided for @createEventSitePickerOfflineMessage.
  ///
  /// In en, this message translates to:
  /// **'Showing built-in sites because the live list was empty or unavailable.'**
  String get createEventSitePickerOfflineMessage;

  /// No description provided for @createEventSitePickerLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh'**
  String get createEventSitePickerLoadFailedTitle;

  /// No description provided for @createEventSitePickerLoadFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'You can still pick from the offline site list. Try again to load live sites.'**
  String get createEventSitePickerLoadFailedMessage;

  /// No description provided for @createEventSitePickerRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get createEventSitePickerRetry;

  /// No description provided for @createEventDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard event?'**
  String get createEventDiscardTitle;

  /// No description provided for @createEventDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'You will lose what you entered on this screen.'**
  String get createEventDiscardBody;

  /// No description provided for @createEventDiscardKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get createEventDiscardKeepEditing;

  /// No description provided for @createEventLoadingSemantic.
  ///
  /// In en, this message translates to:
  /// **'Loading create event form'**
  String get createEventLoadingSemantic;

  /// No description provided for @createEventSectionScheduleCaption.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get createEventSectionScheduleCaption;

  /// No description provided for @createEventSectionDetailsCaption.
  ///
  /// In en, this message translates to:
  /// **'Event details'**
  String get createEventSectionDetailsCaption;

  /// No description provided for @createEventCleanupSiteTitle.
  ///
  /// In en, this message translates to:
  /// **'Cleanup site'**
  String get createEventCleanupSiteTitle;

  /// No description provided for @createEventSelectSiteSemantic.
  ///
  /// In en, this message translates to:
  /// **'Select cleanup site'**
  String get createEventSelectSiteSemantic;

  /// No description provided for @createEventChooseSitePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Choose a pollution site'**
  String get createEventChooseSitePlaceholder;

  /// No description provided for @createEventSiteAnchorHint.
  ///
  /// In en, this message translates to:
  /// **'Every event should be anchored to one cleanup location.'**
  String get createEventSiteAnchorHint;

  /// No description provided for @createEventSiteDistanceAway.
  ///
  /// In en, this message translates to:
  /// **'{distanceKm} km away · {description}'**
  String createEventSiteDistanceAway(String distanceKm, String description);

  /// No description provided for @createEventSiteRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Choose the site before creating the event.'**
  String get createEventSiteRequiredError;

  /// No description provided for @createEventTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Event title'**
  String get createEventTitleLabel;

  /// No description provided for @createEventTitleCounter.
  ///
  /// In en, this message translates to:
  /// **'{current} / {max}'**
  String createEventTitleCounter(int current, int max);

  /// No description provided for @createEventTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Weekend river cleanup'**
  String get createEventTitleHint;

  /// No description provided for @createEventTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Event title is required.'**
  String get createEventTitleRequired;

  /// No description provided for @createEventTitleMinLength.
  ///
  /// In en, this message translates to:
  /// **'Use at least 3 characters for the title.'**
  String get createEventTitleMinLength;

  /// No description provided for @createEventSitePickerTabList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get createEventSitePickerTabList;

  /// No description provided for @createEventSitePickerTabMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get createEventSitePickerTabMap;

  /// No description provided for @createEventSitePickerMapEmpty.
  ///
  /// In en, this message translates to:
  /// **'No sites on the map match this search, or locations are not available yet.'**
  String get createEventSitePickerMapEmpty;

  /// No description provided for @createEventSitePickerMapSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Map of pollution sites'**
  String get createEventSitePickerMapSemanticLabel;

  /// No description provided for @createEventSitePickerMapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a pin to select a site.'**
  String get createEventSitePickerMapHint;

  /// No description provided for @createEventSiteMapPreviewSemantic.
  ///
  /// In en, this message translates to:
  /// **'Open site map picker'**
  String get createEventSiteMapPreviewSemantic;

  /// No description provided for @createEventTypeRequired.
  ///
  /// In en, this message translates to:
  /// **'Select an event type.'**
  String get createEventTypeRequired;

  /// No description provided for @createEventGearPlaceholderQuestion.
  ///
  /// In en, this message translates to:
  /// **'What should volunteers bring?'**
  String get createEventGearPlaceholderQuestion;

  /// No description provided for @createEventGearLabel.
  ///
  /// In en, this message translates to:
  /// **'Gear needed'**
  String get createEventGearLabel;

  /// No description provided for @createEventSelectGearSemantic.
  ///
  /// In en, this message translates to:
  /// **'Select gear needed'**
  String get createEventSelectGearSemantic;

  /// No description provided for @createEventDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get createEventDescriptionLabel;

  /// No description provided for @createEventDescriptionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional: give volunteers more context.'**
  String get createEventDescriptionSubtitle;

  /// No description provided for @createEventDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe what to expect, meeting point, etc.'**
  String get createEventDescriptionHint;

  /// No description provided for @eventsEventNotFoundShort.
  ///
  /// In en, this message translates to:
  /// **'Event not found.'**
  String get eventsEventNotFoundShort;

  /// No description provided for @eventsBeforeLabel.
  ///
  /// In en, this message translates to:
  /// **'Before'**
  String get eventsBeforeLabel;

  /// No description provided for @eventsAfterLabel.
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get eventsAfterLabel;

  /// No description provided for @eventsDiscardChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get eventsDiscardChangesTitle;

  /// No description provided for @eventsDiscardChangesBody.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved photos. Are you sure you want to leave?'**
  String get eventsDiscardChangesBody;

  /// No description provided for @eventsSetCover.
  ///
  /// In en, this message translates to:
  /// **'Set as cover'**
  String get eventsSetCover;

  /// No description provided for @eventsViewFullscreen.
  ///
  /// In en, this message translates to:
  /// **'View fullscreen'**
  String get eventsViewFullscreen;

  /// No description provided for @eventsAddToCalendar.
  ///
  /// In en, this message translates to:
  /// **'Add to calendar'**
  String get eventsAddToCalendar;

  /// No description provided for @eventsParticipantsRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get eventsParticipantsRecent;

  /// No description provided for @eventsParticipantsAz.
  ///
  /// In en, this message translates to:
  /// **'A-Z'**
  String get eventsParticipantsAz;

  /// No description provided for @eventsParticipantsCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Checked-in'**
  String get eventsParticipantsCheckedIn;

  /// No description provided for @eventsSaveImpactSummary.
  ///
  /// In en, this message translates to:
  /// **'Save impact summary'**
  String get eventsSaveImpactSummary;

  /// No description provided for @eventsCheckedInBadge.
  ///
  /// In en, this message translates to:
  /// **'Checked in'**
  String get eventsCheckedInBadge;

  /// No description provided for @eventsCleanupPhotosCount.
  ///
  /// In en, this message translates to:
  /// **'{count} cleanup photos'**
  String eventsCleanupPhotosCount(int count);

  /// No description provided for @eventsCtaStartEvent.
  ///
  /// In en, this message translates to:
  /// **'Start event'**
  String get eventsCtaStartEvent;

  /// No description provided for @eventsCtaManageCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Manage check-in'**
  String get eventsCtaManageCheckIn;

  /// No description provided for @eventsCtaExtendCleanupEnd.
  ///
  /// In en, this message translates to:
  /// **'Extend planned end'**
  String get eventsCtaExtendCleanupEnd;

  /// No description provided for @eventsExtendEndSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Extend cleanup'**
  String get eventsExtendEndSheetTitle;

  /// No description provided for @eventsExtendEndSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Current planned end is {time}.'**
  String eventsExtendEndSheetSubtitle(String time);

  /// No description provided for @eventsExtendEndCurrentChoice.
  ///
  /// In en, this message translates to:
  /// **'New end: {time}'**
  String eventsExtendEndCurrentChoice(String time);

  /// No description provided for @eventsExtendEndPlus15.
  ///
  /// In en, this message translates to:
  /// **'+15 min'**
  String get eventsExtendEndPlus15;

  /// No description provided for @eventsExtendEndPlus30.
  ///
  /// In en, this message translates to:
  /// **'+30 min'**
  String get eventsExtendEndPlus30;

  /// No description provided for @eventsExtendEndPlus60.
  ///
  /// In en, this message translates to:
  /// **'+1 hour'**
  String get eventsExtendEndPlus60;

  /// No description provided for @eventsExtendEndCustomTime.
  ///
  /// In en, this message translates to:
  /// **'Custom time…'**
  String get eventsExtendEndCustomTime;

  /// No description provided for @eventsExtendEndApply.
  ///
  /// In en, this message translates to:
  /// **'Save new end time'**
  String get eventsExtendEndApply;

  /// No description provided for @eventsExtendEndSuccess.
  ///
  /// In en, this message translates to:
  /// **'Planned end updated.'**
  String get eventsExtendEndSuccess;

  /// No description provided for @eventsExtendEndSameAsCurrent.
  ///
  /// In en, this message translates to:
  /// **'That is already the planned end time.'**
  String get eventsExtendEndSameAsCurrent;

  /// No description provided for @eventsExtendEndInvalidRange.
  ///
  /// In en, this message translates to:
  /// **'That end time is not valid for this cleanup.'**
  String get eventsExtendEndInvalidRange;

  /// No description provided for @eventsExtendEndTooSoon.
  ///
  /// In en, this message translates to:
  /// **'Choose an end time a little further ahead.'**
  String get eventsExtendEndTooSoon;

  /// No description provided for @eventsEndSoonBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Cleanup is ending soon'**
  String get eventsEndSoonBannerTitle;

  /// No description provided for @eventsEndSoonBannerBody.
  ///
  /// In en, this message translates to:
  /// **'You can extend the planned end or finish when you are ready.'**
  String get eventsEndSoonBannerBody;

  /// No description provided for @eventsEndSoonBannerExtend.
  ///
  /// In en, this message translates to:
  /// **'Extend'**
  String get eventsEndSoonBannerExtend;

  /// No description provided for @eventsOrganizerExtendEndSemantic.
  ///
  /// In en, this message translates to:
  /// **'Extend planned cleanup end time'**
  String get eventsOrganizerExtendEndSemantic;

  /// No description provided for @eventsOrganizerEndSoonNotifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Cleanup ending soon'**
  String get eventsOrganizerEndSoonNotifyTitle;

  /// No description provided for @eventsOrganizerEndSoonNotifyBody.
  ///
  /// In en, this message translates to:
  /// **'Your cleanup is nearing its planned end. Tap to review.'**
  String get eventsOrganizerEndSoonNotifyBody;

  /// No description provided for @eventsOrganizerEndSoonNotifyChannelName.
  ///
  /// In en, this message translates to:
  /// **'Organizer cleanup reminders'**
  String get eventsOrganizerEndSoonNotifyChannelName;

  /// No description provided for @eventsOrganizerEndSoonNotifyChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Local reminders when a cleanup you run is nearing its planned end.'**
  String get eventsOrganizerEndSoonNotifyChannelDescription;

  /// No description provided for @eventsCtaEditAfterPhotos.
  ///
  /// In en, this message translates to:
  /// **'Edit after photos'**
  String get eventsCtaEditAfterPhotos;

  /// No description provided for @eventsCtaUploadAfterPhotos.
  ///
  /// In en, this message translates to:
  /// **'Upload after photos'**
  String get eventsCtaUploadAfterPhotos;

  /// No description provided for @eventsCtaCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Checked in'**
  String get eventsCtaCheckedIn;

  /// No description provided for @eventsCtaScanToCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Scan to check in'**
  String get eventsCtaScanToCheckIn;

  /// No description provided for @eventsCtaCheckInPaused.
  ///
  /// In en, this message translates to:
  /// **'Check-in paused'**
  String get eventsCtaCheckInPaused;

  /// No description provided for @eventsCtaTurnReminderOff.
  ///
  /// In en, this message translates to:
  /// **'Turn reminder off'**
  String get eventsCtaTurnReminderOff;

  /// No description provided for @eventsCtaSetReminder.
  ///
  /// In en, this message translates to:
  /// **'Set reminder'**
  String get eventsCtaSetReminder;

  /// No description provided for @eventsCtaLeaveEvent.
  ///
  /// In en, this message translates to:
  /// **'Leave event'**
  String get eventsCtaLeaveEvent;

  /// No description provided for @eventsCtaJoinEcoAction.
  ///
  /// In en, this message translates to:
  /// **'Join eco action'**
  String get eventsCtaJoinEcoAction;

  /// No description provided for @eventsStatusUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get eventsStatusUpcoming;

  /// No description provided for @eventsStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get eventsStatusInProgress;

  /// No description provided for @eventsStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get eventsStatusCompleted;

  /// No description provided for @eventsStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get eventsStatusCancelled;

  /// No description provided for @eventsCardActionsSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Event actions'**
  String get eventsCardActionsSheetTitle;

  /// No description provided for @eventsCardCopyTitle.
  ///
  /// In en, this message translates to:
  /// **'Copy event details'**
  String get eventsCardCopyTitle;

  /// No description provided for @eventsCardCopySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Copy title, date and location'**
  String get eventsCardCopySubtitle;

  /// No description provided for @eventsCardCopiedSnack.
  ///
  /// In en, this message translates to:
  /// **'Event details copied.'**
  String get eventsCardCopiedSnack;

  /// No description provided for @eventsCardShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share event'**
  String get eventsCardShareTitle;

  /// No description provided for @eventsCardShareSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share with friends'**
  String get eventsCardShareSubtitle;

  /// No description provided for @eventsCardOpenTitle.
  ///
  /// In en, this message translates to:
  /// **'Open event'**
  String get eventsCardOpenTitle;

  /// No description provided for @eventsCardOpenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View full event details'**
  String get eventsCardOpenSubtitle;

  /// No description provided for @eventsCardMoreActionsSemantic.
  ///
  /// In en, this message translates to:
  /// **'More event actions'**
  String get eventsCardMoreActionsSemantic;

  /// No description provided for @eventsCardSoonLabel.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get eventsCardSoonLabel;

  /// No description provided for @eventsFeedUpNext.
  ///
  /// In en, this message translates to:
  /// **'Up next'**
  String get eventsFeedUpNext;

  /// No description provided for @eventsCountdownStarted.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get eventsCountdownStarted;

  /// No description provided for @eventsCountdownDaysHours.
  ///
  /// In en, this message translates to:
  /// **'Starts in {days}d {hours}h'**
  String eventsCountdownDaysHours(int days, int hours);

  /// No description provided for @eventsCountdownHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'Starts in {hours}h {minutes}m'**
  String eventsCountdownHoursMinutes(int hours, int minutes);

  /// No description provided for @eventsCountdownMinutes.
  ///
  /// In en, this message translates to:
  /// **'Starts in {minutes}m'**
  String eventsCountdownMinutes(int minutes);

  /// No description provided for @eventsShareEventTooltip.
  ///
  /// In en, this message translates to:
  /// **'Share event'**
  String get eventsShareEventTooltip;

  /// No description provided for @eventsAttendeeCheckInSemantic.
  ///
  /// In en, this message translates to:
  /// **'Scan to check in at event'**
  String get eventsAttendeeCheckInSemantic;

  /// No description provided for @eventsAttendeeAlreadyCheckedInSnack.
  ///
  /// In en, this message translates to:
  /// **'You are already checked in.'**
  String get eventsAttendeeAlreadyCheckedInSnack;

  /// No description provided for @eventsAttendeeCheckInPausedSnack.
  ///
  /// In en, this message translates to:
  /// **'Organizer has paused check-in for now.'**
  String get eventsAttendeeCheckInPausedSnack;

  /// No description provided for @eventsAttendeeCheckInCompleteSnack.
  ///
  /// In en, this message translates to:
  /// **'Check-in complete.'**
  String get eventsAttendeeCheckInCompleteSnack;

  /// No description provided for @eventsAttendeeBannerTitleCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'You are checked in'**
  String get eventsAttendeeBannerTitleCheckedIn;

  /// No description provided for @eventsAttendeeBannerTitleInProgress.
  ///
  /// In en, this message translates to:
  /// **'Event is in progress'**
  String get eventsAttendeeBannerTitleInProgress;

  /// No description provided for @eventsAttendeeBannerSubtitleAttendanceConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Attendance confirmed'**
  String get eventsAttendeeBannerSubtitleAttendanceConfirmed;

  /// No description provided for @eventsAttendeeBannerSubtitleCheckedInAt.
  ///
  /// In en, this message translates to:
  /// **'Checked in at {time}'**
  String eventsAttendeeBannerSubtitleCheckedInAt(String time);

  /// No description provided for @eventsAttendeeBannerSubtitleScanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan the organizer\'s QR to check in'**
  String get eventsAttendeeBannerSubtitleScanQr;

  /// No description provided for @eventsAttendeeBannerSubtitlePaused.
  ///
  /// In en, this message translates to:
  /// **'Check-in is temporarily paused'**
  String get eventsAttendeeBannerSubtitlePaused;

  /// No description provided for @eventsDetailShareSuccess.
  ///
  /// In en, this message translates to:
  /// **'Event shared.'**
  String get eventsDetailShareSuccess;

  /// No description provided for @eventsDetailShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open share. Try again.'**
  String get eventsDetailShareFailed;

  /// No description provided for @eventsDetailCalendarAdded.
  ///
  /// In en, this message translates to:
  /// **'Event added to your calendar.'**
  String get eventsDetailCalendarAdded;

  /// No description provided for @eventsDetailCalendarFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not add to calendar. Try again.'**
  String get eventsDetailCalendarFailed;

  /// No description provided for @eventsDetailRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh this event. Try again.'**
  String get eventsDetailRefreshFailed;

  /// No description provided for @eventsDetailCancelledCallout.
  ///
  /// In en, this message translates to:
  /// **'This event has been cancelled.'**
  String get eventsDetailCancelledCallout;

  /// No description provided for @eventsDetailOpenInMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Maps'**
  String get eventsDetailOpenInMaps;

  /// No description provided for @eventsDetailCoverSemantic.
  ///
  /// In en, this message translates to:
  /// **'Cover image for {title}'**
  String eventsDetailCoverSemantic(String title);

  /// No description provided for @eventsDetailGroupedPanelSemantic.
  ///
  /// In en, this message translates to:
  /// **'Location, schedule, and details'**
  String get eventsDetailGroupedPanelSemantic;

  /// Accessibility label for the hero toolbar chat action, including unread count when applicable.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Group chat} one{Group chat, 1 unread} other{Group chat, {count} unread}}'**
  String eventsHeroChatSemantic(int count);

  /// No description provided for @eventsDetailParticipationSemantic.
  ///
  /// In en, this message translates to:
  /// **'Your participation'**
  String get eventsDetailParticipationSemantic;

  /// No description provided for @eventsAnalyticsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load analytics.'**
  String get eventsAnalyticsLoadFailed;

  /// No description provided for @eventsAnalyticsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get eventsAnalyticsRetry;

  /// No description provided for @eventsRecurrenceDaily.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get eventsRecurrenceDaily;

  /// No description provided for @eventsRecurrenceNavigatePrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous occurrence in series'**
  String get eventsRecurrenceNavigatePrevious;

  /// No description provided for @eventsRecurrenceNavigateNext.
  ///
  /// In en, this message translates to:
  /// **'Next occurrence in series'**
  String get eventsRecurrenceNavigateNext;

  /// No description provided for @eventsImpactSummarySaved.
  ///
  /// In en, this message translates to:
  /// **'Impact summary saved.'**
  String get eventsImpactSummarySaved;

  /// No description provided for @eventsImpactSummaryUpdated.
  ///
  /// In en, this message translates to:
  /// **'Impact summary updated.'**
  String get eventsImpactSummaryUpdated;

  /// No description provided for @eventsReminderSetSnack.
  ///
  /// In en, this message translates to:
  /// **'Reminder set for {when}.'**
  String eventsReminderSetSnack(String when);

  /// No description provided for @eventsFeedbackSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Post-event feedback'**
  String get eventsFeedbackSheetTitle;

  /// No description provided for @eventsFeedbackHowWasEvent.
  ///
  /// In en, this message translates to:
  /// **'How was the event?'**
  String get eventsFeedbackHowWasEvent;

  /// No description provided for @eventsFeedbackBagsCollected.
  ///
  /// In en, this message translates to:
  /// **'Bags collected'**
  String get eventsFeedbackBagsCollected;

  /// No description provided for @eventsFeedbackVolunteerHours.
  ///
  /// In en, this message translates to:
  /// **'Volunteer hours: {hours}h'**
  String eventsFeedbackVolunteerHours(String hours);

  /// No description provided for @eventsFeedbackNotesHint.
  ///
  /// In en, this message translates to:
  /// **'What worked well? Any notes for next time?'**
  String get eventsFeedbackNotesHint;

  /// No description provided for @eventsEvidenceMaxPhotosSnack.
  ///
  /// In en, this message translates to:
  /// **'Maximum {max} photos reached.'**
  String eventsEvidenceMaxPhotosSnack(int max);

  /// No description provided for @eventsEvidencePickFailedSnack.
  ///
  /// In en, this message translates to:
  /// **'Could not pick photos. Check permissions.'**
  String get eventsEvidencePickFailedSnack;

  /// No description provided for @eventsEvidenceRemoveAction.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get eventsEvidenceRemoveAction;

  /// No description provided for @eventsEvidenceAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Cleanup evidence'**
  String get eventsEvidenceAppBarTitle;

  /// No description provided for @eventsEvidenceSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get eventsEvidenceSaving;

  /// No description provided for @eventsEvidenceSaveInProgressHint.
  ///
  /// In en, this message translates to:
  /// **'Please wait until save finishes before leaving this screen.'**
  String get eventsEvidenceSaveInProgressHint;

  /// No description provided for @eventsEvidenceAfterPhotosSaved.
  ///
  /// In en, this message translates to:
  /// **'After photos saved.'**
  String get eventsEvidenceAfterPhotosSaved;

  /// No description provided for @eventsEvidenceSaveSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Photos saved'**
  String get eventsEvidenceSaveSuccessTitle;

  /// No description provided for @eventsEvidenceSaveSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'Your after photos are on the event page.'**
  String get eventsEvidenceSaveSuccessBody;

  /// No description provided for @eventsEvidenceSaveFailureTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not save photos'**
  String get eventsEvidenceSaveFailureTitle;

  /// No description provided for @eventsEvidenceSaveFailureBody.
  ///
  /// In en, this message translates to:
  /// **'{message}'**
  String eventsEvidenceSaveFailureBody(String message);

  /// No description provided for @eventsEvidenceNoChanges.
  ///
  /// In en, this message translates to:
  /// **'No changes to save.'**
  String get eventsEvidenceNoChanges;

  /// No description provided for @eventsSiteReferencePhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Site reference photo'**
  String get eventsSiteReferencePhotoTitle;

  /// No description provided for @eventsSiteReferencePhotoBody.
  ///
  /// In en, this message translates to:
  /// **'Reference taken before cleanup. Use the After tab to add photos of the cleaned site.'**
  String get eventsSiteReferencePhotoBody;

  /// No description provided for @eventsManageCheckInOnlyInProgress.
  ///
  /// In en, this message translates to:
  /// **'Check-in is available only while the event is in progress.'**
  String get eventsManageCheckInOnlyInProgress;

  /// No description provided for @eventsEventFull.
  ///
  /// In en, this message translates to:
  /// **'This event is full.'**
  String get eventsEventFull;

  /// No description provided for @eventsParticipationUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update participation. Try again.'**
  String get eventsParticipationUpdateFailed;

  /// No description provided for @eventsJoinedEcoAction.
  ///
  /// In en, this message translates to:
  /// **'You joined this eco action.'**
  String get eventsJoinedEcoAction;

  /// No description provided for @eventsJoinPointsEarned.
  ///
  /// In en, this message translates to:
  /// **'+{points} points — you\'re in!'**
  String eventsJoinPointsEarned(int points);

  /// No description provided for @eventsLeftEcoAction.
  ///
  /// In en, this message translates to:
  /// **'You left this eco action.'**
  String get eventsLeftEcoAction;

  /// No description provided for @eventsCheckInPointsEarned.
  ///
  /// In en, this message translates to:
  /// **'+{points} points — checked in!'**
  String eventsCheckInPointsEarned(int points);

  /// No description provided for @eventsManualCheckInWithPoints.
  ///
  /// In en, this message translates to:
  /// **'{name} checked in · +{points} pts for them'**
  String eventsManualCheckInWithPoints(String name, int points);

  /// No description provided for @eventsJoinFirstForReminders.
  ///
  /// In en, this message translates to:
  /// **'Join the event first to set reminders.'**
  String get eventsJoinFirstForReminders;

  /// No description provided for @eventsReminderDisabled.
  ///
  /// In en, this message translates to:
  /// **'Reminder disabled.'**
  String get eventsReminderDisabled;

  /// No description provided for @eventsReminderSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose reminder time'**
  String get eventsReminderSheetTitle;

  /// No description provided for @eventsReminderSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Event starts at {timeRange} on {date}.'**
  String eventsReminderSheetSubtitle(String timeRange, String date);

  /// No description provided for @eventsReminderPreset1Day.
  ///
  /// In en, this message translates to:
  /// **'1 day before'**
  String get eventsReminderPreset1Day;

  /// No description provided for @eventsReminderPreset3Hours.
  ///
  /// In en, this message translates to:
  /// **'3 hours before'**
  String get eventsReminderPreset3Hours;

  /// No description provided for @eventsReminderPreset1Hour.
  ///
  /// In en, this message translates to:
  /// **'1 hour before'**
  String get eventsReminderPreset1Hour;

  /// No description provided for @eventsReminderPreset30Mins.
  ///
  /// In en, this message translates to:
  /// **'30 minutes before'**
  String get eventsReminderPreset30Mins;

  /// No description provided for @eventsReminderUnavailableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unavailable for this event time'**
  String get eventsReminderUnavailableSubtitle;

  /// No description provided for @eventsReminderCustomTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom date and time'**
  String get eventsReminderCustomTitle;

  /// No description provided for @eventsReminderCustomSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a specific reminder moment'**
  String get eventsReminderCustomSubtitle;

  /// No description provided for @eventsReminderPickTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick reminder'**
  String get eventsReminderPickTitle;

  /// No description provided for @eventsReminderDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get eventsReminderDone;

  /// No description provided for @eventsCardParticipantsMore.
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String eventsCardParticipantsMore(int count);

  /// No description provided for @eventsCardParticipantsCountMax.
  ///
  /// In en, this message translates to:
  /// **'{count} / {max}'**
  String eventsCardParticipantsCountMax(int count, int max);

  /// No description provided for @eventsCardParticipantsJoined.
  ///
  /// In en, this message translates to:
  /// **'{count} joined'**
  String eventsCardParticipantsJoined(int count);

  /// No description provided for @eventsDiscoveryThisWeekRetryHint.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t load this week’s picks.'**
  String get eventsDiscoveryThisWeekRetryHint;

  /// No description provided for @eventsDiscoveryThisWeekRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get eventsDiscoveryThisWeekRetry;

  /// No description provided for @eventsDetailSemanticsLabel.
  ///
  /// In en, this message translates to:
  /// **'Event detail: {title}'**
  String eventsDetailSemanticsLabel(String title);

  /// No description provided for @eventsCountdownBadgeSemantic.
  ///
  /// In en, this message translates to:
  /// **'Time until event starts: {label}'**
  String eventsCountdownBadgeSemantic(String label);

  /// No description provided for @eventsEvidenceThumbnailMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get eventsEvidenceThumbnailMenuTitle;

  /// No description provided for @eventsFeedRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh events.'**
  String get eventsFeedRefreshFailed;

  /// No description provided for @eventsCreateGenericError.
  ///
  /// In en, this message translates to:
  /// **'Could not create event. Try again.'**
  String get eventsCreateGenericError;

  /// No description provided for @qrScannerPointCameraHint.
  ///
  /// In en, this message translates to:
  /// **'Point your camera at the organizer\'s live QR code'**
  String get qrScannerPointCameraHint;

  /// No description provided for @qrScannerEnterManually.
  ///
  /// In en, this message translates to:
  /// **'Can\'t scan? Enter code manually'**
  String get qrScannerEnterManually;

  /// No description provided for @qrScannerRetryCamera.
  ///
  /// In en, this message translates to:
  /// **'Retry camera'**
  String get qrScannerRetryCamera;

  /// No description provided for @qrScannerSubmitCode.
  ///
  /// In en, this message translates to:
  /// **'Submit code'**
  String get qrScannerSubmitCode;

  /// No description provided for @qrScannerHintFreshQr.
  ///
  /// In en, this message translates to:
  /// **'If the organizer refreshes their QR, scan the newest one.'**
  String get qrScannerHintFreshQr;

  /// No description provided for @qrScannerHintCameraBlocked.
  ///
  /// In en, this message translates to:
  /// **'If camera access stays blocked, paste the code manually or enable camera access in Settings.'**
  String get qrScannerHintCameraBlocked;

  /// No description provided for @qrScannerGenericEventTitle.
  ///
  /// In en, this message translates to:
  /// **'this cleanup event'**
  String get qrScannerGenericEventTitle;

  /// No description provided for @qrScannerErrorInvalidFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid QR format.'**
  String get qrScannerErrorInvalidFormat;

  /// No description provided for @qrScannerErrorInvalidQr.
  ///
  /// In en, this message translates to:
  /// **'This QR is not valid for check-in.'**
  String get qrScannerErrorInvalidQr;

  /// No description provided for @qrScannerErrorWrongEvent.
  ///
  /// In en, this message translates to:
  /// **'This QR belongs to another event.'**
  String get qrScannerErrorWrongEvent;

  /// No description provided for @qrScannerErrorSessionClosed.
  ///
  /// In en, this message translates to:
  /// **'Organizer paused check-in.'**
  String get qrScannerErrorSessionClosed;

  /// No description provided for @qrScannerErrorSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'QR expired. Ask organizer for a new code.'**
  String get qrScannerErrorSessionExpired;

  /// No description provided for @qrScannerErrorReplayDetected.
  ///
  /// In en, this message translates to:
  /// **'This QR was already used.'**
  String get qrScannerErrorReplayDetected;

  /// No description provided for @qrScannerErrorAlreadyCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'You are already checked in.'**
  String get qrScannerErrorAlreadyCheckedIn;

  /// No description provided for @qrScannerErrorRequiresJoin.
  ///
  /// In en, this message translates to:
  /// **'Join this event in the app before checking in.'**
  String get qrScannerErrorRequiresJoin;

  /// No description provided for @qrScannerErrorCheckInUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Check-in is not open for this event right now.'**
  String get qrScannerErrorCheckInUnavailable;

  /// No description provided for @qrScannerErrorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a moment and try again.'**
  String get qrScannerErrorRateLimited;

  /// No description provided for @qrScannerCameraUnavailableFeedback.
  ///
  /// In en, this message translates to:
  /// **'Camera access is unavailable. You can paste the organizer code or re-enable camera access in Settings.'**
  String get qrScannerCameraUnavailableFeedback;

  /// No description provided for @qrScannerManualEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter code manually'**
  String get qrScannerManualEntryTitle;

  /// No description provided for @qrScannerPasteOrganizerQrHint.
  ///
  /// In en, this message translates to:
  /// **'Paste organizer QR text'**
  String get qrScannerPasteOrganizerQrHint;

  /// No description provided for @qrScannerPasteFromClipboardTooltip.
  ///
  /// In en, this message translates to:
  /// **'Paste from clipboard'**
  String get qrScannerPasteFromClipboardTooltip;

  /// No description provided for @qrScannerEnterCodeFirst.
  ///
  /// In en, this message translates to:
  /// **'Enter a code first.'**
  String get qrScannerEnterCodeFirst;

  /// No description provided for @qrScannerCheckedInTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re checked in!'**
  String get qrScannerCheckedInTitle;

  /// No description provided for @qrScannerWelcomeTo.
  ///
  /// In en, this message translates to:
  /// **'Welcome to {eventTitle}'**
  String qrScannerWelcomeTo(String eventTitle);

  /// No description provided for @qrScannerCheckedInAt.
  ///
  /// In en, this message translates to:
  /// **'Checked in at {time}'**
  String qrScannerCheckedInAt(String time);

  /// No description provided for @qrScannerDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get qrScannerDone;

  /// No description provided for @qrScannerAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan to check in'**
  String get qrScannerAppBarTitle;

  /// No description provided for @qrScannerToggleFlashlightSemantic.
  ///
  /// In en, this message translates to:
  /// **'Toggle flashlight'**
  String get qrScannerToggleFlashlightSemantic;

  /// No description provided for @qrScannerCameraStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting camera…'**
  String get qrScannerCameraStarting;

  /// No description provided for @qrScannerCheckingIn.
  ///
  /// In en, this message translates to:
  /// **'Verifying check-in…'**
  String get qrScannerCheckingIn;

  /// No description provided for @qrScannerCameraErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera unavailable'**
  String get qrScannerCameraErrorTitle;

  /// No description provided for @qrScannerManualEntrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Paste the full text the organizer shared (copy from their screen or a message).'**
  String get qrScannerManualEntrySubtitle;

  /// No description provided for @qrScannerPasteButton.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get qrScannerPasteButton;

  /// No description provided for @siteReportReasonFakeLabel.
  ///
  /// In en, this message translates to:
  /// **'Fake or misleading data'**
  String get siteReportReasonFakeLabel;

  /// No description provided for @siteReportReasonFakeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Information does not reflect reality'**
  String get siteReportReasonFakeSubtitle;

  /// No description provided for @siteReportReasonResolvedLabel.
  ///
  /// In en, this message translates to:
  /// **'Already resolved'**
  String get siteReportReasonResolvedLabel;

  /// No description provided for @siteReportReasonResolvedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Issue was cleaned or fixed'**
  String get siteReportReasonResolvedSubtitle;

  /// No description provided for @siteReportReasonWrongLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Wrong location'**
  String get siteReportReasonWrongLocationLabel;

  /// No description provided for @siteReportReasonWrongLocationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Site is placed incorrectly on the map'**
  String get siteReportReasonWrongLocationSubtitle;

  /// No description provided for @siteReportReasonDuplicateLabel.
  ///
  /// In en, this message translates to:
  /// **'Duplicate report'**
  String get siteReportReasonDuplicateLabel;

  /// No description provided for @siteReportReasonDuplicateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Same site reported multiple times'**
  String get siteReportReasonDuplicateSubtitle;

  /// No description provided for @siteReportReasonSpamLabel.
  ///
  /// In en, this message translates to:
  /// **'Spam or abuse'**
  String get siteReportReasonSpamLabel;

  /// No description provided for @siteReportReasonSpamSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate or malicious content'**
  String get siteReportReasonSpamSubtitle;

  /// No description provided for @siteReportReasonOtherLabel.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get siteReportReasonOtherLabel;

  /// No description provided for @siteReportReasonOtherSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Something else is wrong'**
  String get siteReportReasonOtherSubtitle;

  /// No description provided for @takeActionDonationOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open donation page'**
  String get takeActionDonationOpenFailed;

  /// No description provided for @takeActionShareSiteTitle.
  ///
  /// In en, this message translates to:
  /// **'Share site'**
  String get takeActionShareSiteTitle;

  /// No description provided for @takeActionShareSiteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Help others discover and support this site'**
  String get takeActionShareSiteSubtitle;

  /// No description provided for @takeActionLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get takeActionLinkCopied;

  /// No description provided for @takeActionSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Take action'**
  String get takeActionSheetTitle;

  /// No description provided for @takeActionSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to help'**
  String get takeActionSheetSubtitle;

  /// No description provided for @takeActionCreateEcoTitle.
  ///
  /// In en, this message translates to:
  /// **'Create eco action'**
  String get takeActionCreateEcoTitle;

  /// No description provided for @takeActionCreateEcoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule a cleanup event at this site'**
  String get takeActionCreateEcoSubtitle;

  /// No description provided for @takeActionJoinTitle.
  ///
  /// In en, this message translates to:
  /// **'Join action'**
  String get takeActionJoinTitle;

  /// No description provided for @takeActionJoinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find and join upcoming cleanups here'**
  String get takeActionJoinSubtitle;

  /// No description provided for @takeActionShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share site'**
  String get takeActionShareTitle;

  /// No description provided for @takeActionShareSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Help others discover this site'**
  String get takeActionShareSubtitle;

  /// No description provided for @shareSheetSemanticDragHandle.
  ///
  /// In en, this message translates to:
  /// **'Drag to resize or dismiss'**
  String get shareSheetSemanticDragHandle;

  /// No description provided for @shareSheetCopyLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get shareSheetCopyLinkTitle;

  /// No description provided for @shareSheetCopyLinkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Copy the site link to the clipboard'**
  String get shareSheetCopyLinkSubtitle;

  /// No description provided for @shareSheetCopyLinkSemantic.
  ///
  /// In en, this message translates to:
  /// **'Copy link to this pollution site'**
  String get shareSheetCopyLinkSemantic;

  /// No description provided for @shareSheetSendTitle.
  ///
  /// In en, this message translates to:
  /// **'Send to people'**
  String get shareSheetSendTitle;

  /// No description provided for @shareSheetSendSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share in messages or another app'**
  String get shareSheetSendSubtitle;

  /// No description provided for @shareSheetSendSemantic.
  ///
  /// In en, this message translates to:
  /// **'Open the share sheet to send this site'**
  String get shareSheetSendSemantic;

  /// No description provided for @siteDetailSemanticShareCount.
  ///
  /// In en, this message translates to:
  /// **'{count} shares on this site'**
  String siteDetailSemanticShareCount(int count);

  /// No description provided for @siteDetailThankYouReportSnack.
  ///
  /// In en, this message translates to:
  /// **'Thank you. Your report helps us improve.'**
  String get siteDetailThankYouReportSnack;

  /// No description provided for @siteDetailUpvoteFailedSnack.
  ///
  /// In en, this message translates to:
  /// **'Could not update upvote. Please try again.'**
  String get siteDetailUpvoteFailedSnack;

  /// No description provided for @siteDetailNoUpvotesSnack.
  ///
  /// In en, this message translates to:
  /// **'No upvotes yet. Be the first to support this site!'**
  String get siteDetailNoUpvotesSnack;

  /// No description provided for @siteUpvotersSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Upvoters'**
  String get siteUpvotersSheetTitle;

  /// No description provided for @siteUpvotersSupportingLabel.
  ///
  /// In en, this message translates to:
  /// **'Supporting'**
  String get siteUpvotersSupportingLabel;

  /// No description provided for @siteUpvotersSupportersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 supporter} other{{count} supporters}}'**
  String siteUpvotersSupportersCount(int count);

  /// No description provided for @siteUpvotersLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load supporters.'**
  String get siteUpvotersLoadFailed;

  /// No description provided for @siteUpvotersRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get siteUpvotersRetry;

  /// No description provided for @siteDetailNoVolunteersSnack.
  ///
  /// In en, this message translates to:
  /// **'No volunteers yet for this site.'**
  String get siteDetailNoVolunteersSnack;

  /// No description provided for @siteDetailDirectionsUnavailableSnack.
  ///
  /// In en, this message translates to:
  /// **'Directions not available for this site.'**
  String get siteDetailDirectionsUnavailableSnack;

  /// No description provided for @siteDetailOpenMapsFailedSnack.
  ///
  /// In en, this message translates to:
  /// **'Could not open Maps'**
  String get siteDetailOpenMapsFailedSnack;

  /// No description provided for @siteDetailNoCoReportersSnack.
  ///
  /// In en, this message translates to:
  /// **'No other contributors yet. Co-reporters appear when someone else reports the same place.'**
  String get siteDetailNoCoReportersSnack;

  /// No description provided for @siteStatsCoReportersSemantic.
  ///
  /// In en, this message translates to:
  /// **'{count} co-reporters for this report'**
  String siteStatsCoReportersSemantic(int count);

  /// No description provided for @siteParticipantStatsSemantic.
  ///
  /// In en, this message translates to:
  /// **'{count} for contributors (co-reporters or merged duplicates)'**
  String siteParticipantStatsSemantic(int count);

  /// No description provided for @siteMergedDuplicatesModalTitle.
  ///
  /// In en, this message translates to:
  /// **'Merged duplicate reports'**
  String get siteMergedDuplicatesModalTitle;

  /// No description provided for @siteMergedDuplicatesModalBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{One similar submission was merged into this report. When someone else reports the same place, they appear as co-reporters.} other{{count} similar submissions were merged into this report. When someone else reports the same place, they appear as co-reporters.}}'**
  String siteMergedDuplicatesModalBody(int count);

  /// No description provided for @siteCardUpvoteFailedSnack.
  ///
  /// In en, this message translates to:
  /// **'Could not update upvote. Please try again.'**
  String get siteCardUpvoteFailedSnack;

  /// No description provided for @siteCardSavedFailedSnack.
  ///
  /// In en, this message translates to:
  /// **'Could not update saved state. Please try again.'**
  String get siteCardSavedFailedSnack;

  /// No description provided for @siteCardTakeActionSemantic.
  ///
  /// In en, this message translates to:
  /// **'Take action'**
  String get siteCardTakeActionSemantic;

  /// No description provided for @siteCardFeedOptionsSemantic.
  ///
  /// In en, this message translates to:
  /// **'Feed options'**
  String get siteCardFeedOptionsSemantic;

  /// No description provided for @siteCardCommentsLoadFailedSnack.
  ///
  /// In en, this message translates to:
  /// **'Could not load comments right now.'**
  String get siteCardCommentsLoadFailedSnack;

  /// No description provided for @siteCardShareTrackFailedSnack.
  ///
  /// In en, this message translates to:
  /// **'Could not track share right now.'**
  String get siteCardShareTrackFailedSnack;

  /// No description provided for @siteCardFeedbackSubmitFailedSnack.
  ///
  /// In en, this message translates to:
  /// **'Could not submit feedback right now.'**
  String get siteCardFeedbackSubmitFailedSnack;

  /// No description provided for @siteCardNotRelevantTitle.
  ///
  /// In en, this message translates to:
  /// **'Not relevant'**
  String get siteCardNotRelevantTitle;

  /// No description provided for @siteCardShowLessTitle.
  ///
  /// In en, this message translates to:
  /// **'Show less like this'**
  String get siteCardShowLessTitle;

  /// No description provided for @siteCardDuplicateTitle.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get siteCardDuplicateTitle;

  /// No description provided for @siteCardMisleadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Misleading'**
  String get siteCardMisleadingTitle;

  /// No description provided for @siteCardHidePostTitle.
  ///
  /// In en, this message translates to:
  /// **'Hide this post'**
  String get siteCardHidePostTitle;

  /// No description provided for @feedSiteCommentsAppBarFallback.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get feedSiteCommentsAppBarFallback;

  /// No description provided for @feedSiteNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'This site could not be found.'**
  String get feedSiteNotFoundMessage;

  /// No description provided for @feedDisplayNameFallback.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get feedDisplayNameFallback;

  /// No description provided for @feedOpenProfileSemantics.
  ///
  /// In en, this message translates to:
  /// **'Open profile'**
  String get feedOpenProfileSemantics;

  /// No description provided for @feedGreetingPrefix.
  ///
  /// In en, this message translates to:
  /// **'Hi, '**
  String get feedGreetingPrefix;

  /// No description provided for @feedGreetingFallbackName.
  ///
  /// In en, this message translates to:
  /// **'there'**
  String get feedGreetingFallbackName;

  /// No description provided for @feedHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Explore pollution sites near you'**
  String get feedHeaderSubtitle;

  /// No description provided for @feedNotificationBellAllReadSemantic.
  ///
  /// In en, this message translates to:
  /// **'Notifications, all read'**
  String get feedNotificationBellAllReadSemantic;

  /// No description provided for @feedNotificationBellUnreadSemantic.
  ///
  /// In en, this message translates to:
  /// **'Notifications, {count} unread'**
  String feedNotificationBellUnreadSemantic(int count);

  /// No description provided for @siteDetailTabPollutionSite.
  ///
  /// In en, this message translates to:
  /// **'Pollution site'**
  String get siteDetailTabPollutionSite;

  /// No description provided for @siteDetailTabCleaningEvents.
  ///
  /// In en, this message translates to:
  /// **'Cleaning events'**
  String get siteDetailTabCleaningEvents;

  /// No description provided for @siteDetailInfoCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Community action needed'**
  String get siteDetailInfoCardTitle;

  /// No description provided for @siteDetailInfoCardBody.
  ///
  /// In en, this message translates to:
  /// **'Join a cleanup, report changes, or help spread the word so we can act faster.'**
  String get siteDetailInfoCardBody;

  /// No description provided for @siteDetailReportedByPrefix.
  ///
  /// In en, this message translates to:
  /// **'Reported by '**
  String get siteDetailReportedByPrefix;

  /// No description provided for @siteDetailCoReportersTitle.
  ///
  /// In en, this message translates to:
  /// **'Co-reporters'**
  String get siteDetailCoReportersTitle;

  /// No description provided for @siteDetailCoReportersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 person also reported this site} other{{count} people also reported this site}}'**
  String siteDetailCoReportersSubtitle(int count);

  /// No description provided for @siteDetailGalleryPhotoSemantic.
  ///
  /// In en, this message translates to:
  /// **'Pollution site photo {index}'**
  String siteDetailGalleryPhotoSemantic(int index);

  /// No description provided for @siteDetailOpenGalleryLabel.
  ///
  /// In en, this message translates to:
  /// **'Open pollution site gallery'**
  String get siteDetailOpenGalleryLabel;

  /// No description provided for @siteDetailGalleryTapToExpand.
  ///
  /// In en, this message translates to:
  /// **'Tap to expand'**
  String get siteDetailGalleryTapToExpand;

  /// No description provided for @siteDetailGalleryOpenPhoto.
  ///
  /// In en, this message translates to:
  /// **'Open photo'**
  String get siteDetailGalleryOpenPhoto;

  /// No description provided for @commonNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get commonNotAvailable;

  /// No description provided for @commonDistanceMetersUnit.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get commonDistanceMetersUnit;

  /// No description provided for @commonDistanceKilometersUnit.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get commonDistanceKilometersUnit;

  /// No description provided for @siteCommentsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'No comments yet.\nBe the first to comment.'**
  String get siteCommentsEmptyBody;

  /// No description provided for @feedCommentsLoadMoreFailedSnack.
  ///
  /// In en, this message translates to:
  /// **'Could not load more comments. Pull to refresh or try again.'**
  String get feedCommentsLoadMoreFailedSnack;

  /// No description provided for @commentsSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Comment actions'**
  String get commentsSheetTitle;

  /// No description provided for @commentsSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage this comment'**
  String get commentsSheetSubtitle;

  /// No description provided for @commentsEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit comment'**
  String get commentsEditTitle;

  /// No description provided for @commentsEditSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update the text in composer'**
  String get commentsEditSubtitle;

  /// No description provided for @commentsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete comment'**
  String get commentsDeleteTitle;

  /// No description provided for @commentsDeleteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remove it from this thread'**
  String get commentsDeleteSubtitle;

  /// No description provided for @commentsEditFailedSnack.
  ///
  /// In en, this message translates to:
  /// **'Could not edit comment right now.'**
  String get commentsEditFailedSnack;

  /// No description provided for @commentsReplyFailedSnack.
  ///
  /// In en, this message translates to:
  /// **'Could not post your reply. Please try again.'**
  String get commentsReplyFailedSnack;

  /// No description provided for @commentsSortFailedSnack.
  ///
  /// In en, this message translates to:
  /// **'Could not change comment order. Try again.'**
  String get commentsSortFailedSnack;

  /// No description provided for @commentsDeletedSnack.
  ///
  /// In en, this message translates to:
  /// **'Comment deleted.'**
  String get commentsDeletedSnack;

  /// No description provided for @commentsDeleteFailedSnack.
  ///
  /// In en, this message translates to:
  /// **'Could not delete comment right now.'**
  String get commentsDeleteFailedSnack;

  /// No description provided for @commentsLikeFailedSnack.
  ///
  /// In en, this message translates to:
  /// **'Could not update like right now.'**
  String get commentsLikeFailedSnack;

  /// No description provided for @commentsCancelEditSemantic.
  ///
  /// In en, this message translates to:
  /// **'Cancel editing and clear draft'**
  String get commentsCancelEditSemantic;

  /// No description provided for @commentsCancelReplySemantic.
  ///
  /// In en, this message translates to:
  /// **'Cancel replying and clear draft'**
  String get commentsCancelReplySemantic;

  /// No description provided for @commentsReplyToSemantic.
  ///
  /// In en, this message translates to:
  /// **'Reply to {name}'**
  String commentsReplyToSemantic(String name);

  /// No description provided for @commentsReplyButton.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get commentsReplyButton;

  /// No description provided for @commentsViewReplies.
  ///
  /// In en, this message translates to:
  /// **'View replies'**
  String get commentsViewReplies;

  /// No description provided for @commentsLoadMoreReplies.
  ///
  /// In en, this message translates to:
  /// **'Load {count} more'**
  String commentsLoadMoreReplies(int count);

  /// No description provided for @siteEngagementQueuedOfflineSnack.
  ///
  /// In en, this message translates to:
  /// **'Connection dropped. We will retry this when you are back online.'**
  String get siteEngagementQueuedOfflineSnack;

  /// No description provided for @commentsHideReplies.
  ///
  /// In en, this message translates to:
  /// **'Hide replies'**
  String get commentsHideReplies;

  /// No description provided for @commentsStatusDeleting.
  ///
  /// In en, this message translates to:
  /// **'Deleting…'**
  String get commentsStatusDeleting;

  /// No description provided for @commentsStatusSavingEdits.
  ///
  /// In en, this message translates to:
  /// **'Saving edits…'**
  String get commentsStatusSavingEdits;

  /// No description provided for @commentsCommentMetaJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get commentsCommentMetaJustNow;

  /// No description provided for @commentsCommentMetaJustNowWithLikes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Just now • 1 like} other{Just now • {count} likes}}'**
  String commentsCommentMetaJustNowWithLikes(int count);

  /// No description provided for @commentsCommentMetaMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, one{1 minute ago} other{{minutes} minutes ago}}'**
  String commentsCommentMetaMinutesAgo(int minutes);

  /// No description provided for @commentsCommentMetaMinutesAgoWithLikes.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, one{1 minute ago} other{{minutes} minutes ago}} • {count, plural, one{1 like} other{{count} likes}}'**
  String commentsCommentMetaMinutesAgoWithLikes(int minutes, int count);

  /// No description provided for @commentsCommentMetaHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours, plural, one{1 hour ago} other{{hours} hours ago}}'**
  String commentsCommentMetaHoursAgo(int hours);

  /// No description provided for @commentsCommentMetaHoursAgoWithLikes.
  ///
  /// In en, this message translates to:
  /// **'{hours, plural, one{1 hour ago} other{{hours} hours ago}} • {count, plural, one{1 like} other{{count} likes}}'**
  String commentsCommentMetaHoursAgoWithLikes(int hours, int count);

  /// No description provided for @commentsCommentMetaDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one{1 day ago} other{{days} days ago}}'**
  String commentsCommentMetaDaysAgo(int days);

  /// No description provided for @commentsCommentMetaDaysAgoWithLikes.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one{1 day ago} other{{days} days ago}} • {count, plural, one{1 like} other{{count} likes}}'**
  String commentsCommentMetaDaysAgoWithLikes(int days, int count);

  /// No description provided for @commentsCommentMetaDate.
  ///
  /// In en, this message translates to:
  /// **'{date}'**
  String commentsCommentMetaDate(String date);

  /// No description provided for @commentsCommentMetaDateWithLikes.
  ///
  /// In en, this message translates to:
  /// **'{date} • {count, plural, one{1 like} other{{count} likes}}'**
  String commentsCommentMetaDateWithLikes(String date, int count);

  /// No description provided for @commentsOptimisticAuthorYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get commentsOptimisticAuthorYou;

  /// No description provided for @commentsReplyingToBanner.
  ///
  /// In en, this message translates to:
  /// **'Replying to {name}'**
  String commentsReplyingToBanner(String name);

  /// No description provided for @commentsSemanticSheetDragHandle.
  ///
  /// In en, this message translates to:
  /// **'Resize or dismiss comments'**
  String get commentsSemanticSheetDragHandle;

  /// No description provided for @commentsPrefetchCouldNotRefreshSnack.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh comments. Showing the last loaded thread.'**
  String get commentsPrefetchCouldNotRefreshSnack;

  /// No description provided for @commentsComposerCharsRemaining.
  ///
  /// In en, this message translates to:
  /// **'{remaining, plural, one{1 character left} other{{remaining} characters left}}'**
  String commentsComposerCharsRemaining(int remaining);

  /// No description provided for @commentsSemanticHideReplies.
  ///
  /// In en, this message translates to:
  /// **'Hide replies for {name}'**
  String commentsSemanticHideReplies(String name);

  /// No description provided for @commentsSemanticViewReplies.
  ///
  /// In en, this message translates to:
  /// **'View replies for {name}'**
  String commentsSemanticViewReplies(String name);

  /// No description provided for @commentsInputHintEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit your comment…'**
  String get commentsInputHintEdit;

  /// No description provided for @commentsInputHintAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a comment…'**
  String get commentsInputHintAdd;

  /// No description provided for @commentsInputHintReply.
  ///
  /// In en, this message translates to:
  /// **'Write a reply…'**
  String get commentsInputHintReply;

  /// No description provided for @commentsLikeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Like comment'**
  String get commentsLikeTooltip;

  /// No description provided for @commentsUnlikeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Unlike comment'**
  String get commentsUnlikeTooltip;

  /// No description provided for @searchModalCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get searchModalCancel;

  /// No description provided for @searchModalPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search pollution sites'**
  String get searchModalPlaceholder;

  /// No description provided for @appSmartImageRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get appSmartImageRetry;

  /// No description provided for @appSmartImageRetryIn.
  ///
  /// In en, this message translates to:
  /// **'Retry in {seconds}s'**
  String appSmartImageRetryIn(int seconds);

  /// No description provided for @semanticClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get semanticClose;

  /// No description provided for @pollutionSiteTabTakeAction.
  ///
  /// In en, this message translates to:
  /// **'Take action'**
  String get pollutionSiteTabTakeAction;

  /// No description provided for @reportDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Anything else'**
  String get reportDescriptionHint;

  /// No description provided for @reportSubmittedFallbackCategory.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportSubmittedFallbackCategory;

  /// No description provided for @reportSeverityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get reportSeverityLow;

  /// No description provided for @reportSeverityModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get reportSeverityModerate;

  /// No description provided for @reportSeveritySignificant.
  ///
  /// In en, this message translates to:
  /// **'Significant'**
  String get reportSeveritySignificant;

  /// No description provided for @reportSeverityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get reportSeverityHigh;

  /// No description provided for @reportSeverityCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get reportSeverityCritical;

  /// No description provided for @reportDetailViewOnMap.
  ///
  /// In en, this message translates to:
  /// **'View on map'**
  String get reportDetailViewOnMap;

  /// No description provided for @reportListSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search your reports'**
  String get reportListSearchPlaceholder;

  /// No description provided for @reportListSearchHintPrefix.
  ///
  /// In en, this message translates to:
  /// **'Search by title, location, category, or status.'**
  String get reportListSearchHintPrefix;

  /// No description provided for @reportListSearchNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get reportListSearchNoMatches;

  /// No description provided for @reportListSearchOneReport.
  ///
  /// In en, this message translates to:
  /// **'1 report'**
  String get reportListSearchOneReport;

  /// No description provided for @reportListSearchNReports.
  ///
  /// In en, this message translates to:
  /// **'{count} reports'**
  String reportListSearchNReports(int count);

  /// No description provided for @reportListEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No reports yet'**
  String get reportListEmptyTitle;

  /// No description provided for @reportListEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your future reports will appear here after you submit them.'**
  String get reportListEmptySubtitle;

  /// No description provided for @reportStatusUnderReviewShort.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get reportStatusUnderReviewShort;

  /// No description provided for @reportStatusApprovedShort.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get reportStatusApprovedShort;

  /// No description provided for @reportStatusDeclinedShort.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get reportStatusDeclinedShort;

  /// No description provided for @reportStatusAlreadyReportedShort.
  ///
  /// In en, this message translates to:
  /// **'Already reported'**
  String get reportStatusAlreadyReportedShort;

  /// No description provided for @reportListFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get reportListFilterAll;

  /// No description provided for @reportListOptimisticPill.
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get reportListOptimisticPill;

  /// No description provided for @reportListFilterSemanticPrefix.
  ///
  /// In en, this message translates to:
  /// **'Report status'**
  String get reportListFilterSemanticPrefix;

  /// No description provided for @reportListHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Your reports'**
  String get reportListHeaderTitle;

  /// No description provided for @reportListHeaderTotalPill.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 report in total} other{{count} reports in total}}'**
  String reportListHeaderTotalPill(int count);

  /// No description provided for @reportListHeaderUnderReviewPill.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 under review} other{{count} under review}}'**
  String reportListHeaderUnderReviewPill(int count);

  /// No description provided for @reportListHeaderSemanticSummary.
  ///
  /// In en, this message translates to:
  /// **'{totalReports, plural, one{1 report in total} other{{totalReports} reports in total}}. {underReview, plural, one{1 currently under review} other{{underReview} currently under review}}.'**
  String reportListHeaderSemanticSummary(int totalReports, int underReview);

  /// No description provided for @reportListFilteredFooterAll.
  ///
  /// In en, this message translates to:
  /// **'All reports shown'**
  String get reportListFilteredFooterAll;

  /// No description provided for @reportListFilteredFooterCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 report} other{{count} reports}}'**
  String reportListFilteredFooterCount(int count);

  /// No description provided for @reportListNoMatchesSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'No reports found'**
  String get reportListNoMatchesSearchTitle;

  /// No description provided for @reportListNoMatchesFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'No reports with this filter'**
  String get reportListNoMatchesFilterTitle;

  /// No description provided for @reportListNoMatchesHintSearchAndFilter.
  ///
  /// In en, this message translates to:
  /// **'Try a different search or clear filters to see more reports.'**
  String get reportListNoMatchesHintSearchAndFilter;

  /// No description provided for @reportListNoMatchesHintSearchOnly.
  ///
  /// In en, this message translates to:
  /// **'Check the spelling or try a broader search.'**
  String get reportListNoMatchesHintSearchOnly;

  /// No description provided for @reportListNoMatchesHintFilterOnly.
  ///
  /// In en, this message translates to:
  /// **'Try another filter, or clear it to see all reports.'**
  String get reportListNoMatchesHintFilterOnly;

  /// No description provided for @reportListClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get reportListClearSearch;

  /// No description provided for @reportListDateWeeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{weeks, plural, one{1 week ago} other{{weeks} weeks ago}}'**
  String reportListDateWeeksAgo(int weeks);

  /// No description provided for @reportDetailOpeningInProgress.
  ///
  /// In en, this message translates to:
  /// **'Opening…'**
  String get reportDetailOpeningInProgress;

  /// No description provided for @reportDetailNoPhotos.
  ///
  /// In en, this message translates to:
  /// **'No photos'**
  String get reportDetailNoPhotos;

  /// No description provided for @reportDetailStatusUnderReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Under review by moderators'**
  String get reportDetailStatusUnderReviewTitle;

  /// No description provided for @reportDetailStatusUnderReviewBody.
  ///
  /// In en, this message translates to:
  /// **'Moderators are checking your evidence and location before they decide how to handle this report.'**
  String get reportDetailStatusUnderReviewBody;

  /// No description provided for @reportDetailStatusApprovedTitle.
  ///
  /// In en, this message translates to:
  /// **'Approved and linked to a site'**
  String get reportDetailStatusApprovedTitle;

  /// No description provided for @reportDetailStatusApprovedBody.
  ///
  /// In en, this message translates to:
  /// **'This report helped confirm a public pollution site and may contribute to cleanup actions.'**
  String get reportDetailStatusApprovedBody;

  /// No description provided for @reportDetailStatusAlreadyReportedTitle.
  ///
  /// In en, this message translates to:
  /// **'Already tracked as an existing site'**
  String get reportDetailStatusAlreadyReportedTitle;

  /// No description provided for @reportDetailStatusAlreadyReportedBody.
  ///
  /// In en, this message translates to:
  /// **'Your report matched an existing site. The evidence is still useful for understanding the problem.'**
  String get reportDetailStatusAlreadyReportedBody;

  /// No description provided for @reportDetailStatusOutcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Review outcome'**
  String get reportDetailStatusOutcomeTitle;

  /// No description provided for @reportDetailStatusOutcomeBodyFallback.
  ///
  /// In en, this message translates to:
  /// **'This report could not be approved in its current form.'**
  String get reportDetailStatusOutcomeBodyFallback;

  /// No description provided for @reportDetailSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Report details'**
  String get reportDetailSheetTitle;

  /// No description provided for @reportDetailSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'See what you submitted and how moderators handled this report.'**
  String get reportDetailSheetSubtitle;

  /// No description provided for @reportDetailSheetSubtitleWithNumber.
  ///
  /// In en, this message translates to:
  /// **'{reportNumber} · See what you submitted and how moderators handled this report.'**
  String reportDetailSheetSubtitleWithNumber(String reportNumber);

  /// No description provided for @reportDetailPhotoAttachedPill.
  ///
  /// In en, this message translates to:
  /// **'Photo attached'**
  String get reportDetailPhotoAttachedPill;

  /// No description provided for @reportDetailPointsLabel.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get reportDetailPointsLabel;

  /// No description provided for @reportDetailEvidencePhotoSemantic.
  ///
  /// In en, this message translates to:
  /// **'Evidence photo {index}'**
  String reportDetailEvidencePhotoSemantic(int index);

  /// No description provided for @reportDetailEvidenceGalleryOpenSemantic.
  ///
  /// In en, this message translates to:
  /// **'Open report evidence photos'**
  String get reportDetailEvidenceGalleryOpenSemantic;

  /// No description provided for @reportDetailEvidenceTapToExpand.
  ///
  /// In en, this message translates to:
  /// **'Tap to expand'**
  String get reportDetailEvidenceTapToExpand;

  /// No description provided for @reportDetailEvidenceOpenPhoto.
  ///
  /// In en, this message translates to:
  /// **'Open photo'**
  String get reportDetailEvidenceOpenPhoto;

  /// No description provided for @reportDetailSiteNotFoundOpeningMaps.
  ///
  /// In en, this message translates to:
  /// **'Site not found. Opening in maps.'**
  String get reportDetailSiteNotFoundOpeningMaps;

  /// No description provided for @reportDetailSiteNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Site not available.'**
  String get reportDetailSiteNotAvailable;

  /// No description provided for @reportDetailCouldNotLoadSite.
  ///
  /// In en, this message translates to:
  /// **'Could not load site.'**
  String get reportDetailCouldNotLoadSite;

  /// No description provided for @reportCardDeclineNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Review note'**
  String get reportCardDeclineNoteTitle;

  /// No description provided for @reportListFilterChipSemantic.
  ///
  /// In en, this message translates to:
  /// **'{label} filter, {selected, plural, =1{selected} other{not selected}}'**
  String reportListFilterChipSemantic(String label, int selected);

  /// No description provided for @reportListFilterChipHint.
  ///
  /// In en, this message translates to:
  /// **'Double-tap to filter reports by {label}.'**
  String reportListFilterChipHint(String label);

  /// No description provided for @reportReviewTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Brief headline'**
  String get reportReviewTitleHint;

  /// No description provided for @reportFlowCameraUnavailableSnack.
  ///
  /// In en, this message translates to:
  /// **'Unable to open the camera right now. Please try again in a moment.'**
  String get reportFlowCameraUnavailableSnack;

  /// No description provided for @reportSemanticsLocationPinThenConfirm.
  ///
  /// In en, this message translates to:
  /// **'Location: pin, then confirm.'**
  String get reportSemanticsLocationPinThenConfirm;

  /// No description provided for @newReportTooltipAboutStep.
  ///
  /// In en, this message translates to:
  /// **'About this step'**
  String get newReportTooltipAboutStep;

  /// No description provided for @newReportTooltipDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get newReportTooltipDismiss;

  /// No description provided for @reportFlowSubmitPhaseCreating.
  ///
  /// In en, this message translates to:
  /// **'Creating…'**
  String get reportFlowSubmitPhaseCreating;

  /// No description provided for @reportFlowSubmitPhaseUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get reportFlowSubmitPhaseUploading;

  /// No description provided for @reportFlowSubmitPhaseSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get reportFlowSubmitPhaseSubmitting;

  /// No description provided for @reportFormPrimarySemanticsHintSubmit.
  ///
  /// In en, this message translates to:
  /// **'Double-tap to submit.'**
  String get reportFormPrimarySemanticsHintSubmit;

  /// No description provided for @reportFormPrimarySemanticsHintNext.
  ///
  /// In en, this message translates to:
  /// **'Double-tap to go to the next step.'**
  String get reportFormPrimarySemanticsHintNext;

  /// No description provided for @reportCardSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'{category}, {status}, {location}. Tap to view details.'**
  String reportCardSemanticLabel(
    String category,
    String status,
    String location,
  );

  /// No description provided for @appSmartImageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Image unavailable'**
  String get appSmartImageUnavailable;

  /// No description provided for @eventsReminderSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Event reminder'**
  String get eventsReminderSectionTitle;

  /// No description provided for @eventsReminderSectionEnabled.
  ///
  /// In en, this message translates to:
  /// **'Reminder is on'**
  String get eventsReminderSectionEnabled;

  /// No description provided for @eventsReminderSectionSetFor.
  ///
  /// In en, this message translates to:
  /// **'Set for {time}'**
  String eventsReminderSectionSetFor(String time);

  /// No description provided for @eventsReminderSectionDisabled.
  ///
  /// In en, this message translates to:
  /// **'Get notified before event starts'**
  String get eventsReminderSectionDisabled;

  /// No description provided for @eventsReminderSectionDisable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get eventsReminderSectionDisable;

  /// No description provided for @eventsReminderSectionEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get eventsReminderSectionEnable;

  /// No description provided for @eventsDescriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get eventsDescriptionTitle;

  /// No description provided for @eventsDescriptionShowLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get eventsDescriptionShowLess;

  /// No description provided for @eventsDescriptionReadMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get eventsDescriptionReadMore;

  /// No description provided for @eventsAfterCleanupTitle.
  ///
  /// In en, this message translates to:
  /// **'After cleanup'**
  String get eventsAfterCleanupTitle;

  /// No description provided for @eventsAfterPhotoSemantic.
  ///
  /// In en, this message translates to:
  /// **'View after cleanup photo {index} of {total}'**
  String eventsAfterPhotoSemantic(int index, int total);

  /// No description provided for @eventsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get eventsFilterAll;

  /// No description provided for @eventsFilterUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get eventsFilterUpcoming;

  /// No description provided for @eventsFilterNearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get eventsFilterNearby;

  /// No description provided for @eventsFilterPast.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get eventsFilterPast;

  /// No description provided for @eventsFilterMyEvents.
  ///
  /// In en, this message translates to:
  /// **'My events'**
  String get eventsFilterMyEvents;

  /// No description provided for @eventsFilterSemanticPrefix.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get eventsFilterSemanticPrefix;

  /// No description provided for @eventsParticipantsTitle.
  ///
  /// In en, this message translates to:
  /// **'Attendees'**
  String get eventsParticipantsTitle;

  /// No description provided for @eventsParticipantsViewSemantic.
  ///
  /// In en, this message translates to:
  /// **'View {count} attendees'**
  String eventsParticipantsViewSemantic(int count);

  /// No description provided for @eventsParticipantsYouAndOthers.
  ///
  /// In en, this message translates to:
  /// **'You and {count} others joined'**
  String eventsParticipantsYouAndOthers(int count);

  /// No description provided for @eventsParticipantsVolunteersJoined.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 volunteer joined} other{{count} volunteers joined}}'**
  String eventsParticipantsVolunteersJoined(int count);

  /// No description provided for @eventsParticipantsSpotsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} spots left'**
  String eventsParticipantsSpotsLeft(int count);

  /// No description provided for @eventsParticipantsCheckedInCount.
  ///
  /// In en, this message translates to:
  /// **'{checkedIn} of {total} checked in'**
  String eventsParticipantsCheckedInCount(int checkedIn, int total);

  /// No description provided for @eventsParticipantsSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search attendee'**
  String get eventsParticipantsSearchPlaceholder;

  /// No description provided for @eventsParticipantsNoSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No attendee matches your search.'**
  String get eventsParticipantsNoSearchResults;

  /// No description provided for @eventsParticipantsYouOrganizer.
  ///
  /// In en, this message translates to:
  /// **'You · Organizer'**
  String get eventsParticipantsYouOrganizer;

  /// No description provided for @eventsParticipantsOrganizer.
  ///
  /// In en, this message translates to:
  /// **'Organizer'**
  String get eventsParticipantsOrganizer;

  /// No description provided for @eventsParticipantsYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get eventsParticipantsYou;

  /// No description provided for @eventsParticipantsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load attendees. Check your connection and try again.'**
  String get eventsParticipantsLoadFailed;

  /// No description provided for @eventsParticipantsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get eventsParticipantsRetry;

  /// No description provided for @eventsParticipantsViewRosterSemantic.
  ///
  /// In en, this message translates to:
  /// **'View attendee list'**
  String get eventsParticipantsViewRosterSemantic;

  /// No description provided for @eventsGearSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Gear to bring'**
  String get eventsGearSectionTitle;

  /// No description provided for @eventsGearNoneNeeded.
  ///
  /// In en, this message translates to:
  /// **'No special gear needed'**
  String get eventsGearNoneNeeded;

  /// No description provided for @eventsImpactSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Impact summary'**
  String get eventsImpactSummaryTitle;

  /// No description provided for @eventsImpactSummaryAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get eventsImpactSummaryAdd;

  /// No description provided for @eventsImpactSummaryEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get eventsImpactSummaryEdit;

  /// No description provided for @eventsImpactSummaryEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Note results and lessons from this cleanup.'**
  String get eventsImpactSummaryEmptyHint;

  /// No description provided for @eventsLivePulseTitle.
  ///
  /// In en, this message translates to:
  /// **'Live impact'**
  String get eventsLivePulseTitle;

  /// No description provided for @eventsLivePulseVolunteers.
  ///
  /// In en, this message translates to:
  /// **'{count} joined'**
  String eventsLivePulseVolunteers(int count);

  /// No description provided for @eventsLivePulseCheckIns.
  ///
  /// In en, this message translates to:
  /// **'{count} checked in'**
  String eventsLivePulseCheckIns(int count);

  /// No description provided for @eventsLivePulseBags.
  ///
  /// In en, this message translates to:
  /// **'{count} bags · est. {kg} kg'**
  String eventsLivePulseBags(int count, String kg);

  /// No description provided for @eventsEvidenceStripTitle.
  ///
  /// In en, this message translates to:
  /// **'Field proof'**
  String get eventsEvidenceStripTitle;

  /// No description provided for @eventsEvidenceStripSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Photos from the cleanup evidence feed.'**
  String get eventsEvidenceStripSubtitle;

  /// No description provided for @eventsEvidenceStripSemantic.
  ///
  /// In en, this message translates to:
  /// **'Before, after, and field photos from the evidence feed'**
  String get eventsEvidenceStripSemantic;

  /// No description provided for @eventsEvidenceKindBefore.
  ///
  /// In en, this message translates to:
  /// **'Before'**
  String get eventsEvidenceKindBefore;

  /// No description provided for @eventsEvidenceKindAfter.
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get eventsEvidenceKindAfter;

  /// No description provided for @eventsEvidenceKindField.
  ///
  /// In en, this message translates to:
  /// **'Field'**
  String get eventsEvidenceKindField;

  /// No description provided for @eventsEvidenceStripTileSemantic.
  ///
  /// In en, this message translates to:
  /// **'Photo {index} of {total}, {kind}'**
  String eventsEvidenceStripTileSemantic(int index, int total, String kind);

  /// No description provided for @eventsRouteProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get eventsRouteProgressTitle;

  /// No description provided for @eventsFieldModeRowServerError.
  ///
  /// In en, this message translates to:
  /// **'Server: {code}'**
  String eventsFieldModeRowServerError(String code);

  /// No description provided for @eventsFieldModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Field mode'**
  String get eventsFieldModeTitle;

  /// No description provided for @eventsFieldModeSync.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get eventsFieldModeSync;

  /// No description provided for @eventsFieldModeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing queued offline.'**
  String get eventsFieldModeEmpty;

  /// No description provided for @eventsFieldModeSynced.
  ///
  /// In en, this message translates to:
  /// **'Queue synced.'**
  String get eventsFieldModeSynced;

  /// No description provided for @eventsFieldModeSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not sync. Try again when online.'**
  String get eventsFieldModeSyncFailed;

  /// No description provided for @eventsFieldModeSyncPartial.
  ///
  /// In en, this message translates to:
  /// **'Synced {synced} update(s). {failed} still in the offline queue.'**
  String eventsFieldModeSyncPartial(int synced, int failed);

  /// No description provided for @eventsFieldModeRowLiveImpactBags.
  ///
  /// In en, this message translates to:
  /// **'Live impact · {count} bags'**
  String eventsFieldModeRowLiveImpactBags(int count);

  /// No description provided for @eventsFieldModeRowUnknown.
  ///
  /// In en, this message translates to:
  /// **'Offline change'**
  String get eventsFieldModeRowUnknown;

  /// No description provided for @eventsFieldModeRowStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get eventsFieldModeRowStatusPending;

  /// No description provided for @eventsFieldModeRowStatusSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing'**
  String get eventsFieldModeRowStatusSyncing;

  /// No description provided for @eventsOfflineWorkHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline work'**
  String get eventsOfflineWorkHubTitle;

  /// No description provided for @eventsOfflineWorkHubSemanticSheet.
  ///
  /// In en, this message translates to:
  /// **'Offline work summary and sync actions'**
  String get eventsOfflineWorkHubSemanticSheet;

  /// No description provided for @eventsOfflineWorkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Queued changes across check-ins, field updates, and chat.'**
  String get eventsOfflineWorkSubtitle;

  /// No description provided for @eventsOfflineWorkSectionCheckIns.
  ///
  /// In en, this message translates to:
  /// **'Check-ins'**
  String get eventsOfflineWorkSectionCheckIns;

  /// No description provided for @eventsOfflineWorkSectionField.
  ///
  /// In en, this message translates to:
  /// **'Field updates'**
  String get eventsOfflineWorkSectionField;

  /// No description provided for @eventsOfflineWorkSectionChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get eventsOfflineWorkSectionChat;

  /// No description provided for @eventsOfflineWorkCountPending.
  ///
  /// In en, this message translates to:
  /// **'{count} pending'**
  String eventsOfflineWorkCountPending(int count);

  /// No description provided for @eventsOfflineWorkCountFailed.
  ///
  /// In en, this message translates to:
  /// **'{count} need attention'**
  String eventsOfflineWorkCountFailed(int count);

  /// No description provided for @eventsOfflineWorkSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get eventsOfflineWorkSyncNow;

  /// No description provided for @eventsOfflineWorkOpenFieldQueue.
  ///
  /// In en, this message translates to:
  /// **'Open field queue'**
  String get eventsOfflineWorkOpenFieldQueue;

  /// No description provided for @eventsOfflineWorkOpenChat.
  ///
  /// In en, this message translates to:
  /// **'Open event chat'**
  String get eventsOfflineWorkOpenChat;

  /// No description provided for @eventsOfflineWorkRetryFailedChat.
  ///
  /// In en, this message translates to:
  /// **'Retry failed chat sends'**
  String get eventsOfflineWorkRetryFailedChat;

  /// No description provided for @eventsOfflineWorkResolveInChat.
  ///
  /// In en, this message translates to:
  /// **'Open the chat and fix or delete the message that could not be sent.'**
  String get eventsOfflineWorkResolveInChat;

  /// No description provided for @eventsOfflineWorkSyncDone.
  ///
  /// In en, this message translates to:
  /// **'Sync finished'**
  String get eventsOfflineWorkSyncDone;

  /// No description provided for @eventsOfflineWorkSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get eventsOfflineWorkSyncing;

  /// No description provided for @eventsOfflineWorkDrainFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not finish syncing. Try again when you are online.'**
  String get eventsOfflineWorkDrainFailed;

  /// No description provided for @eventsChatOutboxFull.
  ///
  /// In en, this message translates to:
  /// **'Too many messages are waiting to send offline (limit {max}). Go online to send pending messages, then try again.'**
  String eventsChatOutboxFull(int max);

  /// No description provided for @eventsCompletedBagsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Trash bags collected'**
  String get eventsCompletedBagsSectionTitle;

  /// No description provided for @eventsCompletedBagsSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get eventsCompletedBagsSave;

  /// No description provided for @eventsCompletedBagsSaved.
  ///
  /// In en, this message translates to:
  /// **'Bag count saved.'**
  String get eventsCompletedBagsSaved;

  /// No description provided for @eventsImpactBadgeRating.
  ///
  /// In en, this message translates to:
  /// **'{rating}★ rating'**
  String eventsImpactBadgeRating(int rating);

  /// No description provided for @eventsImpactBadgeBags.
  ///
  /// In en, this message translates to:
  /// **'{count} bags'**
  String eventsImpactBadgeBags(int count);

  /// No description provided for @eventsImpactBadgeHours.
  ///
  /// In en, this message translates to:
  /// **'{hours}h'**
  String eventsImpactBadgeHours(String hours);

  /// No description provided for @eventsImpactEstimatedLine.
  ///
  /// In en, this message translates to:
  /// **'{kg} kg removed · {co2} kg CO2e avoided'**
  String eventsImpactEstimatedLine(String kg, String co2);

  /// No description provided for @eventsLocationSiteSemantic.
  ///
  /// In en, this message translates to:
  /// **'View pollution site, {distanceKm} km away'**
  String eventsLocationSiteSemantic(String distanceKm);

  /// No description provided for @eventsLocationDotKm.
  ///
  /// In en, this message translates to:
  /// **'· {distanceKm} km'**
  String eventsLocationDotKm(String distanceKm);

  /// No description provided for @eventsEmptyAllTitle.
  ///
  /// In en, this message translates to:
  /// **'No eco events yet'**
  String get eventsEmptyAllTitle;

  /// No description provided for @eventsEmptyAllSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Be the first to create one! Tap + above to get started.'**
  String get eventsEmptyAllSubtitle;

  /// No description provided for @eventsEmptyUpcomingTitle.
  ///
  /// In en, this message translates to:
  /// **'No upcoming events'**
  String get eventsEmptyUpcomingTitle;

  /// No description provided for @eventsEmptyUpcomingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create one to get volunteers together.'**
  String get eventsEmptyUpcomingSubtitle;

  /// No description provided for @eventsEmptyNearbyTitle.
  ///
  /// In en, this message translates to:
  /// **'No nearby events'**
  String get eventsEmptyNearbyTitle;

  /// No description provided for @eventsEmptyNearbySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try a different filter or create an event in your area.'**
  String get eventsEmptyNearbySubtitle;

  /// No description provided for @eventsEmptyPastTitle.
  ///
  /// In en, this message translates to:
  /// **'No past events'**
  String get eventsEmptyPastTitle;

  /// No description provided for @eventsEmptyPastSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Completed events will show here.'**
  String get eventsEmptyPastSubtitle;

  /// No description provided for @eventsEmptyMyEventsTitle.
  ///
  /// In en, this message translates to:
  /// **'No events yet'**
  String get eventsEmptyMyEventsTitle;

  /// No description provided for @eventsEmptyMyEventsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join or create an event to see it here.'**
  String get eventsEmptyMyEventsSubtitle;

  /// No description provided for @eventsSearchEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String eventsSearchEmptyTitle(String query);

  /// No description provided for @eventsSearchEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term or check your spelling.'**
  String get eventsSearchEmptySubtitle;

  /// No description provided for @eventsSearchEmptyScopeHint.
  ///
  /// In en, this message translates to:
  /// **'Matches come from the server as you type and from events already loaded in this list.'**
  String get eventsSearchEmptyScopeHint;

  /// No description provided for @eventsSitePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose site'**
  String get eventsSitePickerTitle;

  /// No description provided for @eventsSitePickerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Anchor this event to one cleanup location.'**
  String get eventsSitePickerSubtitle;

  /// No description provided for @eventsSitePickerSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search by name or description'**
  String get eventsSitePickerSearchPlaceholder;

  /// No description provided for @eventsSitePickerNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No sites match \"{query}\"'**
  String eventsSitePickerNoMatch(String query);

  /// No description provided for @eventsSitePickerRowKmDesc.
  ///
  /// In en, this message translates to:
  /// **'{km} km away · {desc}'**
  String eventsSitePickerRowKmDesc(String km, String desc);

  /// No description provided for @eventsSuccessDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Event created'**
  String get eventsSuccessDialogTitle;

  /// No description provided for @eventsSuccessDialogBody.
  ///
  /// In en, this message translates to:
  /// **'{title} at {siteName} is ready. Share it with your community to get volunteers on board.'**
  String eventsSuccessDialogBody(String title, String siteName);

  /// No description provided for @eventsSuccessDialogOpenEvent.
  ///
  /// In en, this message translates to:
  /// **'Open event'**
  String get eventsSuccessDialogOpenEvent;

  /// No description provided for @eventsSuccessDialogViewEvent.
  ///
  /// In en, this message translates to:
  /// **'View event'**
  String get eventsSuccessDialogViewEvent;

  /// No description provided for @eventsSuccessDialogPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Submitted for review'**
  String get eventsSuccessDialogPendingTitle;

  /// No description provided for @eventsSuccessDialogPendingBody.
  ///
  /// In en, this message translates to:
  /// **'{title} at {siteName} was submitted. A moderator will approve or decline it before it appears publicly. You can open it from your events anytime.'**
  String eventsSuccessDialogPendingBody(String title, String siteName);

  /// No description provided for @eventsTimePickerSelectTime.
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get eventsTimePickerSelectTime;

  /// No description provided for @eventsTimePickerConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get eventsTimePickerConfirm;

  /// No description provided for @eventsTimePickerFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get eventsTimePickerFrom;

  /// No description provided for @eventsTimePickerTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get eventsTimePickerTo;

  /// No description provided for @eventsTimePickerTimeBlockSemantic.
  ///
  /// In en, this message translates to:
  /// **'{role}, {time}'**
  String eventsTimePickerTimeBlockSemantic(String role, String time);

  /// No description provided for @eventsFeedbackRatingStars.
  ///
  /// In en, this message translates to:
  /// **'{rating}★'**
  String eventsFeedbackRatingStars(int rating);

  /// No description provided for @eventsFeedRecentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get eventsFeedRecentSearches;

  /// No description provided for @eventsCleanupAfterUploadSemantic.
  ///
  /// In en, this message translates to:
  /// **'Upload after photos'**
  String get eventsCleanupAfterUploadSemantic;

  /// No description provided for @eventsCleanupAfterViewFullscreenSemantic.
  ///
  /// In en, this message translates to:
  /// **'View photo fullscreen'**
  String get eventsCleanupAfterViewFullscreenSemantic;

  /// No description provided for @eventsCleanupAfterUploadMoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload more photos'**
  String get eventsCleanupAfterUploadMoreTitle;

  /// No description provided for @eventsCleanupAfterUploadedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} uploaded'**
  String eventsCleanupAfterUploadedCount(int count);

  /// No description provided for @eventsCleanupAfterSlotsRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 more slot available} other{{count} more slots available}}'**
  String eventsCleanupAfterSlotsRemaining(int count);

  /// No description provided for @eventsCleanupAfterAddMoreSemantic.
  ///
  /// In en, this message translates to:
  /// **'Add more photos'**
  String get eventsCleanupAfterAddMoreSemantic;

  /// No description provided for @eventsCleanupAfterRemoveSemantic.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get eventsCleanupAfterRemoveSemantic;

  /// No description provided for @eventsCleanupAfterEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Add photos of the cleaned site'**
  String get eventsCleanupAfterEmptyTitle;

  /// No description provided for @eventsCleanupAfterEmptyMaxPhotos.
  ///
  /// In en, this message translates to:
  /// **'Up to {max} photos'**
  String eventsCleanupAfterEmptyMaxPhotos(int max);

  /// No description provided for @eventsCleanupAfterEmptyTapGallery.
  ///
  /// In en, this message translates to:
  /// **'Tap to select from gallery'**
  String get eventsCleanupAfterEmptyTapGallery;

  /// No description provided for @eventsCleanupEvidencePhotoSemantic.
  ///
  /// In en, this message translates to:
  /// **'Cleanup evidence photo'**
  String get eventsCleanupEvidencePhotoSemantic;

  /// No description provided for @eventsDateRelativeEarlierToday.
  ///
  /// In en, this message translates to:
  /// **'Earlier today'**
  String get eventsDateRelativeEarlierToday;

  /// No description provided for @eventsDateRelativeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String eventsDateRelativeDaysAgo(int days);

  /// No description provided for @eventsDateRelativeToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get eventsDateRelativeToday;

  /// No description provided for @eventsDateRelativeTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get eventsDateRelativeTomorrow;

  /// No description provided for @eventsDateRelativeInDays.
  ///
  /// In en, this message translates to:
  /// **'In {days} days'**
  String eventsDateRelativeInDays(int days);

  /// No description provided for @eventsDateInfoSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Date and time'**
  String get eventsDateInfoSheetTitle;

  /// No description provided for @eventsDateInfoSemantic.
  ///
  /// In en, this message translates to:
  /// **'{date}, {timeRange}'**
  String eventsDateInfoSemantic(String date, String timeRange);

  /// No description provided for @eventsCategorySheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get eventsCategorySheetTitle;

  /// No description provided for @eventsCategorySemantic.
  ///
  /// In en, this message translates to:
  /// **'Event category: {label}'**
  String eventsCategorySemantic(String label);

  /// No description provided for @eventsOrganizerSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Organizer'**
  String get eventsOrganizerSheetTitle;

  /// No description provided for @eventsOrganizerYouOwnThis.
  ///
  /// In en, this message translates to:
  /// **'This is your event'**
  String get eventsOrganizerYouOwnThis;

  /// No description provided for @eventsOrganizerRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Event organizer'**
  String get eventsOrganizerRoleLabel;

  /// No description provided for @eventsOrganizerCreatedOn.
  ///
  /// In en, this message translates to:
  /// **'Event created on {day}/{month}/{year}'**
  String eventsOrganizerCreatedOn(int day, int month, int year);

  /// No description provided for @eventsOrganizerSemantic.
  ///
  /// In en, this message translates to:
  /// **'Organizer: {name}'**
  String eventsOrganizerSemantic(String name);

  /// No description provided for @eventsOrganizedByLabel.
  ///
  /// In en, this message translates to:
  /// **'Organized by'**
  String get eventsOrganizedByLabel;

  /// No description provided for @eventsFeedSemantic.
  ///
  /// In en, this message translates to:
  /// **'Events feed'**
  String get eventsFeedSemantic;

  /// No description provided for @eventsFeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get eventsFeedTitle;

  /// No description provided for @eventsFeedCreateSemantic.
  ///
  /// In en, this message translates to:
  /// **'Create event'**
  String get eventsFeedCreateSemantic;

  /// No description provided for @eventsFeedSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search events'**
  String get eventsFeedSearchPlaceholder;

  /// No description provided for @eventsFeedHappeningNow.
  ///
  /// In en, this message translates to:
  /// **'Happening now'**
  String get eventsFeedHappeningNow;

  /// No description provided for @eventsFeedComingUp.
  ///
  /// In en, this message translates to:
  /// **'Coming up'**
  String get eventsFeedComingUp;

  /// No description provided for @eventsFeedRecentlyCompleted.
  ///
  /// In en, this message translates to:
  /// **'Recently completed'**
  String get eventsFeedRecentlyCompleted;

  /// No description provided for @eventsFeedViewListToggle.
  ///
  /// In en, this message translates to:
  /// **'List view'**
  String get eventsFeedViewListToggle;

  /// No description provided for @eventsFeedViewCalendarToggle.
  ///
  /// In en, this message translates to:
  /// **'Calendar view'**
  String get eventsFeedViewCalendarToggle;

  /// No description provided for @eventsCalendarPreviousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get eventsCalendarPreviousMonth;

  /// No description provided for @eventsCalendarNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get eventsCalendarNextMonth;

  /// No description provided for @eventsCalendarDaySemantic.
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String eventsCalendarDaySemantic(int day);

  /// No description provided for @eventsCalendarNoEventsThisDay.
  ///
  /// In en, this message translates to:
  /// **'No events on this day'**
  String get eventsCalendarNoEventsThisDay;

  /// No description provided for @eventsCalendarIncompleteListHint.
  ///
  /// In en, this message translates to:
  /// **'More events may be available. Load the next page to fill this month.'**
  String get eventsCalendarIncompleteListHint;

  /// No description provided for @eventsCalendarLoadMoreButton.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get eventsCalendarLoadMoreButton;

  /// No description provided for @eventsCalendarDayA11yOutOfMonth.
  ///
  /// In en, this message translates to:
  /// **'Day {day}, not in this month'**
  String eventsCalendarDayA11yOutOfMonth(int day);

  /// No description provided for @eventsCalendarDayA11y.
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String eventsCalendarDayA11y(int day);

  /// No description provided for @eventsCalendarDayA11yHasEvents.
  ///
  /// In en, this message translates to:
  /// **'Day {day}, has events'**
  String eventsCalendarDayA11yHasEvents(int day);

  /// No description provided for @eventsCalendarDayA11ySelected.
  ///
  /// In en, this message translates to:
  /// **'Day {day}, selected'**
  String eventsCalendarDayA11ySelected(int day);

  /// No description provided for @eventsCalendarDayA11ySelectedHasEvents.
  ///
  /// In en, this message translates to:
  /// **'Day {day}, selected, has events'**
  String eventsCalendarDayA11ySelectedHasEvents(int day);

  /// No description provided for @eventsEmptyActionClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get eventsEmptyActionClearFilters;

  /// No description provided for @eventsEmptyActionCreateEvent.
  ///
  /// In en, this message translates to:
  /// **'Create event'**
  String get eventsEmptyActionCreateEvent;

  /// No description provided for @eventsSearchEmptyClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get eventsSearchEmptyClearSearch;

  /// No description provided for @siteCardPollutionSiteSemantic.
  ///
  /// In en, this message translates to:
  /// **'Pollution site: {title}. Tap to open details.'**
  String siteCardPollutionSiteSemantic(String title);

  /// No description provided for @siteCardPhotoSemantic.
  ///
  /// In en, this message translates to:
  /// **'Photo of {title}'**
  String siteCardPhotoSemantic(String title);

  /// No description provided for @siteCardGalleryPhotoSemantic.
  ///
  /// In en, this message translates to:
  /// **'Photo {number} of {siteTitle}'**
  String siteCardGalleryPhotoSemantic(int number, String siteTitle);

  /// No description provided for @siteCardSemanticRemoveUpvote.
  ///
  /// In en, this message translates to:
  /// **'Remove upvote for {title}'**
  String siteCardSemanticRemoveUpvote(String title);

  /// No description provided for @siteCardSemanticUpvote.
  ///
  /// In en, this message translates to:
  /// **'Upvote {title}'**
  String siteCardSemanticUpvote(String title);

  /// No description provided for @siteUpvoteLongPressOpensSupporters.
  ///
  /// In en, this message translates to:
  /// **'Long press to open the list of supporters'**
  String get siteUpvoteLongPressOpensSupporters;

  /// No description provided for @siteCardSemanticUpvotesOpenSupporters.
  ///
  /// In en, this message translates to:
  /// **'{count} upvotes on {title}. Tap to see supporters'**
  String siteCardSemanticUpvotesOpenSupporters(int count, String title);

  /// No description provided for @siteCardSemanticCommentsOnSite.
  ///
  /// In en, this message translates to:
  /// **'{count} comments on {title}'**
  String siteCardSemanticCommentsOnSite(int count, String title);

  /// No description provided for @siteCardSemanticSharesOnSite.
  ///
  /// In en, this message translates to:
  /// **'{count} shares on {title}'**
  String siteCardSemanticSharesOnSite(int count, String title);

  /// No description provided for @siteCardSemanticSaveSite.
  ///
  /// In en, this message translates to:
  /// **'Save {title} and get updates'**
  String siteCardSemanticSaveSite(String title);

  /// No description provided for @siteCardSemanticUnsaveSite.
  ///
  /// In en, this message translates to:
  /// **'Unsave {title} and stop updates'**
  String siteCardSemanticUnsaveSite(String title);

  /// No description provided for @siteCardSaveUpdatesOnSnack.
  ///
  /// In en, this message translates to:
  /// **'You will get updates for this site'**
  String get siteCardSaveUpdatesOnSnack;

  /// No description provided for @siteCardSaveRemovedSnack.
  ///
  /// In en, this message translates to:
  /// **'Removed from your saved sites'**
  String get siteCardSaveRemovedSnack;

  /// No description provided for @siteCardFeedbackPostHiddenSnack.
  ///
  /// In en, this message translates to:
  /// **'Post hidden from your feed'**
  String get siteCardFeedbackPostHiddenSnack;

  /// No description provided for @siteCardFeedbackThanksSnack.
  ///
  /// In en, this message translates to:
  /// **'Thanks for your feedback'**
  String get siteCardFeedbackThanksSnack;

  /// No description provided for @siteCardFeedOptionsSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Feed options'**
  String get siteCardFeedOptionsSheetTitle;

  /// No description provided for @siteCardFeedOptionsSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tune what you want to see'**
  String get siteCardFeedOptionsSheetSubtitle;

  /// No description provided for @siteCardEngagementSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in to support or save sites.'**
  String get siteCardEngagementSignInRequired;

  /// No description provided for @siteCardEngagementWaitBriefly.
  ///
  /// In en, this message translates to:
  /// **'Please wait a moment before trying again.'**
  String get siteCardEngagementWaitBriefly;

  /// No description provided for @siteCardRateLimitedSnack.
  ///
  /// In en, this message translates to:
  /// **'Too many actions. Try again in {seconds} seconds.'**
  String siteCardRateLimitedSnack(int seconds);

  /// No description provided for @siteDetailSaveAddedSnack.
  ///
  /// In en, this message translates to:
  /// **'Site saved to your list.'**
  String get siteDetailSaveAddedSnack;

  /// No description provided for @siteDetailSaveRemovedSnack.
  ///
  /// In en, this message translates to:
  /// **'Removed from saved sites.'**
  String get siteDetailSaveRemovedSnack;

  /// No description provided for @siteQuickActionSaveSiteLabel.
  ///
  /// In en, this message translates to:
  /// **'Save site'**
  String get siteQuickActionSaveSiteLabel;

  /// No description provided for @siteQuickActionSavedLabel.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get siteQuickActionSavedLabel;

  /// No description provided for @siteQuickActionReportIssueLabel.
  ///
  /// In en, this message translates to:
  /// **'Report issue'**
  String get siteQuickActionReportIssueLabel;

  /// No description provided for @siteQuickActionReportedLabel.
  ///
  /// In en, this message translates to:
  /// **'Reported'**
  String get siteQuickActionReportedLabel;

  /// No description provided for @siteQuickActionShareLabel.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get siteQuickActionShareLabel;

  /// No description provided for @siteCardDistanceMeters.
  ///
  /// In en, this message translates to:
  /// **'{meters} m'**
  String siteCardDistanceMeters(int meters);

  /// No description provided for @siteCardDistanceKmShort.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String siteCardDistanceKmShort(String km);

  /// No description provided for @siteCardDistanceKmWhole.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String siteCardDistanceKmWhole(String km);

  /// No description provided for @eventsFilterSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter events'**
  String get eventsFilterSheetTitle;

  /// No description provided for @eventsFilterSheetCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get eventsFilterSheetCategory;

  /// No description provided for @eventsFilterSheetStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get eventsFilterSheetStatus;

  /// No description provided for @eventsFilterSheetDateRange.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get eventsFilterSheetDateRange;

  /// No description provided for @eventsFilterSheetDateFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get eventsFilterSheetDateFrom;

  /// No description provided for @eventsFilterSheetDateTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get eventsFilterSheetDateTo;

  /// No description provided for @eventsFilterSheetShowResults.
  ///
  /// In en, this message translates to:
  /// **'Show results'**
  String get eventsFilterSheetShowResults;

  /// No description provided for @eventsFilterSheetClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get eventsFilterSheetClearAll;

  /// No description provided for @eventsFilterSheetActiveCount.
  ///
  /// In en, this message translates to:
  /// **'{count} active'**
  String eventsFilterSheetActiveCount(int count);

  /// No description provided for @eventsOrganizerDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'My events'**
  String get eventsOrganizerDashboardTitle;

  /// No description provided for @eventsOrganizerDashboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t organised any events yet.'**
  String get eventsOrganizerDashboardEmpty;

  /// No description provided for @eventsOrganizerDashboardEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Create first event'**
  String get eventsOrganizerDashboardEmptyAction;

  /// No description provided for @eventsOrganizerDashboardSectionUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get eventsOrganizerDashboardSectionUpcoming;

  /// No description provided for @eventsOrganizerDashboardSectionInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get eventsOrganizerDashboardSectionInProgress;

  /// No description provided for @eventsOrganizerDashboardSectionCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get eventsOrganizerDashboardSectionCompleted;

  /// No description provided for @eventsOrganizerDashboardSectionCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get eventsOrganizerDashboardSectionCancelled;

  /// No description provided for @eventsOrganizerDashboardParticipants.
  ///
  /// In en, this message translates to:
  /// **'{count}/{max} participants'**
  String eventsOrganizerDashboardParticipants(int count, String max);

  /// No description provided for @eventsOrganizerDashboardParticipantsUnlimited.
  ///
  /// In en, this message translates to:
  /// **'{count} participants'**
  String eventsOrganizerDashboardParticipantsUnlimited(int count);

  /// No description provided for @eventsOrganizerDashboardEvidenceAction.
  ///
  /// In en, this message translates to:
  /// **'Evidence'**
  String get eventsOrganizerDashboardEvidenceAction;

  /// No description provided for @eventsAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get eventsAnalyticsTitle;

  /// No description provided for @eventsAnalyticsAttendanceRate.
  ///
  /// In en, this message translates to:
  /// **'Attendance rate'**
  String get eventsAnalyticsAttendanceRate;

  /// No description provided for @eventsAnalyticsJoiners.
  ///
  /// In en, this message translates to:
  /// **'Joiners over time'**
  String get eventsAnalyticsJoiners;

  /// No description provided for @eventsAnalyticsCheckInsByHour.
  ///
  /// In en, this message translates to:
  /// **'Check-ins by hour'**
  String get eventsAnalyticsCheckInsByHour;

  /// No description provided for @eventsAnalyticsNoData.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get eventsAnalyticsNoData;

  /// No description provided for @eventsAnalyticsRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh analytics'**
  String get eventsAnalyticsRefresh;

  /// No description provided for @eventsAnalyticsCheckedInRatio.
  ///
  /// In en, this message translates to:
  /// **'{checkedInCount} of {totalJoiners} checked in'**
  String eventsAnalyticsCheckedInRatio(int checkedInCount, int totalJoiners);

  /// No description provided for @eventsAnalyticsJoinersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No one has joined this event yet.'**
  String get eventsAnalyticsJoinersEmpty;

  /// No description provided for @eventsAnalyticsCheckInsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No check-ins yet. Hours are shown in UTC.'**
  String get eventsAnalyticsCheckInsEmpty;

  /// No description provided for @eventsAnalyticsPeakCheckInsUtc.
  ///
  /// In en, this message translates to:
  /// **'Peak: {hour} UTC'**
  String eventsAnalyticsPeakCheckInsUtc(String hour);

  /// No description provided for @eventsAnalyticsSemanticsJoinCurve.
  ///
  /// In en, this message translates to:
  /// **'Join trend from {fromCount} to {toCount} participants, {steps} data points.'**
  String eventsAnalyticsSemanticsJoinCurve(
    int fromCount,
    int toCount,
    int steps,
  );

  /// No description provided for @eventsAnalyticsSemanticsCheckInHeatmap.
  ///
  /// In en, this message translates to:
  /// **'Check-ins by hour in UTC. Peak {peakCount} at {hour}.'**
  String eventsAnalyticsSemanticsCheckInHeatmap(int peakCount, String hour);

  /// No description provided for @eventsAnalyticsSemanticsCheckInNoData.
  ///
  /// In en, this message translates to:
  /// **'Check-ins by hour in UTC. No check-ins recorded.'**
  String get eventsAnalyticsSemanticsCheckInNoData;

  /// No description provided for @eventsOfflineSyncQueued.
  ///
  /// In en, this message translates to:
  /// **'Saved. Will sync when back online.'**
  String get eventsOfflineSyncQueued;

  /// No description provided for @eventsOfflineSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed. Will retry automatically.'**
  String get eventsOfflineSyncFailed;

  /// No description provided for @eventsWeatherForecast.
  ///
  /// In en, this message translates to:
  /// **'Weather forecast'**
  String get eventsWeatherForecast;

  /// No description provided for @eventsWeatherLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Weather unavailable'**
  String get eventsWeatherLoadFailed;

  /// No description provided for @eventsWeatherPrecipitationMm.
  ///
  /// In en, this message translates to:
  /// **'{amount} mm precipitation'**
  String eventsWeatherPrecipitationMm(String amount);

  /// No description provided for @eventsWeatherNoPrecipitation.
  ///
  /// In en, this message translates to:
  /// **'No measurable precipitation'**
  String get eventsWeatherNoPrecipitation;

  /// No description provided for @eventsWeatherPrecipChance.
  ///
  /// In en, this message translates to:
  /// **'{percent}% chance of precipitation'**
  String eventsWeatherPrecipChance(int percent);

  /// No description provided for @eventsWeatherIndicativeNote.
  ///
  /// In en, this message translates to:
  /// **'Indicative forecast from Open-Meteo; actual conditions may differ.'**
  String get eventsWeatherIndicativeNote;

  /// No description provided for @eventsWeatherIndicativeInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'About this forecast'**
  String get eventsWeatherIndicativeInfoTitle;

  /// No description provided for @eventsWeatherIndicativeInfoSemantic.
  ///
  /// In en, this message translates to:
  /// **'Information about the weather forecast source'**
  String get eventsWeatherIndicativeInfoSemantic;

  /// No description provided for @eventsRecurrenceNone.
  ///
  /// In en, this message translates to:
  /// **'Does not repeat'**
  String get eventsRecurrenceNone;

  /// No description provided for @eventsRecurrenceWeekly.
  ///
  /// In en, this message translates to:
  /// **'Every week'**
  String get eventsRecurrenceWeekly;

  /// No description provided for @eventsRecurrenceBiweekly.
  ///
  /// In en, this message translates to:
  /// **'Every 2 weeks'**
  String get eventsRecurrenceBiweekly;

  /// No description provided for @eventsRecurrenceMonthly.
  ///
  /// In en, this message translates to:
  /// **'Every month'**
  String get eventsRecurrenceMonthly;

  /// No description provided for @eventsRecurrenceOccurrences.
  ///
  /// In en, this message translates to:
  /// **'{count} occurrences'**
  String eventsRecurrenceOccurrences(int count);

  /// No description provided for @eventsRecurrencePartOfSeries.
  ///
  /// In en, this message translates to:
  /// **'Part of a series'**
  String get eventsRecurrencePartOfSeries;

  /// No description provided for @eventsRecurrenceSeriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Event {index} of {total}'**
  String eventsRecurrenceSeriesLabel(int index, int total);

  /// No description provided for @eventsRecurrenceDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get eventsRecurrenceDone;

  /// No description provided for @eventsCategoryGeneralCleanup.
  ///
  /// In en, this message translates to:
  /// **'General cleanup'**
  String get eventsCategoryGeneralCleanup;

  /// No description provided for @eventsCategoryGeneralCleanupDescription.
  ///
  /// In en, this message translates to:
  /// **'Pick up litter, sweep debris, and restore the area.'**
  String get eventsCategoryGeneralCleanupDescription;

  /// No description provided for @eventsCategoryRiverAndLake.
  ///
  /// In en, this message translates to:
  /// **'River & lake cleanup'**
  String get eventsCategoryRiverAndLake;

  /// No description provided for @eventsCategoryRiverAndLakeDescription.
  ///
  /// In en, this message translates to:
  /// **'Remove waste from waterways, shores, and drainage channels.'**
  String get eventsCategoryRiverAndLakeDescription;

  /// No description provided for @eventsCategoryTreeAndGreen.
  ///
  /// In en, this message translates to:
  /// **'Tree planting & greening'**
  String get eventsCategoryTreeAndGreen;

  /// No description provided for @eventsCategoryTreeAndGreenDescription.
  ///
  /// In en, this message translates to:
  /// **'Plant trees, restore green spaces, and build garden beds.'**
  String get eventsCategoryTreeAndGreenDescription;

  /// No description provided for @eventsCategoryRecyclingDrive.
  ///
  /// In en, this message translates to:
  /// **'Recycling drive'**
  String get eventsCategoryRecyclingDrive;

  /// No description provided for @eventsCategoryRecyclingDriveDescription.
  ///
  /// In en, this message translates to:
  /// **'Sort, collect, and transport recyclables to processing centers.'**
  String get eventsCategoryRecyclingDriveDescription;

  /// No description provided for @eventsCategoryHazardousRemoval.
  ///
  /// In en, this message translates to:
  /// **'Hazardous waste removal'**
  String get eventsCategoryHazardousRemoval;

  /// No description provided for @eventsCategoryHazardousRemovalDescription.
  ///
  /// In en, this message translates to:
  /// **'Safely collect chemicals, tires, batteries, or asbestos.'**
  String get eventsCategoryHazardousRemovalDescription;

  /// No description provided for @eventsCategoryAwarenessAndEducation.
  ///
  /// In en, this message translates to:
  /// **'Awareness & education'**
  String get eventsCategoryAwarenessAndEducation;

  /// No description provided for @eventsCategoryAwarenessAndEducationDescription.
  ///
  /// In en, this message translates to:
  /// **'Workshops, talks, or community engagement on eco practices.'**
  String get eventsCategoryAwarenessAndEducationDescription;

  /// No description provided for @eventsCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get eventsCategoryOther;

  /// No description provided for @eventsCategoryOtherDescription.
  ///
  /// In en, this message translates to:
  /// **'Custom event that doesn\'t match the categories above.'**
  String get eventsCategoryOtherDescription;

  /// No description provided for @eventsGearTrashBags.
  ///
  /// In en, this message translates to:
  /// **'Trash bags'**
  String get eventsGearTrashBags;

  /// No description provided for @eventsGearGloves.
  ///
  /// In en, this message translates to:
  /// **'Gloves'**
  String get eventsGearGloves;

  /// No description provided for @eventsGearRakes.
  ///
  /// In en, this message translates to:
  /// **'Rakes & shovels'**
  String get eventsGearRakes;

  /// No description provided for @eventsGearWheelbarrow.
  ///
  /// In en, this message translates to:
  /// **'Wheelbarrow'**
  String get eventsGearWheelbarrow;

  /// No description provided for @eventsGearWaterBoots.
  ///
  /// In en, this message translates to:
  /// **'Water boots'**
  String get eventsGearWaterBoots;

  /// No description provided for @eventsGearSafetyVest.
  ///
  /// In en, this message translates to:
  /// **'Safety vest'**
  String get eventsGearSafetyVest;

  /// No description provided for @eventsGearFirstAid.
  ///
  /// In en, this message translates to:
  /// **'First aid kit'**
  String get eventsGearFirstAid;

  /// No description provided for @eventsGearSunscreen.
  ///
  /// In en, this message translates to:
  /// **'Sunscreen & water'**
  String get eventsGearSunscreen;

  /// No description provided for @eventsScaleSmall.
  ///
  /// In en, this message translates to:
  /// **'Small (1–5 people)'**
  String get eventsScaleSmall;

  /// No description provided for @eventsScaleSmallDescription.
  ///
  /// In en, this message translates to:
  /// **'Quick spot cleanup, one bag or two.'**
  String get eventsScaleSmallDescription;

  /// No description provided for @eventsScaleMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium (6–15 people)'**
  String get eventsScaleMedium;

  /// No description provided for @eventsScaleMediumDescription.
  ///
  /// In en, this message translates to:
  /// **'Half-day effort, several areas covered.'**
  String get eventsScaleMediumDescription;

  /// No description provided for @eventsScaleLarge.
  ///
  /// In en, this message translates to:
  /// **'Large (16–40 people)'**
  String get eventsScaleLarge;

  /// No description provided for @eventsScaleLargeDescription.
  ///
  /// In en, this message translates to:
  /// **'Organized group, heavy waste removal.'**
  String get eventsScaleLargeDescription;

  /// No description provided for @eventsScaleMassive.
  ///
  /// In en, this message translates to:
  /// **'Massive (40+ people)'**
  String get eventsScaleMassive;

  /// No description provided for @eventsScaleMassiveDescription.
  ///
  /// In en, this message translates to:
  /// **'City-wide or multi-site event.'**
  String get eventsScaleMassiveDescription;

  /// No description provided for @eventsDifficultyEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get eventsDifficultyEasy;

  /// No description provided for @eventsDifficultyEasyDescription.
  ///
  /// In en, this message translates to:
  /// **'Flat terrain, light waste, family-friendly.'**
  String get eventsDifficultyEasyDescription;

  /// No description provided for @eventsDifficultyModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get eventsDifficultyModerate;

  /// No description provided for @eventsDifficultyModerateDescription.
  ///
  /// In en, this message translates to:
  /// **'Mixed terrain or bulky items, some effort.'**
  String get eventsDifficultyModerateDescription;

  /// No description provided for @eventsDifficultyHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get eventsDifficultyHard;

  /// No description provided for @eventsDifficultyHardDescription.
  ///
  /// In en, this message translates to:
  /// **'Steep slopes, heavy debris, or hazardous materials.'**
  String get eventsDifficultyHardDescription;

  /// No description provided for @eventsSiteCoercedDescription.
  ///
  /// In en, this message translates to:
  /// **'Community cleanup site'**
  String get eventsSiteCoercedDescription;

  /// No description provided for @homeSiteCleaningEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No cleaning events yet'**
  String get homeSiteCleaningEmptyTitle;

  /// No description provided for @homeSiteCleaningEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Be the first to organize an eco action and rally volunteers for this site.'**
  String get homeSiteCleaningEmptyBody;

  /// No description provided for @homeSiteCleaningTapToCreate.
  ///
  /// In en, this message translates to:
  /// **'Tap to create'**
  String get homeSiteCleaningTapToCreate;

  /// No description provided for @homeSiteCleaningCtaCreateFirst.
  ///
  /// In en, this message translates to:
  /// **'Create eco action'**
  String get homeSiteCleaningCtaCreateFirst;

  /// No description provided for @homeSiteCleaningCtaScheduleAnother.
  ///
  /// In en, this message translates to:
  /// **'Schedule another action'**
  String get homeSiteCleaningCtaScheduleAnother;

  /// No description provided for @homeSiteCleaningVolunteersJoined.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 volunteer joined} other{{count} volunteers joined}}'**
  String homeSiteCleaningVolunteersJoined(int count);

  /// No description provided for @homeSiteCleaningOrganizerHint.
  ///
  /// In en, this message translates to:
  /// **'You\'re organizing this action. Upload \"after\" photos once it\'s completed.'**
  String get homeSiteCleaningOrganizerHint;

  /// No description provided for @homeSiteCleaningVolunteerHint.
  ///
  /// In en, this message translates to:
  /// **'Join the action to help clean this site.'**
  String get homeSiteCleaningVolunteerHint;

  /// No description provided for @homeSiteCleaningJoinAction.
  ///
  /// In en, this message translates to:
  /// **'Join action'**
  String get homeSiteCleaningJoinAction;

  /// No description provided for @homeSiteCleaningEventUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Event details are unavailable right now.'**
  String get homeSiteCleaningEventUnavailable;

  /// No description provided for @homeSiteCleaningListLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load events. Check your connection and try again.'**
  String get homeSiteCleaningListLoadError;

  /// No description provided for @homeSiteCleaningRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get homeSiteCleaningRetry;

  /// No description provided for @homeSiteCleaningLoadingSemantic.
  ///
  /// In en, this message translates to:
  /// **'Loading eco actions.'**
  String get homeSiteCleaningLoadingSemantic;

  /// No description provided for @eventsDistanceLessThan100m.
  ///
  /// In en, this message translates to:
  /// **'<100 m'**
  String get eventsDistanceLessThan100m;

  /// No description provided for @eventsDistanceMeters.
  ///
  /// In en, this message translates to:
  /// **'{meters} m'**
  String eventsDistanceMeters(int meters);

  /// No description provided for @eventsDistanceKilometers.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String eventsDistanceKilometers(String km);

  /// No description provided for @errorUserNetwork.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get errorUserNetwork;

  /// No description provided for @errorUserTimeout.
  ///
  /// In en, this message translates to:
  /// **'That took too long. Please try again.'**
  String get errorUserTimeout;

  /// No description provided for @errorUserUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to continue.'**
  String get errorUserUnauthorized;

  /// No description provided for @errorUserForbidden.
  ///
  /// In en, this message translates to:
  /// **'You don’t have permission to do that.'**
  String get errorUserForbidden;

  /// No description provided for @errorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t find that.'**
  String get errorUserNotFound;

  /// No description provided for @errorUserServer.
  ///
  /// In en, this message translates to:
  /// **'The service is busy. Please try again shortly.'**
  String get errorUserServer;

  /// No description provided for @errorUserTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment.'**
  String get errorUserTooManyRequests;

  /// No description provided for @errorUserUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorUserUnknown;

  /// No description provided for @eventsFilterSheetSemantic.
  ///
  /// In en, this message translates to:
  /// **'Filter events'**
  String get eventsFilterSheetSemantic;

  /// No description provided for @eventChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get eventChatTitle;

  /// No description provided for @eventChatRowTitle.
  ///
  /// In en, this message translates to:
  /// **'Group chat'**
  String get eventChatRowTitle;

  /// No description provided for @eventChatInputHint.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get eventChatInputHint;

  /// No description provided for @eventChatSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get eventChatSend;

  /// No description provided for @eventChatEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Start the conversation'**
  String get eventChatEmptyTitle;

  /// No description provided for @eventChatEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Coordinate with other volunteers before and during the event.'**
  String get eventChatEmptyBody;

  /// No description provided for @eventChatMessageRemoved.
  ///
  /// In en, this message translates to:
  /// **'This message was removed'**
  String get eventChatMessageRemoved;

  /// No description provided for @eventChatNewMessages.
  ///
  /// In en, this message translates to:
  /// **'New messages'**
  String get eventChatNewMessages;

  /// No description provided for @eventChatToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get eventChatToday;

  /// No description provided for @eventChatYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get eventChatYesterday;

  /// No description provided for @eventChatReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get eventChatReply;

  /// No description provided for @eventChatDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get eventChatDelete;

  /// No description provided for @eventChatLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load messages'**
  String get eventChatLoadError;

  /// No description provided for @eventChatSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Message not sent. Tap to retry.'**
  String get eventChatSendFailed;

  /// No description provided for @eventChatOpenMapsFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t open Maps. Try again.'**
  String get eventChatOpenMapsFailed;

  /// No description provided for @eventChatAttachPhotoLibrary.
  ///
  /// In en, this message translates to:
  /// **'Photo Library'**
  String get eventChatAttachPhotoLibrary;

  /// No description provided for @eventChatAttachCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get eventChatAttachCamera;

  /// No description provided for @eventChatAttachVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get eventChatAttachVideo;

  /// No description provided for @eventChatAttachDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get eventChatAttachDocument;

  /// No description provided for @eventChatAttachAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get eventChatAttachAudio;

  /// No description provided for @eventChatVoiceDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard recording'**
  String get eventChatVoiceDiscard;

  /// No description provided for @eventChatVoiceSend.
  ///
  /// In en, this message translates to:
  /// **'Send voice message'**
  String get eventChatVoiceSend;

  /// No description provided for @eventChatVoicePreviewHint.
  ///
  /// In en, this message translates to:
  /// **'Voice preview'**
  String get eventChatVoicePreviewHint;

  /// No description provided for @eventChatAttachLocation.
  ///
  /// In en, this message translates to:
  /// **'Share Location'**
  String get eventChatAttachLocation;

  /// No description provided for @eventChatSendLocation.
  ///
  /// In en, this message translates to:
  /// **'Send Location'**
  String get eventChatSendLocation;

  /// No description provided for @eventChatSending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get eventChatSending;

  /// No description provided for @eventChatReplyingTo.
  ///
  /// In en, this message translates to:
  /// **'Replying to {name}'**
  String eventChatReplyingTo(String name);

  /// No description provided for @eventChatCharCountHint.
  ///
  /// In en, this message translates to:
  /// **'{count} / 2000'**
  String eventChatCharCountHint(int count);

  /// No description provided for @eventChatSemanticsBubble.
  ///
  /// In en, this message translates to:
  /// **'{author}, {time}. {body}'**
  String eventChatSemanticsBubble(String author, String time, String body);

  /// No description provided for @eventChatInputSemantics.
  ///
  /// In en, this message translates to:
  /// **'Chat message'**
  String get eventChatInputSemantics;

  /// No description provided for @eventChatMessagesListSemantics.
  ///
  /// In en, this message translates to:
  /// **'Messages list'**
  String get eventChatMessagesListSemantics;

  /// No description provided for @eventChatAttachmentsNeedNetwork.
  ///
  /// In en, this message translates to:
  /// **'Photos, video, files, and voice require an internet connection.'**
  String get eventChatAttachmentsNeedNetwork;

  /// No description provided for @eventChatPushChannelName.
  ///
  /// In en, this message translates to:
  /// **'Event chat'**
  String get eventChatPushChannelName;

  /// No description provided for @eventChatEdited.
  ///
  /// In en, this message translates to:
  /// **'(edited)'**
  String get eventChatEdited;

  /// No description provided for @eventChatEditMessage.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get eventChatEditMessage;

  /// No description provided for @eventChatEditing.
  ///
  /// In en, this message translates to:
  /// **'Editing message'**
  String get eventChatEditing;

  /// No description provided for @eventChatEditHint.
  ///
  /// In en, this message translates to:
  /// **'Edit your message'**
  String get eventChatEditHint;

  /// No description provided for @eventChatSaveEdit.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get eventChatSaveEdit;

  /// No description provided for @eventChatPinMessage.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get eventChatPinMessage;

  /// No description provided for @eventChatUnpinMessage.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get eventChatUnpinMessage;

  /// No description provided for @eventChatPinnedBy.
  ///
  /// In en, this message translates to:
  /// **'Pinned by {name}'**
  String eventChatPinnedBy(String name);

  /// No description provided for @eventChatPinnedMessagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Pinned messages'**
  String get eventChatPinnedMessagesTitle;

  /// No description provided for @eventChatPinnedBarHint.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get eventChatPinnedBarHint;

  /// No description provided for @eventChatNoPinnedMessages.
  ///
  /// In en, this message translates to:
  /// **'No pinned messages'**
  String get eventChatNoPinnedMessages;

  /// No description provided for @eventChatMuted.
  ///
  /// In en, this message translates to:
  /// **'Notifications muted'**
  String get eventChatMuted;

  /// No description provided for @eventChatUnmuted.
  ///
  /// In en, this message translates to:
  /// **'Notifications unmuted'**
  String get eventChatUnmuted;

  /// No description provided for @eventChatCopied.
  ///
  /// In en, this message translates to:
  /// **'Message copied'**
  String get eventChatCopied;

  /// No description provided for @eventChatReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get eventChatReconnecting;

  /// No description provided for @eventChatConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get eventChatConnected;

  /// No description provided for @eventChatSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search messages'**
  String get eventChatSearchHint;

  /// No description provided for @eventChatSearchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matching messages'**
  String get eventChatSearchNoResults;

  /// No description provided for @eventChatSearchAction.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get eventChatSearchAction;

  /// No description provided for @eventChatSearchFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not search messages. Check your connection and try again.'**
  String get eventChatSearchFailed;

  /// No description provided for @eventChatSearchMinChars.
  ///
  /// In en, this message translates to:
  /// **'Type at least 2 characters to search.'**
  String get eventChatSearchMinChars;

  /// No description provided for @eventChatSearchIncludingLocalMatches.
  ///
  /// In en, this message translates to:
  /// **'Including messages loaded on this device.'**
  String get eventChatSearchIncludingLocalMatches;

  /// No description provided for @eventChatSearchLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more results'**
  String get eventChatSearchLoadMore;

  /// No description provided for @eventChatParticipantsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} participants'**
  String eventChatParticipantsCount(int count);

  /// No description provided for @eventChatParticipantsSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'People in this chat'**
  String get eventChatParticipantsSheetTitle;

  /// No description provided for @eventChatParticipantsTitleSemantic.
  ///
  /// In en, this message translates to:
  /// **'{eventTitle}, {count} participants'**
  String eventChatParticipantsTitleSemantic(String eventTitle, int count);

  /// No description provided for @eventChatParticipantsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load participants.'**
  String get eventChatParticipantsLoadError;

  /// No description provided for @eventChatParticipantsYouBadge.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get eventChatParticipantsYouBadge;

  /// No description provided for @eventChatParticipantsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No participants loaded yet.'**
  String get eventChatParticipantsEmpty;

  /// No description provided for @eventChatSystemUserJoined.
  ///
  /// In en, this message translates to:
  /// **'{name} joined the event'**
  String eventChatSystemUserJoined(String name);

  /// No description provided for @eventChatSystemUserLeft.
  ///
  /// In en, this message translates to:
  /// **'{name} left the event'**
  String eventChatSystemUserLeft(String name);

  /// No description provided for @eventChatSystemEventUpdated.
  ///
  /// In en, this message translates to:
  /// **'Event details were updated'**
  String get eventChatSystemEventUpdated;

  /// No description provided for @eventChatSwipeReplySemantic.
  ///
  /// In en, this message translates to:
  /// **'Swipe to reply to this message'**
  String get eventChatSwipeReplySemantic;

  /// No description provided for @eventChatVoiceLevelSemantic.
  ///
  /// In en, this message translates to:
  /// **'Voice level meter'**
  String get eventChatVoiceLevelSemantic;

  /// No description provided for @eventChatMessageOptions.
  ///
  /// In en, this message translates to:
  /// **'Message options'**
  String get eventChatMessageOptions;

  /// No description provided for @eventChatTypingUnknownParticipant.
  ///
  /// In en, this message translates to:
  /// **'Someone'**
  String get eventChatTypingUnknownParticipant;

  /// No description provided for @eventChatCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get eventChatCopy;

  /// No description provided for @eventChatUnpinConfirm.
  ///
  /// In en, this message translates to:
  /// **'Message unpinned'**
  String get eventChatUnpinConfirm;

  /// No description provided for @eventChatMaxPinnedReached.
  ///
  /// In en, this message translates to:
  /// **'Maximum pinned messages reached'**
  String get eventChatMaxPinnedReached;

  /// No description provided for @eventChatMessageNotInView.
  ///
  /// In en, this message translates to:
  /// **'That message isn’t loaded. Scroll up for older messages.'**
  String get eventChatMessageNotInView;

  /// No description provided for @eventChatMuteNotifications.
  ///
  /// In en, this message translates to:
  /// **'Mute notifications'**
  String get eventChatMuteNotifications;

  /// No description provided for @eventChatUnmuteNotifications.
  ///
  /// In en, this message translates to:
  /// **'Unmute notifications'**
  String get eventChatUnmuteNotifications;

  /// No description provided for @eventChatSeenBy.
  ///
  /// In en, this message translates to:
  /// **'Seen by {names}'**
  String eventChatSeenBy(String names);

  /// No description provided for @eventChatSeenByTruncated.
  ///
  /// In en, this message translates to:
  /// **'Seen by {names} +{count}'**
  String eventChatSeenByTruncated(String names, int count);

  /// No description provided for @eventChatTypingOne.
  ///
  /// In en, this message translates to:
  /// **'{name} is typing…'**
  String eventChatTypingOne(String name);

  /// No description provided for @eventChatTypingTwo.
  ///
  /// In en, this message translates to:
  /// **'{first} and {second} are typing…'**
  String eventChatTypingTwo(String first, String second);

  /// No description provided for @eventChatTypingMany.
  ///
  /// In en, this message translates to:
  /// **'{name} and {count} others are typing…'**
  String eventChatTypingMany(String name, int count);

  /// No description provided for @eventChatImageViewerTitle.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get eventChatImageViewerTitle;

  /// No description provided for @eventChatImageViewerPage.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String eventChatImageViewerPage(int current, int total);

  /// No description provided for @eventChatVideoViewerTitle.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get eventChatVideoViewerTitle;

  /// No description provided for @eventChatOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Open file'**
  String get eventChatOpenFile;

  /// No description provided for @eventChatDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t download the file'**
  String get eventChatDownloadFailed;

  /// No description provided for @eventChatPdfOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t open the PDF'**
  String get eventChatPdfOpenFailed;

  /// No description provided for @eventChatShareFile.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get eventChatShareFile;

  /// No description provided for @eventChatLocationMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get eventChatLocationMapTitle;

  /// No description provided for @eventChatCopyCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Copy coordinates'**
  String get eventChatCopyCoordinates;

  /// No description provided for @eventChatDirections.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get eventChatDirections;

  /// No description provided for @eventChatAudioExpandedTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice message'**
  String get eventChatAudioExpandedTitle;

  /// No description provided for @eventChatHoldToRecord.
  ///
  /// In en, this message translates to:
  /// **'Hold to record'**
  String get eventChatHoldToRecord;

  /// No description provided for @eventChatReleaseToSend.
  ///
  /// In en, this message translates to:
  /// **'Release to send'**
  String get eventChatReleaseToSend;

  /// No description provided for @eventChatSlideToCancel.
  ///
  /// In en, this message translates to:
  /// **'Slide left to cancel'**
  String get eventChatSlideToCancel;

  /// No description provided for @eventChatReleaseToCancel.
  ///
  /// In en, this message translates to:
  /// **'Release to cancel'**
  String get eventChatReleaseToCancel;

  /// No description provided for @eventChatRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording…'**
  String get eventChatRecording;

  /// No description provided for @eventChatMicPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone access is required to send voice messages.'**
  String get eventChatMicPermissionDenied;

  /// No description provided for @reportEntryLabelGuided.
  ///
  /// In en, this message translates to:
  /// **'Guided report'**
  String get reportEntryLabelGuided;

  /// No description provided for @reportEntryLabelCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera report'**
  String get reportEntryLabelCamera;

  /// No description provided for @reportEntryHintCamera.
  ///
  /// In en, this message translates to:
  /// **'Starting from a live photo can speed up moderation because the evidence is already attached.'**
  String get reportEntryHintCamera;

  /// No description provided for @homeReportingCapacityCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not check reporting availability right now.'**
  String get homeReportingCapacityCheckFailed;

  /// No description provided for @homeCameraOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to open the camera right now. Please try again in a moment.'**
  String get homeCameraOpenFailed;

  /// No description provided for @mapTabPlaceholderHint.
  ///
  /// In en, this message translates to:
  /// **'Open this tab to load the live map and nearby pollution sites.'**
  String get mapTabPlaceholderHint;

  /// No description provided for @reportCategoryPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose category'**
  String get reportCategoryPickerTitle;

  /// No description provided for @reportCategoryPickerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick the closest match for the issue you are reporting.'**
  String get reportCategoryPickerSubtitle;

  /// No description provided for @reportCategoryPickerBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the closest match'**
  String get reportCategoryPickerBannerTitle;

  /// No description provided for @reportCategoryPickerBannerBody.
  ///
  /// In en, this message translates to:
  /// **'Pick the category moderators should verify first. It does not need to be perfect.'**
  String get reportCategoryPickerBannerBody;

  /// No description provided for @reportCategoryIllegalLandfillTitle.
  ///
  /// In en, this message translates to:
  /// **'Illegal landfill'**
  String get reportCategoryIllegalLandfillTitle;

  /// No description provided for @reportCategoryIllegalLandfillDescription.
  ///
  /// In en, this message translates to:
  /// **'Dumped waste, trash piles, or informal disposal sites.'**
  String get reportCategoryIllegalLandfillDescription;

  /// No description provided for @reportCategoryWaterPollutionTitle.
  ///
  /// In en, this message translates to:
  /// **'Water pollution'**
  String get reportCategoryWaterPollutionTitle;

  /// No description provided for @reportCategoryWaterPollutionDescription.
  ///
  /// In en, this message translates to:
  /// **'Contaminated rivers, lakes, drains, or wastewater discharge.'**
  String get reportCategoryWaterPollutionDescription;

  /// No description provided for @reportCategoryAirPollutionTitle.
  ///
  /// In en, this message translates to:
  /// **'Air pollution'**
  String get reportCategoryAirPollutionTitle;

  /// No description provided for @reportCategoryAirPollutionDescription.
  ///
  /// In en, this message translates to:
  /// **'Smoke, dust, burning waste, or emissions harming air quality.'**
  String get reportCategoryAirPollutionDescription;

  /// No description provided for @reportCategoryIndustrialWasteTitle.
  ///
  /// In en, this message translates to:
  /// **'Industrial waste'**
  String get reportCategoryIndustrialWasteTitle;

  /// No description provided for @reportCategoryIndustrialWasteDescription.
  ///
  /// In en, this message translates to:
  /// **'Construction debris, factory waste, or hazardous materials.'**
  String get reportCategoryIndustrialWasteDescription;

  /// No description provided for @reportCategoryOtherTitle.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reportCategoryOtherTitle;

  /// No description provided for @reportCategoryOtherDescription.
  ///
  /// In en, this message translates to:
  /// **'Use when the issue does not clearly match the categories above.'**
  String get reportCategoryOtherDescription;

  /// No description provided for @unknownRouteTitle.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get unknownRouteTitle;

  /// No description provided for @unknownRouteMessage.
  ///
  /// In en, this message translates to:
  /// **'This link may be out of date or incorrect.'**
  String get unknownRouteMessage;

  /// No description provided for @unknownRouteContinueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue to the app'**
  String get unknownRouteContinueButton;

  /// No description provided for @unknownRouteDebugRoute.
  ///
  /// In en, this message translates to:
  /// **'Debug: route name was “{routeName}”.'**
  String unknownRouteDebugRoute(String routeName);

  /// No description provided for @chatShareLocation.
  ///
  /// In en, this message translates to:
  /// **'Share Location'**
  String get chatShareLocation;

  /// No description provided for @chatSharedLocation.
  ///
  /// In en, this message translates to:
  /// **'Shared location'**
  String get chatSharedLocation;

  /// No description provided for @organizerToolkitTitle.
  ///
  /// In en, this message translates to:
  /// **'Become an organizer'**
  String get organizerToolkitTitle;

  /// No description provided for @organizerToolkitPage1Title.
  ///
  /// In en, this message translates to:
  /// **'Plan ahead'**
  String get organizerToolkitPage1Title;

  /// No description provided for @organizerToolkitPage1Body.
  ///
  /// In en, this message translates to:
  /// **'Assess the site for hazards, prepare safety gear, and brief your team before volunteers arrive.'**
  String get organizerToolkitPage1Body;

  /// No description provided for @organizerToolkitPage2Title.
  ///
  /// In en, this message translates to:
  /// **'Moderation keeps trust'**
  String get organizerToolkitPage2Title;

  /// No description provided for @organizerToolkitPage2Body.
  ///
  /// In en, this message translates to:
  /// **'After you create an event, moderators review it. Once approved, volunteers can see and join.'**
  String get organizerToolkitPage2Body;

  /// No description provided for @organizerToolkitPage3Title.
  ///
  /// In en, this message translates to:
  /// **'Verify attendance'**
  String get organizerToolkitPage3Title;

  /// No description provided for @organizerToolkitPage3Body.
  ///
  /// In en, this message translates to:
  /// **'Use the in-app QR check-in so every volunteer gets credit for showing up.'**
  String get organizerToolkitPage3Body;

  /// No description provided for @organizerToolkitPage4Title.
  ///
  /// In en, this message translates to:
  /// **'Weather and safety'**
  String get organizerToolkitPage4Title;

  /// No description provided for @organizerToolkitPage4Body.
  ///
  /// In en, this message translates to:
  /// **'If conditions turn unsafe, pause or postpone. Tell joined volunteers promptly in the app so nobody travels for a cancelled start.'**
  String get organizerToolkitPage4Body;

  /// No description provided for @organizerToolkitPage5Title.
  ///
  /// In en, this message translates to:
  /// **'Waste and disposal'**
  String get organizerToolkitPage5Title;

  /// No description provided for @organizerToolkitPage5Body.
  ///
  /// In en, this message translates to:
  /// **'Sort recyclables when you can, bag sharp objects safely, and take waste to authorized disposal points. Leave the site cleaner than you found it.'**
  String get organizerToolkitPage5Body;

  /// No description provided for @organizerToolkitPage6Title.
  ///
  /// In en, this message translates to:
  /// **'Include everyone'**
  String get organizerToolkitPage6Title;

  /// No description provided for @organizerToolkitPage6Body.
  ///
  /// In en, this message translates to:
  /// **'Offer clear roles, steady pacing, and patience. A welcoming briefing helps first-time volunteers feel confident and stay safe.'**
  String get organizerToolkitPage6Body;

  /// No description provided for @organizerToolkitPage7Title.
  ///
  /// In en, this message translates to:
  /// **'Privacy in chat'**
  String get organizerToolkitPage7Title;

  /// No description provided for @organizerToolkitPage7Body.
  ///
  /// In en, this message translates to:
  /// **'Keep personal phone numbers and addresses out of public event chat. Use in-app messaging so the whole team stays informed without oversharing.'**
  String get organizerToolkitPage7Body;

  /// No description provided for @organizerToolkitPage8Title.
  ///
  /// In en, this message translates to:
  /// **'Evidence and honest impact'**
  String get organizerToolkitPage8Title;

  /// No description provided for @organizerToolkitPage8Body.
  ///
  /// In en, this message translates to:
  /// **'After photos and bag counts should reflect what really happened. Accurate reporting builds trust with volunteers, moderators, and the wider community.'**
  String get organizerToolkitPage8Body;

  /// No description provided for @organizerToolkitContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get organizerToolkitContinue;

  /// No description provided for @organizerToolkitStartQuiz.
  ///
  /// In en, this message translates to:
  /// **'Take the quiz'**
  String get organizerToolkitStartQuiz;

  /// No description provided for @organizerQuizTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick knowledge check'**
  String get organizerQuizTitle;

  /// No description provided for @organizerQuizLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the quiz. Please try again.'**
  String get organizerQuizLoadFailed;

  /// No description provided for @organizerQuizLoadInvalidResponse.
  ///
  /// In en, this message translates to:
  /// **'The quiz data from the server was incomplete. Please try again.'**
  String get organizerQuizLoadInvalidResponse;

  /// No description provided for @organizerQuizRetryLoad.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get organizerQuizRetryLoad;

  /// No description provided for @organizerQuizSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not submit answers. Try again.'**
  String get organizerQuizSubmitFailed;

  /// No description provided for @organizerQuizOptionSemantic.
  ///
  /// In en, this message translates to:
  /// **'Question {index} of {total}: {optionText}'**
  String organizerQuizOptionSemantic(int index, int total, String optionText);

  /// No description provided for @organizerQuizSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit answers'**
  String get organizerQuizSubmit;

  /// No description provided for @organizerQuizPassedTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re certified!'**
  String get organizerQuizPassedTitle;

  /// No description provided for @organizerQuizPassedBody.
  ///
  /// In en, this message translates to:
  /// **'You can now create cleanup events. Volunteers are waiting.'**
  String get organizerQuizPassedBody;

  /// No description provided for @organizerQuizFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Not quite'**
  String get organizerQuizFailedTitle;

  /// No description provided for @organizerQuizFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Review the tutorial and try again. You got {correct} out of {total}.'**
  String organizerQuizFailedBody(int correct, int total);

  /// No description provided for @organizerQuizRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get organizerQuizRetry;

  /// No description provided for @organizerQuizCreateEvent.
  ///
  /// In en, this message translates to:
  /// **'Create your first event'**
  String get organizerQuizCreateEvent;

  /// No description provided for @organizerCertifiedBadge.
  ///
  /// In en, this message translates to:
  /// **'Certified organizer'**
  String get organizerCertifiedBadge;

  /// No description provided for @errorOrganizerQuizSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'That quiz session expired. Load a new quiz and try again.'**
  String get errorOrganizerQuizSessionExpired;

  /// No description provided for @errorOrganizerQuizSessionInvalid.
  ///
  /// In en, this message translates to:
  /// **'This quiz session is not valid. Load the quiz again.'**
  String get errorOrganizerQuizSessionInvalid;

  /// No description provided for @errorOrganizerQuizAnswersMismatch.
  ///
  /// In en, this message translates to:
  /// **'Answers do not match the quiz you started. Load the quiz again.'**
  String get errorOrganizerQuizAnswersMismatch;

  /// No description provided for @errorOrganizerQuizInvalid.
  ///
  /// In en, this message translates to:
  /// **'One or more answers are not valid for this quiz. Load the quiz again.'**
  String get errorOrganizerQuizInvalid;

  /// No description provided for @errorOrganizerCertificationAlreadyDone.
  ///
  /// In en, this message translates to:
  /// **'You are already a certified organizer. No need to take the quiz again.'**
  String get errorOrganizerCertificationAlreadyDone;

  /// No description provided for @reportsSseReconnectBanner.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting to live updates…'**
  String get reportsSseReconnectBanner;

  /// No description provided for @reportsSseReconnectAction.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get reportsSseReconnectAction;

  /// No description provided for @reportsListMergedToast.
  ///
  /// In en, this message translates to:
  /// **'This report was merged and removed from your list.'**
  String get reportsListMergedToast;

  /// No description provided for @reportDraftResumeTitle.
  ///
  /// In en, this message translates to:
  /// **'Continue your draft?'**
  String get reportDraftResumeTitle;

  /// No description provided for @reportDraftResumeBody.
  ///
  /// In en, this message translates to:
  /// **'{photoCount, plural, =0{No photos saved yet.} one{1 photo saved.} other{{photoCount} photos saved.}}\n\nTitle: \"{titlePreview}\"\n\nLast saved: {savedAt}.'**
  String reportDraftResumeBody(
    int photoCount,
    String titlePreview,
    String savedAt,
  );

  /// No description provided for @reportDraftResumeContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get reportDraftResumeContinue;

  /// No description provided for @reportDraftResumeDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard draft'**
  String get reportDraftResumeDiscard;

  /// No description provided for @reportDraftSavedJustNow.
  ///
  /// In en, this message translates to:
  /// **'Saved just now'**
  String get reportDraftSavedJustNow;

  /// No description provided for @reportDraftSavedMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'Saved {minutes} min ago'**
  String reportDraftSavedMinutesAgo(int minutes);

  /// No description provided for @reportDraftSavedHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'Saved {hours} h ago'**
  String reportDraftSavedHoursAgo(int hours);

  /// No description provided for @reportDraftPhotosLost.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 attached photo was missing and removed from your draft.} other{{count} attached photos were missing and removed from your draft.}}'**
  String reportDraftPhotosLost(int count);

  /// No description provided for @reportDraftDiscardConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard draft?'**
  String get reportDraftDiscardConfirmTitle;

  /// No description provided for @reportDraftDiscardConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Your saved text and photos for this report will be deleted from this device.'**
  String get reportDraftDiscardConfirmBody;

  /// No description provided for @reportDraftCentralFabSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'You have a saved draft'**
  String get reportDraftCentralFabSheetTitle;

  /// No description provided for @reportDraftCentralFabSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{photoCount, plural, =0{No photos} one{1 photo} other{{photoCount} photos}} · {savedAgo}'**
  String reportDraftCentralFabSubtitle(int photoCount, String savedAgo);

  /// No description provided for @reportDraftCentralFabContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue draft'**
  String get reportDraftCentralFabContinue;

  /// No description provided for @reportDraftCentralFabTakeNewPhoto.
  ///
  /// In en, this message translates to:
  /// **'Take new photo'**
  String get reportDraftCentralFabTakeNewPhoto;

  /// No description provided for @reportDraftCentralFabCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get reportDraftCentralFabCancel;

  /// No description provided for @reportDraftIncomingPhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Continue draft or use this photo?'**
  String get reportDraftIncomingPhotoTitle;

  /// No description provided for @reportDraftIncomingPhotoBody.
  ///
  /// In en, this message translates to:
  /// **'You have a saved draft ({photoCount, plural, =0{no photos} one{1 photo} other{{photoCount} photos}}). {savedAgo}'**
  String reportDraftIncomingPhotoBody(int photoCount, String savedAgo);

  /// No description provided for @reportDraftIncomingPhotoContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue draft'**
  String get reportDraftIncomingPhotoContinue;

  /// No description provided for @reportDraftIncomingPhotoReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace draft'**
  String get reportDraftIncomingPhotoReplace;

  /// No description provided for @reportDraftIncomingPhotoAdd.
  ///
  /// In en, this message translates to:
  /// **'Add to draft'**
  String get reportDraftIncomingPhotoAdd;

  /// No description provided for @savedMapAreasTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved map areas'**
  String get savedMapAreasTitle;

  /// No description provided for @savedMapAreasPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Offline regions and background downloads will appear here.'**
  String get savedMapAreasPlaceholder;

  /// No description provided for @mapWhatsNewTitle.
  ///
  /// In en, this message translates to:
  /// **'Map updates'**
  String get mapWhatsNewTitle;

  /// No description provided for @mapWhatsNewBody.
  ///
  /// In en, this message translates to:
  /// **'Smarter prefetch, stable clusters, and safer map pipelines.'**
  String get mapWhatsNewBody;
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
