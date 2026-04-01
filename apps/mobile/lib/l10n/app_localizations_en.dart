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
      'Your draft is saved — you can try again when ready.';

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
  String get profileAvatarCropHint => 'Pinch to zoom · drag to position';

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
}
