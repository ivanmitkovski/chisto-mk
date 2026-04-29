import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/domain/models/site_report_reason.dart';
import 'package:chisto_mobile/features/home/presentation/l10n/site_report_reason_l10n.dart';
import 'package:chisto_mobile/features/home/data/site_issue_report_repository.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';

class ReportIssueSheet extends StatefulWidget {
  const ReportIssueSheet({
    super.key,
    required this.site,
    required this.repository,
  });

  final PollutionSite site;
  final SiteIssueReportRepository repository;

  static Future<bool?> show(
    BuildContext context, {
    required PollutionSite site,
    SiteIssueReportRepository? repository,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.transparent,
      barrierColor: AppColors.overlay,
      builder: (BuildContext context) {
        return ReportIssueSheet(
          site: site,
          repository: repository ?? SiteIssueReportRepository(),
        );
      },
    );
  }

  @override
  State<ReportIssueSheet> createState() => _ReportIssueSheetState();
}

class _ReportIssueSheetState extends State<ReportIssueSheet> {
  SiteReportReason? _selectedReason;
  final TextEditingController _detailsController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  bool get _canSubmit => _selectedReason != null;

  Future<void> _handleSubmit() async {
    if (!_canSubmit || _isSubmitting) return;

    final NavigatorState navigator = Navigator.of(context);
    final l10n = context.l10n;
    setState(() => _isSubmitting = true);
    AppHaptics.light();

    try {
      await ServiceLocator.instance.sitesRepository.trackFeedEvent(
        widget.site.id,
        eventType: 'cta_report_issue_started',
        metadata: <String, dynamic>{'reason': _selectedReason!.name},
      );
      await widget.repository.submitReport(
        siteId: widget.site.id,
        reason: _selectedReason!,
        details: _detailsController.text.trim().isEmpty
            ? null
            : _detailsController.text.trim(),
      );

      if (!mounted) return;
      AppHaptics.success();
      await ServiceLocator.instance.sitesRepository.trackFeedEvent(
        widget.site.id,
        eventType: 'cta_report_issue_success',
        metadata: <String, dynamic>{'reason': _selectedReason!.name},
      );
      navigator.pop(true);
    } catch (_) {
      if (!mounted) return;
      await ServiceLocator.instance.sitesRepository.trackFeedEvent(
        widget.site.id,
        eventType: 'cta_report_issue_failed',
        metadata: <String, dynamic>{'reason': _selectedReason?.name},
      );
      if (!mounted) return;
      AppSnack.show(
        context,
        message: l10n.reportIssueFailedSnack,
        type: AppSnackType.warning,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusSheet)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: AppSpacing.sheetHandle,
                    height: AppSpacing.sheetHandleHeight,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  context.l10n.reportIssueSheetTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.reportIssueSheetSubtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                ...SiteReportReason.values.map(
                  (SiteReportReason reason) => _ReasonTile(
                    reason: reason,
                    isSelected: _selectedReason == reason,
                    onTap: () {
                      AppHaptics.tap();
                      setState(() => _selectedReason = reason);
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  context.l10n.reportIssueDetailsLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextField(
                  controller: _detailsController,
                  onChanged: (_) => setState(() {}),
                  maxLength: 500,
                  maxLines: 3,
                  minLines: 2,
                  textInputAction: TextInputAction.done,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: context.l10n.reportIssueDetailsHint,
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                    filled: true,
                    fillColor: AppColors.inputFill,
                    contentPadding: const EdgeInsets.all(AppSpacing.sm),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radius14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radius14),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radius14),
                      borderSide: const BorderSide(
                        color: AppColors.primaryDark,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: _isSubmitting
                      ? context.l10n.reportIssueSubmitting
                      : context.l10n.reportIssueSubmit,
                  enabled: _canSubmit && !_isSubmitting,
                  onPressed: _handleSubmit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReasonTile extends StatelessWidget {
  const _ReasonTile({
    required this.reason,
    required this.isSelected,
    required this.onTap,
  });

  final SiteReportReason reason;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radius14),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radius14),
              color: AppColors.inputFill.withValues(alpha: 0.6),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryDark.withValues(alpha: 0.12)
                        : AppColors.panelBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryDark.withValues(alpha: 0.3)
                          : AppColors.divider,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    reason.icon,
                    size: 18,
                    color: isSelected
                        ? AppColors.primaryDark
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        reason.localizedLabel(context.l10n),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.primaryDark
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        reason.localizedSubtitle(context.l10n),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    size: 20,
                    color: AppColors.primaryDark,
                  )
                else
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
