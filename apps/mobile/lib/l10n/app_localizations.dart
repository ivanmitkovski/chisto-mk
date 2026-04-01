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

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

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

  /// No description provided for @profileDeleteAccountFinalDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete?'**
  String get profileDeleteAccountFinalDialogTitle;

  /// No description provided for @profileDeleteAccountFinalDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Your account and all associated data will be permanently deleted.'**
  String get profileDeleteAccountFinalDialogBody;

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
  /// **'Report was submitted. Tap Retry to upload your photos, or Skip to continue.'**
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

  /// No description provided for @feedLoadMoreFailedSnack.
  ///
  /// In en, this message translates to:
  /// **'Could not load more posts. Tap retry.'**
  String get feedLoadMoreFailedSnack;

  /// No description provided for @feedScrollToTopSemantic.
  ///
  /// In en, this message translates to:
  /// **'Scroll feed to top'**
  String get feedScrollToTopSemantic;

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

  /// No description provided for @createEventLocalInfoSnack.
  ///
  /// In en, this message translates to:
  /// **'Creation keeps the event local for now, but the organizer flow is ready right away.'**
  String get createEventLocalInfoSnack;

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

  /// No description provided for @takeActionSharedToProfile.
  ///
  /// In en, this message translates to:
  /// **'Shared to your profile'**
  String get takeActionSharedToProfile;

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

  /// No description provided for @searchModalCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get searchModalCancel;

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

  /// No description provided for @appSmartImageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Image unavailable'**
  String get appSmartImageUnavailable;

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
