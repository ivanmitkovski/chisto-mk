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
  String reportFlowStepProgressStep(int current) {
    return 'Step $current of 3';
  }

  @override
  String get reportFlowStepProgressReady => 'Ready to submit';

  @override
  String get reportFlowStepStatusComplete => 'Complete';

  @override
  String get reportFlowStepStatusInProgress => 'In progress';

  @override
  String get reportFlowStepChipPhotos => 'Photos';

  @override
  String get reportFlowStepChipCategory => 'Category';

  @override
  String get reportFlowStepChipLocation => 'Location';

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
  String get reportSubmitSentPending => 'Sent';

  @override
  String get semanticsClose => 'Close';

  @override
  String get homeShellNavHome => 'Home';

  @override
  String get homeShellNavReports => 'Reports';

  @override
  String get homeShellNavMap => 'Map';

  @override
  String get homeShellNavEvents => 'Events';

  @override
  String semanticsReportPhotoNumber(int number) {
    return 'Report photo $number';
  }

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
  String get reportSubmittedPointsPending =>
      'Points are credited after moderators approve your report.';

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
  String get profilePointsReasonEventOrganizerApproved =>
      'Your cleanup event was approved';

  @override
  String get profilePointsReasonEventJoined => 'Joined a cleanup event';

  @override
  String get profilePointsReasonEventJoinNoShow =>
      'Join bonus adjusted — no check-in';

  @override
  String get profilePointsReasonEventCheckIn => 'Event check-in';

  @override
  String get profilePointsReasonEventCompleted => 'Cleanup event completed';

  @override
  String get profilePointsReasonReportApproved => 'Report approved';

  @override
  String get profilePointsReasonReportApprovalRevoked =>
      'Report approval reversed';

  @override
  String get profilePointsReasonReportSubmitted => 'Report filed (legacy)';

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
  String get reportListAppBarStartNewReportLabel => 'Start a new report';

  @override
  String reportListDraftChipLabel(int photoCount, String savedAgo) {
    String _temp0 = intl.Intl.pluralLogic(
      photoCount,
      locale: localeName,
      other: '$photoCount photos',
      one: '1 photo',
      zero: 'no photos',
    );
    return 'Draft · $_temp0 · $savedAgo';
  }

  @override
  String reportListDraftChipSemantic(int photoCount) {
    String _temp0 = intl.Intl.pluralLogic(
      photoCount,
      locale: localeName,
      other: '$photoCount photos',
      one: '1 photo',
    );
    return 'Saved draft with $_temp0. Double tap to open.';
  }

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
      'Photos could not be uploaded. Tap Retry to try again, or Skip to submit without photos.';

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
  String get feedLoadingMoreSemantic => 'Loading more feed posts';

  @override
  String get feedShowAllSites => 'Show all sites';

  @override
  String get feedPullToRefreshSemantic => 'Pull to refresh';

  @override
  String get feedLoadMoreFailedSnack => 'Could not load more posts. Tap retry.';

  @override
  String get feedRefreshStaleSnack =>
      'Could not refresh. Showing the last loaded feed.';

  @override
  String get feedScrollToTopSemantic => 'Scroll feed to top';

  @override
  String get feedPollutionFeedTitle => 'Pollution feed';

  @override
  String get feedOfflineBanner =>
      'You\'re offline. Showing the last loaded feed.';

  @override
  String get feedCaughtUpTitle => 'You\'re all caught up';

  @override
  String get feedCaughtUpSubtitle => 'Pull to refresh for new reports';

  @override
  String get feedMoreFiltersTooltip => 'More filters';

  @override
  String feedFilterSemantic(String name) {
    return '$name filter';
  }

  @override
  String get feedEmptyAllTitle => 'No pollution sites yet';

  @override
  String get feedEmptyAllHint => 'Pull to refresh or check back later';

  @override
  String get feedEmptyUrgentTitle => 'No urgent sites right now';

  @override
  String get feedEmptyUrgentHint => 'Show all sites or try another filter';

  @override
  String get feedEmptyNearbyTitleOnline => 'No nearby sites found';

  @override
  String get feedEmptyNearbyTitleOffline =>
      'Enable location to see nearby sites';

  @override
  String get feedEmptyNearbyHintOffline =>
      'Turn on location services and allow access';

  @override
  String get feedEmptyNearbyHintOnline =>
      'Show all sites or try another filter';

  @override
  String get feedEmptyMostVotedTitle => 'No sites have been voted yet';

  @override
  String get feedEmptyMostVotedHint => 'Show all sites or try another filter';

  @override
  String get feedEmptyRecentTitle => 'No recent reports';

  @override
  String get feedEmptyRecentHint => 'Show all sites or try another filter';

  @override
  String get feedEmptySavedTitle => 'No saved sites yet';

  @override
  String get feedEmptySavedHint => 'Save sites from the menu to find them here';

  @override
  String get feedFilterAllName => 'All';

  @override
  String get feedFilterAllDesc => 'Balanced feed ranking';

  @override
  String get feedFilterUrgentName => 'Urgent';

  @override
  String get feedFilterUrgentDesc => 'High-priority incidents first';

  @override
  String get feedFilterNearbyName => 'Nearby';

  @override
  String get feedFilterNearbyDesc => 'Closest reports around you';

  @override
  String get feedFilterMostVotedName => 'Top support';

  @override
  String get feedFilterMostVotedDesc => 'Most community-backed';

  @override
  String get feedFilterRecentName => 'Recent';

  @override
  String get feedFilterRecentDesc => 'Newest reports first';

  @override
  String get feedFilterSavedName => 'Saved';

  @override
  String get feedFilterSavedDesc => 'Sites you bookmarked';

  @override
  String get feedFiltersSheetTitle => 'Feed filters';

  @override
  String get feedFiltersSheetSubtitle =>
      'Choose how you want to browse reports';

  @override
  String get commentsFeedHeaderTitle => 'Comments';

  @override
  String get commentsSortTop => 'Top';

  @override
  String get commentsSortNew => 'New';

  @override
  String get commentsEditingBanner => 'Editing comment';

  @override
  String get commentsBodyTooLong =>
      'Comment is too long (max 2000 characters).';

  @override
  String get commentsReplyTargetFallback => 'comment';

  @override
  String get reportIssueSheetTitle => 'Report issue';

  @override
  String get reportIssueSubmitting => 'Submitting...';

  @override
  String get reportIssueSubmit => 'Submit report';

  @override
  String get reportIssueFailedSnack => 'Could not send report. Try again.';

  @override
  String get reportIssueSheetSubtitle =>
      'Help us improve. Why are you reporting this site?';

  @override
  String get reportIssueDetailsLabel => 'Additional details (optional)';

  @override
  String get reportIssueDetailsHint => 'Describe the issue…';

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
  String reportPhotoGridAttachedCount(int current, int max) {
    return '$current of $max photos attached';
  }

  @override
  String get reportPhotoOpenGallerySemantic => 'Open report photo gallery';

  @override
  String get reportPhotoTapToReviewSingle => 'Tap to review photo';

  @override
  String get reportPhotoTapToReviewMany => 'Tap to review photos';

  @override
  String get reportPhotoVerificationHelpPrimarySelected =>
      'Keep the first photo as the clearest overview of the site.';

  @override
  String get reportPhotoVerificationHelpPrimaryOther =>
      'Use extra photos only for details, scale, or another useful angle.';

  @override
  String get reportPhotoVerificationHelpEmpty =>
      'Start with one clear overview of the site. Add detail only if it helps.';

  @override
  String get reportPhotoStackCaptionSingle =>
      'One clear photo is enough. Add another only if it helps explain the site.';

  @override
  String reportPhotoStackCaptionMany(int count) {
    return '$count photos attached. Keep only the frames that make the report easier to verify.';
  }

  @override
  String reportPhotoSemanticThumbnail(int index, int total) {
    return 'Photo $index of $total. Double-tap to select.';
  }

  @override
  String get reportPhotoSemanticRemove => 'Remove photo';

  @override
  String get reportPhotoSemanticAddPhoto => 'Add evidence photo';

  @override
  String reportPhotoSemanticReportPhoto(int index) {
    return 'Report photo $index';
  }

  @override
  String get reportRequirementPhotos => 'Add at least one photo';

  @override
  String get reportRequirementCategory => 'Choose a category';

  @override
  String get reportRequirementTitle => 'Add a short title';

  @override
  String get reportRequirementLocation => 'Confirm a location in Macedonia';

  @override
  String get reportCooldownUnlockHintDefault =>
      'Join and verify attendance, or create an eco action to unlock more reports.';

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
  String get eventsDetailBrowseEvents => 'Browse events';

  @override
  String get eventsDetailCouldNotRefresh =>
      'Couldn’t refresh. Showing saved details.';

  @override
  String get eventsDetailRetryRefresh => 'Retry';

  @override
  String get eventsDetailLocationTitle => 'Location';

  @override
  String get eventsDetailCopyAddress => 'Copy address';

  @override
  String get eventsDetailAddressCopied => 'Address copied';

  @override
  String get eventsDetailLocationLongPressHint =>
      'Long-press for full address and actions';

  @override
  String get eventsDetailCoverImageUnavailable => 'Image unavailable';

  @override
  String get eventsWeatherUnavailableBody =>
      'Forecast isn’t available right now.';

  @override
  String get eventsWeatherRetry => 'Try again';

  @override
  String get eventsUnableToStartEventGeneric =>
      'Could not start the event. Check your connection and try again.';

  @override
  String get eventsStartEventTooEarly =>
      'You can start this eco action once the scheduled start time arrives.';

  @override
  String get eventsJoinNotYetOpen =>
      'Joining opens when the scheduled start time arrives.';

  @override
  String get eventsJoinWindowClosed =>
      'You can no longer join this action. Joining stayed open until 15 minutes after the scheduled start.';

  @override
  String get errorEventEndAtTooFar =>
      'The planned end cannot be that far after the start. Try a shorter extension.';

  @override
  String get errorEventsEndDifferentSkopjeCalendarDay =>
      'The end time must be on the same calendar day as the start (Europe/Skopje).';

  @override
  String get errorEventsEndAfterSkopjeLocalDay =>
      'The event must end by 23:59 on the start day.';

  @override
  String get eventsAwaitingModerationCta => 'Awaiting approval';

  @override
  String get eventsModerationBannerTitle => 'Awaiting approval';

  @override
  String get eventsModerationBannerBody =>
      'This action is visible to you as the organizer. Volunteers will be able to join after moderators approve it.';

  @override
  String get eventsAttendeeModerationBannerTitle => 'Awaiting approval';

  @override
  String get eventsAttendeeModerationBannerBody =>
      'Moderators are reviewing this action. You can open it, but joining opens only after approval.';

  @override
  String get eventsDeclinedBannerTitle => 'Not approved';

  @override
  String get eventsDeclinedBannerBody =>
      'This event did not meet the criteria. Edit and resubmit to try again.';

  @override
  String get eventsDeclinedResubmitCta => 'Edit & resubmit';

  @override
  String get eventsDeclinedDashboardPill => 'Declined';

  @override
  String get eventsPendingDashboardPill => 'Under review';

  @override
  String get eventsEventPendingPublicCta => 'Not open for joining yet';

  @override
  String get eventsFeedOfflineStaleBanner =>
      'Showing saved events — couldn’t refresh. Pull down to retry.';

  @override
  String get eventsFeedInitialLoadFailed =>
      'We couldn’t load events. Check your connection and try again.';

  @override
  String get eventsOrganizerInvalidateQrTitle => 'Invalidate previous QR codes';

  @override
  String get eventsOrganizerInvalidateQrSubtitle =>
      'Use if a code was shared or photographed. Already scanned codes stay valid until they expire; this rotates the session so new scans need a fresh QR.';

  @override
  String get eventsOrganizerQrSessionRotated =>
      'QR session updated. Show the new code to attendees.';

  @override
  String get eventsOrganizerQrRotateFailed =>
      'Could not invalidate codes. Try again.';

  @override
  String get eventsEditEventTitle => 'Edit event';

  @override
  String get eventsEditEventSave => 'Save changes';

  @override
  String editEventTitleTooLong(int max) {
    return 'Title must be at most $max characters.';
  }

  @override
  String editEventDescriptionTooLong(int max) {
    return 'Description must be at most $max characters.';
  }

  @override
  String get editEventMaxParticipantsInvalid =>
      'Enter a valid whole number of spots, or leave blank for no limit.';

  @override
  String editEventMaxParticipantsRange(int min, int max) {
    return 'Team size must be between $min and $max, or leave blank for no limit.';
  }

  @override
  String editEventGearLimitReached(int max) {
    return 'You can select up to $max gear items.';
  }

  @override
  String get editEventDiscardTitle => 'Discard changes?';

  @override
  String get editEventDiscardMessage =>
      'You have unsaved changes. If you leave now, they will be lost.';

  @override
  String get editEventDiscardConfirm => 'Discard';

  @override
  String get editEventDiscardKeepEditing => 'Keep editing';

  @override
  String get editEventSchedulePreviewFailed =>
      'Could not check for schedule conflicts. You can still save; the server will reject overlapping times.';

  @override
  String get editEventOfflineSave =>
      'You appear to be offline. Connect and try again.';

  @override
  String get editEventHelpTitle => 'Editing your event';

  @override
  String get editEventHelpSubtitle => 'Schedule, volunteers, and moderation';

  @override
  String get editEventHelpButtonTooltip => 'Help';

  @override
  String get editEventDuplicateSubmitTitle => 'Schedule conflict';

  @override
  String editEventDuplicateSubmitBody(String title, String when) {
    return '$title is already scheduled at $when. Adjust your times and try again.';
  }

  @override
  String get editEventNoChangesToSave => 'Nothing to save.';

  @override
  String get editEventPendingModerationBanner =>
      'This event is still awaiting moderator approval. Changes apply to your draft.';

  @override
  String get eventsEventNotEditable => 'This event can no longer be edited.';

  @override
  String get eventsEventUpdated => 'Event updated';

  @override
  String get eventsMutationFailedGeneric =>
      'Something went wrong. Please try again.';

  @override
  String get eventsScheduleConflictPreviewTitle => 'Possible schedule overlap';

  @override
  String eventsScheduleConflictPreviewBody(String title, String when) {
    return 'Another event at this site may overlap your time: $title at $when.';
  }

  @override
  String get eventsScheduleConflictContinue => 'Continue anyway';

  @override
  String get eventsScheduleConflictAdjustTime => 'Change time';

  @override
  String eventsDuplicateEventBlocked(String title, String when) {
    return 'This time overlaps \"$title\" ($when). Choose a different time.';
  }

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
  String get eventsOrganizerManualCheckInSubtitle =>
      'Search volunteers who joined this event, then check them in.';

  @override
  String get eventsOrganizerManualCheckInNoJoiners =>
      'No volunteers have joined this event yet.';

  @override
  String get eventsOrganizerManualCheckInSelectParticipant =>
      'Select a volunteer from the list.';

  @override
  String get eventsOrganizerManualCheckInNotParticipant =>
      'This person is not on the participant list.';

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
  String get eventsOrganizerCompletionCheckedInNone =>
      'No attendees checked in.';

  @override
  String eventsOrganizerCompletionJoinedLine(int count) {
    return '$count volunteers joined';
  }

  @override
  String eventsOrganizerCompletionJoinedOfCap(int joined, int cap) {
    return '$joined of $cap spots filled';
  }

  @override
  String get eventsOrganizerCompletionSheetSemantic =>
      'Event completed. Review next steps.';

  @override
  String get eventsOrganizerCompletionBackToEvent => 'Back to event';

  @override
  String get eventsOrganizerCompletionAddPhotosNow => 'Add cleanup photos now';

  @override
  String get eventsOrganizerCompletionWhatNextIntro =>
      'Wrap up on the event page: document results and share the impact you made together.';

  @override
  String get eventsOrganizerCompletionNextStepsHeading => 'NEXT STEPS';

  @override
  String get eventsOrganizerCompletionStepPhotosTitle => 'Add after photos';

  @override
  String get eventsOrganizerCompletionStepPhotosBody =>
      'Show the difference you made. They appear on the event page for everyone.';

  @override
  String get eventsOrganizerCompletionStepImpactTitle => 'Log your impact';

  @override
  String get eventsOrganizerCompletionStepImpactBody =>
      'Record bags collected, time volunteered, and estimates from the event page.';

  @override
  String get eventsOrganizerCompletionStepVisibilityTitle => 'Build trust';

  @override
  String get eventsOrganizerCompletionStepVisibilityBody =>
      'Photos help moderators verify the cleanup and inspire future actions in your community.';

  @override
  String get eventsOrganizerCompletionViewReceipt => 'View impact receipt';

  @override
  String get eventsImpactReceiptScreenTitle => 'Impact receipt';

  @override
  String eventsImpactReceiptHeroSemantic(String title) {
    return 'Impact receipt for $title';
  }

  @override
  String get eventsImpactReceiptMetricCheckIns => 'Check-ins';

  @override
  String get eventsImpactReceiptMetricParticipants => 'Joined';

  @override
  String get eventsImpactReceiptMetricBags => 'Bags (reported)';

  @override
  String get eventsImpactReceiptProofHeading => 'Proof';

  @override
  String get eventsImpactReceiptNoMediaHint =>
      'Add after photos or structured evidence from the event page when you can.';

  @override
  String eventsImpactReceiptAsOf(String timestamp) {
    return 'Updated $timestamp';
  }

  @override
  String get eventsImpactReceiptCompletenessInProgress => 'In progress';

  @override
  String get eventsImpactReceiptCompletenessFull => 'Complete record';

  @override
  String get eventsImpactReceiptCompletenessPartialAfter =>
      'After photos pending';

  @override
  String get eventsImpactReceiptCompletenessPartialEvidence =>
      'Structured evidence pending';

  @override
  String get eventsImpactReceiptCompletenessPartialBoth =>
      'After photos and evidence pending';

  @override
  String get eventsImpactReceiptShare => 'Share';

  @override
  String get eventsImpactReceiptCopyLink => 'Copy link';

  @override
  String get eventsImpactReceiptLinkCopied => 'Link copied';

  @override
  String get eventsImpactReceiptViewCta => 'Impact receipt';

  @override
  String get eventsImpactReceiptRetry => 'Try again';

  @override
  String get eventsImpactReceiptLoadFailed => 'Could not load receipt.';

  @override
  String eventsImpactReceiptShareSummary(int checkIns, int bags, int joined) {
    return '$checkIns check-ins · $bags bags · $joined joined';
  }

  @override
  String get errorEventsImpactReceiptNotAvailable =>
      'Impact receipt is not available for this event yet.';

  @override
  String get eventsOrganizerDetailPendingAfterPhotosTitle => 'After photos';

  @override
  String get eventsOrganizerDetailPendingAfterPhotosMessage =>
      'Upload photos after cleanup so volunteers and moderators can see your results. Use the button below when you are ready.';

  @override
  String get eventsAttendeeCompletedTitle => 'Thank you';

  @override
  String get eventsAttendeeCompletedBody =>
      'This eco action is complete. Thanks for showing up for your community.';

  @override
  String get eventsAfterPhotosOrganizerEmptyHint =>
      'No after photos yet. Use the button below to add them.';

  @override
  String get eventsEvidenceScreenSubtitle =>
      'After photos document your results and appear on the event page.';

  @override
  String eventsEvidencePhotoCountChip(int current, int max) {
    return '$current of $max photos';
  }

  @override
  String get eventsEvidenceBeforeAfterTabsSemantic => 'Before and after photos';

  @override
  String get eventsEvidenceSavingSemantic => 'Saving after photos';

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
  String get eventsOrganizerQrLoadFailedGeneric =>
      'Could not load a check-in code. Check your connection and try again.';

  @override
  String get eventsOrganizerQrRateLimited =>
      'Too many refresh attempts. Wait a moment and try again.';

  @override
  String get eventsOrganizerSessionSetupFailed =>
      'Could not start check-in. Confirm the event is in progress and try again.';

  @override
  String get eventsOrganizerConfirmTitle => 'Confirm check-in';

  @override
  String get eventsOrganizerConfirmSubtitle =>
      'Wants to check in to this event';

  @override
  String get eventsOrganizerConfirmApprove => 'Confirm';

  @override
  String get eventsOrganizerConfirmReject => 'Dismiss';

  @override
  String get eventsOrganizerConfirmExpired =>
      'This check-in request has expired.';

  @override
  String get eventsVolunteerPendingTitle => 'Waiting for confirmation';

  @override
  String get eventsVolunteerPendingSubtitle =>
      'The organizer needs to confirm your check-in...';

  @override
  String get eventsVolunteerRejected =>
      'Check-in was not confirmed by the organizer.';

  @override
  String get eventsVolunteerExpired => 'Request expired. Please scan again.';

  @override
  String get eventsOrganizerQrRetry => 'Try again';

  @override
  String get eventsOrganizerQrBrightnessHint =>
      'Tip: turn up screen brightness so the code is easier to scan.';

  @override
  String eventsOrganizerQrSemantics(int seconds) {
    return 'Check-in QR code. Refreshes in about $seconds seconds.';
  }

  @override
  String get eventsOrganizerQrEncodeError =>
      'This code could not be drawn. Tap try again.';

  @override
  String get eventsOrganizerFeedbackInvalidQrStrict =>
      'That QR is not valid for check-in.';

  @override
  String get eventsOrganizerFeedbackRequiresJoin =>
      'Join the event in the app before checking in.';

  @override
  String get eventsOrganizerFeedbackCheckInUnavailable =>
      'Check-in is not available for this event right now.';

  @override
  String get eventsOrganizerFeedbackRateLimited =>
      'Too many attempts. Wait briefly and try again.';

  @override
  String get eventsOrganizerCopyQrText => 'Copy QR code text';

  @override
  String get eventsOrganizerQrTextCopied =>
      'QR code text copied — paste it in a message to attendees who can\'t scan.';

  @override
  String get eventsOrganizerNoQrToCopy => 'No active QR code to copy yet.';

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
  String get eventsOrganizerMoreActionsSemantic => 'More event actions';

  @override
  String get eventsOrganizerMoreSheetTitle => 'Event actions';

  @override
  String get eventsOrganizerEndEventConfirmTitle => 'End this event?';

  @override
  String get eventsOrganizerEndEventConfirmMessage =>
      'Check-in will close and the event will be marked completed. You can upload after photos from the event detail.';

  @override
  String get eventsOrganizerEndEventKeepManaging => 'Keep managing';

  @override
  String get eventsOrganizerEndEventConfirmAction => 'End event';

  @override
  String get eventsOrganizerCancelEventConfirmTitle => 'Cancel this event?';

  @override
  String get eventsOrganizerCancelEventConfirmMessage =>
      'Volunteers will see the event as cancelled. This cannot be undone from the app.';

  @override
  String get eventsOrganizerCancelEventKeepEvent => 'Keep event';

  @override
  String get eventsOrganizerCancelEventConfirmAction => 'Cancel event';

  @override
  String eventsOrganizerRemoveAttendeeSemantic(String name) {
    return 'Remove $name from check-in';
  }

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
  String createEventScheduleStartInPast(int minutes) {
    return 'Choose a start time at least $minutes minutes from now.';
  }

  @override
  String createEventScheduleEndInPast(int minutes) {
    return 'Choose an end time at least $minutes minutes from now.';
  }

  @override
  String get createEventScheduleDateLabel => 'Event date';

  @override
  String get createEventScheduleEndAfterDayError =>
      'The event must end by 23:59 on the same day.';

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
  String get createEventHelpTitle => 'Creating an event';

  @override
  String get createEventHelpSubtitle => 'Quick guide for organizers';

  @override
  String get createEventHelpBulletModeration =>
      'Events are reviewed so the community sees accurate, safe cleanups.';

  @override
  String get createEventHelpBulletVolunteers =>
      'Volunteers see your title, schedule, site, gear list, and description once the event is live.';

  @override
  String get createEventHelpBulletSite =>
      'Pick a pollution site on the list or map so everyone knows where to meet.';

  @override
  String get createEventHelpBulletSchedule =>
      'Pick the event date, then start and end times on that same day.';

  @override
  String get createEventHelpBulletSameDay =>
      'The event must finish on the same calendar day and by 23:59 at the latest.';

  @override
  String get createEventHelpBulletSubmit =>
      'When everything required is filled in, use Create eco action to publish.';

  @override
  String get createEventFieldVolunteerCap => 'Volunteer cap';

  @override
  String get createEventVolunteerCapPlaceholderNoLimit => 'No limit';

  @override
  String createEventVolunteerCapUpTo(int count) {
    return 'Up to $count volunteers';
  }

  @override
  String get createEventVolunteerCapSheetTitle => 'Volunteer cap';

  @override
  String get createEventVolunteerCapSheetSubtitle =>
      'Optional. You can cap sign-ups between 2 and 5000.';

  @override
  String get createEventVolunteerCapNoLimit => 'No limit';

  @override
  String get createEventVolunteerCapCustomLabel => 'Custom';

  @override
  String get createEventVolunteerCapCustomHint => 'Number (2–5000)';

  @override
  String get createEventVolunteerCapApply => 'Apply';

  @override
  String get createEventVolunteerCapInvalid =>
      'Enter a whole number between 2 and 5000.';

  @override
  String get createEventSitePickerLoading => 'Loading sites…';

  @override
  String get createEventSitePickerOfflineTitle => 'Offline list';

  @override
  String get createEventSitePickerOfflineMessage =>
      'Showing built-in sites because the live list was empty or unavailable.';

  @override
  String get createEventSitePickerLoadFailedTitle => 'Could not refresh';

  @override
  String get createEventSitePickerLoadFailedMessage =>
      'You can still pick from the offline site list. Try again to load live sites.';

  @override
  String get createEventSitePickerRetry => 'Try again';

  @override
  String get createEventDiscardTitle => 'Discard event?';

  @override
  String get createEventDiscardBody =>
      'You will lose what you entered on this screen.';

  @override
  String get createEventDiscardKeepEditing => 'Keep editing';

  @override
  String get createEventLoadingSemantic => 'Loading create event form';

  @override
  String get createEventSectionScheduleCaption => 'Schedule';

  @override
  String get createEventSectionDetailsCaption => 'Event details';

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
  String get createEventTitleMinLength =>
      'Use at least 3 characters for the title.';

  @override
  String get createEventSitePickerTabList => 'List';

  @override
  String get createEventSitePickerTabMap => 'Map';

  @override
  String get createEventSitePickerMapEmpty =>
      'No sites on the map match this search, or locations are not available yet.';

  @override
  String get createEventSitePickerMapSemanticLabel => 'Map of pollution sites';

  @override
  String get createEventSitePickerMapHint => 'Tap a pin to select a site.';

  @override
  String get createEventSiteMapPreviewSemantic => 'Open site map picker';

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
  String get eventsCtaStartEvent => 'Start event';

  @override
  String get eventsCtaManageCheckIn => 'Manage check-in';

  @override
  String get eventsCtaExtendCleanupEnd => 'Extend planned end';

  @override
  String get eventsExtendEndSheetTitle => 'Extend cleanup';

  @override
  String eventsExtendEndSheetSubtitle(String time) {
    return 'Current planned end is $time.';
  }

  @override
  String eventsExtendEndCurrentChoice(String time) {
    return 'New end: $time';
  }

  @override
  String get eventsExtendEndPlus15 => '+15 min';

  @override
  String get eventsExtendEndPlus30 => '+30 min';

  @override
  String get eventsExtendEndPlus60 => '+1 hour';

  @override
  String get eventsExtendEndCustomTime => 'Custom time…';

  @override
  String get eventsExtendEndApply => 'Save new end time';

  @override
  String get eventsExtendEndSuccess => 'Planned end updated.';

  @override
  String get eventsExtendEndSameAsCurrent =>
      'That is already the planned end time.';

  @override
  String get eventsExtendEndInvalidRange =>
      'That end time is not valid for this cleanup.';

  @override
  String get eventsExtendEndTooSoon =>
      'Choose an end time a little further ahead.';

  @override
  String get eventsEndSoonBannerTitle => 'Cleanup is ending soon';

  @override
  String get eventsEndSoonBannerBody =>
      'You can extend the planned end or finish when you are ready.';

  @override
  String get eventsEndSoonBannerExtend => 'Extend';

  @override
  String get eventsOrganizerExtendEndSemantic =>
      'Extend planned cleanup end time';

  @override
  String get eventsOrganizerEndSoonNotifyTitle => 'Cleanup ending soon';

  @override
  String get eventsOrganizerEndSoonNotifyBody =>
      'Your cleanup is nearing its planned end. Tap to review.';

  @override
  String get eventsOrganizerEndSoonNotifyChannelName =>
      'Organizer cleanup reminders';

  @override
  String get eventsOrganizerEndSoonNotifyChannelDescription =>
      'Local reminders when a cleanup you run is nearing its planned end.';

  @override
  String get eventsCtaEditAfterPhotos => 'Edit after photos';

  @override
  String get eventsCtaUploadAfterPhotos => 'Upload after photos';

  @override
  String get eventsCtaCheckedIn => 'Checked in';

  @override
  String get eventsCtaScanToCheckIn => 'Scan to check in';

  @override
  String get eventsCtaCheckInPaused => 'Check-in paused';

  @override
  String get eventsCtaTurnReminderOff => 'Turn reminder off';

  @override
  String get eventsCtaSetReminder => 'Set reminder';

  @override
  String get eventsCtaLeaveEvent => 'Leave event';

  @override
  String get eventsCtaJoinEcoAction => 'Join eco action';

  @override
  String get eventsStatusUpcoming => 'Upcoming';

  @override
  String get eventsStatusInProgress => 'In progress';

  @override
  String get eventsStatusCompleted => 'Completed';

  @override
  String get eventsStatusCancelled => 'Cancelled';

  @override
  String get eventsCardActionsSheetTitle => 'Event actions';

  @override
  String get eventsCardCopyTitle => 'Copy event details';

  @override
  String get eventsCardCopySubtitle => 'Copy title, date and location';

  @override
  String get eventsCardCopiedSnack => 'Event details copied.';

  @override
  String get eventsCardShareTitle => 'Share event';

  @override
  String get eventsCardShareSubtitle => 'Share with friends';

  @override
  String get eventsCardOpenTitle => 'Open event';

  @override
  String get eventsCardOpenSubtitle => 'View full event details';

  @override
  String get eventsCardMoreActionsSemantic => 'More event actions';

  @override
  String get eventsCardSoonLabel => 'Soon';

  @override
  String get eventsFeedUpNext => 'Up next';

  @override
  String get eventsCountdownStarted => 'Started';

  @override
  String eventsCountdownDaysHours(int days, int hours) {
    return 'Starts in ${days}d ${hours}h';
  }

  @override
  String eventsCountdownHoursMinutes(int hours, int minutes) {
    return 'Starts in ${hours}h ${minutes}m';
  }

  @override
  String eventsCountdownMinutes(int minutes) {
    return 'Starts in ${minutes}m';
  }

  @override
  String get eventsShareEventTooltip => 'Share event';

  @override
  String get eventsAttendeeCheckInSemantic => 'Scan to check in at event';

  @override
  String get eventsAttendeeAlreadyCheckedInSnack =>
      'You are already checked in.';

  @override
  String get eventsAttendeeCheckInPausedSnack =>
      'Organizer has paused check-in for now.';

  @override
  String get eventsAttendeeCheckInCompleteSnack => 'Check-in complete.';

  @override
  String get eventsAttendeeBannerTitleCheckedIn => 'You are checked in';

  @override
  String get eventsAttendeeBannerTitleInProgress => 'Event is in progress';

  @override
  String get eventsAttendeeBannerSubtitleAttendanceConfirmed =>
      'Attendance confirmed';

  @override
  String eventsAttendeeBannerSubtitleCheckedInAt(String time) {
    return 'Checked in at $time';
  }

  @override
  String get eventsAttendeeBannerSubtitleScanQr =>
      'Scan the organizer\'s QR to check in';

  @override
  String get eventsAttendeeBannerSubtitlePaused =>
      'Check-in is temporarily paused';

  @override
  String get eventsDetailShareSuccess => 'Event shared.';

  @override
  String get eventsDetailShareFailed => 'Could not open share. Try again.';

  @override
  String get eventsDetailCalendarAdded => 'Event added to your calendar.';

  @override
  String get eventsDetailCalendarFailed =>
      'Could not add to calendar. Try again.';

  @override
  String get eventsDetailRefreshFailed =>
      'Could not refresh this event. Try again.';

  @override
  String get eventsDetailCancelledCallout => 'This event has been cancelled.';

  @override
  String get eventsDetailOpenInMaps => 'Open in Maps';

  @override
  String eventsDetailCoverSemantic(String title) {
    return 'Cover image for $title';
  }

  @override
  String get eventsDetailGroupedPanelSemantic =>
      'Location, schedule, and details';

  @override
  String eventsHeroChatSemantic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Group chat, $count unread',
      one: 'Group chat, 1 unread',
      zero: 'Group chat',
    );
    return '$_temp0';
  }

  @override
  String get eventsDetailParticipationSemantic => 'Your participation';

  @override
  String get eventsAnalyticsLoadFailed => 'Could not load analytics.';

  @override
  String get eventsAnalyticsRetry => 'Retry';

  @override
  String get eventsRecurrenceDaily => 'Every day';

  @override
  String get eventsRecurrenceNavigatePrevious =>
      'Previous occurrence in series';

  @override
  String get eventsRecurrenceNavigateNext => 'Next occurrence in series';

  @override
  String get eventsImpactSummarySaved => 'Impact summary saved.';

  @override
  String get eventsImpactSummaryUpdated => 'Impact summary updated.';

  @override
  String eventsReminderSetSnack(String when) {
    return 'Reminder set for $when.';
  }

  @override
  String get eventsFeedbackSheetTitle => 'Post-event feedback';

  @override
  String get eventsFeedbackHowWasEvent => 'How was the event?';

  @override
  String get eventsFeedbackBagsCollected => 'Bags collected';

  @override
  String eventsFeedbackVolunteerHours(String hours) {
    return 'Volunteer hours: ${hours}h';
  }

  @override
  String get eventsFeedbackNotesHint =>
      'What worked well? Any notes for next time?';

  @override
  String eventsEvidenceMaxPhotosSnack(int max) {
    return 'Maximum $max photos reached.';
  }

  @override
  String get eventsEvidencePickFailedSnack =>
      'Could not pick photos. Check permissions.';

  @override
  String get eventsEvidenceRemoveAction => 'Remove';

  @override
  String get eventsEvidenceAppBarTitle => 'Cleanup evidence';

  @override
  String get eventsEvidenceSaving => 'Saving...';

  @override
  String get eventsEvidenceSaveInProgressHint =>
      'Please wait until save finishes before leaving this screen.';

  @override
  String get eventsEvidenceAfterPhotosSaved => 'After photos saved.';

  @override
  String get eventsEvidenceSaveSuccessTitle => 'Photos saved';

  @override
  String get eventsEvidenceSaveSuccessBody =>
      'Your after photos are on the event page.';

  @override
  String get eventsEvidenceSaveFailureTitle => 'Could not save photos';

  @override
  String eventsEvidenceSaveFailureBody(String message) {
    return '$message';
  }

  @override
  String get eventsEvidenceNoChanges => 'No changes to save.';

  @override
  String get eventsSiteReferencePhotoTitle => 'Site reference photo';

  @override
  String get eventsSiteReferencePhotoBody =>
      'Reference taken before cleanup. Use the After tab to add photos of the cleaned site.';

  @override
  String get eventsManageCheckInOnlyInProgress =>
      'Check-in is available only while the event is in progress.';

  @override
  String get eventsEventFull => 'This event is full.';

  @override
  String get eventsParticipationUpdateFailed =>
      'Could not update participation. Try again.';

  @override
  String get eventsJoinedEcoAction => 'You joined this eco action.';

  @override
  String eventsJoinPointsEarned(int points) {
    return '+$points points — you\'re in!';
  }

  @override
  String get eventsLeftEcoAction => 'You left this eco action.';

  @override
  String eventsCheckInPointsEarned(int points) {
    return '+$points points — checked in!';
  }

  @override
  String eventsManualCheckInWithPoints(String name, int points) {
    return '$name checked in · +$points pts for them';
  }

  @override
  String get eventsJoinFirstForReminders =>
      'Join the event first to set reminders.';

  @override
  String get eventsReminderDisabled => 'Reminder disabled.';

  @override
  String get eventsReminderSheetTitle => 'Choose reminder time';

  @override
  String eventsReminderSheetSubtitle(String timeRange, String date) {
    return 'Event starts at $timeRange on $date.';
  }

  @override
  String get eventsReminderPreset1Day => '1 day before';

  @override
  String get eventsReminderPreset3Hours => '3 hours before';

  @override
  String get eventsReminderPreset1Hour => '1 hour before';

  @override
  String get eventsReminderPreset30Mins => '30 minutes before';

  @override
  String get eventsReminderUnavailableSubtitle =>
      'Unavailable for this event time';

  @override
  String get eventsReminderCustomTitle => 'Custom date and time';

  @override
  String get eventsReminderCustomSubtitle => 'Pick a specific reminder moment';

  @override
  String get eventsReminderPickTitle => 'Pick reminder';

  @override
  String get eventsReminderDone => 'Done';

  @override
  String eventsCardParticipantsMore(int count) {
    return '+$count more';
  }

  @override
  String eventsCardParticipantsCountMax(int count, int max) {
    return '$count / $max';
  }

  @override
  String eventsCardParticipantsJoined(int count) {
    return '$count joined';
  }

  @override
  String get eventsDiscoveryThisWeekRetryHint =>
      'We couldn’t load this week’s picks.';

  @override
  String get eventsDiscoveryThisWeekRetry => 'Retry';

  @override
  String eventsDetailSemanticsLabel(String title) {
    return 'Event detail: $title';
  }

  @override
  String eventsCountdownBadgeSemantic(String label) {
    return 'Time until event starts: $label';
  }

  @override
  String get eventsEvidenceThumbnailMenuTitle => 'Photo';

  @override
  String get eventsFeedRefreshFailed => 'Could not refresh events.';

  @override
  String get eventsCreateGenericError => 'Could not create event. Try again.';

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
  String get qrScannerErrorInvalidQr => 'This QR is not valid for check-in.';

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
  String get qrScannerErrorRequiresJoin =>
      'Join this event in the app before checking in.';

  @override
  String get qrScannerErrorCheckInUnavailable =>
      'Check-in is not open for this event right now.';

  @override
  String get qrScannerErrorRateLimited =>
      'Too many attempts. Wait a moment and try again.';

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
  String get qrScannerCameraStarting => 'Starting camera…';

  @override
  String get qrScannerCheckingIn => 'Verifying check-in…';

  @override
  String get qrScannerCameraErrorTitle => 'Camera unavailable';

  @override
  String get qrScannerManualEntrySubtitle =>
      'Paste the full text the organizer shared (copy from their screen or a message).';

  @override
  String get qrScannerPasteButton => 'Paste';

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
  String get takeActionSheetTitle => 'Take action';

  @override
  String get takeActionSheetSubtitle => 'Choose how you want to help';

  @override
  String get takeActionCreateEcoTitle => 'Create eco action';

  @override
  String get takeActionCreateEcoSubtitle =>
      'Schedule a cleanup event at this site';

  @override
  String get takeActionJoinTitle => 'Join action';

  @override
  String get takeActionJoinSubtitle => 'Find and join upcoming cleanups here';

  @override
  String get takeActionShareTitle => 'Share site';

  @override
  String get takeActionShareSubtitle => 'Help others discover this site';

  @override
  String get shareSheetSemanticDragHandle => 'Drag to resize or dismiss';

  @override
  String get shareSheetCopyLinkTitle => 'Copy link';

  @override
  String get shareSheetCopyLinkSubtitle =>
      'Copy the site link to the clipboard';

  @override
  String get shareSheetCopyLinkSemantic => 'Copy link to this pollution site';

  @override
  String get shareSheetSendTitle => 'Send to people';

  @override
  String get shareSheetSendSubtitle => 'Share in messages or another app';

  @override
  String get shareSheetSendSemantic => 'Open the share sheet to send this site';

  @override
  String siteDetailSemanticShareCount(int count) {
    return '$count shares on this site';
  }

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
  String get siteUpvotersSheetTitle => 'Upvoters';

  @override
  String get siteUpvotersSupportingLabel => 'Supporting';

  @override
  String siteUpvotersSupportersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count supporters',
      one: '1 supporter',
    );
    return '$_temp0';
  }

  @override
  String get siteUpvotersLoadFailed => 'Could not load supporters.';

  @override
  String get siteUpvotersRetry => 'Retry';

  @override
  String get siteDetailNoVolunteersSnack => 'No volunteers yet for this site.';

  @override
  String get siteDetailDirectionsUnavailableSnack =>
      'Directions not available for this site.';

  @override
  String get siteDetailOpenMapsFailedSnack => 'Could not open Maps';

  @override
  String get siteDetailNoCoReportersSnack =>
      'No other contributors yet. Co-reporters appear when someone else reports the same place.';

  @override
  String siteStatsCoReportersSemantic(int count) {
    return '$count co-reporters for this report';
  }

  @override
  String siteParticipantStatsSemantic(int count) {
    return '$count for contributors (co-reporters or merged duplicates)';
  }

  @override
  String get siteMergedDuplicatesModalTitle => 'Merged duplicate reports';

  @override
  String siteMergedDuplicatesModalBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count similar submissions were merged into this report. When someone else reports the same place, they appear as co-reporters.',
      one:
          'One similar submission was merged into this report. When someone else reports the same place, they appear as co-reporters.',
    );
    return '$_temp0';
  }

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
  String get feedSiteCommentsAppBarFallback => 'Comments';

  @override
  String get feedSiteNotFoundMessage => 'This site could not be found.';

  @override
  String get feedDisplayNameFallback => 'You';

  @override
  String get feedOpenProfileSemantics => 'Open profile';

  @override
  String get feedGreetingPrefix => 'Hi, ';

  @override
  String get feedGreetingFallbackName => 'there';

  @override
  String get feedHeaderSubtitle => 'Explore pollution sites near you';

  @override
  String get feedNotificationBellAllReadSemantic => 'Notifications, all read';

  @override
  String feedNotificationBellUnreadSemantic(int count) {
    return 'Notifications, $count unread';
  }

  @override
  String get siteDetailTabPollutionSite => 'Pollution site';

  @override
  String get siteDetailTabCleaningEvents => 'Cleaning events';

  @override
  String get siteDetailInfoCardTitle => 'Community action needed';

  @override
  String get siteDetailInfoCardBody =>
      'Join a cleanup, report changes, or help spread the word so we can act faster.';

  @override
  String get siteDetailReportedByPrefix => 'Reported by ';

  @override
  String get siteDetailCoReportersTitle => 'Co-reporters';

  @override
  String siteDetailCoReportersSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people also reported this site',
      one: '1 person also reported this site',
    );
    return '$_temp0';
  }

  @override
  String siteDetailGalleryPhotoSemantic(int index) {
    return 'Pollution site photo $index';
  }

  @override
  String get siteDetailOpenGalleryLabel => 'Open pollution site gallery';

  @override
  String get siteDetailGalleryTapToExpand => 'Tap to expand';

  @override
  String get siteDetailGalleryOpenPhoto => 'Open photo';

  @override
  String get commonNotAvailable => '—';

  @override
  String get commonDistanceMetersUnit => 'm';

  @override
  String get commonDistanceKilometersUnit => 'km';

  @override
  String get siteCommentsEmptyBody =>
      'No comments yet.\nBe the first to comment.';

  @override
  String get feedCommentsLoadMoreFailedSnack =>
      'Could not load more comments. Pull to refresh or try again.';

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
  String get commentsSortFailedSnack =>
      'Could not change comment order. Try again.';

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
  String get commentsReplyButton => 'Reply';

  @override
  String get commentsViewReplies => 'View replies';

  @override
  String commentsLoadMoreReplies(int count) {
    return 'Load $count more';
  }

  @override
  String get siteEngagementQueuedOfflineSnack =>
      'Connection dropped. We will retry this when you are back online.';

  @override
  String get commentsHideReplies => 'Hide replies';

  @override
  String get commentsStatusDeleting => 'Deleting…';

  @override
  String get commentsStatusSavingEdits => 'Saving edits…';

  @override
  String get commentsCommentMetaJustNow => 'Just now';

  @override
  String commentsCommentMetaJustNowWithLikes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Just now • $count likes',
      one: 'Just now • 1 like',
    );
    return '$_temp0';
  }

  @override
  String commentsCommentMetaMinutesAgo(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String commentsCommentMetaMinutesAgoWithLikes(int minutes, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes ago',
      one: '1 minute ago',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count likes',
      one: '1 like',
    );
    return '$_temp0 • $_temp1';
  }

  @override
  String commentsCommentMetaHoursAgo(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String commentsCommentMetaHoursAgoWithLikes(int hours, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours ago',
      one: '1 hour ago',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count likes',
      one: '1 like',
    );
    return '$_temp0 • $_temp1';
  }

  @override
  String commentsCommentMetaDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String commentsCommentMetaDaysAgoWithLikes(int days, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days ago',
      one: '1 day ago',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count likes',
      one: '1 like',
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
      other: '$count likes',
      one: '1 like',
    );
    return '$date • $_temp0';
  }

  @override
  String get commentsOptimisticAuthorYou => 'You';

  @override
  String commentsReplyingToBanner(String name) {
    return 'Replying to $name';
  }

  @override
  String get commentsSemanticSheetDragHandle => 'Resize or dismiss comments';

  @override
  String get commentsPrefetchCouldNotRefreshSnack =>
      'Could not refresh comments. Showing the last loaded thread.';

  @override
  String commentsComposerCharsRemaining(int remaining) {
    String _temp0 = intl.Intl.pluralLogic(
      remaining,
      locale: localeName,
      other: '$remaining characters left',
      one: '1 character left',
    );
    return '$_temp0';
  }

  @override
  String commentsSemanticHideReplies(String name) {
    return 'Hide replies for $name';
  }

  @override
  String commentsSemanticViewReplies(String name) {
    return 'View replies for $name';
  }

  @override
  String get commentsInputHintEdit => 'Edit your comment…';

  @override
  String get commentsInputHintAdd => 'Add a comment…';

  @override
  String get commentsInputHintReply => 'Write a reply…';

  @override
  String get commentsLikeTooltip => 'Like comment';

  @override
  String get commentsUnlikeTooltip => 'Unlike comment';

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
  String get reportDetailViewOnMap => 'View on map';

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
  String get reportStatusUnderReviewShort => 'Under review';

  @override
  String get reportStatusApprovedShort => 'Approved';

  @override
  String get reportStatusDeclinedShort => 'Declined';

  @override
  String get reportStatusAlreadyReportedShort => 'Already reported';

  @override
  String get reportListFilterAll => 'All';

  @override
  String get reportListOptimisticPill => 'Submitting…';

  @override
  String get reportListFilterSemanticPrefix => 'Report status';

  @override
  String get reportListHeaderTitle => 'Your reports';

  @override
  String reportListHeaderTotalPill(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reports in total',
      one: '1 report in total',
    );
    return '$_temp0';
  }

  @override
  String reportListHeaderUnderReviewPill(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count under review',
      one: '1 under review',
    );
    return '$_temp0';
  }

  @override
  String reportListHeaderSemanticSummary(int totalReports, int underReview) {
    String _temp0 = intl.Intl.pluralLogic(
      totalReports,
      locale: localeName,
      other: '$totalReports reports in total',
      one: '1 report in total',
    );
    String _temp1 = intl.Intl.pluralLogic(
      underReview,
      locale: localeName,
      other: '$underReview currently under review',
      one: '1 currently under review',
    );
    return '$_temp0. $_temp1.';
  }

  @override
  String get reportListFilteredFooterAll => 'All reports shown';

  @override
  String reportListFilteredFooterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reports',
      one: '1 report',
    );
    return '$_temp0';
  }

  @override
  String get reportListNoMatchesSearchTitle => 'No reports found';

  @override
  String get reportListNoMatchesFilterTitle => 'No reports with this filter';

  @override
  String get reportListNoMatchesHintSearchAndFilter =>
      'Try a different search or clear filters to see more reports.';

  @override
  String get reportListNoMatchesHintSearchOnly =>
      'Check the spelling or try a broader search.';

  @override
  String get reportListNoMatchesHintFilterOnly =>
      'Try another filter, or clear it to see all reports.';

  @override
  String get reportListClearSearch => 'Clear search';

  @override
  String reportListDateWeeksAgo(int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks weeks ago',
      one: '1 week ago',
    );
    return '$_temp0';
  }

  @override
  String get reportDetailOpeningInProgress => 'Opening…';

  @override
  String get reportDetailNoPhotos => 'No photos';

  @override
  String get reportDetailStatusUnderReviewTitle => 'Under review by moderators';

  @override
  String get reportDetailStatusUnderReviewBody =>
      'Moderators are checking your evidence and location before they decide how to handle this report.';

  @override
  String get reportDetailStatusApprovedTitle => 'Approved and linked to a site';

  @override
  String get reportDetailStatusApprovedBody =>
      'This report helped confirm a public pollution site and may contribute to cleanup actions.';

  @override
  String get reportDetailStatusAlreadyReportedTitle =>
      'Already tracked as an existing site';

  @override
  String get reportDetailStatusAlreadyReportedBody =>
      'Your report matched an existing site. The evidence is still useful for understanding the problem.';

  @override
  String get reportDetailStatusOutcomeTitle => 'Review outcome';

  @override
  String get reportDetailStatusOutcomeBodyFallback =>
      'This report could not be approved in its current form.';

  @override
  String get reportDetailSheetTitle => 'Report details';

  @override
  String get reportDetailSheetSubtitle =>
      'See what you submitted and how moderators handled this report.';

  @override
  String reportDetailSheetSubtitleWithNumber(String reportNumber) {
    return '$reportNumber · See what you submitted and how moderators handled this report.';
  }

  @override
  String get reportDetailPhotoAttachedPill => 'Photo attached';

  @override
  String get reportDetailPointsLabel => 'Points';

  @override
  String reportDetailEvidencePhotoSemantic(int index) {
    return 'Evidence photo $index';
  }

  @override
  String get reportDetailEvidenceGalleryOpenSemantic =>
      'Open report evidence photos';

  @override
  String get reportDetailEvidenceTapToExpand => 'Tap to expand';

  @override
  String get reportDetailEvidenceOpenPhoto => 'Open photo';

  @override
  String get reportDetailSiteNotFoundOpeningMaps =>
      'Site not found. Opening in maps.';

  @override
  String get reportDetailSiteNotAvailable => 'Site not available.';

  @override
  String get reportDetailCouldNotLoadSite => 'Could not load site.';

  @override
  String get reportCardDeclineNoteTitle => 'Review note';

  @override
  String reportListFilterChipSemantic(String label, int selected) {
    String _temp0 = intl.Intl.pluralLogic(
      selected,
      locale: localeName,
      other: 'not selected',
      one: 'selected',
    );
    return '$label filter, $_temp0';
  }

  @override
  String reportListFilterChipHint(String label) {
    return 'Double-tap to filter reports by $label.';
  }

  @override
  String get reportReviewTitleHint => 'Brief headline';

  @override
  String get reportFlowCameraUnavailableSnack =>
      'Unable to open the camera right now. Please try again in a moment.';

  @override
  String get reportSemanticsLocationPinThenConfirm =>
      'Location: pin, then confirm.';

  @override
  String get newReportTooltipAboutStep => 'About this step';

  @override
  String get newReportTooltipDismiss => 'Dismiss';

  @override
  String get reportFlowSubmitPhaseCreating => 'Creating…';

  @override
  String get reportFlowSubmitPhaseUploading => 'Uploading…';

  @override
  String get reportFlowSubmitPhaseSubmitting => 'Submitting…';

  @override
  String get reportFormPrimarySemanticsHintSubmit => 'Double-tap to submit.';

  @override
  String get reportFormPrimarySemanticsHintNext =>
      'Double-tap to go to the next step.';

  @override
  String reportCardSemanticLabel(
    String category,
    String status,
    String location,
  ) {
    return '$category, $status, $location. Tap to view details.';
  }

  @override
  String get appSmartImageUnavailable => 'Image unavailable';

  @override
  String get eventsReminderSectionTitle => 'Event reminder';

  @override
  String get eventsReminderSectionEnabled => 'Reminder is on';

  @override
  String eventsReminderSectionSetFor(String time) {
    return 'Set for $time';
  }

  @override
  String get eventsReminderSectionDisabled =>
      'Get notified before event starts';

  @override
  String get eventsReminderSectionDisable => 'Disable';

  @override
  String get eventsReminderSectionEnable => 'Enable';

  @override
  String get eventsDescriptionTitle => 'About';

  @override
  String get eventsDescriptionShowLess => 'Show less';

  @override
  String get eventsDescriptionReadMore => 'Read more';

  @override
  String get eventsAfterCleanupTitle => 'After cleanup';

  @override
  String eventsAfterPhotoSemantic(int index, int total) {
    return 'View after cleanup photo $index of $total';
  }

  @override
  String get eventsFilterAll => 'All';

  @override
  String get eventsFilterUpcoming => 'Upcoming';

  @override
  String get eventsFilterNearby => 'Nearby';

  @override
  String get eventsFilterPast => 'Past';

  @override
  String get eventsFilterMyEvents => 'My events';

  @override
  String get eventsFilterSemanticPrefix => 'Events';

  @override
  String get eventsParticipantsTitle => 'Attendees';

  @override
  String eventsParticipantsViewSemantic(int count) {
    return 'View $count attendees';
  }

  @override
  String eventsParticipantsYouAndOthers(int count) {
    return 'You and $count others joined';
  }

  @override
  String eventsParticipantsVolunteersJoined(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count volunteers joined',
      one: '1 volunteer joined',
    );
    return '$_temp0';
  }

  @override
  String eventsParticipantsSpotsLeft(int count) {
    return '$count spots left';
  }

  @override
  String eventsParticipantsCheckedInCount(int checkedIn, int total) {
    return '$checkedIn of $total checked in';
  }

  @override
  String get eventsParticipantsSearchPlaceholder => 'Search attendee';

  @override
  String get eventsParticipantsNoSearchResults =>
      'No attendee matches your search.';

  @override
  String get eventsParticipantsYouOrganizer => 'You · Organizer';

  @override
  String get eventsParticipantsOrganizer => 'Organizer';

  @override
  String get eventsParticipantsYou => 'You';

  @override
  String get eventsParticipantsLoadFailed =>
      'Couldn\'t load attendees. Check your connection and try again.';

  @override
  String get eventsParticipantsRetry => 'Retry';

  @override
  String get eventsParticipantsViewRosterSemantic => 'View attendee list';

  @override
  String get eventsGearSectionTitle => 'Gear to bring';

  @override
  String get eventsGearNoneNeeded => 'No special gear needed';

  @override
  String get eventsImpactSummaryTitle => 'Impact summary';

  @override
  String get eventsImpactSummaryAdd => 'Add';

  @override
  String get eventsImpactSummaryEdit => 'Edit';

  @override
  String get eventsImpactSummaryEmptyHint =>
      'Note results and lessons from this cleanup.';

  @override
  String get eventsLivePulseTitle => 'Live impact';

  @override
  String eventsLivePulseVolunteers(int count) {
    return '$count joined';
  }

  @override
  String eventsLivePulseCheckIns(int count) {
    return '$count checked in';
  }

  @override
  String eventsLivePulseBags(int count, String kg) {
    return '$count bags · est. $kg kg';
  }

  @override
  String get eventsEvidenceStripTitle => 'Field proof';

  @override
  String get eventsEvidenceStripSubtitle =>
      'Photos from the cleanup evidence feed.';

  @override
  String get eventsEvidenceStripSemantic =>
      'Before, after, and field photos from the evidence feed';

  @override
  String get eventsEvidenceKindBefore => 'Before';

  @override
  String get eventsEvidenceKindAfter => 'After';

  @override
  String get eventsEvidenceKindField => 'Field';

  @override
  String eventsEvidenceStripTileSemantic(int index, int total, String kind) {
    return 'Photo $index of $total, $kind';
  }

  @override
  String get eventsRouteProgressTitle => 'Route';

  @override
  String eventsFieldModeRowServerError(String code) {
    return 'Server: $code';
  }

  @override
  String get eventsFieldModeTitle => 'Field mode';

  @override
  String get eventsFieldModeSync => 'Sync now';

  @override
  String get eventsFieldModeEmpty => 'Nothing queued offline.';

  @override
  String get eventsFieldModeSynced => 'Queue synced.';

  @override
  String get eventsFieldModeSyncFailed =>
      'Could not sync. Try again when online.';

  @override
  String eventsFieldModeSyncPartial(int synced, int failed) {
    return 'Synced $synced update(s). $failed still in the offline queue.';
  }

  @override
  String eventsFieldModeRowLiveImpactBags(int count) {
    return 'Live impact · $count bags';
  }

  @override
  String get eventsFieldModeRowUnknown => 'Offline change';

  @override
  String get eventsFieldModeRowStatusPending => 'Pending';

  @override
  String get eventsFieldModeRowStatusSyncing => 'Syncing';

  @override
  String get eventsOfflineWorkHubTitle => 'Offline work';

  @override
  String get eventsOfflineWorkHubSemanticSheet =>
      'Offline work summary and sync actions';

  @override
  String get eventsOfflineWorkSubtitle =>
      'Queued changes across check-ins, field updates, and chat.';

  @override
  String get eventsOfflineWorkSectionCheckIns => 'Check-ins';

  @override
  String get eventsOfflineWorkSectionField => 'Field updates';

  @override
  String get eventsOfflineWorkSectionChat => 'Chat';

  @override
  String eventsOfflineWorkCountPending(int count) {
    return '$count pending';
  }

  @override
  String eventsOfflineWorkCountFailed(int count) {
    return '$count need attention';
  }

  @override
  String get eventsOfflineWorkSyncNow => 'Sync now';

  @override
  String get eventsOfflineWorkOpenFieldQueue => 'Open field queue';

  @override
  String get eventsOfflineWorkOpenChat => 'Open event chat';

  @override
  String get eventsOfflineWorkRetryFailedChat => 'Retry failed chat sends';

  @override
  String get eventsOfflineWorkResolveInChat =>
      'Open the chat and fix or delete the message that could not be sent.';

  @override
  String get eventsOfflineWorkSyncDone => 'Sync finished';

  @override
  String get eventsOfflineWorkSyncing => 'Syncing…';

  @override
  String get eventsOfflineWorkDrainFailed =>
      'Could not finish syncing. Try again when you are online.';

  @override
  String eventsChatOutboxFull(int max) {
    return 'Too many messages are waiting to send offline (limit $max). Go online to send pending messages, then try again.';
  }

  @override
  String get eventsCompletedBagsSectionTitle => 'Trash bags collected';

  @override
  String get eventsCompletedBagsSave => 'Save';

  @override
  String get eventsCompletedBagsSaved => 'Bag count saved.';

  @override
  String eventsImpactBadgeRating(int rating) {
    return '$rating★ rating';
  }

  @override
  String eventsImpactBadgeBags(int count) {
    return '$count bags';
  }

  @override
  String eventsImpactBadgeHours(String hours) {
    return '${hours}h';
  }

  @override
  String eventsImpactEstimatedLine(String kg, String co2) {
    return '$kg kg removed · $co2 kg CO2e avoided';
  }

  @override
  String eventsLocationSiteSemantic(String distanceKm) {
    return 'View pollution site, $distanceKm km away';
  }

  @override
  String eventsLocationDotKm(String distanceKm) {
    return '· $distanceKm km';
  }

  @override
  String get eventsEmptyAllTitle => 'No eco events yet';

  @override
  String get eventsEmptyAllSubtitle =>
      'Be the first to create one! Tap + above to get started.';

  @override
  String get eventsEmptyUpcomingTitle => 'No upcoming events';

  @override
  String get eventsEmptyUpcomingSubtitle =>
      'Create one to get volunteers together.';

  @override
  String get eventsEmptyNearbyTitle => 'No nearby events';

  @override
  String get eventsEmptyNearbySubtitle =>
      'Try a different filter or create an event in your area.';

  @override
  String get eventsEmptyPastTitle => 'No past events';

  @override
  String get eventsEmptyPastSubtitle => 'Completed events will show here.';

  @override
  String get eventsEmptyMyEventsTitle => 'No events yet';

  @override
  String get eventsEmptyMyEventsSubtitle =>
      'Join or create an event to see it here.';

  @override
  String eventsSearchEmptyTitle(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get eventsSearchEmptySubtitle =>
      'Try a different search term or check your spelling.';

  @override
  String get eventsSearchEmptyScopeHint =>
      'Matches come from the server as you type and from events already loaded in this list.';

  @override
  String get eventsSitePickerTitle => 'Choose site';

  @override
  String get eventsSitePickerSubtitle =>
      'Anchor this event to one cleanup location.';

  @override
  String get eventsSitePickerSearchPlaceholder =>
      'Search by name or description';

  @override
  String eventsSitePickerNoMatch(String query) {
    return 'No sites match \"$query\"';
  }

  @override
  String eventsSitePickerRowKmDesc(String km, String desc) {
    return '$km km away · $desc';
  }

  @override
  String get eventsSuccessDialogTitle => 'Event created';

  @override
  String eventsSuccessDialogBody(String title, String siteName) {
    return '$title at $siteName is ready. Share it with your community to get volunteers on board.';
  }

  @override
  String get eventsSuccessDialogOpenEvent => 'Open event';

  @override
  String get eventsSuccessDialogViewEvent => 'View event';

  @override
  String get eventsSuccessDialogPendingTitle => 'Submitted for review';

  @override
  String eventsSuccessDialogPendingBody(String title, String siteName) {
    return '$title at $siteName was submitted. A moderator will approve or decline it before it appears publicly. You can open it from your events anytime.';
  }

  @override
  String get eventsTimePickerSelectTime => 'Select time';

  @override
  String get eventsTimePickerConfirm => 'Confirm';

  @override
  String get eventsTimePickerFrom => 'From';

  @override
  String get eventsTimePickerTo => 'To';

  @override
  String eventsTimePickerTimeBlockSemantic(String role, String time) {
    return '$role, $time';
  }

  @override
  String eventsFeedbackRatingStars(int rating) {
    return '$rating★';
  }

  @override
  String get eventsFeedRecentSearches => 'Recent searches';

  @override
  String get eventsCleanupAfterUploadSemantic => 'Upload after photos';

  @override
  String get eventsCleanupAfterViewFullscreenSemantic =>
      'View photo fullscreen';

  @override
  String get eventsCleanupAfterUploadMoreTitle => 'Upload more photos';

  @override
  String eventsCleanupAfterUploadedCount(int count) {
    return '$count uploaded';
  }

  @override
  String eventsCleanupAfterSlotsRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more slots available',
      one: '1 more slot available',
    );
    return '$_temp0';
  }

  @override
  String get eventsCleanupAfterAddMoreSemantic => 'Add more photos';

  @override
  String get eventsCleanupAfterRemoveSemantic => 'Remove photo';

  @override
  String get eventsCleanupAfterEmptyTitle => 'Add photos of the cleaned site';

  @override
  String eventsCleanupAfterEmptyMaxPhotos(int max) {
    return 'Up to $max photos';
  }

  @override
  String get eventsCleanupAfterEmptyTapGallery => 'Tap to select from gallery';

  @override
  String get eventsCleanupEvidencePhotoSemantic => 'Cleanup evidence photo';

  @override
  String get eventsDateRelativeEarlierToday => 'Earlier today';

  @override
  String eventsDateRelativeDaysAgo(int days) {
    return '$days days ago';
  }

  @override
  String get eventsDateRelativeToday => 'Today';

  @override
  String get eventsDateRelativeTomorrow => 'Tomorrow';

  @override
  String eventsDateRelativeInDays(int days) {
    return 'In $days days';
  }

  @override
  String get eventsDateInfoSheetTitle => 'Date and time';

  @override
  String eventsDateInfoSemantic(String date, String timeRange) {
    return '$date, $timeRange';
  }

  @override
  String get eventsCategorySheetTitle => 'Category';

  @override
  String eventsCategorySemantic(String label) {
    return 'Event category: $label';
  }

  @override
  String get eventsOrganizerSheetTitle => 'Organizer';

  @override
  String get eventsOrganizerYouOwnThis => 'This is your event';

  @override
  String get eventsOrganizerRoleLabel => 'Event organizer';

  @override
  String eventsOrganizerCreatedOn(int day, int month, int year) {
    return 'Event created on $day/$month/$year';
  }

  @override
  String eventsOrganizerSemantic(String name) {
    return 'Organizer: $name';
  }

  @override
  String get eventsOrganizedByLabel => 'Organized by';

  @override
  String get eventsFeedSemantic => 'Events feed';

  @override
  String get eventsFeedTitle => 'Events';

  @override
  String get eventsFeedCreateSemantic => 'Create event';

  @override
  String get eventsFeedSearchPlaceholder => 'Search events';

  @override
  String get eventsFeedHappeningNow => 'Happening now';

  @override
  String get eventsFeedComingUp => 'Coming up';

  @override
  String get eventsFeedRecentlyCompleted => 'Recently completed';

  @override
  String get eventsFeedViewListToggle => 'List view';

  @override
  String get eventsFeedViewCalendarToggle => 'Calendar view';

  @override
  String get eventsCalendarPreviousMonth => 'Previous month';

  @override
  String get eventsCalendarNextMonth => 'Next month';

  @override
  String eventsCalendarDaySemantic(int day) {
    return 'Day $day';
  }

  @override
  String get eventsCalendarNoEventsThisDay => 'No events on this day';

  @override
  String get eventsCalendarIncompleteListHint =>
      'More events may be available. Load the next page to fill this month.';

  @override
  String get eventsCalendarLoadMoreButton => 'Load more';

  @override
  String eventsCalendarDayA11yOutOfMonth(int day) {
    return 'Day $day, not in this month';
  }

  @override
  String eventsCalendarDayA11y(int day) {
    return 'Day $day';
  }

  @override
  String eventsCalendarDayA11yHasEvents(int day) {
    return 'Day $day, has events';
  }

  @override
  String eventsCalendarDayA11ySelected(int day) {
    return 'Day $day, selected';
  }

  @override
  String eventsCalendarDayA11ySelectedHasEvents(int day) {
    return 'Day $day, selected, has events';
  }

  @override
  String get eventsEmptyActionClearFilters => 'Clear filters';

  @override
  String get eventsEmptyActionCreateEvent => 'Create event';

  @override
  String get eventsSearchEmptyClearSearch => 'Clear search';

  @override
  String siteCardPollutionSiteSemantic(String title) {
    return 'Pollution site: $title. Tap to open details.';
  }

  @override
  String siteCardPhotoSemantic(String title) {
    return 'Photo of $title';
  }

  @override
  String siteCardGalleryPhotoSemantic(int number, String siteTitle) {
    return 'Photo $number of $siteTitle';
  }

  @override
  String siteCardSemanticRemoveUpvote(String title) {
    return 'Remove upvote for $title';
  }

  @override
  String siteCardSemanticUpvote(String title) {
    return 'Upvote $title';
  }

  @override
  String get siteUpvoteLongPressOpensSupporters =>
      'Long press to open the list of supporters';

  @override
  String siteCardSemanticUpvotesOpenSupporters(int count, String title) {
    return '$count upvotes on $title. Tap to see supporters';
  }

  @override
  String siteCardSemanticCommentsOnSite(int count, String title) {
    return '$count comments on $title';
  }

  @override
  String siteCardSemanticSharesOnSite(int count, String title) {
    return '$count shares on $title';
  }

  @override
  String siteCardSemanticSaveSite(String title) {
    return 'Save $title and get updates';
  }

  @override
  String siteCardSemanticUnsaveSite(String title) {
    return 'Unsave $title and stop updates';
  }

  @override
  String get siteCardSaveUpdatesOnSnack => 'You will get updates for this site';

  @override
  String get siteCardSaveRemovedSnack => 'Removed from your saved sites';

  @override
  String get siteCardFeedbackPostHiddenSnack => 'Post hidden from your feed';

  @override
  String get siteCardFeedbackThanksSnack => 'Thanks for your feedback';

  @override
  String get siteCardFeedOptionsSheetTitle => 'Feed options';

  @override
  String get siteCardFeedOptionsSheetSubtitle => 'Tune what you want to see';

  @override
  String get siteCardEngagementSignInRequired =>
      'Sign in to support or save sites.';

  @override
  String get siteCardEngagementWaitBriefly =>
      'Please wait a moment before trying again.';

  @override
  String siteCardRateLimitedSnack(int seconds) {
    return 'Too many actions. Try again in $seconds seconds.';
  }

  @override
  String get siteDetailSaveAddedSnack => 'Site saved to your list.';

  @override
  String get siteDetailSaveRemovedSnack => 'Removed from saved sites.';

  @override
  String get siteQuickActionSaveSiteLabel => 'Save site';

  @override
  String get siteQuickActionSavedLabel => 'Saved';

  @override
  String get siteQuickActionReportIssueLabel => 'Report issue';

  @override
  String get siteQuickActionReportedLabel => 'Reported';

  @override
  String get siteQuickActionShareLabel => 'Share';

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
  String get eventsFilterSheetTitle => 'Filter events';

  @override
  String get eventsFilterSheetCategory => 'Category';

  @override
  String get eventsFilterSheetStatus => 'Status';

  @override
  String get eventsFilterSheetDateRange => 'Date range';

  @override
  String get eventsFilterSheetDateFrom => 'From';

  @override
  String get eventsFilterSheetDateTo => 'To';

  @override
  String get eventsFilterSheetShowResults => 'Show results';

  @override
  String get eventsFilterSheetClearAll => 'Clear all';

  @override
  String eventsFilterSheetActiveCount(int count) {
    return '$count active';
  }

  @override
  String get eventsOrganizerDashboardTitle => 'My events';

  @override
  String get eventsOrganizerDashboardEmpty =>
      'You haven\'t organised any events yet.';

  @override
  String get eventsOrganizerDashboardEmptyAction => 'Create first event';

  @override
  String get eventsOrganizerDashboardSectionUpcoming => 'Upcoming';

  @override
  String get eventsOrganizerDashboardSectionInProgress => 'In progress';

  @override
  String get eventsOrganizerDashboardSectionCompleted => 'Completed';

  @override
  String get eventsOrganizerDashboardSectionCancelled => 'Cancelled';

  @override
  String eventsOrganizerDashboardParticipants(int count, String max) {
    return '$count/$max participants';
  }

  @override
  String eventsOrganizerDashboardParticipantsUnlimited(int count) {
    return '$count participants';
  }

  @override
  String get eventsOrganizerDashboardEvidenceAction => 'Evidence';

  @override
  String get eventsAnalyticsTitle => 'Analytics';

  @override
  String get eventsAnalyticsAttendanceRate => 'Attendance rate';

  @override
  String get eventsAnalyticsJoiners => 'Joiners over time';

  @override
  String get eventsAnalyticsCheckInsByHour => 'Check-ins by hour';

  @override
  String get eventsAnalyticsNoData => 'No data yet';

  @override
  String get eventsAnalyticsRefresh => 'Refresh analytics';

  @override
  String eventsAnalyticsCheckedInRatio(int checkedInCount, int totalJoiners) {
    return '$checkedInCount of $totalJoiners checked in';
  }

  @override
  String get eventsAnalyticsJoinersEmpty => 'No one has joined this event yet.';

  @override
  String get eventsAnalyticsCheckInsEmpty =>
      'No check-ins yet. Hours are shown in UTC.';

  @override
  String eventsAnalyticsPeakCheckInsUtc(String hour) {
    return 'Peak: $hour UTC';
  }

  @override
  String eventsAnalyticsSemanticsJoinCurve(
    int fromCount,
    int toCount,
    int steps,
  ) {
    return 'Join trend from $fromCount to $toCount participants, $steps data points.';
  }

  @override
  String eventsAnalyticsSemanticsCheckInHeatmap(int peakCount, String hour) {
    return 'Check-ins by hour in UTC. Peak $peakCount at $hour.';
  }

  @override
  String get eventsAnalyticsSemanticsCheckInNoData =>
      'Check-ins by hour in UTC. No check-ins recorded.';

  @override
  String get eventsOfflineSyncQueued => 'Saved. Will sync when back online.';

  @override
  String get eventsOfflineSyncFailed =>
      'Sync failed. Will retry automatically.';

  @override
  String get eventsWeatherForecast => 'Weather forecast';

  @override
  String get eventsWeatherLoadFailed => 'Weather unavailable';

  @override
  String eventsWeatherPrecipitationMm(String amount) {
    return '$amount mm precipitation';
  }

  @override
  String get eventsWeatherNoPrecipitation => 'No measurable precipitation';

  @override
  String eventsWeatherPrecipChance(int percent) {
    return '$percent% chance of precipitation';
  }

  @override
  String get eventsWeatherIndicativeNote =>
      'Indicative forecast from Open-Meteo; actual conditions may differ.';

  @override
  String get eventsWeatherIndicativeInfoTitle => 'About this forecast';

  @override
  String get eventsWeatherIndicativeInfoSemantic =>
      'Information about the weather forecast source';

  @override
  String get eventsRecurrenceNone => 'Does not repeat';

  @override
  String get eventsRecurrenceWeekly => 'Every week';

  @override
  String get eventsRecurrenceBiweekly => 'Every 2 weeks';

  @override
  String get eventsRecurrenceMonthly => 'Every month';

  @override
  String eventsRecurrenceOccurrences(int count) {
    return '$count occurrences';
  }

  @override
  String get eventsRecurrencePartOfSeries => 'Part of a series';

  @override
  String eventsRecurrenceSeriesLabel(int index, int total) {
    return 'Event $index of $total';
  }

  @override
  String get eventsRecurrenceDone => 'Done';

  @override
  String get eventsCategoryGeneralCleanup => 'General cleanup';

  @override
  String get eventsCategoryGeneralCleanupDescription =>
      'Pick up litter, sweep debris, and restore the area.';

  @override
  String get eventsCategoryRiverAndLake => 'River & lake cleanup';

  @override
  String get eventsCategoryRiverAndLakeDescription =>
      'Remove waste from waterways, shores, and drainage channels.';

  @override
  String get eventsCategoryTreeAndGreen => 'Tree planting & greening';

  @override
  String get eventsCategoryTreeAndGreenDescription =>
      'Plant trees, restore green spaces, and build garden beds.';

  @override
  String get eventsCategoryRecyclingDrive => 'Recycling drive';

  @override
  String get eventsCategoryRecyclingDriveDescription =>
      'Sort, collect, and transport recyclables to processing centers.';

  @override
  String get eventsCategoryHazardousRemoval => 'Hazardous waste removal';

  @override
  String get eventsCategoryHazardousRemovalDescription =>
      'Safely collect chemicals, tires, batteries, or asbestos.';

  @override
  String get eventsCategoryAwarenessAndEducation => 'Awareness & education';

  @override
  String get eventsCategoryAwarenessAndEducationDescription =>
      'Workshops, talks, or community engagement on eco practices.';

  @override
  String get eventsCategoryOther => 'Other';

  @override
  String get eventsCategoryOtherDescription =>
      'Custom event that doesn\'t match the categories above.';

  @override
  String get eventsGearTrashBags => 'Trash bags';

  @override
  String get eventsGearGloves => 'Gloves';

  @override
  String get eventsGearRakes => 'Rakes & shovels';

  @override
  String get eventsGearWheelbarrow => 'Wheelbarrow';

  @override
  String get eventsGearWaterBoots => 'Water boots';

  @override
  String get eventsGearSafetyVest => 'Safety vest';

  @override
  String get eventsGearFirstAid => 'First aid kit';

  @override
  String get eventsGearSunscreen => 'Sunscreen & water';

  @override
  String get eventsScaleSmall => 'Small (1–5 people)';

  @override
  String get eventsScaleSmallDescription =>
      'Quick spot cleanup, one bag or two.';

  @override
  String get eventsScaleMedium => 'Medium (6–15 people)';

  @override
  String get eventsScaleMediumDescription =>
      'Half-day effort, several areas covered.';

  @override
  String get eventsScaleLarge => 'Large (16–40 people)';

  @override
  String get eventsScaleLargeDescription =>
      'Organized group, heavy waste removal.';

  @override
  String get eventsScaleMassive => 'Massive (40+ people)';

  @override
  String get eventsScaleMassiveDescription => 'City-wide or multi-site event.';

  @override
  String get eventsDifficultyEasy => 'Easy';

  @override
  String get eventsDifficultyEasyDescription =>
      'Flat terrain, light waste, family-friendly.';

  @override
  String get eventsDifficultyModerate => 'Moderate';

  @override
  String get eventsDifficultyModerateDescription =>
      'Mixed terrain or bulky items, some effort.';

  @override
  String get eventsDifficultyHard => 'Hard';

  @override
  String get eventsDifficultyHardDescription =>
      'Steep slopes, heavy debris, or hazardous materials.';

  @override
  String get eventsSiteCoercedDescription => 'Community cleanup site';

  @override
  String get homeSiteCleaningEmptyTitle => 'No cleaning events yet';

  @override
  String get homeSiteCleaningEmptyBody =>
      'Be the first to organize an eco action and rally volunteers for this site.';

  @override
  String get homeSiteCleaningTapToCreate => 'Tap to create';

  @override
  String get homeSiteCleaningCtaCreateFirst => 'Create eco action';

  @override
  String get homeSiteCleaningCtaScheduleAnother => 'Schedule another action';

  @override
  String homeSiteCleaningVolunteersJoined(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count volunteers joined',
      one: '1 volunteer joined',
    );
    return '$_temp0';
  }

  @override
  String get homeSiteCleaningOrganizerHint =>
      'You\'re organizing this action. Upload \"after\" photos once it\'s completed.';

  @override
  String get homeSiteCleaningVolunteerHint =>
      'Join the action to help clean this site.';

  @override
  String get homeSiteCleaningJoinAction => 'Join action';

  @override
  String get homeSiteCleaningEventUnavailable =>
      'Event details are unavailable right now.';

  @override
  String get homeSiteCleaningListLoadError =>
      'Could not load events. Check your connection and try again.';

  @override
  String get homeSiteCleaningRetry => 'Retry';

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
  String get errorUserNetwork => 'Check your connection and try again.';

  @override
  String get errorUserTimeout => 'That took too long. Please try again.';

  @override
  String get errorUserUnauthorized => 'Please sign in again to continue.';

  @override
  String get errorUserForbidden => 'You don’t have permission to do that.';

  @override
  String get errorUserNotFound => 'We couldn’t find that.';

  @override
  String get errorUserServer =>
      'The service is busy. Please try again shortly.';

  @override
  String get errorUserTooManyRequests =>
      'Too many attempts. Please wait a moment.';

  @override
  String get errorUserUnknown => 'Something went wrong. Please try again.';

  @override
  String get eventsFilterSheetSemantic => 'Filter events';

  @override
  String get eventChatTitle => 'Chat';

  @override
  String get eventChatRowTitle => 'Group chat';

  @override
  String get eventChatInputHint => 'Message';

  @override
  String get eventChatSend => 'Send';

  @override
  String get eventChatEmptyTitle => 'Start the conversation';

  @override
  String get eventChatEmptyBody =>
      'Coordinate with other volunteers before and during the event.';

  @override
  String get eventChatMessageRemoved => 'This message was removed';

  @override
  String get eventChatNewMessages => 'New messages';

  @override
  String get eventChatToday => 'Today';

  @override
  String get eventChatYesterday => 'Yesterday';

  @override
  String get eventChatReply => 'Reply';

  @override
  String get eventChatDelete => 'Delete';

  @override
  String get eventChatLoadError => 'Could not load messages';

  @override
  String get eventChatSendFailed => 'Message not sent. Tap to retry.';

  @override
  String get eventChatOpenMapsFailed => 'Couldn’t open Maps. Try again.';

  @override
  String get eventChatAttachPhotoLibrary => 'Photo Library';

  @override
  String get eventChatAttachCamera => 'Camera';

  @override
  String get eventChatAttachVideo => 'Video';

  @override
  String get eventChatAttachDocument => 'Document';

  @override
  String get eventChatAttachAudio => 'Audio';

  @override
  String get eventChatVoiceDiscard => 'Discard recording';

  @override
  String get eventChatVoiceSend => 'Send voice message';

  @override
  String get eventChatVoicePreviewHint => 'Voice preview';

  @override
  String get eventChatAttachLocation => 'Share Location';

  @override
  String get eventChatSendLocation => 'Send Location';

  @override
  String get eventChatSending => 'Sending…';

  @override
  String eventChatReplyingTo(String name) {
    return 'Replying to $name';
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
  String get eventChatInputSemantics => 'Chat message';

  @override
  String get eventChatMessagesListSemantics => 'Messages list';

  @override
  String get eventChatAttachmentsNeedNetwork =>
      'Photos, video, files, and voice require an internet connection.';

  @override
  String get eventChatPushChannelName => 'Event chat';

  @override
  String get eventChatEdited => '(edited)';

  @override
  String get eventChatEditMessage => 'Edit';

  @override
  String get eventChatEditing => 'Editing message';

  @override
  String get eventChatEditHint => 'Edit your message';

  @override
  String get eventChatSaveEdit => 'Save';

  @override
  String get eventChatPinMessage => 'Pin';

  @override
  String get eventChatUnpinMessage => 'Unpin';

  @override
  String eventChatPinnedBy(String name) {
    return 'Pinned by $name';
  }

  @override
  String get eventChatPinnedMessagesTitle => 'Pinned messages';

  @override
  String get eventChatPinnedBarHint => 'Pinned';

  @override
  String get eventChatNoPinnedMessages => 'No pinned messages';

  @override
  String get eventChatMuted => 'Notifications muted';

  @override
  String get eventChatUnmuted => 'Notifications unmuted';

  @override
  String get eventChatCopied => 'Message copied';

  @override
  String get eventChatReconnecting => 'Reconnecting…';

  @override
  String get eventChatConnected => 'Connected';

  @override
  String get eventChatSearchHint => 'Search messages';

  @override
  String get eventChatSearchNoResults => 'No matching messages';

  @override
  String get eventChatSearchAction => 'Search';

  @override
  String get eventChatSearchFailed =>
      'Could not search messages. Check your connection and try again.';

  @override
  String get eventChatSearchMinChars => 'Type at least 2 characters to search.';

  @override
  String get eventChatSearchIncludingLocalMatches =>
      'Including messages loaded on this device.';

  @override
  String get eventChatSearchLoadMore => 'Load more results';

  @override
  String eventChatParticipantsCount(int count) {
    return '$count participants';
  }

  @override
  String get eventChatParticipantsSheetTitle => 'People in this chat';

  @override
  String eventChatParticipantsTitleSemantic(String eventTitle, int count) {
    return '$eventTitle, $count participants';
  }

  @override
  String get eventChatParticipantsLoadError => 'Couldn’t load participants.';

  @override
  String get eventChatParticipantsYouBadge => 'You';

  @override
  String get eventChatParticipantsEmpty => 'No participants loaded yet.';

  @override
  String eventChatSystemUserJoined(String name) {
    return '$name joined the event';
  }

  @override
  String eventChatSystemUserLeft(String name) {
    return '$name left the event';
  }

  @override
  String get eventChatSystemEventUpdated => 'Event details were updated';

  @override
  String get eventChatSwipeReplySemantic => 'Swipe to reply to this message';

  @override
  String get eventChatVoiceLevelSemantic => 'Voice level meter';

  @override
  String get eventChatMessageOptions => 'Message options';

  @override
  String get eventChatTypingUnknownParticipant => 'Someone';

  @override
  String get eventChatCopy => 'Copy';

  @override
  String get eventChatUnpinConfirm => 'Message unpinned';

  @override
  String get eventChatMaxPinnedReached => 'Maximum pinned messages reached';

  @override
  String get eventChatMessageNotInView =>
      'That message isn’t loaded. Scroll up for older messages.';

  @override
  String get eventChatMuteNotifications => 'Mute notifications';

  @override
  String get eventChatUnmuteNotifications => 'Unmute notifications';

  @override
  String eventChatSeenBy(String names) {
    return 'Seen by $names';
  }

  @override
  String eventChatSeenByTruncated(String names, int count) {
    return 'Seen by $names +$count';
  }

  @override
  String eventChatTypingOne(String name) {
    return '$name is typing…';
  }

  @override
  String eventChatTypingTwo(String first, String second) {
    return '$first and $second are typing…';
  }

  @override
  String eventChatTypingMany(String name, int count) {
    return '$name and $count others are typing…';
  }

  @override
  String get eventChatImageViewerTitle => 'Photo';

  @override
  String eventChatImageViewerPage(int current, int total) {
    return '$current of $total';
  }

  @override
  String get eventChatVideoViewerTitle => 'Video';

  @override
  String get eventChatOpenFile => 'Open file';

  @override
  String get eventChatDownloadFailed => 'Couldn’t download the file';

  @override
  String get eventChatPdfOpenFailed => 'Couldn’t open the PDF';

  @override
  String get eventChatShareFile => 'Share';

  @override
  String get eventChatLocationMapTitle => 'Location';

  @override
  String get eventChatCopyCoordinates => 'Copy coordinates';

  @override
  String get eventChatDirections => 'Directions';

  @override
  String get eventChatAudioExpandedTitle => 'Voice message';

  @override
  String get eventChatHoldToRecord => 'Hold to record';

  @override
  String get eventChatReleaseToSend => 'Release to send';

  @override
  String get eventChatSlideToCancel => 'Slide left to cancel';

  @override
  String get eventChatReleaseToCancel => 'Release to cancel';

  @override
  String get eventChatRecording => 'Recording…';

  @override
  String get eventChatMicPermissionDenied =>
      'Microphone access is required to send voice messages.';

  @override
  String get reportEntryLabelGuided => 'Guided report';

  @override
  String get reportEntryLabelCamera => 'Camera report';

  @override
  String get reportEntryHintCamera =>
      'Starting from a live photo can speed up moderation because the evidence is already attached.';

  @override
  String get homeReportingCapacityCheckFailed =>
      'Could not check reporting availability right now.';

  @override
  String get homeCameraOpenFailed =>
      'Unable to open the camera right now. Please try again in a moment.';

  @override
  String get mapTabPlaceholderHint =>
      'Open this tab to load the live map and nearby pollution sites.';

  @override
  String get reportCategoryPickerTitle => 'Choose category';

  @override
  String get reportCategoryPickerSubtitle =>
      'Pick the closest match for the issue you are reporting.';

  @override
  String get reportCategoryPickerBannerTitle => 'Choose the closest match';

  @override
  String get reportCategoryPickerBannerBody =>
      'Pick the category moderators should verify first. It does not need to be perfect.';

  @override
  String get reportCategoryIllegalLandfillTitle => 'Illegal landfill';

  @override
  String get reportCategoryIllegalLandfillDescription =>
      'Dumped waste, trash piles, or informal disposal sites.';

  @override
  String get reportCategoryWaterPollutionTitle => 'Water pollution';

  @override
  String get reportCategoryWaterPollutionDescription =>
      'Contaminated rivers, lakes, drains, or wastewater discharge.';

  @override
  String get reportCategoryAirPollutionTitle => 'Air pollution';

  @override
  String get reportCategoryAirPollutionDescription =>
      'Smoke, dust, burning waste, or emissions harming air quality.';

  @override
  String get reportCategoryIndustrialWasteTitle => 'Industrial waste';

  @override
  String get reportCategoryIndustrialWasteDescription =>
      'Construction debris, factory waste, or hazardous materials.';

  @override
  String get reportCategoryOtherTitle => 'Other';

  @override
  String get reportCategoryOtherDescription =>
      'Use when the issue does not clearly match the categories above.';

  @override
  String get unknownRouteTitle => 'Page not found';

  @override
  String get unknownRouteMessage =>
      'This link may be out of date or incorrect.';

  @override
  String get unknownRouteContinueButton => 'Continue to the app';

  @override
  String unknownRouteDebugRoute(String routeName) {
    return 'Debug: route name was “$routeName”.';
  }

  @override
  String get chatShareLocation => 'Share Location';

  @override
  String get chatSharedLocation => 'Shared location';

  @override
  String get organizerToolkitTitle => 'Become an organizer';

  @override
  String get organizerToolkitPage1Title => 'Plan ahead';

  @override
  String get organizerToolkitPage1Body =>
      'Assess the site for hazards, prepare safety gear, and brief your team before volunteers arrive.';

  @override
  String get organizerToolkitPage2Title => 'Moderation keeps trust';

  @override
  String get organizerToolkitPage2Body =>
      'After you create an event, moderators review it. Once approved, volunteers can see and join.';

  @override
  String get organizerToolkitPage3Title => 'Verify attendance';

  @override
  String get organizerToolkitPage3Body =>
      'Use the in-app QR check-in so every volunteer gets credit for showing up.';

  @override
  String get organizerToolkitPage4Title => 'Weather and safety';

  @override
  String get organizerToolkitPage4Body =>
      'If conditions turn unsafe, pause or postpone. Tell joined volunteers promptly in the app so nobody travels for a cancelled start.';

  @override
  String get organizerToolkitPage5Title => 'Waste and disposal';

  @override
  String get organizerToolkitPage5Body =>
      'Sort recyclables when you can, bag sharp objects safely, and take waste to authorized disposal points. Leave the site cleaner than you found it.';

  @override
  String get organizerToolkitPage6Title => 'Include everyone';

  @override
  String get organizerToolkitPage6Body =>
      'Offer clear roles, steady pacing, and patience. A welcoming briefing helps first-time volunteers feel confident and stay safe.';

  @override
  String get organizerToolkitPage7Title => 'Privacy in chat';

  @override
  String get organizerToolkitPage7Body =>
      'Keep personal phone numbers and addresses out of public event chat. Use in-app messaging so the whole team stays informed without oversharing.';

  @override
  String get organizerToolkitPage8Title => 'Evidence and honest impact';

  @override
  String get organizerToolkitPage8Body =>
      'After photos and bag counts should reflect what really happened. Accurate reporting builds trust with volunteers, moderators, and the wider community.';

  @override
  String get organizerToolkitContinue => 'Continue';

  @override
  String get organizerToolkitStartQuiz => 'Take the quiz';

  @override
  String get organizerQuizTitle => 'Quick knowledge check';

  @override
  String get organizerQuizLoadFailed =>
      'Could not load the quiz. Please try again.';

  @override
  String get organizerQuizLoadInvalidResponse =>
      'The quiz data from the server was incomplete. Please try again.';

  @override
  String get organizerQuizRetryLoad => 'Try again';

  @override
  String get organizerQuizSubmitFailed =>
      'Could not submit answers. Try again.';

  @override
  String organizerQuizOptionSemantic(int index, int total, String optionText) {
    return 'Question $index of $total: $optionText';
  }

  @override
  String get organizerQuizSubmit => 'Submit answers';

  @override
  String get organizerQuizPassedTitle => 'You\'re certified!';

  @override
  String get organizerQuizPassedBody =>
      'You can now create cleanup events. Volunteers are waiting.';

  @override
  String get organizerQuizFailedTitle => 'Not quite';

  @override
  String organizerQuizFailedBody(int correct, int total) {
    return 'Review the tutorial and try again. You got $correct out of $total.';
  }

  @override
  String get organizerQuizRetry => 'Try again';

  @override
  String get organizerQuizCreateEvent => 'Create your first event';

  @override
  String get organizerCertifiedBadge => 'Certified organizer';

  @override
  String get errorOrganizerQuizSessionExpired =>
      'That quiz session expired. Load a new quiz and try again.';

  @override
  String get errorOrganizerQuizSessionInvalid =>
      'This quiz session is not valid. Load the quiz again.';

  @override
  String get errorOrganizerQuizAnswersMismatch =>
      'Answers do not match the quiz you started. Load the quiz again.';

  @override
  String get errorOrganizerQuizInvalid =>
      'One or more answers are not valid for this quiz. Load the quiz again.';

  @override
  String get errorOrganizerCertificationAlreadyDone =>
      'You are already a certified organizer. No need to take the quiz again.';

  @override
  String get reportsSseReconnectBanner => 'Reconnecting to live updates…';

  @override
  String get reportsSseReconnectAction => 'Reconnect';

  @override
  String get reportsListMergedToast =>
      'This report was merged and removed from your list.';

  @override
  String get reportDraftResumeTitle => 'Continue your draft?';

  @override
  String reportDraftResumeBody(
    int photoCount,
    String titlePreview,
    String savedAt,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      photoCount,
      locale: localeName,
      other: '$photoCount photos saved.',
      one: '1 photo saved.',
      zero: 'No photos saved yet.',
    );
    return '$_temp0\n\nTitle: \"$titlePreview\"\n\nLast saved: $savedAt.';
  }

  @override
  String get reportDraftResumeContinue => 'Continue';

  @override
  String get reportDraftResumeDiscard => 'Discard draft';

  @override
  String get reportDraftSavedJustNow => 'Saved just now';

  @override
  String reportDraftSavedMinutesAgo(int minutes) {
    return 'Saved $minutes min ago';
  }

  @override
  String reportDraftSavedHoursAgo(int hours) {
    return 'Saved $hours h ago';
  }

  @override
  String reportDraftPhotosLost(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attached photos were missing and removed from your draft.',
      one: '1 attached photo was missing and removed from your draft.',
    );
    return '$_temp0';
  }

  @override
  String get reportDraftDiscardConfirmTitle => 'Discard draft?';

  @override
  String get reportDraftDiscardConfirmBody =>
      'Your saved text and photos for this report will be deleted from this device.';

  @override
  String get reportDraftCentralFabSheetTitle => 'You have a saved draft';

  @override
  String reportDraftCentralFabSubtitle(int photoCount, String savedAgo) {
    String _temp0 = intl.Intl.pluralLogic(
      photoCount,
      locale: localeName,
      other: '$photoCount photos',
      one: '1 photo',
      zero: 'No photos',
    );
    return '$_temp0 · $savedAgo';
  }

  @override
  String get reportDraftCentralFabContinue => 'Continue draft';

  @override
  String get reportDraftCentralFabTakeNewPhoto => 'Take new photo';

  @override
  String get reportDraftCentralFabCancel => 'Cancel';

  @override
  String get reportDraftIncomingPhotoTitle =>
      'Continue draft or use this photo?';

  @override
  String reportDraftIncomingPhotoBody(int photoCount, String savedAgo) {
    String _temp0 = intl.Intl.pluralLogic(
      photoCount,
      locale: localeName,
      other: '$photoCount photos',
      one: '1 photo',
      zero: 'no photos',
    );
    return 'You have a saved draft ($_temp0). $savedAgo';
  }

  @override
  String get reportDraftIncomingPhotoContinue => 'Continue draft';

  @override
  String get reportDraftIncomingPhotoReplace => 'Replace draft';

  @override
  String get reportDraftIncomingPhotoAdd => 'Add to draft';
}
