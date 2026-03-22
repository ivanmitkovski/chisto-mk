import 'dart:io';
import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/core/validation/phone_display_formatter.dart';
import 'package:chisto_mobile/features/profile/data/profile_mock_data.dart';
import 'package:chisto_mobile/features/profile/data/profile_avatar_state.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';
import 'package:chisto_mobile/shared/widgets/keyboard_aware_form_scroll.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';

class ProfileGeneralInfoScreen extends StatefulWidget {
  const ProfileGeneralInfoScreen({super.key, this.user});

  /// Current user (from profile screen or auth). If null, built from auth state.
  final ProfileUser? user;

  @override
  State<ProfileGeneralInfoScreen> createState() => _ProfileGeneralInfoScreenState();
}

class _ProfileGeneralInfoScreenState extends State<ProfileGeneralInfoScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final GlobalKey _nameFieldKey = GlobalKey();
  final GlobalKey _phoneFieldKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  bool _isSaving = false;
  String? _localAvatarPath;

  void _initFromUser(ProfileUser user) {
    _nameController = TextEditingController(
      text: user.firstName.isNotEmpty || user.lastName.isNotEmpty
          ? '${user.firstName} ${user.lastName}'.trim()
          : user.name,
    );
    _phoneController = TextEditingController(text: formatPhoneForDisplay(user.phoneNumber));
  }

  Future<void> _fetchAndInitUser() async {
    try {
      final ProfileUser user = await ServiceLocator.instance.profileRepository.getMe();
      if (!mounted) return;
      setState(() {
        _nameController.text = user.firstName.isNotEmpty || user.lastName.isNotEmpty
            ? '${user.firstName} ${user.lastName}'.trim()
            : user.name;
        _phoneController.text = formatPhoneForDisplay(user.phoneNumber);
      });
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
        message: 'Could not load profile',
        type: AppSnackType.warning,
      );
    }
  }

  static bool _isAuthError(String code) =>
      code == 'UNAUTHORIZED' || code == 'INVALID_TOKEN_USER' || code == 'ACCOUNT_NOT_ACTIVE';

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
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollPhoneFieldAboveKeyboard());
      Future<void>.delayed(const Duration(milliseconds: 300), _scrollPhoneFieldAboveKeyboard);
      Future<void>.delayed(const Duration(milliseconds: 550), _scrollPhoneFieldAboveKeyboard);
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
    final double targetOffset = (position.pixels + delta).clamp(0.0, position.maxScrollExtent);
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
      phoneNumber: '—',
      points: 0,
      totalPointsEarned: 0,
      level: 1,
      pointsToNextLevel: 100,
      avatarColor: AppColors.primary,
    );
  }

  @override
  void dispose() {
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

  Future<void> _handleSave() async {
    if (_isSaving) return;
    final String nameTrimmed = _nameController.text.trim();
    if (nameTrimmed.isEmpty) {
      AppSnack.show(context, message: 'Name is required', type: AppSnackType.warning);
      return;
    }
    if (nameTrimmed.length > 100) {
      AppSnack.show(
        context,
        message: 'Name is too long',
        type: AppSnackType.warning,
      );
      return;
    }
    final int spaceIndex = nameTrimmed.indexOf(' ');
    final String firstName = spaceIndex >= 0 ? nameTrimmed.substring(0, spaceIndex) : nameTrimmed;
    final String lastName = spaceIndex >= 0 ? nameTrimmed.substring(spaceIndex + 1).trim() : '';

    setState(() => _isSaving = true);
    AppHaptics.light();

    try {
      final ProfileUser? updated = await ServiceLocator.instance.profileRepository.updateProfile(
        firstName: firstName,
        lastName: lastName,
      );
      if (!mounted) return;
      AppSnack.show(context, message: 'Profile updated', type: AppSnackType.success);
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
    AppHaptics.tap();
    if (!mounted) return;
    AppSnack.show(context, message: 'Coming soon', type: AppSnackType.info);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.panelBackground,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 0),
              child: AppBackButton(backgroundColor: AppColors.inputFill),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'General info',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Edit your profile details',
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
                          GestureDetector(
                            onTap: _handleChangeAvatar,
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              width: AppSpacing.avatarLg + AppSpacing.lg,
                              height: AppSpacing.avatarLg + AppSpacing.lg,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.inputFill,
                              ),
                              child: _localAvatarPath != null
                                  ? ClipOval(
                                      child: Image.file(
                                        File(_localAvatarPath!),
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person_outline_rounded,
                                      size: AppSpacing.iconLg + AppSpacing.md,
                                      color: AppColors.textMuted,
                                    ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextButton(
                            onPressed: _handleChangeAvatar,
                            child: Text(
                              'Upload new image',
                              style: AppTypography.cardSubtitle.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryDark,
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
                        borderRadius: BorderRadius.circular(AppSpacing.radius18),
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
                              'Name',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
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
                                onSubmitted: (_) =>
                                    FocusScope.of(context).requestFocus(_phoneFocus),
                                decoration: _inputDecoration('Your name'),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Mobile phone',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
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
                                decoration: _inputDecoration('70 123 456'),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: AppColors.inputFill,
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radius14),
                                border: Border.all(
                                  color: AppColors.divider.withValues(alpha: 0.9),
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
                                      'Name changes are limited. Phone number changes require verification.',
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
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
              child: PrimaryButton(
                label: _isSaving ? 'Saving…' : 'Update info',
                onPressed: _isSaving ? null : _handleSave,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.cardSubtitle.copyWith(
        fontSize: 15,
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

