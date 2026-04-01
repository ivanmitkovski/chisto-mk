// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

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
      'Add at least one photo to continue.';

  @override
  String get reportFlowLocationOutsideMacedoniaHelper =>
      'This location is outside Macedonia. Drag the pin into the country, then tap Confirm location.';

  @override
  String get reportLocationAdvanceBlockedBanner =>
      'Place the pin in Macedonia and tap Confirm location.';

  @override
  String get reviewTapToEdit => 'Tap to edit';

  @override
  String semanticsCurrentReportStep(String label) {
    return 'Current step: $label';
  }

  @override
  String get errorBannerDraftSavedHint =>
      'Your draft is saved, you can try again when ready.';

  @override
  String get reportSubmittedTitle => 'Report submitted';

  @override
  String reportSubmittedSavedAs(String number) {
    return 'Saved as report $number';
  }

  @override
  String reportSubmittedBodyWithAddress(String category, String address) {
    return '$category near $address is now in the review queue.';
  }

  @override
  String reportSubmittedBodyNoAddress(String category) {
    return '$category is now in the review queue.';
  }

  @override
  String get reportSubmittedNewSiteBadge => 'New site added to the map';

  @override
  String reportSubmittedPointsEarned(int points) {
    return '+$points pts earned';
  }

  @override
  String reportSubmittedPointsPending(int max) {
    return 'Earn up to $max pts when approved';
  }

  @override
  String get reportSubmittedViewThisReport => 'View this report';

  @override
  String get reportSubmittedViewAllReports => 'View all reports';

  @override
  String get reportSubmittedViewInMyReports => 'View in My reports';

  @override
  String get reportSubmittedReportAnother => 'Report another';

  @override
  String get reportSubmittedSemanticsSuccess => 'Report submitted successfully';

  @override
  String get profileAvatarSourceTitle => 'Profile photo';

  @override
  String get profileAvatarSourceSubtitle =>
      'Take a new photo or choose from your library. You can crop it in the next step.';

  @override
  String get profileAvatarSourceCamera => 'Camera';

  @override
  String get profileAvatarSourceCameraHint =>
      'Front camera works best with good light.';

  @override
  String get profileAvatarSourcePhotos => 'Photos';

  @override
  String get profileAvatarSourcePhotosHint =>
      'Pick any image you already have.';

  @override
  String get profileAvatarSourceRemove => 'Remove current photo';

  @override
  String get profileAvatarSourceRemoveHint =>
      'Show your initials instead of a picture';

  @override
  String get profileAvatarRemoveConfirmTitle => 'Remove profile photo?';

  @override
  String get profileAvatarRemoveConfirmMessage =>
      'Your picture will be deleted and your initials will be shown instead.';

  @override
  String get profileAvatarRemoveConfirmCancel => 'Cancel';

  @override
  String get profileAvatarRemoveConfirmRemove => 'Remove';

  @override
  String get profileAvatarRemovedMessage => 'Profile photo removed';

  @override
  String get profileAvatarRemoveFailed =>
      'Could not remove your photo. Please try again.';

  @override
  String get profileAvatarSourceRecommended => 'Recommended';

  @override
  String get profileAvatarCropMoveAndScale => 'Move and scale';

  @override
  String get profileAvatarCropHint => 'Pinch to zoom, drag to position';

  @override
  String get profileAvatarCropLoading => 'Loading photo…';

  @override
  String get profileAvatarCropCancel => 'Cancel';

  @override
  String get profileAvatarCropDone => 'Done';

  @override
  String get profileAvatarTapToChange => 'Tap to change photo';

  @override
  String get profileAvatarUploadingCaption => 'Uploading…';

  @override
  String get profileAvatarCropEditorSemantic =>
      'Crop your profile photo. Pinch to zoom and drag to position the image.';

  @override
  String get profileAvatarCropFailed =>
      'Could not crop the photo. Please try again.';

  @override
  String get profileAvatarCameraUnavailable =>
      'Unable to open the camera right now. Please try again in a moment.';

  @override
  String get profileAvatarReadPhotoFailed =>
      'Could not read the photo. Please try again.';

  @override
  String get profileAvatarProcessPhotoFailed =>
      'Could not process the photo. Please try again.';

  @override
  String get profileAvatarPeekSemantic => 'Profile photo';

  @override
  String get errorBannerDismiss => 'Dismiss';

  @override
  String get errorBannerTryAgain => 'Try again';

  @override
  String get authSemanticGoBack => 'Go back';

  @override
  String get authLoading => 'Loading';

  @override
  String get authSignInTitle => 'Sign in';

  @override
  String get authSignInSubtitle =>
      'Welcome back. Enter your details to continue.';

  @override
  String get authFieldPhone => 'Phone number';

  @override
  String get authFieldPhoneHint => '70 123 456';

  @override
  String get authFieldPassword => 'Password';

  @override
  String get authFieldPasswordHint => 'Enter your password';

  @override
  String get authRememberMe => 'Remember me';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authSignInCta => 'Sign in';

  @override
  String get authValidationCheckPhonePassword =>
      'Please check your phone number and password.';

  @override
  String get authSignUpPrompt => 'Don\'t have an account? ';

  @override
  String get authSignUpLink => 'Sign up';

  @override
  String get authSignUpTitle => 'Sign up';

  @override
  String get authSignUpSubtitle => 'Welcome! Please enter your details';

  @override
  String get authFieldFullName => 'Full name';

  @override
  String get authFieldFullNameHint => 'John Doe';

  @override
  String get authFieldEmail => 'Email';

  @override
  String get authFieldEmailHint => 'john@chisto.mk';

  @override
  String get authFieldPhoneNumber => 'Phone number';

  @override
  String get authPasswordRequirementsHint =>
      'At least 8 characters, with letters and numbers';

  @override
  String get authTermsPrefix => 'By signing up you agree to our ';

  @override
  String get authTermsLink => 'terms and conditions';

  @override
  String get authValidationCheckFields =>
      'Please check the highlighted fields above.';

  @override
  String get authSignUpCta => 'Sign up';

  @override
  String get authSignInPrompt => 'Already have an account? ';

  @override
  String get authSignInLink => 'Sign in';

  @override
  String authValidationFieldRequired(String fieldName) {
    return '$fieldName is required';
  }

  @override
  String get authValidationPhoneRequired => 'Phone number is required';

  @override
  String get authValidationPhoneDigits => 'Enter an 8-digit phone number';

  @override
  String get authValidationEmailRequired => 'Email is required';

  @override
  String get authValidationEmailInvalid => 'Enter a valid email';

  @override
  String get authValidationPasswordRequired => 'Password is required';

  @override
  String get authValidationPasswordMinLength =>
      'Password must be at least 8 characters';

  @override
  String get authValidationPasswordNeedNumber =>
      'Password must contain at least one number';

  @override
  String get authValidationPasswordNeedLetter =>
      'Password must contain at least one letter';

  @override
  String get authValidationConfirmPasswordRequired =>
      'Please confirm your password';

  @override
  String get authValidationConfirmPasswordMismatch => 'Passwords do not match';

  @override
  String get authErrorInvalidCredentials => 'Wrong phone number or password.';

  @override
  String get authErrorAccountSuspended => 'This account is not active.';

  @override
  String get authErrorPhoneNotRegistered =>
      'No account found for this phone number.';

  @override
  String get authErrorEmailRegistered => 'This email is already registered.';

  @override
  String get authErrorPhoneRegistered =>
      'This phone number is already registered.';

  @override
  String get authErrorOtpNotFound => 'No code was sent. Request a new code.';

  @override
  String get authErrorOtpExpired =>
      'This code has expired. Request a new code.';

  @override
  String get authErrorOtpInvalid => 'Invalid code. Please try again.';

  @override
  String get authErrorOtpMaxAttempts =>
      'Too many wrong codes. Request a new code.';

  @override
  String get authErrorCurrentPasswordInvalid =>
      'Current password is incorrect.';

  @override
  String get authErrorTooManyAttempts =>
      'Too many failed attempts. Try again later.';

  @override
  String get authErrorRateLimited =>
      'Too many requests. Please wait a moment and try again.';

  @override
  String get authErrorUserNotFound =>
      'We could not find an account for this number. Please check and try again.';

  @override
  String get authOtpTitle => 'Enter code';

  @override
  String authOtpSubtitle(String phone) {
    return 'We just sent a 4-digit code to $phone';
  }

  @override
  String get authOtpContinue => 'Continue';

  @override
  String get authOtpResendPrefix => 'Didn\'t receive code? ';

  @override
  String get authOtpResendAction => 'Send again';

  @override
  String authOtpResendCountdown(int seconds) {
    return 'Resend code in ${seconds}s';
  }

  @override
  String authOtpResentMessage(String phone) {
    return 'We\'ve sent a new code to $phone.';
  }

  @override
  String get authForgotPasswordTitle => 'Reset password';

  @override
  String get authForgotPasswordSubtitle =>
      'Enter your phone number and we\'ll send you a code to reset your password';

  @override
  String get authForgotPasswordSendCode => 'Send reset code';

  @override
  String get authForgotPasswordRequestSemantic => 'Send reset code';

  @override
  String get authForgotPasswordOtpTitle => 'Enter code';

  @override
  String authForgotPasswordOtpSubtitle(String phone) {
    return 'We sent a 4-digit code to $phone';
  }

  @override
  String get authNewPasswordTitle => 'Create new password';

  @override
  String get authNewPasswordSubtitle => 'Enter a new password for your account';

  @override
  String get authFieldNewPassword => 'New password';

  @override
  String get authFieldNewPasswordHint => 'At least 8 characters';

  @override
  String get authFieldConfirmPassword => 'Confirm password';

  @override
  String get authFieldConfirmPasswordHint => 'Re-enter your password';

  @override
  String get authResetPasswordCta => 'Reset password';

  @override
  String get authPasswordResetSuccessTitle => 'Password reset';

  @override
  String get authPasswordResetSuccessBody =>
      'Your password has been reset successfully. You can now sign in with your new password.';

  @override
  String get authBackToSignIn => 'Back to sign in';

  @override
  String get authOnboardingWelcomeTo => 'Welcome to';

  @override
  String get authOnboardingBrandName => 'Chisto.mk';

  @override
  String get authOnboardingWelcomeDescription => 'See it. Report it. Clean it.';

  @override
  String get authOnboardingWelcomeSupporting =>
      'A cleaner city starts with one tap.';

  @override
  String get authOnboardingSlide2Title => 'Report in seconds';

  @override
  String get authOnboardingSlide2Description =>
      'Share a report with location in a few taps.';

  @override
  String get authOnboardingSlide2Supporting =>
      'Fast flow, clear status updates.';

  @override
  String get authOnboardingSlide3Title => 'Join cleanup events';

  @override
  String get authOnboardingSlide3Description =>
      'Track progress and community impact nearby.';

  @override
  String get authOnboardingSlide3Supporting =>
      'Together we keep neighborhoods green.';

  @override
  String get authOnboardingContinue => 'Continue';

  @override
  String get authOnboardingGetStarted => 'Get started';

  @override
  String get authLocationTitle => 'Choose your location';

  @override
  String get authLocationSubtitle =>
      'We use your location to show cleanups and reports near you.';

  @override
  String get authLocationMapPlaceholder =>
      'Use current location to update this area';

  @override
  String get authLocationDetecting => 'Detecting location…';

  @override
  String get authLocationContinue => 'Continue';

  @override
  String get authLocationUseCurrent => 'Use current location';

  @override
  String get authLocationUseDifferent => 'Use a different location';

  @override
  String get authLocationPrivacyNote =>
      'We only use your location to show nearby cleanups. We don\'t track you in the background.';

  @override
  String get authLocationServicesDisabled =>
      'Location services are disabled. Please enable them in Settings.';

  @override
  String get authLocationPermissionDenied =>
      'Location permission denied. You can enable it in Settings to use this feature.';

  @override
  String get authLocationPermissionForever =>
      'Location permission is permanently denied. Opening Settings…';

  @override
  String get authLocationMacedoniaOnly =>
      'Currently we only support locations in Macedonia.';

  @override
  String get authLocationResolveFailed =>
      'Could not resolve your location. Please try again.';

  @override
  String get authOtpCodeSemantic => 'Verification code';

  @override
  String authOtpDigitSemantic(int index, int total) {
    return 'Digit $index of $total';
  }

  @override
  String get profileWeeklyRankingsTitle => 'Weekly rankings';

  @override
  String get profileWeeklyRankingsSubtitle =>
      'Reports, eco-actions & more, this week.';

  @override
  String get profileWeeklyRankingsTopSupporters =>
      'This week\'s top supporters';

  @override
  String get profileWeeklyRankingsEmptyTitle => 'No rankings yet';

  @override
  String get profileWeeklyRankingsEmptySubtitle =>
      'Earn points this week from any credited activity to show up here.';

  @override
  String get profileWeeklyRankingsRetry => 'Retry';

  @override
  String profileWeeklyRankingsYouRank(int rank) {
    return 'You are No. $rank this week';
  }

  @override
  String profileWeeklyRankingsPtsThisWeek(int points) {
    return '$points pts this week';
  }

  @override
  String get profileWeeklyRankingsYouBadge => 'You';

  @override
  String get profileWeeklyRankingsScrollToYouHint =>
      'Scroll to your position in the list';

  @override
  String get profileWeeklyRankingsLoadingSemantic => 'Loading weekly rankings';

  @override
  String profileWeeklyRankingsRowSemantic(int rank, String name, int points) {
    return 'Rank $rank, $name, $points points';
  }

  @override
  String profileLevelLine(int level) {
    return 'Level $level';
  }

  @override
  String get profileTierLegend => 'Chisto Legend';

  @override
  String profilePtsToNextLevel(int points) {
    return '$points pts to next level';
  }

  @override
  String profileLevelXpSegment(int current, int total) {
    return '$current / $total XP';
  }

  @override
  String profileLifetimeXpOnBar(int xp) {
    return '$xp lifetime XP';
  }

  @override
  String profilePointsBalanceShort(int balance) {
    return 'Balance $balance';
  }

  @override
  String get profileMyWeeklyRankTitle => 'My weekly rank';

  @override
  String profileMyWeeklyRankDetailRanked(int rank, int points) {
    return '#$rank, $points pts';
  }

  @override
  String profileMyWeeklyRankDetailPointsOnly(int points) {
    return '$points pts';
  }

  @override
  String get profileMyWeeklyRankNoPoints => 'No points this week yet';

  @override
  String get profileViewRankings => 'View rankings';

  @override
  String get profilePointsHistoryTitle => 'Points & levels';

  @override
  String get profilePointsHistorySubtitle =>
      'XP you earned and every level you unlocked.';

  @override
  String get profilePointsHistoryOpenSemantic =>
      'Open points and level history';

  @override
  String get profilePointsHistoryLoadingSemantic => 'Loading points and levels';

  @override
  String get profileLoadingSemantic => 'Loading profile';

  @override
  String get profilePointsHistoryMilestonesSection => 'Level ups';

  @override
  String get profilePointsHistoryActivitySection => 'Activity';

  @override
  String get profilePointsHistoryDayToday => 'Today';

  @override
  String get profilePointsHistoryDayYesterday => 'Yesterday';

  @override
  String get profilePointsHistoryEmpty =>
      'No points yet. When a report you submitted is approved as the first on a site, you earn XP here.';

  @override
  String get profilePointsHistoryLevelUpBadge => 'LEVEL UP';

  @override
  String get profilePointsHistoryLoadMore => 'Loading…';

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
      'First approved report on a site';

  @override
  String get profilePointsReasonEcoApproved => 'Eco action approved';

  @override
  String get profilePointsReasonEcoRealized => 'Eco action completed';

  @override
  String get profilePointsReasonOther => 'Points update';

  @override
  String get profileReportCreditsTitle => 'Report credits';

  @override
  String get profileAccountDetailsSection => 'Account details';

  @override
  String get profileGeneralInfoTile => 'General info';

  @override
  String get profileLanguageTile => 'Language';

  @override
  String get profileLanguageScreenTitle => 'App language';

  @override
  String get profileLanguageSubtitleDevice => 'Device settings';

  @override
  String get profileLanguageOptionSystem => 'Use device language';

  @override
  String get profileLanguageNameEn => 'English';

  @override
  String get profileLanguageNameMk => 'Македонски';

  @override
  String get profileLanguageNameSq => 'Shqip';

  @override
  String get profilePasswordTile => 'Password';

  @override
  String get profileSupportSection => 'Support';

  @override
  String get profileHelpCenterTile => 'Help center';

  @override
  String get profileAccountSection => 'Account';

  @override
  String get profileSignOutTile => 'Sign out';

  @override
  String get profileDeleteAccountTile => 'Delete account';

  @override
  String get profileEmailLabel => 'Email';

  @override
  String get profileEmailReadOnlyHint =>
      'Read-only. Contact support to change your email.';

  @override
  String get profileNoConnectionSnack => 'No connection';

  @override
  String get profileRefreshFailedSnack =>
      'Couldn\'t refresh your profile. Try again in a moment.';

  @override
  String get profilePasswordScreenTitle => 'Change password';

  @override
  String get profilePasswordScreenSubtitle =>
      'Choose a strong, unique password.';

  @override
  String get profilePasswordCurrentLabel => 'Current password';

  @override
  String get profilePasswordNewLabel => 'New password';

  @override
  String get profilePasswordConfirmLabel => 'Confirm new password';

  @override
  String get profilePasswordNewHelper =>
      'At least 8 characters, with a number.';

  @override
  String get profilePasswordConfirmMismatchHelper =>
      'Make sure this matches the new password above.';

  @override
  String get profilePasswordSecurityHint =>
      'For security, avoid reusing passwords from other apps.';

  @override
  String get profilePasswordSubmit => 'Update password';

  @override
  String get profilePasswordSubmitting => 'Updating…';

  @override
  String get profilePasswordSuccess => 'Password updated';

  @override
  String get profilePasswordEnterCurrentWarning =>
      'Enter your current password.';

  @override
  String get profilePasswordMismatchError => 'Passwords do not match.';

  @override
  String get profilePasswordSessionExpired =>
      'Session expired. Please sign in again.';

  @override
  String get profilePasswordCurrentSemantic => 'Current password';

  @override
  String get profilePasswordNewSemantic => 'New password';

  @override
  String get profilePasswordConfirmSemantic => 'Confirm new password';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonTryAgain => 'Try again';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonSave => 'Save';

  @override
  String get commonSkip => 'Skip';

  @override
  String get commonBack => 'Back';

  @override
  String get commonClose => 'Close';

  @override
  String get commonGotIt => 'Got it';

  @override
  String get commonKeepEditing => 'Keep editing';

  @override
  String get commonDiscard => 'Discard';

  @override
  String get profileSignOutDialogTitle => 'Sign out?';

  @override
  String get profileSignOutDialogBody =>
      'You can sign back in anytime with your account.';

  @override
  String get profileDeleteAccountDialogTitle => 'Delete account?';

  @override
  String get profileDeleteAccountDialogBody =>
      'All your data will be permanently removed. This action cannot be undone.';

  @override
  String get profileDeleteAccountFinalDialogTitle => 'Permanently delete?';

  @override
  String get profileDeleteAccountFinalDialogBody =>
      'Your account and all associated data will be permanently deleted.';

  @override
  String get profileDeleteAccountTypeConfirmTitle => 'Confirm by typing';

  @override
  String get profileDeleteAccountTypeConfirmBody =>
      'Type the word below exactly as shown. This helps prevent accidental deletion.';

  @override
  String get profileDeleteAccountConfirmPhrase => 'DELETE';

  @override
  String get profileDeleteAccountTypeFieldPlaceholder => 'Type here';

  @override
  String get profileDeleteAccountTypeMismatchSnack =>
      'Type the confirmation word exactly as shown.';

  @override
  String get profileHelpCenterOpenFailedSnack => 'Could not open help center';

  @override
  String get profileGeneralLoadFailedSnack => 'Could not load profile';

  @override
  String get profileGeneralNameRequiredSnack => 'Name is required';

  @override
  String get profileGeneralNameTooLongSnack => 'Name is too long';

  @override
  String get profileGeneralUpdatedSnack => 'Profile updated';

  @override
  String get profileGeneralPictureUpdatedSnack => 'Profile picture updated';

  @override
  String get profileGeneralInfoSubtitle => 'Edit your profile details';

  @override
  String get profileGeneralNameLabel => 'Name';

  @override
  String get profileGeneralNameHint => 'Your name';

  @override
  String get profileGeneralMobileLabel => 'Mobile phone';

  @override
  String get profileGeneralPhonePlaceholder => '70 123 456';

  @override
  String get profileGeneralLimitsNotice =>
      'Name changes are limited. Phone number changes require verification.';

  @override
  String get profileGeneralUpdateButton => 'Update info';

  @override
  String get profileGeneralSaving => 'Saving…';

  @override
  String get profileGeneralAvatarSemanticUpdating => 'Updating profile photo';

  @override
  String get profileGeneralAvatarSemanticChange =>
      'Profile photo. Double tap to change';

  @override
  String get profileGeneralEmptyValue => '—';

  @override
  String get profileGeneralDefaultDisplayName => 'User';

  @override
  String get reportListFabLabel => 'Report pollution';

  @override
  String get reportListSearchSemantic => 'Search reports';

  @override
  String get reportAvailabilityCheckFailedSnack =>
      'Could not check reporting availability right now.';

  @override
  String get reportFinishStepsSnack =>
      'Please finish the missing steps before submitting.';

  @override
  String get reportSubmittedPartialUploadSnack =>
      'Report submitted. Photos could not be uploaded.';

  @override
  String get reportPhotoUploadFailedTitle => 'Photo upload failed';

  @override
  String get reportPhotoUploadFailedBody =>
      'Report was submitted. Tap Retry to upload your photos, or Skip to continue.';

  @override
  String get reportReviewEvidenceTitle => 'Evidence';

  @override
  String reportReviewPhotoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '$count photo',
    );
    return '$_temp0';
  }

  @override
  String get reportReviewAddPhoto => 'Add a photo';

  @override
  String get reportReviewCategoryTitle => 'Category';

  @override
  String get reportReviewChooseCategory => 'Choose category';

  @override
  String get reportReviewTitleLabel => 'Title';

  @override
  String get reportReviewAddTitle => 'Add title';

  @override
  String get reportReviewSeverityTitle => 'Severity';

  @override
  String get reportReviewLocationTitle => 'Location';

  @override
  String get reportReviewPinnedShort => 'Pinned';

  @override
  String get reportReviewPinMacedonia => 'Pin in Macedonia';

  @override
  String get reportReviewExtraContextTitle => 'Extra context';

  @override
  String get reportReviewCleanupEffortTitle => 'Cleanup effort';

  @override
  String get reportSelectCategorySemantic => 'Select report category';

  @override
  String get reportBackSemantic => 'Back';

  @override
  String get reportPreviousStepSemantic => 'Previous step';

  @override
  String get reportCleanupEffortChipHint =>
      'Double-tap to set estimated cleanup effort.';

  @override
  String get reportCleanupEffortOneToTwo => '1–2 people';

  @override
  String get reportCleanupEffortThreeToFive => '3–5 people';

  @override
  String get reportCleanupEffortSixToTen => '6–10 people';

  @override
  String get reportCleanupEffortTenPlus => '10+ people';

  @override
  String get reportCleanupEffortNotSure => 'Not sure';

  @override
  String get reportCooldownTitle => 'Reporting cooldown';

  @override
  String reportCooldownBody(String retry, String hint) {
    return 'You have used all 10 report credits and the emergency allowance.\n\nEmergency unlock retries in $retry.\n\n$hint';
  }

  @override
  String get reportCooldownModalIntro =>
      'You have used all 10 report credits and the emergency allowance.';

  @override
  String get reportCooldownModalRetryLead => 'Emergency unlock retries in';

  @override
  String get reportCooldownDurationListSeparator => ', ';

  @override
  String reportCooldownDurationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
    );
    return '$_temp0';
  }

  @override
  String reportCooldownDurationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '$count hour',
    );
    return '$_temp0';
  }

  @override
  String reportCooldownDurationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '$count minute',
    );
    return '$_temp0';
  }

  @override
  String reportCooldownDurationSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seconds',
      one: '$count second',
    );
    return '$_temp0';
  }

  @override
  String get reportCooldownRetrySoon => 'soon';

  @override
  String reportCooldownRetrySeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String reportCooldownRetryMinutes(int minutes) {
    return '${minutes}m';
  }

  @override
  String reportCooldownRetryHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String get reportCapacityUnlockHint =>
      'Join events or eco actions to get more reports (up to 10).';

  @override
  String reportCapacityPillHealthy(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count credits',
      one: '$count credit',
    );
    return '$_temp0';
  }

  @override
  String get reportCapacityBannerHealthyTitle => 'All set';

  @override
  String reportCapacityBannerHealthyBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count credits available',
      one: '$count credit available',
    );
    return '$_temp0';
  }

  @override
  String get reportCapacityReviewHealthy => 'Uses 1 credit.';

  @override
  String reportCapacityPillLow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reports left',
      one: '$count report left',
    );
    return '$_temp0';
  }

  @override
  String get reportCapacityBannerLowTitle => 'Almost out';

  @override
  String reportCapacityBannerLowBody(String hint) {
    return 'Low balance. $hint';
  }

  @override
  String reportCapacityReviewLow(String hint) {
    return 'Uses 1 credit. $hint';
  }

  @override
  String get reportCapacityPillEmergency => 'Emergency report';

  @override
  String get reportCapacityBannerEmergencyTitle => 'Emergency report';

  @override
  String reportCapacityBannerEmergencyBody(String hint) {
    return 'You have one left. $hint';
  }

  @override
  String reportCapacityReviewEmergency(String hint) {
    return 'Uses your emergency report. $hint';
  }

  @override
  String get reportCapacityPillCooldown => 'Cooldown active';

  @override
  String get reportCapacityBannerCooldownTitle => 'Cooldown';

  @override
  String reportCapacityCooldownRetryOnDate(String date) {
    return 'Next emergency: $date.';
  }

  @override
  String reportCapacityCooldownTryAgainInAbout(String duration) {
    return 'Try again in ~$duration.';
  }

  @override
  String get reportCapacityCooldownStillWaiting =>
      'Emergency report cooling down.';

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
    return '(${seconds}s remaining)';
  }

  @override
  String get feedRetryLoadingMore => 'Retry loading more';

  @override
  String get feedShowAllSites => 'Show all sites';

  @override
  String get feedPullToRefreshSemantic => 'Pull to refresh';

  @override
  String get feedLoadMoreFailedSnack => 'Could not load more posts. Tap retry.';

  @override
  String get feedScrollToTopSemantic => 'Scroll feed to top';

  @override
  String get mapResetFiltersSemantic => 'Reset filters';

  @override
  String get mapOpenMapsFailed => 'Could not open Maps';

  @override
  String get locationRetryAddressSemantic => 'Retry address';

  @override
  String get photoReviewDiscardTitle => 'Discard this photo?';

  @override
  String get photoReviewDiscardBody =>
      'You can retake or choose another from your library.';

  @override
  String get reportPhotoReviewSheetTitle => 'Review evidence';

  @override
  String get reportPhotoReviewSheetSubtitle =>
      'Keep the clearest frame before adding it to the report.';

  @override
  String get reportPhotoReviewSemantic =>
      'Review and confirm photo before adding to report';

  @override
  String get reportPhotoReviewCloseSemantic => 'Close without adding photo';

  @override
  String get reportPhotoReviewRetake => 'Retake';

  @override
  String get reportPhotoReviewUsePhoto => 'Use this photo';

  @override
  String get reportPhotoReviewRetakeSemantic => 'Retake photo';

  @override
  String get reportPhotoReviewUseSemantic => 'Use this photo';

  @override
  String get reportPhotoReviewPreviewSemantic => 'Photo preview';

  @override
  String get reportPhotoGridAddShort => 'Add';

  @override
  String get reportPhotoGridAdd => 'Add a photo';

  @override
  String get reportPhotoGridSourceHint => 'Camera or library';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsMarkAllRead => 'Mark all read';

  @override
  String get notificationsShowAll => 'Show all notifications';

  @override
  String get notificationsPreferencesTooltip => 'Notification preferences';

  @override
  String get notificationsScrollToTopSemantic => 'Scroll notifications to top';

  @override
  String get notificationsRetryLoadingMore => 'Retry loading more';

  @override
  String get notificationsMarkAllReadFailed =>
      'Could not mark all as read. Please try again.';

  @override
  String get notificationsAllMarkedReadSuccess =>
      'All notifications marked as read';

  @override
  String get notificationsSiteUnavailable =>
      'This site is no longer available.';

  @override
  String get notificationsReadStateUpdateFailed =>
      'Could not update read state. Please try again.';

  @override
  String get notificationsMarkedUnreadLocal => 'Marked as unread (local).';

  @override
  String get notificationsArchivedFromView =>
      'Notification archived from this view';

  @override
  String get notificationsPrefsLoadFailed =>
      'Could not load notification preferences.';

  @override
  String get notificationsPreferenceUpdateFailed =>
      'Could not update preference. Please try again.';

  @override
  String get notificationsPrefsSheetTitle => 'Notification preferences';

  @override
  String get notificationsPrefsSheetSubtitle =>
      'Mute notification types you do not want to receive.';

  @override
  String get notificationsPrefMuted => 'Muted';

  @override
  String get notificationsPrefEnabled => 'Enabled';

  @override
  String get notificationsTypeSiteUpdates => 'Site updates';

  @override
  String get notificationsTypeReportStatus => 'Report status';

  @override
  String get notificationsTypeUpvotes => 'Upvotes';

  @override
  String get notificationsTypeComments => 'Comments';

  @override
  String get notificationsTypeNearbyReports => 'Nearby reports';

  @override
  String get notificationsTypeCleanupEvents => 'Cleanup events';

  @override
  String get notificationsTypeSystem => 'System';

  @override
  String get notificationsSwipeMarkUnread => 'Mark unread';

  @override
  String get notificationsSwipeMarkRead => 'Mark read';

  @override
  String get notificationsSwipeArchive => 'Archive';

  @override
  String get notificationsDebugPreviewTriggered =>
      'Local notification preview triggered';

  @override
  String get notificationsAllCaughtUp => 'All caught up';

  @override
  String notificationsUnreadUpdatesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unread updates',
      one: '1 unread update',
    );
    return '$_temp0';
  }

  @override
  String get notificationsUnreadBannerOne =>
      '1 unread notification needs your attention';

  @override
  String notificationsUnreadBannerMany(int count) {
    return '$count unread notifications need your attention';
  }

  @override
  String get notificationsSwipeHint =>
      'Swipe right to mark read or unread · left to archive';

  @override
  String get notificationsEmptyUnreadTitle => 'No unread notifications';

  @override
  String get notificationsEmptyAllTitle => 'No notifications yet';

  @override
  String get notificationsEmptyUnreadBody =>
      'You are all caught up. New updates will appear here.';

  @override
  String get notificationsEmptyAllBody =>
      'When people react to sites and actions, you will see updates here.';

  @override
  String get notificationsErrorLoadTitle => 'Could not load notifications';

  @override
  String get notificationsErrorLoadFallback =>
      'Please check your connection and try again.';

  @override
  String get notificationsErrorNetwork =>
      'Network issue while loading notifications.';

  @override
  String get notificationsErrorGeneric =>
      'Something went wrong while loading notifications.';

  @override
  String get notificationsFilterAll => 'All';

  @override
  String get notificationsFilterUnread => 'Unread';

  @override
  String get eventsEventNotFoundTitle => 'Event not found';

  @override
  String get eventsEventNotFoundBody => 'This event is no longer available.';

  @override
  String get eventsManualCheckInAdd => 'Add';

  @override
  String get eventsManualCheckInTitle => 'Manual check-in';

  @override
  String get eventsCheckInTitle => 'Check-in';

  @override
  String get eventsOrganizerMockAllCheckedIn =>
      'All mock attendees are already checked in.';

  @override
  String get eventsOrganizerAttendeeNamePlaceholder => 'Attendee name';

  @override
  String get eventsOrganizerEnterNameFirst => 'Enter attendee name first.';

  @override
  String eventsOrganizerNameAlreadyCheckedIn(String name) {
    return '$name is already checked in.';
  }

  @override
  String eventsOrganizerNameAddedByOrganizer(String name) {
    return '$name added by organizer.';
  }

  @override
  String eventsOrganizerCouldNotRemoveName(String name) {
    return 'Could not remove $name.';
  }

  @override
  String eventsOrganizerNameRemovedFromCheckIn(String name) {
    return '$name removed from check-in.';
  }

  @override
  String get eventsOrganizerUnableCompleteEvent =>
      'Unable to complete the event.';

  @override
  String get eventsOrganizerEndedTitle => 'Event ended';

  @override
  String get eventsOrganizerThanksOrganizing => 'Thanks for organizing!';

  @override
  String get eventsOrganizerEndSummaryOneAttendee => '1 attendee checked in.';

  @override
  String eventsOrganizerEndSummaryManyAttendees(int count) {
    return '$count attendees checked in.';
  }

  @override
  String get eventsOrganizerUploadAfterPhotosHint =>
      'Upload after photos from the event detail.';

  @override
  String get eventsOrganizerCheckInPausedSnack => 'Check-in paused.';

  @override
  String get eventsOrganizerCheckInResumedSnack => 'Check-in resumed.';

  @override
  String get eventsOrganizerUnableCancelEvent => 'Unable to cancel the event.';

  @override
  String get eventsOrganizerEventCancelledSnack => 'Event cancelled.';

  @override
  String eventsOrganizerFeedbackCheckedIn(String name) {
    return '$name checked in';
  }

  @override
  String get eventsOrganizerFeedbackInvalidQr => 'Invalid QR code.';

  @override
  String get eventsOrganizerFeedbackWrongEvent => 'Wrong event QR.';

  @override
  String get eventsOrganizerFeedbackPaused => 'Check-in is currently paused.';

  @override
  String get eventsOrganizerFeedbackQrExpired =>
      'QR expired. Generate a new one.';

  @override
  String get eventsOrganizerFeedbackQrReplay =>
      'QR already used. Regenerating...';

  @override
  String eventsOrganizerFeedbackAlreadyCheckedIn(String name) {
    return '$name is already checked in.';
  }

  @override
  String get eventsOrganizerQrRefreshHelp =>
      'Attendees should always scan the newest QR. The code refreshes automatically before it expires.';

  @override
  String get eventsOrganizerHoldPhoneForScan =>
      'Hold your phone so attendees can scan';

  @override
  String get eventsOrganizerPausedLabel => 'Check-in paused';

  @override
  String get eventsOrganizerStatusOpen => 'Open';

  @override
  String get eventsOrganizerStatusPaused => 'Paused';

  @override
  String eventsOrganizerRefreshInSeconds(int seconds) {
    return 'Refresh in ${seconds}s';
  }

  @override
  String get eventsOrganizerQrRefreshesWhenOpen =>
      'QR refreshes automatically and after each scan';

  @override
  String get eventsOrganizerResumeForFreshQr =>
      'Resume check-in to issue a fresh QR';

  @override
  String get eventsOrganizerManualOverride =>
      'Manual override: mark attendee present';

  @override
  String get eventsOrganizerCheckedInHeading => 'Checked in';

  @override
  String get eventsOrganizerEmptyListTitle => 'No one checked in yet';

  @override
  String get eventsOrganizerEmptyListSubtitle =>
      'Attendees scan your QR to check in';

  @override
  String get eventsOrganizerEndEvent => 'End event';

  @override
  String get eventsOrganizerPauseCheckIn => 'Pause check-in';

  @override
  String get eventsOrganizerResumeCheckIn => 'Resume check-in';

  @override
  String get eventsOrganizerCancelEvent => 'Cancel event';

  @override
  String get eventsOrganizerSimulateCheckInDev => 'Simulate check-in (dev)';

  @override
  String get eventsPhotosTitle => 'Photos';

  @override
  String get createEventDefaultDescription =>
      'Community cleanup action organized by local volunteers.';

  @override
  String get createEventCategoryTitle => 'Event type';

  @override
  String get createEventCategorySubtitle =>
      'What kind of action are you organizing?';

  @override
  String get createEventGearTitle => 'Gear needed';

  @override
  String get createEventGearSubtitle =>
      'Select everything volunteers should bring.';

  @override
  String createEventGearDoneSelectedCount(int count) {
    return 'Done ($count selected)';
  }

  @override
  String get createEventGearMultiselectTitle => 'Multi-select';

  @override
  String get createEventGearMultiselectMessage =>
      'Tap each item volunteers should bring. You can select as many as needed.';

  @override
  String get createEventTeamSizeTitle => 'Team size';

  @override
  String get createEventTeamSizeSubtitle =>
      'How many volunteers do you expect?';

  @override
  String get createEventDifficultyTitle => 'Difficulty';

  @override
  String get createEventDifficultySubtitle =>
      'Set expectations for volunteers.';

  @override
  String createEventStepProgress(int step) {
    return 'Step $step of 5';
  }

  @override
  String get createEventEndTimeError =>
      'End time must be later than start time.';

  @override
  String get createEventFieldType => 'Event type';

  @override
  String get createEventPlaceholderType => 'Select event type';

  @override
  String get createEventFieldTeamSize => 'Team size';

  @override
  String get createEventPlaceholderTeamSize => 'How many people?';

  @override
  String get createEventFieldDifficulty => 'Difficulty';

  @override
  String get createEventPlaceholderDifficulty => 'Set difficulty level';

  @override
  String get createEventSubmitLabel => 'Create eco action';

  @override
  String get createEventAppBarTitle => 'Create event';

  @override
  String get createEventLocalInfoSnack =>
      'Creation keeps the event local for now, but the organizer flow is ready right away.';

  @override
  String get createEventCleanupSiteTitle => 'Cleanup site';

  @override
  String get createEventSelectSiteSemantic => 'Select cleanup site';

  @override
  String get createEventChooseSitePlaceholder => 'Choose a pollution site';

  @override
  String get createEventSiteAnchorHint =>
      'Every event should be anchored to one cleanup location.';

  @override
  String createEventSiteDistanceAway(String distanceKm, String description) {
    return '$distanceKm km away · $description';
  }

  @override
  String get createEventSiteRequiredError =>
      'Choose the site before creating the event.';

  @override
  String get createEventTitleLabel => 'Event title';

  @override
  String createEventTitleCounter(int current, int max) {
    return '$current / $max';
  }

  @override
  String get createEventTitleHint => 'e.g. Weekend river cleanup';

  @override
  String get createEventTitleRequired => 'Event title is required.';

  @override
  String get createEventTypeRequired => 'Select an event type.';

  @override
  String get createEventGearPlaceholderQuestion =>
      'What should volunteers bring?';

  @override
  String get createEventGearLabel => 'Gear needed';

  @override
  String get createEventSelectGearSemantic => 'Select gear needed';

  @override
  String get createEventDescriptionLabel => 'Description';

  @override
  String get createEventDescriptionSubtitle =>
      'Optional: give volunteers more context.';

  @override
  String get createEventDescriptionHint =>
      'Describe what to expect, meeting point, etc.';

  @override
  String get eventsEventNotFoundShort => 'Event not found.';

  @override
  String get eventsBeforeLabel => 'Before';

  @override
  String get eventsAfterLabel => 'After';

  @override
  String get eventsDiscardChangesTitle => 'Discard changes?';

  @override
  String get eventsDiscardChangesBody =>
      'You have unsaved photos. Are you sure you want to leave?';

  @override
  String get eventsSetCover => 'Set as cover';

  @override
  String get eventsViewFullscreen => 'View fullscreen';

  @override
  String get eventsAddToCalendar => 'Add to calendar';

  @override
  String get eventsParticipantsRecent => 'Recent';

  @override
  String get eventsParticipantsAz => 'A-Z';

  @override
  String get eventsParticipantsCheckedIn => 'Checked-in';

  @override
  String get eventsSaveImpactSummary => 'Save impact summary';

  @override
  String get eventsCheckedInBadge => 'Checked in';

  @override
  String eventsCleanupPhotosCount(int count) {
    return '$count cleanup photos';
  }

  @override
  String get qrScannerPointCameraHint =>
      'Point your camera at the organizer\'s live QR code';

  @override
  String get qrScannerEnterManually => 'Can\'t scan? Enter code manually';

  @override
  String get qrScannerRetryCamera => 'Retry camera';

  @override
  String get qrScannerSubmitCode => 'Submit code';

  @override
  String get qrScannerHintFreshQr =>
      'If the organizer refreshes their QR, scan the newest one.';

  @override
  String get qrScannerHintCameraBlocked =>
      'If camera access stays blocked, paste the code manually or enable camera access in Settings.';

  @override
  String get qrScannerGenericEventTitle => 'this cleanup event';

  @override
  String get qrScannerErrorInvalidFormat => 'Invalid QR format.';

  @override
  String get qrScannerErrorWrongEvent => 'This QR belongs to another event.';

  @override
  String get qrScannerErrorSessionClosed => 'Organizer paused check-in.';

  @override
  String get qrScannerErrorSessionExpired =>
      'QR expired. Ask organizer for a new code.';

  @override
  String get qrScannerErrorReplayDetected => 'This QR was already used.';

  @override
  String get qrScannerErrorAlreadyCheckedIn => 'You are already checked in.';

  @override
  String get qrScannerCameraUnavailableFeedback =>
      'Camera access is unavailable. You can paste the organizer code or re-enable camera access in Settings.';

  @override
  String get qrScannerManualEntryTitle => 'Enter code manually';

  @override
  String get qrScannerPasteOrganizerQrHint => 'Paste organizer QR text';

  @override
  String get qrScannerPasteFromClipboardTooltip => 'Paste from clipboard';

  @override
  String get qrScannerEnterCodeFirst => 'Enter a code first.';

  @override
  String get qrScannerCheckedInTitle => 'You\'re checked in!';

  @override
  String qrScannerWelcomeTo(String eventTitle) {
    return 'Welcome to $eventTitle';
  }

  @override
  String qrScannerCheckedInAt(String time) {
    return 'Checked in at $time';
  }

  @override
  String get qrScannerDone => 'Done';

  @override
  String get qrScannerAppBarTitle => 'Scan to check in';

  @override
  String get qrScannerToggleFlashlightSemantic => 'Toggle flashlight';

  @override
  String get siteReportReasonFakeLabel => 'Fake or misleading data';

  @override
  String get siteReportReasonFakeSubtitle =>
      'Information does not reflect reality';

  @override
  String get siteReportReasonResolvedLabel => 'Already resolved';

  @override
  String get siteReportReasonResolvedSubtitle => 'Issue was cleaned or fixed';

  @override
  String get siteReportReasonWrongLocationLabel => 'Wrong location';

  @override
  String get siteReportReasonWrongLocationSubtitle =>
      'Site is placed incorrectly on the map';

  @override
  String get siteReportReasonDuplicateLabel => 'Duplicate report';

  @override
  String get siteReportReasonDuplicateSubtitle =>
      'Same site reported multiple times';

  @override
  String get siteReportReasonSpamLabel => 'Spam or abuse';

  @override
  String get siteReportReasonSpamSubtitle =>
      'Inappropriate or malicious content';

  @override
  String get siteReportReasonOtherLabel => 'Other';

  @override
  String get siteReportReasonOtherSubtitle => 'Something else is wrong';

  @override
  String get takeActionDonationOpenFailed => 'Could not open donation page';

  @override
  String get takeActionShareSiteTitle => 'Share site';

  @override
  String get takeActionShareSiteSubtitle =>
      'Help others discover and support this site';

  @override
  String get takeActionLinkCopied => 'Link copied';

  @override
  String get takeActionSharedToProfile => 'Shared to your profile';

  @override
  String get siteDetailThankYouReportSnack =>
      'Thank you. Your report helps us improve.';

  @override
  String get siteDetailUpvoteFailedSnack =>
      'Could not update upvote. Please try again.';

  @override
  String get siteDetailNoUpvotesSnack =>
      'No upvotes yet. Be the first to support this site!';

  @override
  String get siteDetailNoVolunteersSnack => 'No volunteers yet for this site.';

  @override
  String get siteDetailDirectionsUnavailableSnack =>
      'Directions not available for this site.';

  @override
  String get siteDetailOpenMapsFailedSnack => 'Could not open Maps';

  @override
  String get siteCardUpvoteFailedSnack =>
      'Could not update upvote. Please try again.';

  @override
  String get siteCardSavedFailedSnack =>
      'Could not update saved state. Please try again.';

  @override
  String get siteCardTakeActionSemantic => 'Take action';

  @override
  String get siteCardFeedOptionsSemantic => 'Feed options';

  @override
  String get siteCardCommentsLoadFailedSnack =>
      'Could not load comments right now.';

  @override
  String get siteCardShareTrackFailedSnack =>
      'Could not track share right now.';

  @override
  String get siteCardFeedbackSubmitFailedSnack =>
      'Could not submit feedback right now.';

  @override
  String get siteCardNotRelevantTitle => 'Not relevant';

  @override
  String get siteCardShowLessTitle => 'Show less like this';

  @override
  String get siteCardDuplicateTitle => 'Duplicate';

  @override
  String get siteCardMisleadingTitle => 'Misleading';

  @override
  String get siteCardHidePostTitle => 'Hide this post';

  @override
  String get commentsSheetTitle => 'Comment actions';

  @override
  String get commentsSheetSubtitle => 'Manage this comment';

  @override
  String get commentsEditTitle => 'Edit comment';

  @override
  String get commentsEditSubtitle => 'Update the text in composer';

  @override
  String get commentsDeleteTitle => 'Delete comment';

  @override
  String get commentsDeleteSubtitle => 'Remove it from this thread';

  @override
  String get commentsEditFailedSnack => 'Could not edit comment right now.';

  @override
  String get commentsReplyFailedSnack =>
      'Could not post your reply. Please try again.';

  @override
  String get commentsDeletedSnack => 'Comment deleted.';

  @override
  String get commentsDeleteFailedSnack => 'Could not delete comment right now.';

  @override
  String get commentsLikeFailedSnack => 'Could not update like right now.';

  @override
  String get commentsCancelEditSemantic => 'Cancel editing and clear draft';

  @override
  String get commentsCancelReplySemantic => 'Cancel replying and clear draft';

  @override
  String commentsReplyToSemantic(String name) {
    return 'Reply to $name';
  }

  @override
  String get searchModalCancel => 'Cancel';

  @override
  String get appSmartImageRetry => 'Retry';

  @override
  String appSmartImageRetryIn(int seconds) {
    return 'Retry in ${seconds}s';
  }

  @override
  String get semanticClose => 'Close';

  @override
  String get pollutionSiteTabTakeAction => 'Take action';

  @override
  String get reportDescriptionHint => 'Anything else';

  @override
  String get reportSubmittedFallbackCategory => 'Report';

  @override
  String get reportSeverityLow => 'Low';

  @override
  String get reportSeverityModerate => 'Moderate';

  @override
  String get reportSeveritySignificant => 'Significant';

  @override
  String get reportSeverityHigh => 'High';

  @override
  String get reportSeverityCritical => 'Critical';

  @override
  String get reportListSearchPlaceholder => 'Search your reports';

  @override
  String get reportListSearchHintPrefix =>
      'Search by title, location, category, or status.';

  @override
  String get reportListSearchNoMatches => 'No matches';

  @override
  String get reportListSearchOneReport => '1 report';

  @override
  String reportListSearchNReports(int count) {
    return '$count reports';
  }

  @override
  String get reportListEmptyTitle => 'No reports yet';

  @override
  String get reportListEmptySubtitle =>
      'Your future reports will appear here after you submit them.';

  @override
  String get appSmartImageUnavailable => 'Image unavailable';

  @override
  String siteCardPollutionSiteSemantic(String title) {
    return 'Pollution site: $title. Tap to open details.';
  }

  @override
  String siteCardPhotoSemantic(String title) {
    return 'Photo of $title';
  }
}
