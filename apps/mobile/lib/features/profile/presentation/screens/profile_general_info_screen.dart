import 'dart:io';
import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/validation/phone_display_formatter.dart';
import 'package:chisto_mobile/features/profile/domain/models/profile_user.dart';
import 'package:chisto_mobile/features/profile/data/profile_avatar_state.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';
import 'package:chisto_mobile/shared/widgets/keyboard_aware_form_scroll.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';
import 'package:chisto_mobile/shared/widgets/app_avatar.dart';
import 'package:chisto_mobile/shared/widgets/profile_avatar_peek_overlay.dart';
import 'package:chisto_mobile/features/profile/presentation/avatar/profile_avatar_flow.dart';
import 'package:chisto_mobile/features/profile/presentation/widgets/profile_primary_action_bar.dart';

class ProfileGeneralInfoScreen extends StatefulWidget {
  const ProfileGeneralInfoScreen({super.key, this.user});

  /// Current user (from profile screen or auth). If null, built from auth state.
  final ProfileUser? user;

  @override
  State<ProfileGeneralInfoScreen> createState() =>
      _ProfileGeneralInfoScreenState();
}

class _ProfileGeneralInfoScreenState extends State<ProfileGeneralInfoScreen> {
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

  Future<void> _fetchAndInitUser() async {
    try {
      final ProfileUser user = await ServiceLocator.instance.profileRepository
          .getMe();
      if (!mounted) return;
      setState(() {
        _email = user.email.trim();
        _nameController.text =
            user.firstName.isNotEmpty || user.lastName.isNotEmpty
            ? '${user.firstName} ${user.lastName}'.trim()
            : user.name;
        _phoneController.text = formatPhoneForDisplay(user.phoneNumber);
        _remoteAvatarUrl = _normalizeAvatarUrl(user.avatarUrl);
      });
      profileAvatarState.setRemoteUrl(_normalizeAvatarUrl(user.avatarUrl));
    } on AppError catch (e) {
      if (!mounted) return;
      if (_isAuthError(e.code)) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.signIn,
          (Route<dynamic> route) => false,
        );
        return;
      }
      AppSnack.show(context, message: e.message, type: AppSnackType.warning);
    } catch (_) {
      if (!mounted) return;
      AppSnack.show(
        context,
        message: context.l10n.profileGeneralLoadFailedSnack,
        type: AppSnackType.warning,
      );
    }
  }

  static bool _isAuthError(String code) =>
      code == 'UNAUTHORIZED' ||
      code == 'INVALID_TOKEN_USER' ||
      code == 'ACCOUNT_NOT_ACTIVE';

  /// Treat blank / whitespace as no avatar so we never offer "remove" for initials-only.
  static String? _normalizeAvatarUrl(String? url) {
    final String? trimmed = url?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _initFromUser(widget.user!);
    } else {
      _initFromUser(_profileUserFromAuthState());
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchAndInitUser());
    }
    _localAvatarPath = profileAvatarState.localPath;
    // When [user] is passed from Profile, it is the source of truth — do not fall back to
    // [profileAvatarState.remoteUrl], which can be stale and incorrectly show "Remove".
    _remoteAvatarUrl = _normalizeAvatarUrl(
      widget.user != null
          ? widget.user!.avatarUrl
          : profileAvatarState.remoteUrl,
    );
    _nameFocus.addListener(_scrollToFocusedField);
    _phoneFocus.addListener(_scrollToFocusedField);
    _nameFocus.addListener(_onFocusChange);
    _phoneFocus.addListener(_onFocusChange);
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
    final RenderObject? renderObject = ctx.findRenderObject();
    if (renderObject is! RenderBox) return;
    final RenderBox box = renderObject;
    final Rect rect = box.localToGlobal(Offset.zero, ancestor: null) & box.size;
    final double keyboardInset = MediaQuery.viewInsetsOf(ctx).bottom;
    if (keyboardInset <= 0) return;
    final double screenHeight = MediaQuery.sizeOf(ctx).height;
    const double paddingAboveKeyboard = 24;
    final double safeY = screenHeight - keyboardInset - paddingAboveKeyboard;
    if (rect.bottom <= safeY) return;
    final double delta = rect.bottom - safeY;
    final ScrollPosition position = _scrollController.position;
    final double targetOffset = (position.pixels + delta).clamp(
      0.0,
      position.maxScrollExtent,
    );
    if ((targetOffset - position.pixels).abs() < 1) return;
    _scrollController.animateTo(
      targetOffset,
      duration: AppMotion.medium,
      curve: AppMotion.smooth,
    );
  }

  static ProfileUser _profileUserFromAuthState() {
    final authState = ServiceLocator.instance.authState;
    return ProfileUser(
      id: authState.userId ?? 'unknown',
      name: authState.displayName ?? 'User',
      firstName: '',
      lastName: '',
      email: '',
      phoneNumber: '—',
      points: 0,
      totalPointsEarned: 0,
      level: 1,
      levelTierKey: 'numeric_1',
      levelDisplayName: 'Level 1',
      pointsToNextLevel: 36,
      levelProgress: 0,
      pointsInLevel: 0,
      weeklyPoints: 0,
      weeklyRank: null,
      weekStartsAt: '',
      weekEndsAt: '',
      avatarColor: AppColors.primary,
      avatarUrl: null,
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
    final String nameTrimmed = _nameController.text.trim();
    if (nameTrimmed.isEmpty) {
      AppSnack.show(
        context,
        message: context.l10n.profileGeneralNameRequiredSnack,
        type: AppSnackType.warning,
      );
      return;
    }
    if (nameTrimmed.length > 100) {
      AppSnack.show(
        context,
        message: context.l10n.profileGeneralNameTooLongSnack,
        type: AppSnackType.warning,
      );
      return;
    }
    final int spaceIndex = nameTrimmed.indexOf(' ');
    final String firstName = spaceIndex >= 0
        ? nameTrimmed.substring(0, spaceIndex)
        : nameTrimmed;
    final String lastName = spaceIndex >= 0
        ? nameTrimmed.substring(spaceIndex + 1).trim()
        : '';

    setState(() => _isSaving = true);
    AppHaptics.light();

    try {
      final ProfileUser? updated = await ServiceLocator
          .instance
          .profileRepository
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
      if (_isAuthError(e.code)) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.signIn,
          (Route<dynamic> route) => false,
        );
        return;
      }
      AppSnack.show(context, message: e.message, type: AppSnackType.error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleChangeAvatar() async {
    if (_isSaving || _isAvatarBusy) return;
    AppHaptics.softTransition();
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
    profileAvatarState.setLocalPath(pickedPath);

    try {
      final String? avatarUrl = await ServiceLocator.instance.profileRepository
          .uploadAvatar(pickedPath);
      if (!mounted) return;
      setState(() {
        _remoteAvatarUrl = _normalizeAvatarUrl(avatarUrl);
        _localAvatarPath = null;
      });
      profileAvatarState.clearLocalPath();
      profileAvatarState.setRemoteUrl(_normalizeAvatarUrl(avatarUrl));
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
        profileAvatarState.setLocalPath(previousLocalPath);
      } else {
        profileAvatarState.clearLocalPath();
      }
      if (_isAuthError(e.code)) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.signIn,
          (Route<dynamic> route) => false,
        );
        return;
      }
      AppSnack.show(context, message: e.message, type: AppSnackType.error);
    } finally {
      if (mounted) {
        setState(() => _isAvatarBusy = false);
      }
    }
  }

  Future<void> _removeAvatarConfirmed() async {
    setState(() => _isAvatarBusy = true);
    try {
      await ServiceLocator.instance.profileRepository.removeAvatar();
      if (!mounted) return;
      setState(() {
        _remoteAvatarUrl = null;
        _localAvatarPath = null;
      });
      profileAvatarState.clearLocalPath();
      profileAvatarState.setRemoteUrl(null);
      AppHaptics.success();
      AppSnack.show(
        context,
        message: context.l10n.profileAvatarRemovedMessage,
        type: AppSnackType.success,
      );
    } on AppError catch (e) {
      if (!mounted) return;
      if (_isAuthError(e.code)) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.signIn,
          (Route<dynamic> route) => false,
        );
        return;
      }
      AppSnack.show(context, message: e.message, type: AppSnackType.error);
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
    final double avatarDiameter = AppSpacing.avatarLg + AppSpacing.lg;
    final bool canPeekAvatar = _canPeekGeneralInfoAvatar();
    return Scaffold(
      backgroundColor: AppColors.panelBackground,
      resizeToAvoidBottomInset: false,
      bottomNavigationBar: ProfilePrimaryActionBar(
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
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                0,
              ),
              child: AppBackButton(backgroundColor: AppColors.inputFill),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    context.l10n.profileGeneralInfoTile,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.profileGeneralInfoSubtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
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
                    Center(
                      child: Column(
                        children: <Widget>[
                          Semantics(
                            label: _isAvatarBusy
                                ? context.l10n.profileGeneralAvatarSemanticUpdating
                                : context.l10n.profileGeneralAvatarSemanticChange,
                            button: true,
                            enabled: !_isSaving && !_isAvatarBusy,
                            child: Material(
                              color: AppColors.transparent,
                              child: InkWell(
                                onTap: _isSaving || _isAvatarBusy
                                    ? null
                                    : _handleChangeAvatar,
                                onLongPress: canPeekAvatar
                                    ? () {
                                        final ImageProvider? image =
                                            _generalInfoPeekImageProvider();
                                        if (image == null) return;
                                        ProfileAvatarPeek.show(
                                          context,
                                          image: image,
                                          semanticLabel: context.l10n
                                              .profileAvatarPeekSemantic,
                                        );
                                      }
                                    : null,
                                onLongPressUp: canPeekAvatar
                                    ? ProfileAvatarPeek.hide
                                    : null,
                                customBorder: const CircleBorder(),
                                child: SizedBox(
                                  width: avatarDiameter + 14,
                                  height: avatarDiameter + 14,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    clipBehavior: Clip.none,
                                    children: <Widget>[
                                      ClipOval(
                                        clipBehavior: Clip.antiAlias,
                                        child: AnimatedContainer(
                                          duration: AppMotion.fast,
                                          curve: AppMotion.smooth,
                                          width: avatarDiameter,
                                          height: avatarDiameter,
                                          decoration: BoxDecoration(
                                            color: AppColors.inputFill,
                                            border: Border.all(
                                              color: _isAvatarBusy
                                                  ? AppColors.primary
                                                      .withValues(alpha: 0.45)
                                                  : AppColors.primaryDark
                                                      .withValues(alpha: 0.12),
                                              width: _isAvatarBusy ? 2.5 : 1.5,
                                            ),
                                          ),
                                          child: Stack(
                                            fit: StackFit.expand,
                                            clipBehavior: Clip.hardEdge,
                                            children: <Widget>[
                                              Positioned.fill(
                                                child: _localAvatarPath != null
                                                    ? Image.file(
                                                        File(
                                                          _localAvatarPath!,
                                                        ),
                                                        fit: BoxFit.cover,
                                                        filterQuality:
                                                            FilterQuality
                                                                .medium,
                                                      )
                                                    : AppAvatar(
                                                        name: _nameController
                                                                .text
                                                                .trim()
                                                                .isEmpty
                                                            ? context.l10n
                                                                .profileGeneralDefaultDisplayName
                                                            : _nameController
                                                                  .text
                                                                  .trim(),
                                                        size: avatarDiameter,
                                                        imageUrl:
                                                            _remoteAvatarUrl,
                                                      ),
                                              ),
                                              if (_isAvatarBusy)
                                                Positioned.fill(
                                                  child: ColoredBox(
                                                    color: AppColors.black
                                                        .withValues(
                                                          alpha: 0.28,
                                                        ),
                                                    child: const Center(
                                                      child: SizedBox(
                                                        width: 28,
                                                        height: 28,
                                                        child:
                                                            CircularProgressIndicator(
                                                          strokeWidth: 2.5,
                                                          color:
                                                              AppColors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (!_isAvatarBusy)
                                        Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppColors.primaryDark,
                                              border: Border.all(
                                                color: AppColors.white,
                                                width: 2,
                                              ),
                                              boxShadow: <BoxShadow>[
                                                BoxShadow(
                                                  color: AppColors.black
                                                      .withValues(alpha: 0.12),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: const Padding(
                                              padding: EdgeInsets.all(6),
                                              child: Icon(
                                                Icons.camera_alt_rounded,
                                                size: 16,
                                                color: AppColors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ExcludeSemantics(
                            child: AnimatedSwitcher(
                              duration: AppMotion.fast,
                              switchInCurve: AppMotion.smooth,
                              switchOutCurve: AppMotion.standardCurve,
                              child: Text(
                                _isAvatarBusy
                                    ? context
                                        .l10n.profileAvatarUploadingCaption
                                    : context.l10n.profileAvatarTapToChange,
                                key: ValueKey<bool>(_isAvatarBusy),
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.panelBackground,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radius18,
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: AppColors.shadowLight,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: AppColors.divider.withValues(alpha: 0.9),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              context.l10n.profileGeneralNameLabel,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.1,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            RepaintBoundary(
                              key: _nameFieldKey,
                              child: TextField(
                                controller: _nameController,
                                focusNode: _nameFocus,
                                textInputAction: TextInputAction.next,
                                style: _profileFieldValueStyle(context),
                                onSubmitted: (_) => FocusScope.of(
                                  context,
                                ).requestFocus(_phoneFocus),
                                decoration: _inputDecoration(
                                  context,
                                  context.l10n.profileGeneralNameHint,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              context.l10n.profileEmailLabel,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.1,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Semantics(
                              readOnly: true,
                              label: context.l10n.profileEmailLabel,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.inputFill,
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radius18,
                                  ),
                                  border: Border.all(
                                    color: AppColors.inputBorder,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  _email.isEmpty
                                      ? context.l10n.profileGeneralEmptyValue
                                      : _email,
                                  style: _profileFieldValueStyle(context),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              context.l10n.profileEmailReadOnlyHint,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColors.textMuted,
                                    height: 1.35,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              context.l10n.profileGeneralMobileLabel,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.1,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            RepaintBoundary(
                              key: _phoneFieldKey,
                              child: TextField(
                                controller: _phoneController,
                                focusNode: _phoneFocus,
                                readOnly: true,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.done,
                                style: _profileFieldValueStyle(context),
                                decoration: _inputDecoration(
                                  context,
                                  context.l10n.profileGeneralPhonePlaceholder,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: AppColors.inputFill,
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radius14,
                                ),
                                border: Border.all(
                                  color: AppColors.divider.withValues(
                                    alpha: 0.9,
                                  ),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    size: AppSpacing.iconMd,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Expanded(
                                    child: Text(
                                      context.l10n.profileGeneralLimitsNotice,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.textMuted,
                                            height: 1.35,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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
      hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w400,
            height: 1.35,
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
