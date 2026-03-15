import 'dart:io';
import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/profile/data/profile_mock_data.dart';
import 'package:chisto_mobile/features/profile/data/profile_avatar_state.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/photo_source_modal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';

class ProfileGeneralInfoScreen extends StatefulWidget {
  const ProfileGeneralInfoScreen({super.key});

  @override
  State<ProfileGeneralInfoScreen> createState() => _ProfileGeneralInfoScreenState();
}

class _ProfileGeneralInfoScreenState extends State<ProfileGeneralInfoScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();
  String? _localAvatarPath;

  @override
  void initState() {
    super.initState();
    final ProfileUser user = ProfileMockData.currentUser;
    _nameController = TextEditingController(text: user.name);
    _phoneController = TextEditingController(text: user.phoneNumber);
    _localAvatarPath = profileAvatarState.localPath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    AppHaptics.light();

    await Future<void>.delayed(AppMotion.slow);
    if (!mounted) return;

    setState(() => _isSaving = false);
    AppSnack.show(
      context,
      message: 'Profile updated',
      type: AppSnackType.success,
    );
  }

  Future<void> _handleChangeAvatar() async {
    AppHaptics.tap();
    final ImageSource? source = await showPhotoSourceModal(context);
    if (source == null || !mounted) return;

    final XFile? file = await _picker.pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 92,
      maxWidth: 1024,
    );
    if (file == null || !mounted) return;

    setState(() => _localAvatarPath = file.path);
    profileAvatarState.setLocalPath(file.path);
    AppSnack.show(
      context,
      message: 'Profile photo updated',
      type: AppSnackType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.panelBackground,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const AppBackButton(),
                const SizedBox(height: AppSpacing.sm),
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
                const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
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
                              TextField(
                                controller: _nameController,
                                textInputAction: TextInputAction.next,
                                decoration: _inputDecoration('John Doe'),
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
                              TextField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.done,
                                decoration: _inputDecoration(
                                  '+389 70 123 456',
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: AppColors.inputFill,
                                  borderRadius: BorderRadius.circular(AppSpacing.radius14),
                                  border: Border.all(
                                    color: AppColors.divider
                                        .withValues(alpha: 0.9),
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
                                        'You can only change your name and number a limited number of times.',
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
              PrimaryButton(
                label: _isSaving ? 'Saving…' : 'Update info',
                onPressed: _isSaving ? null : _handleSave,
              ),
            ],
          ),
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

