import 'dart:async';
import 'dart:io';

import 'package:chisto_infrastructure/core/auth/session_invalidation.dart';
import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/forms/forms.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_profile/src/domain/models/profile_user.dart';
import 'package:feature_profile/src/presentation/avatar/profile_avatar_flow.dart';
import 'package:feature_profile/src/presentation/providers/profile_avatar_notifier.dart';
import 'package:feature_profile/src/presentation/providers/profile_providers.dart';
import 'package:feature_profile/src/presentation/widgets/profile_avatar_section.dart';
import 'package:feature_profile/src/presentation/widgets/profile_info_fields_card.dart';
import 'package:feature_profile/src/presentation/widgets/profile_primary_action_bar.dart';
import 'package:feature_profile/src/presentation/widgets/profile_sub_screen_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileGeneralInfoScreen extends ConsumerStatefulWidget {
  const ProfileGeneralInfoScreen({super.key, required this.user});

  /// Current user (from profile screen).
  final ProfileUser user;

  @override
  ConsumerState<ProfileGeneralInfoScreen> createState() =>
      _ProfileGeneralInfoScreenState();
}

class _ProfileGeneralInfoScreenState
    extends ConsumerState<ProfileGeneralInfoScreen>
    with FormValidationMixin {
  static const List<String> _fieldOrder = <String>[FormFieldIds.fullName];
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late String _email;
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final GlobalKey _nameFieldKey = GlobalKey();
  final GlobalKey _phoneFieldKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  bool _isSaving = false;
  bool _isAvatarBusy = false;
  String? _localAvatarPath;
  String? _remoteAvatarUrl;
  void _initFromUser(ProfileUser user) {
    _email = user.email.trim();
    _nameController = TextEditingController(
      text: user.firstName.isNotEmpty || user.lastName.isNotEmpty
          ? '${user.firstName} ${user.lastName}'.trim()
          : user.name,
    );
    _phoneController = TextEditingController(
      text: formatPhoneForDisplay(user.phoneNumber),
    );
  }

  /// Treat blank / whitespace as no avatar so we never offer "remove" for initials-only.
  static String? _normalizeAvatarUrl(String? url) {
    final String? trimmed = url?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  @override
  void initState() {
    super.initState();
    _initFromUser(widget.user);
    _localAvatarPath = ref.read(profileAvatarNotifierProvider).localPath;
    // [user] from Profile is the source of truth — do not fall back to global remote preview,
    // which can be stale and incorrectly show "Remove".
    _remoteAvatarUrl = _normalizeAvatarUrl(widget.user.avatarUrl);
    registerFormField(
      FormFieldIds.fullName,
      focusNode: _nameFocus,
      fieldKey: _nameFieldKey,
    );
    _nameController.addListener(_onFieldChanged);
    _nameFocus.addListener(_scrollToFocusedField);
    _phoneFocus.addListener(_scrollToFocusedField);
    _nameFocus.addListener(_onFocusChange);
    _phoneFocus.addListener(_onFocusChange);
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  String? _nameValidationError(AppLocalizations l10n) {
    return validateIfVisible(FormFieldIds.fullName, () {
      final String trimmed = _nameController.text.trim();
      final String? required = FormValidators.requiredField(
        l10n,
        trimmed,
        l10n.profileGeneralNameLabel,
      );
      if (required != null) return required;
      if (trimmed.length > 100) return l10n.profileGeneralNameTooLongSnack;
      return null;
    });
  }

  Map<String, String? Function()> _validators(AppLocalizations l10n) {
    return <String, String? Function()>{
      FormFieldIds.fullName: () {
        final String trimmed = _nameController.text.trim();
        final String? required = FormValidators.requiredField(
          l10n,
          trimmed,
          l10n.profileGeneralNameLabel,
        );
        if (required != null) return required;
        if (trimmed.length > 100) return l10n.profileGeneralNameTooLongSnack;
        return null;
      },
    };
  }

  void _onFocusChange() {
    if (_nameFocus.hasFocus || _phoneFocus.hasFocus) return;
    if (!_scrollController.hasClients) return;
    if (_scrollController.offset <= 0) return;
    _scrollController.animateTo(
      0,
      duration: AppMotion.medium,
      curve: AppMotion.smooth,
    );
  }

  void _scrollToFocusedField() {
    if (!mounted) return;
    if (_phoneFocus.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollPhoneFieldAboveKeyboard(),
      );
      Future<void>.delayed(
        const Duration(milliseconds: 300),
        _scrollPhoneFieldAboveKeyboard,
      );
      Future<void>.delayed(
        const Duration(milliseconds: 550),
        _scrollPhoneFieldAboveKeyboard,
      );
      return;
    }
    final BuildContext? ctx = _nameFieldKey.currentContext;
    if (ctx == null) return;
    final double keyboardInset = MediaQuery.viewInsetsOf(ctx).bottom;
    double alignment = 0.2;
    if (keyboardInset > 0) {
      final ScrollableState? scrollable = Scrollable.maybeOf(ctx);
      if (scrollable != null) {
        final double vh = scrollable.position.viewportDimension;
        final double vis = vh - keyboardInset;
        if (vis > 0) alignment = (vis * 0.15 / vh).clamp(0.0, 1.0);
      }
    }
    Scrollable.ensureVisible(
      ctx,
      alignment: alignment,
      duration: AppMotion.medium,
      curve: AppMotion.smooth,
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
    );
  }

  void _scrollPhoneFieldAboveKeyboard() {
    if (!mounted || !_phoneFocus.hasFocus) return;
    final BuildContext? ctx = _phoneFieldKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.25,
      duration: AppMotion.medium,
      curve: AppMotion.smooth,
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
    );
  }

  ImageProvider? _generalInfoPeekImageProvider() {
    final String? local = _localAvatarPath?.trim();
    if (local != null && local.isNotEmpty) {
      return FileImage(File(local));
    }
    final String? url = _normalizeAvatarUrl(_remoteAvatarUrl);
    if (url == null) return null;
    return NetworkImage(url);
  }

  bool _canPeekGeneralInfoAvatar() {
    if (_isSaving || _isAvatarBusy) return false;
    return _generalInfoPeekImageProvider() != null;
  }

  @override
  void dispose() {
    ProfileAvatarPeek.hide();
    _nameController.removeListener(_onFieldChanged);
    _nameFocus.removeListener(_scrollToFocusedField);
    _phoneFocus.removeListener(_scrollToFocusedField);
    _nameFocus.removeListener(_onFocusChange);
    _phoneFocus.removeListener(_onFocusChange);
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _scrollController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Shared style for name, email, and phone values so the form reads as one rhythm.
  TextStyle _profileFieldValueStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w400,
      height: 1.35,
    );
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;

    clearServerFieldErrors();
    final AppLocalizations l10n = context.l10n;
    if (await handleInvalidSubmit(
      context,
      l10n,
      _fieldOrder,
      _validators(l10n),
    )) {
      return;
    }

    final String nameTrimmed = _nameController.text.trim();
    final int spaceIndex = nameTrimmed.indexOf(' ');
    final String firstName = spaceIndex >= 0
        ? nameTrimmed.substring(0, spaceIndex)
        : nameTrimmed;
    final String lastName = spaceIndex >= 0
        ? nameTrimmed.substring(spaceIndex + 1).trim()
        : '';

    setState(() => _isSaving = true);

    try {
      final ProfileUser? updated = await ref
          .read(profileRepositoryProvider)
          .updateProfile(firstName: firstName, lastName: lastName);
      if (!mounted) return;
      AppSnack.show(
        context,
        message: context.l10n.profileGeneralUpdatedSnack,
        type: AppSnackType.success,
      );
      if (updated != null) {
        Navigator.of(context).pop(updated);
      }
    } on AppError catch (e) {
      if (!mounted) return;
      if (SessionInvalidation.shouldHandle(e)) {
        unawaited(SessionInvalidation.fromError(e));
        return;
      }
      final Map<String, String> fieldErrors = fieldErrorsFromAppError(e, l10n);
      if (fieldErrors.isNotEmpty) {
        setServerFieldErrors(fieldErrors);
        await focusAndScrollToFirstInvalid(
          context,
          _fieldOrder,
          _validators(l10n),
        );
        return;
      }
      AppSnack.failure(context, error: e);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleChangeAvatar() async {
    if (_isSaving || _isAvatarBusy) return;
    final bool showRemove = _normalizeAvatarUrl(_remoteAvatarUrl) != null;
    final ProfileAvatarFlowResult flow = await runProfileAvatarFlow(
      context,
      showRemoveOption: showRemove,
    );
    if (!mounted) return;
    if (flow.kind == ProfileAvatarFlowKind.cancelled) return;
    if (flow.kind == ProfileAvatarFlowKind.remove) {
      await _removeAvatarConfirmed();
      return;
    }
    final String? pickedPath = flow.uploadPath;
    if (pickedPath == null || pickedPath.isEmpty) return;

    final String? previousLocalPath = _localAvatarPath;
    setState(() {
      _isAvatarBusy = true;
      _localAvatarPath = pickedPath;
    });
    ref.read(profileAvatarNotifierProvider.notifier).setLocalPath(pickedPath);

    try {
      final String avatarUrl = await ref
          .read(profileRepositoryProvider)
          .uploadAvatar(pickedPath);
      if (!mounted) return;
      setState(() {
        _remoteAvatarUrl = _normalizeAvatarUrl(avatarUrl);
        _localAvatarPath = null;
      });
      ref.read(profileAvatarNotifierProvider.notifier).clearLocalPath();
      ref
          .read(profileAvatarNotifierProvider.notifier)
          .setRemoteUrl(_normalizeAvatarUrl(avatarUrl));
      AppSnack.show(
        context,
        message: context.l10n.profileGeneralPictureUpdatedSnack,
        type: AppSnackType.success,
      );
    } on AppError catch (e) {
      if (!mounted) return;
      setState(() {
        _localAvatarPath = previousLocalPath;
      });
      if (previousLocalPath != null && previousLocalPath.isNotEmpty) {
        ref
            .read(profileAvatarNotifierProvider.notifier)
            .setLocalPath(previousLocalPath);
      } else {
        ref.read(profileAvatarNotifierProvider.notifier).clearLocalPath();
      }
      if (SessionInvalidation.shouldHandle(e)) {
        unawaited(SessionInvalidation.fromError(e));
        return;
      }
      AppSnack.failure(context, error: e);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _localAvatarPath = previousLocalPath;
      });
      if (previousLocalPath != null && previousLocalPath.isNotEmpty) {
        ref
            .read(profileAvatarNotifierProvider.notifier)
            .setLocalPath(previousLocalPath);
      } else {
        ref.read(profileAvatarNotifierProvider.notifier).clearLocalPath();
      }
      AppSnack.show(
        context,
        message: context.l10n.profileAvatarProcessPhotoFailed,
        type: AppSnackType.warning,
      );
    } finally {
      if (mounted) {
        setState(() => _isAvatarBusy = false);
      }
    }
  }

  Future<void> _removeAvatarConfirmed() async {
    setState(() => _isAvatarBusy = true);
    try {
      await ref.read(profileRepositoryProvider).removeAvatar();
      if (!mounted) return;
      setState(() {
        _remoteAvatarUrl = null;
        _localAvatarPath = null;
      });
      ref.read(profileAvatarNotifierProvider.notifier).clearLocalPath();
      ref.read(profileAvatarNotifierProvider.notifier).setRemoteUrl(null);
      AppSnack.show(
        context,
        message: context.l10n.profileAvatarRemovedMessage,
        type: AppSnackType.success,
      );
    } on AppError catch (e) {
      if (!mounted) return;
      if (SessionInvalidation.shouldHandle(e)) {
        unawaited(SessionInvalidation.fromError(e));
        return;
      }
      AppSnack.failure(context, error: e);
    } catch (_) {
      if (!mounted) return;
      AppSnack.show(
        context,
        message: context.l10n.profileAvatarRemoveFailed,
        type: AppSnackType.error,
      );
    } finally {
      if (mounted) setState(() => _isAvatarBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final bool canPeekAvatar = _canPeekGeneralInfoAvatar();
    return Scaffold(
      backgroundColor: AppColors.panelBackground,
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: ProfilePrimaryActionBar(
        padForKeyboard: false,
        child: PrimaryButton(
          label: _isSaving
              ? context.l10n.profileGeneralSaving
              : context.l10n.profileGeneralUpdateButton,
          onPressed: _isSaving ? null : _handleSave,
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ProfileSubScreenHeader(
              title: context.l10n.profileGeneralInfoTile,
              subtitle: context.l10n.profileGeneralInfoSubtitle,
            ),
            Expanded(
              child: KeyboardAwareFormScroll(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ListenableBuilder(
                      listenable: _nameController,
                      builder: (BuildContext context, Widget? _) {
                        final String avatarDisplayName =
                            _nameController.text.trim().isEmpty
                            ? context.l10n.profileGeneralDefaultDisplayName
                            : _nameController.text.trim();
                        return ProfileAvatarSection(
                          avatarDisplayName: avatarDisplayName,
                          localAvatarPath: _localAvatarPath,
                          remoteAvatarUrl: _remoteAvatarUrl,
                          isSaving: _isSaving,
                          isAvatarBusy: _isAvatarBusy,
                          canPeekAvatar: canPeekAvatar,
                          peekImageProvider: _generalInfoPeekImageProvider,
                          onChangeAvatar: _handleChangeAvatar,
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    ProfileInfoFieldsCard(
                      nameController: _nameController,
                      phoneController: _phoneController,
                      nameFocus: _nameFocus,
                      phoneFocus: _phoneFocus,
                      nameFieldKey: _nameFieldKey,
                      phoneFieldKey: _phoneFieldKey,
                      email: _email,
                      nameErrorText: _nameValidationError(l10n),
                      fieldValueStyle: _profileFieldValueStyle(context),
                      inputDecoration: (String hint) =>
                          _inputDecoration(context, hint),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTypographySurfaces.profileGeneralInfoFieldHint(
        Theme.of(context).textTheme,
      ),
      filled: true,
      fillColor: AppColors.inputFill,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radius18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radius18),
        borderSide: const BorderSide(color: AppColors.inputBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radius18),
        borderSide: const BorderSide(color: AppColors.primaryDark, width: 1.5),
      ),
    );
  }
}
