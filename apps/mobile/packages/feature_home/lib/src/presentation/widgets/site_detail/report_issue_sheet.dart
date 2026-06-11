import 'package:chisto_infrastructure/core/concurrency/single_flight.dart';
import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/providers/home_providers.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/src/data/site_issue_report_repository.dart';
import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/domain/models/site_report_reason.dart';
import 'package:feature_home/src/presentation/l10n/site_report_reason_l10n.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReportIssueSheet extends ConsumerStatefulWidget {
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
    return AppBottomSheet.show<bool>(
      context: context,
      useRootNavigator: true,
      keyboardInsetMode: SheetKeyboardInsetMode.overlay,
      builder: (BuildContext context) {
        return ReportIssueSheet(
          site: site,
          repository: repository ?? SiteIssueReportRepository(),
        );
      },
    );
  }

  @override
  ConsumerState<ReportIssueSheet> createState() => _ReportIssueSheetState();
}

class _ReportIssueSheetState extends ConsumerState<ReportIssueSheet> {
  SiteReportReason? _selectedReason;
  final TextEditingController _detailsController = TextEditingController();
  bool _isSubmitting = false;
  final SingleFlight<void> _submitFlight = SingleFlight<void>();

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  bool get _canSubmit => _selectedReason != null;

  Future<void> _handleSubmit() async {
    if (!_canSubmit || _isSubmitting) return;

    await _submitFlight.run(() async {
      if (!mounted || !_canSubmit) return;

      final NavigatorState navigator = Navigator.of(context);
      final l10n = context.l10n;
      final sitesRepository = ref.read(sitesRepositoryProvider);
      setState(() => _isSubmitting = true);

      try {
        await sitesRepository.trackFeedEvent(
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
        await sitesRepository.trackFeedEvent(
          widget.site.id,
          eventType: 'cta_report_issue_success',
          metadata: <String, dynamic>{'reason': _selectedReason!.name},
        );
        navigator.pop(true);
      } catch (_) {
        if (!mounted) return;
        await sitesRepository.trackFeedEvent(
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    return AppSheetScaffold(
      title: context.l10n.reportIssueSheetTitle,
      subtitle: context.l10n.reportIssueSheetSubtitle,
      useModalRouteShape: true,
      fillAvailableHeight: true,
      addBottomInset: true,
      trailing: AppCircleIconButton(
        icon: Icons.close_rounded,
        semanticLabel: context.l10n.commonClose,
        onTap: () => Navigator.of(context).pop(),
      ),
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.translucent,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(bottom: AppSpacing.lg + keyboardInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
            ...SiteReportReason.values.map(
              (SiteReportReason reason) => _ReasonTile(
                reason: reason,
                isSelected: _selectedReason == reason,
                onTap: () {
                  setState(() => _selectedReason = reason);
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.reportIssueDetailsLabel,
              style: AppTypographySurfaces.homeReportIssueLabel(
                Theme.of(context).textTheme,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppTextField(
              controller: _detailsController,
              hintText: context.l10n.reportIssueDetailsHint,
              onChanged: (_) => setState(() {}),
              maxLength: 500,
              maxLines: 3,
              minLines: 2,
              textInputAction: TextInputAction.done,
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
                    borderRadius: BorderRadius.circular(AppSpacing.radius10),
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
                        style: AppTypographySurfaces.homeReportIssueReasonTitle(
                          Theme.of(context).textTheme,
                          color: isSelected
                              ? AppColors.primaryDark
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        reason.localizedSubtitle(context.l10n),
                        style: AppTypographySurfaces.homeReportIssueCaption(
                          Theme.of(context).textTheme,
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
