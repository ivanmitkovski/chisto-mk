import 'dart:async';

import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_shadows.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/profile/presentation/widgets/blocked_user_list_tile.dart';
import 'package:chisto_mobile/features/profile/presentation/widgets/profile_sub_screen_header.dart';
import 'package:chisto_mobile/features/safety/data/ugc_moderation_repository.dart';
import 'package:chisto_mobile/features/safety/domain/blocked_user_row.dart';
import 'package:chisto_mobile/shared/widgets/atoms/app_loading_indicator.dart';
import 'package:chisto_mobile/shared/widgets/atoms/app_snack.dart';
import 'package:chisto_mobile/shared/widgets/molecules/app_error_view.dart';
import 'package:chisto_mobile/shared/widgets/organisms/app_confirm_dialog.dart';
import 'package:flutter/material.dart';

class ProfileBlockedUsersScreen extends StatefulWidget {
  const ProfileBlockedUsersScreen({
    super.key,
    this.repository,
  });

  final UgcModerationRepository? repository;

  @override
  State<ProfileBlockedUsersScreen> createState() => _ProfileBlockedUsersScreenState();
}

class _ProfileBlockedUsersScreenState extends State<ProfileBlockedUsersScreen> {
  late final UgcModerationRepository _repo =
      widget.repository ?? UgcModerationRepository();
  bool _loading = true;
  AppError? _error;
  List<BlockedUserRow> _blocks = <BlockedUserRow>[];
  String? _unblockingUserId;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<BlockedUserRow> rows = await _repo.listBlocks();
      if (!mounted) return;
      setState(() {
        _blocks = rows;
        _loading = false;
      });
    } on AppError catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _error = AppError.unknown();
        _loading = false;
      });
    }
  }

  Future<void> _confirmUnblock(BlockedUserRow row) async {
    final bool? confirmed = await AppConfirmDialog.show(
      context: context,
      title: context.l10n.safetyUnblockUserTitle,
      body: context.l10n.safetyUnblockUserBody(row.displayName),
      confirmLabel: context.l10n.safetyUnblockUserConfirm,
      cancelLabel: context.l10n.commonCancel,
      isDestructive: false,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _unblockingUserId = row.blockedUserId);
    try {
      await _repo.unblockUser(row.blockedUserId);
      if (!mounted) return;
      await _load();
    } on Object {
      if (!mounted) return;
      AppSnack.show(
        context,
        message: context.l10n.profileBlockedUsersUnblockFailed,
        type: AppSnackType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _unblockingUserId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ProfileSubScreenHeader(
              title: l10n.profileBlockedUsersTile,
              subtitle: l10n.profileBlockedUsersSubtitle,
            ),
            Expanded(child: _buildBody(l10n)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(dynamic l10n) {
    if (_loading) {
      return const Center(child: AppLoadingIndicator());
    }
    if (_error != null) {
      return AppErrorView(error: _error!, onRetry: _load);
    }
    if (_blocks.isEmpty) {
      return _BlockedUsersEmptyState(
        title: l10n.profileBlockedUsersEmpty,
        subtitle: l10n.profileBlockedUsersEmptySubtitle,
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        itemCount: _blocks.length,
        separatorBuilder: (_, int index) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (BuildContext context, int index) {
          final BlockedUserRow row = _blocks[index];
          return BlockedUserListTile(
            row: row,
            unblockLabel: l10n.profileBlockedUsersUnblock,
            isUnblocking: _unblockingUserId == row.blockedUserId,
            onUnblock: _unblockingUserId == null
                ? () => unawaited(_confirmUnblock(row))
                : null,
          );
        },
      ),
    );
  }
}

class _BlockedUsersEmptyState extends StatelessWidget {
  const _BlockedUsersEmptyState({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                boxShadow: AppShadows.panel(Theme.of(context).colorScheme),
              ),
              child: const Icon(
                Icons.block_flipped,
                size: 30,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.emptyStateTitle.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.25,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.emptyStateSubtitle,
            ),
          ],
        ),
      ),
    );
  }
}
